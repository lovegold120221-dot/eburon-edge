import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kokoro_tts_flutter/kokoro_tts_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/tts_model_info.dart';
import '../chat_storage_service.dart';
import '../log_service.dart';
import '../model_manager.dart';

enum TtsState { uninitialized, ready, speaking, error }

class KokoroTtsService extends GetxService {
  Kokoro? _kokoro;
  AudioPlayer? _audioPlayer;
  StreamSubscription? _playerStateSub;

  final state = TtsState.uninitialized.obs;
  final isSpeaking = false.obs;
  final ttsEnabled = false.obs;
  final autoPlay = false.obs;

  String? _selectedVoiceId;
  String? _currentText;
  String? _modelsDir;

  /// Tracks model download progress.
  final modelDownloadProgress = 0.0.obs;
  final modelDownloadSpeed = 0.0.obs;
  final isModelDownloading = false.obs;
  bool _modelDownloadCancelled = false;

  /// The expected ONNX model filename once downloaded.
  static const _modelFilename = 'kokoro-82m.onnx';

  String? get selectedVoiceId => _selectedVoiceId;
  List<TtsVoiceInfo> get availableVoices => TtsCatalog.voices;
  TtsVoiceInfo? getVoice(String id) => TtsCatalog.getVoice(id);

  @override
  void onInit() {
    super.onInit();
    _initSettings();
    _tryAutoLoad();
  }

  void _initSettings() {
    try {
      final storage = Get.find<ChatStorageService>();
      ttsEnabled.value = storage.ttsEnabled;
      autoPlay.value = storage.ttsAutoPlay;
      _selectedVoiceId = storage.ttsVoiceId;
    } catch (_) {
      ttsEnabled.value = false;
      autoPlay.value = false;
    }
  }

  Future<void> _tryAutoLoad() async {
    try {
      final modelPath = await _findOnnxModelPath();
      if (modelPath == null) {
        debugPrint('KokoroTts: No ONNX model found, TTS unavailable');
        return;
      }
      debugPrint('KokoroTts: Auto-loading model from $modelPath');
      await loadModel(modelPath);
    } catch (e) {
      if (kDebugMode) debugPrint('KokoroTts: Auto-load skipped: $e');
    }
  }

  /// Look for a previously downloaded ONNX model in the TTS directory.
  Future<String?> _findOnnxModelPath() async {
    final dir = await _getTtsDir();
    final candidate = p.join(dir, _modelFilename);
    if (await File(candidate).exists()) return candidate;
    return null;
  }

  Future<String> _getTtsDir() async {
    if (_modelsDir != null) return _modelsDir!;
    try {
      final manager = Get.find<ModelManager>();
      _modelsDir = p.join(manager.modelsDir, 'tts');
      await Directory(_modelsDir!).create(recursive: true);
      return _modelsDir!;
    } catch (e) {
      final appDir = await getApplicationDocumentsDirectory();
      _modelsDir = p.join(appDir.path, 'EburonEdge', 'tts');
      await Directory(_modelsDir!).create(recursive: true);
      return _modelsDir!;
    }
  }

  Future<void> loadModel(String modelPath) async {
    try {
      state.value = TtsState.uninitialized;
      await _unloadKokoro();

      _kokoro = Kokoro(KokoroConfig(
        modelPath: modelPath,
        voicesPath: 'assets/voices.json',
      ));
      await _kokoro!.initialize();

      state.value = TtsState.ready;
      if (kDebugMode) debugPrint('KokoroTts: Model loaded from $modelPath');
    } catch (e) {
      state.value = TtsState.error;
      if (kDebugMode) debugPrint('KokoroTts: Failed to load model: $e');
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    await _unloadKokoro();
    state.value = TtsState.uninitialized;
  }

  Future<void> _unloadKokoro() async {
    if (_kokoro != null) {
      try {
        await _kokoro!.dispose();
      } catch (_) {}
      _kokoro = null;
    }
  }

  Future<bool> selectVoice(String voiceId) async {
    _selectedVoiceId = voiceId;
    try {
      Get.find<ChatStorageService>().ttsVoiceId = voiceId;
    } catch (_) {}
    if (kDebugMode) debugPrint('KokoroTts: Selected voice $voiceId');
    return true;
  }

  /// Download the TTS model (ONNX) with progress and cancel support.
  Future<void> downloadModel({
    required String url,
    required String destPath,
    required int totalBytes,
  }) async {
    _modelDownloadCancelled = false;
    isModelDownloading.value = true;
    modelDownloadProgress.value = 0.0;
    modelDownloadSpeed.value = 0.0;

    final file = File(destPath);
    int startOffset = 0;
    if (await file.exists()) {
      startOffset = await file.length();
    }

    try {
      final client = Get.find<http.Client>();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'EburonEdge/1.0';
      if (startOffset > 0) {
        request.headers['Range'] = 'bytes=$startOffset-';
      }
      final response = await client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
      int downloaded = startOffset;
      final stopwatch = Stopwatch()..start();
      int lastReported = startOffset;

      try {
        await for (final chunk in response.stream) {
          if (_modelDownloadCancelled) break;

          sink.add(chunk);
          downloaded += chunk.length;
          modelDownloadProgress.value =
              totalBytes > 0 ? downloaded / totalBytes : 0.0;

          final elapsed = stopwatch.elapsedMilliseconds;
          if (elapsed > 100) {
            final bytesSinceLastReport = downloaded - lastReported;
            modelDownloadSpeed.value =
                bytesSinceLastReport / (elapsed / 1000.0);
            lastReported = downloaded;
            stopwatch.reset();
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (_modelDownloadCancelled) {
        if (await file.exists()) await file.delete();
      } else {
        modelDownloadProgress.value = 1.0;
      }
    } catch (e) {
      if (await file.exists()) await file.delete();
      rethrow;
    } finally {
      isModelDownloading.value = false;
    }
  }

  /// Cancel an in-progress model download.
  void cancelModelDownload() {
    _modelDownloadCancelled = true;
    isModelDownloading.value = false;
  }

  Future<bool> speak(String text) async {
    if (!ttsEnabled.value || text.isEmpty) {
      _log('TTS disabled or empty text', level: 'WARN');
      return false;
    }
    if (state.value != TtsState.ready) {
      _log('TTS model not loaded, state=${state.value}', level: 'WARN');
      return false;
    }
    final voice = _selectedVoiceId ?? TtsCatalog.defaultVoice.id;
    _log('Speaking: "${text.substring(0, text.length.clamp(0, 80))}..." voice=$voice');

    // Split long text into sentences to stay within the tokenizer's 510-phoneme limit.
    final sentences = _splitSentences(text);
    if (sentences.length > 1) {
      _log('Split into ${sentences.length} sentences');
    }

    isSpeaking.value = true;
    _currentText = text;

    try {
      // Create a tokenizer for G2P phonemization (separate from Kokoro's internal one).
      // We phonemize first, then pass phonemes to createTTS with isPhonemes: true,
      // matching the proven pattern from the package's integration tests.
      final tokenizer = Tokenizer();
      await tokenizer.ensureInitialized();

      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        if (sentence.trim().isEmpty) continue;

        _log('Phonemizing sentence ${i + 1}/${sentences.length}...');
        final phonemes = await tokenizer.phonemize(sentence, lang: 'en-us');
        if (phonemes.isEmpty) {
          _log('Empty phonemes for sentence $i', level: 'WARN');
          continue;
        }
        _log('Phonemes (${phonemes.length} chars)');

        final result = await _kokoro!.createTTS(
          text: phonemes,
          voice: voice,
          isPhonemes: true,
          lang: 'en-us',
        );
        _log('Sentence ${i + 1} audio: ${result.audio.length} samples');

        if (result.audio.isNotEmpty) {
          final audio = Float32List.fromList(
            result.audio.map((e) => e.toDouble()).toList(),
          );
          await _playAudio(audio, result.sampleRate);
        }
      }
      isSpeaking.value = false;
      _currentText = null;
      return true;
    } catch (e) {
      _log('TTS speak error: $e', level: 'ERROR');
      isSpeaking.value = false;
      _currentText = null;
      return false;
    }
  }

  /// Split text into sentences for incremental TTS synthesis.
  /// Each sentence is at most ~300 chars to stay well under the 510-phoneme limit.
  List<String> _splitSentences(String text) {
    if (text.length <= 300) return [text];

    final result = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Split at sentence boundaries (period, exclamation, question mark + space/end)
      if ((text[i] == '.' || text[i] == '!' || text[i] == '?') &&
          (i + 1 >= text.length || text[i + 1] == ' ')) {
        final chunk = buffer.toString().trim();
        if (chunk.isNotEmpty) {
          result.add(chunk);
          buffer.clear();
        }
      }
      // Hard split at 300 chars if no sentence boundary found
      if (buffer.length >= 300) {
        final chunk = buffer.toString().trim();
        if (chunk.isNotEmpty) {
          result.add(chunk);
          buffer.clear();
        }
      }
    }
    // Add remaining text
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      result.add(remaining);
    }

    return result.isEmpty ? [text] : result;
  }

  Future<void> _playAudio(Float32List audio, int sampleRate) async {
    if (audio.isEmpty) return;

    await _disposePlayer();

    // Encode audio to WAV
    final wavBytes = _encodeWav(audio, sampleRate);
    _log('WAV encoded: ${wavBytes.length} bytes, ${audio.length} samples @ ${sampleRate}Hz');

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      p.join(tempDir.path, 'kokoro_tts_${_randomString()}.wav'),
    );
    await tempFile.writeAsBytes(wavBytes);

    try {
      _audioPlayer = AudioPlayer();
      final completer = Completer<void>();

      _playerStateSub = _audioPlayer!.onPlayerComplete.listen((_) {
        _log('Audio playback completed');
        if (!completer.isCompleted) completer.complete();
      });

      // Fallback timeout: duration + 3s safety margin
      final durationMs = (audio.length / sampleRate * 1000).round();
      final timeoutMs = durationMs + 3000;
      _log('Playing audio (est ${durationMs}ms, timeout ${timeoutMs}ms)');
      Timer(
        Duration(milliseconds: timeoutMs),
        () {
          if (!completer.isCompleted) {
            _log('Audio playback timeout fired', level: 'WARN');
            completer.complete();
          }
        },
      );

      await _audioPlayer!.play(DeviceFileSource(tempFile.path));
      await completer.future;

      // Clean up temp file
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
    } catch (e) {
      _log('Audio playback error: $e', level: 'ERROR');
    } finally {
      await _disposePlayer();
    }
  }

  void _log(String msg, {String level = 'INFO'}) {
    debugPrint('KokoroTts: $msg');
    try {
      final log = Get.find<LogService>();
      switch (level) {
        case 'ERROR': log.error(msg, source: 'TTS'); break;
        case 'WARN': log.warn(msg, source: 'TTS'); break;
        default: log.info(msg, source: 'TTS');
      }
    } catch (_) {}
  }

  Future<void> _disposePlayer() async {
    await _playerStateSub?.cancel();
    _playerStateSub = null;
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.dispose();
      } catch (_) {}
      _audioPlayer = null;
    }
  }

  Uint8List _encodeWav(Float32List samples, int sampleRate) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = samples.length * bitsPerSample ~/ 8;
    final fileSize = 44 + dataSize;
    final writer = BytesBuilder();
    _writeString(writer, 'RIFF');
    _writeInt32(writer, fileSize - 8);
    _writeString(writer, 'WAVE');
    _writeString(writer, 'fmt ');
    _writeInt32(writer, 16);
    _writeInt16(writer, 1);
    _writeInt16(writer, numChannels);
    _writeInt32(writer, sampleRate);
    _writeInt32(writer, byteRate);
    _writeInt16(writer, blockAlign);
    _writeInt16(writer, bitsPerSample);
    _writeString(writer, 'data');
    _writeInt32(writer, dataSize);
    for (final sample in samples) {
      final clamped = sample.clamp(-1.0, 1.0);
      final intSample =
          (clamped * 32767).round().clamp(-32768, 32767);
      _writeInt16(writer, intSample);
    }
    return writer.toBytes();
  }

  void _writeString(BytesBuilder builder, String s) =>
      builder.add(s.codeUnits);
  void _writeInt32(BytesBuilder builder, int value) {
    builder.addByte(value & 0xFF);
    builder.addByte((value >> 8) & 0xFF);
    builder.addByte((value >> 16) & 0xFF);
    builder.addByte((value >> 24) & 0xFF);
  }

  void _writeInt16(BytesBuilder builder, int value) {
    builder.addByte(value & 0xFF);
    builder.addByte((value >> 8) & 0xFF);
  }

  String _randomString() => Random().nextInt(100000).toString();

  /// Run a TTS diagnostic test. Returns a list of step results.
  /// Tests: audio playback, tokenizer, model inference.
  Future<List<String>> testTts() async {
    final results = <String>[];

    // 1. Test audio playback with a generated sine wave
    results.add('--- TTS Diagnostic ---');
    results.add('State: ${state.value}');
    results.add('Enabled: ${ttsEnabled.value}');
    results.add('Voice: ${_selectedVoiceId ?? "none"}');
    results.add('Model loaded: ${_kokoro != null}');

    try {
      results.add('--- Test 1: Audio playback (sine wave) ---');
      final sampleRate = 24000;
      final durationSec = 0.5;
      final numSamples = (sampleRate * durationSec).round();
      final sineWave = Float32List(numSamples);
      for (int i = 0; i < numSamples; i++) {
        sineWave[i] = (0.3 * sin(2 * pi * 440 * i / sampleRate));
      }
      await _playAudio(sineWave, sampleRate);
      results.add('✓ Sine wave playback completed');
    } catch (e) {
      results.add('✗ Audio playback failed: $e');
    }

    // 2. Test tokenizer
    try {
      results.add('--- Test 2: Tokenizer ---');
      final tokenizer = Tokenizer();
      await tokenizer.ensureInitialized();
      final phonemes = await tokenizer.phonemize('Hello world.', lang: 'en-us');
      results.add('Phonemes: "$phonemes" (${phonemes.length} chars)');
      if (phonemes.isNotEmpty && phonemes.length > 5) {
        results.add('✓ Tokenizer OK');
      } else {
        results.add('✗ Tokenizer produced short/empty output');
      }
    } catch (e) {
      results.add('✗ Tokenizer failed: $e');
    }

    // 3. Test model inference (only if model is loaded)
    if (_kokoro != null && state.value == TtsState.ready) {
      try {
        results.add('--- Test 3: Model inference ---');
        final tokenizer = Tokenizer();
        await tokenizer.ensureInitialized();
        final phonemes = await tokenizer.phonemize('Hello.', lang: 'en-us');
        final voice = _selectedVoiceId ?? TtsCatalog.defaultVoice.id;
        results.add('Voice: $voice');
        final ttsResult = await _kokoro!.createTTS(
          text: phonemes,
          voice: voice,
          isPhonemes: true,
        );
        results.add(
            'Audio samples: ${ttsResult.audio.length}, sampleRate: ${ttsResult.sampleRate}');
        if (ttsResult.audio.length > 100) {
          results.add('✓ Model inference OK (${ttsResult.audio.length} samples)');
          // Play the result
          final audio = Float32List.fromList(
            ttsResult.audio.map((e) => e.toDouble()).toList(),
          );
          await _playAudio(audio, ttsResult.sampleRate);
          results.add('✓ Playback completed');
        } else {
          results.add('✗ Model produced too few audio samples');
        }
      } catch (e) {
        results.add('✗ Model inference failed: $e');
      }
    } else {
      results.add('--- Test 3: Model inference --- SKIPPED (model not loaded)');
    }

    results.add('--- Diagnostic complete ---');
    return results;
  }

  /// Stop current speech playback immediately.
  Future<void> stop() async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
      } catch (_) {}
      await _disposePlayer();
    }
    isSpeaking.value = false;
    _currentText = null;
  }

  Future<void> togglePlay(String text) async {
    if (isSpeaking.value && _currentText == text) {
      await stop();
    } else {
      await stop();
      await speak(text);
    }
  }

  bool isSpeakingThis(String text) =>
      isSpeaking.value && _currentText == text;

  void setEnabled(bool val) {
    ttsEnabled.value = val;
    try {
      Get.find<ChatStorageService>().ttsEnabled = val;
    } catch (_) {}
    if (!val) stop();
  }

  void setAutoPlay(bool val) {
    autoPlay.value = val;
    try {
      Get.find<ChatStorageService>().ttsAutoPlay = val;
    } catch (_) {}
  }

  /// Check if the ONNX model file exists in the TTS directory.
  Future<bool> hasModelDownloaded() async {
    final dir = await _getTtsDir();
    return await File(p.join(dir, _modelFilename)).exists();
  }

  /// Get path to the downloaded ONNX model in the TTS directory.
  Future<String?> getDownloadedModelPath() async {
    final dir = await _getTtsDir();
    final path = p.join(dir, _modelFilename);
    if (await File(path).exists()) return path;
    return null;
  }

  /// Get the destination path where the model should be saved.
  Future<String> getModelDestPath() async {
    final dir = await _getTtsDir();
    return p.join(dir, _modelFilename);
  }

  @override
  void onClose() {
    stop();
    _unloadKokoro();
    super.onClose();
  }
}
