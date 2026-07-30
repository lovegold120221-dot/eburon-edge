import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/tts_model_info.dart';
import '../model_manager.dart';

enum LuxTtsState { uninitialized, downloading, ready, error }

/// Tracks download progress for a single LuxTTS file.
class LuxFileDownload {
  final String fileId;
  final double totalBytes;
  double receivedBytes;
  double speedBytesPerSec;
  bool isCancelled;

  LuxFileDownload({
    required this.fileId,
    required this.totalBytes,
    this.receivedBytes = 0,
    this.speedBytesPerSec = 0,
    this.isCancelled = false,
  });

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
}

class LuxTtsService extends GetxService {
  AudioPlayer? _audioPlayer;

  final state = LuxTtsState.uninitialized.obs;
  final isSpeaking = false.obs;
  final overallProgress = 0.0.obs;
  final currentFile = ''.obs;

  /// Tracks which files are downloaded on disk.
  final downloadedFiles = <String>[].obs;

  /// Tracks active file downloads.
  final fileDownloads = <String, LuxFileDownload>{}.obs;

  String? _modelsDir;
  bool _allFilesCancelled = false;

  @override
  void onInit() {
    super.onInit();
    _refreshStatus();
  }

  Future<String> _getLuxDir() async {
    if (_modelsDir != null) return _modelsDir!;
    try {
      final manager = Get.find<ModelManager>();
      _modelsDir = p.join(manager.modelsDir, 'tts', 'lux');
      await Directory(_modelsDir!).create(recursive: true);
      return _modelsDir!;
    } catch (e) {
      final appDir = await getApplicationDocumentsDirectory();
      _modelsDir = p.join(appDir.path, 'EburonEdge', 'tts', 'lux');
      await Directory(_modelsDir!).create(recursive: true);
      return _modelsDir!;
    }
  }

  /// Scan the LuxTTS directory for downloaded files.
  Future<void> _refreshStatus() async {
    final dir = await _getLuxDir();
    if (!await Directory(dir).exists()) {
      downloadedFiles.value = [];
      return;
    }
    final files = await Directory(dir)
        .list()
        .where((f) => f is File)
        .map((f) => p.basename(f.path))
        .toList();
    downloadedFiles.value = files;
  }

  /// Check if all required LuxTTS files are downloaded.
  Future<bool> isComplete() async {
    await _refreshStatus();
    final required = TtsCatalog.luxTts.files
        .where((f) => !f.id.contains('int8')) // skip int8 variants
        .map((f) => f.filename)
        .toSet();
    return required.every((f) => downloadedFiles.contains(f));
  }

  /// Download all LuxTTS model files with progress.
  Future<void> downloadAll() async {
    _allFilesCancelled = false;
    state.value = LuxTtsState.downloading;
    overallProgress.value = 0.0;

    final model = TtsCatalog.luxTts;
    // Only download the non-int8 files (full precision)
    final filesToDl = model.files
        .where((f) => !f.id.contains('int8'))
        .toList();
    final totalBytes =
        filesToDl.fold<double>(0, (sum, f) => sum + f.sizeMb * 1024 * 1024);
    double accumulatedBytes = 0;

    for (final file in filesToDl) {
      if (_allFilesCancelled) break;

      currentFile.value = file.name;
      final destPath = p.join(await _getLuxDir(), file.filename);

      // Skip if already downloaded
      if (downloadedFiles.contains(file.filename)) {
        accumulatedBytes += file.sizeMb * 1024 * 1024;
        overallProgress.value =
            totalBytes > 0 ? accumulatedBytes / totalBytes : 0;
        continue;
      }

      final fileBytes = (file.sizeMb * 1024 * 1024).toInt();
      final dlState = LuxFileDownload(
        fileId: file.id,
        totalBytes: fileBytes.toDouble(),
      );
      fileDownloads[file.id] = dlState;

      try {
        final client = Get.find<http.Client>();
        final request = http.Request('GET', Uri.parse(file.url));
        final response = await client.send(request);
        if (response.statusCode != 200) {
          throw Exception('Download failed: HTTP ${response.statusCode}');
        }

        final sink = File(destPath).openWrite();
        int received = 0;
        final stopwatch = Stopwatch()..start();
        int lastSpeedCheck = 0;
        int lastSpeedBytes = 0;

        await for (final chunk in response.stream) {
          if (_allFilesCancelled || dlState.isCancelled) break;

          sink.add(chunk);
          received += chunk.length;
          dlState.receivedBytes = received.toDouble();

          if (stopwatch.elapsedMilliseconds - lastSpeedCheck > 500) {
            final elapsed =
                (stopwatch.elapsedMilliseconds - lastSpeedCheck) / 1000;
            final bytesDelta = received - lastSpeedBytes;
            dlState.speedBytesPerSec =
                elapsed > 0 ? bytesDelta / elapsed : 0;
            lastSpeedCheck = stopwatch.elapsedMilliseconds;
            lastSpeedBytes = received;
            fileDownloads.refresh();
          }

          // Update overall progress
          accumulatedBytes = fileDownloads.values.fold<double>(
            0,
            (s, d) => s + d.receivedBytes,
          );
          overallProgress.value =
              totalBytes > 0 ? accumulatedBytes / totalBytes : 0;
        }

        await sink.flush();
        await sink.close();

        if (!_allFilesCancelled && !dlState.isCancelled) {
          if (!downloadedFiles.contains(file.filename)) {
            downloadedFiles.add(file.filename);
          }
          accumulatedBytes += file.sizeMb * 1024 * 1024;
        } else {
          final f = File(destPath);
          if (await f.exists()) await f.delete();
        }
      } catch (e) {
        final f = File(destPath);
        if (await f.exists()) await f.delete();
        rethrow;
      } finally {
        fileDownloads.remove(file.id);
      }

      overallProgress.value =
          totalBytes > 0 ? accumulatedBytes / totalBytes : 0;
    }

    currentFile.value = '';
    if (!_allFilesCancelled) {
      state.value = LuxTtsState.ready;
      overallProgress.value = 1.0;
    } else {
      state.value = LuxTtsState.uninitialized;
    }
  }

  /// Cancel all in-progress downloads.
  void cancelAll() {
    _allFilesCancelled = true;
    for (final entry in fileDownloads.entries) {
      entry.value.isCancelled = true;
    }
    fileDownloads.clear();
    state.value = LuxTtsState.uninitialized;
    currentFile.value = '';
    overallProgress.value = 0.0;
  }

  /// Delete all downloaded LuxTTS files.
  Future<void> deleteAll() async {
    final dir = await _getLuxDir();
    if (await Directory(dir).exists()) {
      await Directory(dir).delete(recursive: true);
    }
    downloadedFiles.value = [];
    state.value = LuxTtsState.uninitialized;
  }

  /// Get path to a specific downloaded file.
  Future<String?> getFilePath(String fileId) async {
    final dir = await _getLuxDir();
    final path = p.join(dir, fileId);
    if (await File(path).exists()) return path;
    return null;
  }

  /// Check if a specific file is downloaded.
  Future<bool> hasFile(String fileId) async {
    if (downloadedFiles.contains(fileId)) return true;
    final dir = await _getLuxDir();
    return await File(p.join(dir, fileId)).exists();
  }

  /// Get total download size in MB for display.
  double get totalSizeMb => TtsCatalog.luxTts.totalSizeMb;

  @override
  void onClose() {
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    super.onClose();
  }
}
