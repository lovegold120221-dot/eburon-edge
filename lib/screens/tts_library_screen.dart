/// TTS Library screen — download TTS models and voices.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../services/tts/kokoro_tts_service.dart';
import '../services/tts/lux_tts_service.dart';
import '../models/tts_model_info.dart';
import '../theme/app_colors.dart';

enum _TtsProvider { kokoro, lux }

/// Embedded or full-screen TTS library.
class TtsLibraryScreen extends StatefulWidget {
  final bool embedded;
  const TtsLibraryScreen({super.key, this.embedded = false});

  @override
  State<TtsLibraryScreen> createState() => _TtsLibraryScreenState();
}

class _TtsLibraryScreenState extends State<TtsLibraryScreen> {
  _TtsProvider _provider = _TtsProvider.kokoro;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top bar ──────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            top: widget.embedded
                ? 0
                : MediaQuery.of(context).padding.top,
            left: 4,
            right: 4,
          ),
          decoration: BoxDecoration(
            color: context.bg,
            border: Border(
              bottom: BorderSide(color: context.border, width: 0.5),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  'TTS Models',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: context.text,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),

        // ── Provider tabs ───────────────────────────
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _providerTab('Kokoro', _TtsProvider.kokoro),
              const SizedBox(width: 8),
              _providerTab('LuxTTS', _TtsProvider.lux),
            ],
          ),
        ),

        // ── Body ─────────────────────────────────────
        Expanded(
          child: _provider == _TtsProvider.kokoro
              ? const _KokoroSection()
              : const _LuxSection(),
        ),
      ],
    );
  }

  Widget _providerTab(String label, _TtsProvider provider) {
    final selected = _provider == provider;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _provider = provider),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : context.bgPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : context.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.accent : context.textM,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KOKORO SECTION
// ═══════════════════════════════════════════════════════════════

class _KokoroSection extends StatefulWidget {
  const _KokoroSection();

  @override
  State<_KokoroSection> createState() => _KokoroSectionState();
}

class _KokoroSectionState extends State<_KokoroSection> {
  String? _selectedAccent;
  bool _modelDownloaded = false;
  late KokoroTtsService _service;

  @override
  void initState() {
    super.initState();
    _service = Get.find<KokoroTtsService>();
    _checkModelDownloaded();
  }

  Future<void> _checkModelDownloaded() async {
    final downloaded = await _service.hasModelDownloaded();
    if (mounted) {
      setState(() => _modelDownloaded = downloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _service.state.value;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _sectionHeader(context, 'Kokoro-82M Model'),
          const SizedBox(height: 8),
          _kokoroModelCard(context, _modelDownloaded, state),

          const SizedBox(height: 24),

          _sectionHeader(
            context,
            'Voices (${TtsCatalog.voices.length})',
          ),
          const SizedBox(height: 4),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _accentChip(context, 'All', null),
                ...TtsCatalog.accentLabels.entries.map(
                  (e) => _accentChip(context, e.value, e.key),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ..._filteredVoices().map((voice) {
            final isSelected = _service.selectedVoiceId == voice.id;
            return _VoiceCard(
              key: ValueKey(voice.id),
              voice: voice,
              isSelected: isSelected,
              service: _service,
            );
          }),

          const SizedBox(height: 24),
        ],
      );
    });
  }

  List<TtsVoiceInfo> _filteredVoices() {
    if (_selectedAccent == null) return TtsCatalog.voices;
    return TtsCatalog.voicesByAccent[_selectedAccent] ?? [];
  }

  Widget _accentChip(BuildContext context, String label, String? accent) {
    final selected = _selectedAccent == accent;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : context.text,
          ),
        ),
        selected: selected,
        onSelected: (_) => setState(() => _selectedAccent = accent),
        selectedColor: AppColors.accent,
        checkmarkColor: Colors.white,
        backgroundColor: context.bgPanel,
        side: BorderSide(
          color: selected
              ? AppColors.accent
              : context.border.withValues(alpha: 0.5),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textD,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Kokoro Model card ─────────────────────────────────────

Widget _kokoroModelCard(
  BuildContext context,
  bool modelDownloaded,
  TtsState state,
) {
  final model = TtsCatalog.defaultModel;
  final svc = Get.find<KokoroTtsService>();

  return Container(
    decoration: BoxDecoration(
      color: context.bgPanel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.border.withValues(alpha: 0.5)),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.record_voice_over_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${model.sizeMb} MB — ONNX Runtime',
                    style: TextStyle(fontSize: 12, color: context.textD),
                  ),
                ],
              ),
            ),
            if (modelDownloaded && state == TtsState.ready)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Loaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          model.description,
          style: TextStyle(fontSize: 12, color: context.textD, height: 1.4),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (svc.isModelDownloading.value) {
            return _buildKokoroDownloadProgress(context, svc);
          }
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                modelDownloaded
                    ? Icons.play_arrow_rounded
                    : Icons.download_rounded,
                size: 18,
              ),
              label: Text(
                modelDownloaded
                    ? (state == TtsState.ready ? 'Reload Model' : 'Load Model')
                    : 'Download Model (${model.sizeMb} MB)',
              ),
              onPressed: () => _handleKokoroModelAction(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

Widget _buildKokoroDownloadProgress(
    BuildContext context, KokoroTtsService svc) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Downloading model...',
                style: TextStyle(fontSize: 12, color: context.text),
              ),
            ),
            Text(
              '${(svc.modelDownloadProgress.value * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: svc.modelDownloadProgress.value.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: context.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => svc.cancelModelDownload(),
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
          ),
        ),
      ],
    ),
  );
}

Future<void> _handleKokoroModelAction(BuildContext context) async {
  final svc = Get.find<KokoroTtsService>();
  final existingPath = await svc.getDownloadedModelPath();

  if (existingPath != null) {
    try {
      await svc.loadModel(existingPath);
      if (context.mounted) {
        Get.snackbar(
          'TTS Model',
          'Model loaded successfully (${p.extension(existingPath)})',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar('Error', 'Failed to load model: $e');
      }
    }
  } else {
    if (context.mounted) _downloadKokoroModel(context);
  }
}

Future<void> _downloadKokoroModel(BuildContext context) async {
  if (!context.mounted) return;

  final model = TtsCatalog.defaultModel;
  final svc = Get.find<KokoroTtsService>();
  final destPath = await svc.getModelDestPath();
  await Directory(p.dirname(destPath)).create(recursive: true);

  try {
    await svc.downloadModel(
      url: model.modelUrl,
      destPath: destPath,
      totalBytes: (model.sizeMb * 1024 * 1024).toInt(),
    );

    if (svc.isModelDownloading.value) return;

    try {
      await svc.loadModel(destPath);
      if (context.mounted) {
        Get.snackbar(
          'TTS Model',
          'Model downloaded and loaded successfully!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar('Error', 'Failed to load downloaded model: $e');
      }
    }
  } catch (e) {
    if (context.mounted) {
      Get.snackbar('Download Failed', 'Could not download model: $e');
    }
  }
}

// ── Kokoro Voice card ────────────────────────────────────

class _VoiceCard extends StatelessWidget {
  final TtsVoiceInfo voice;
  final bool isSelected;
  final KokoroTtsService service;

  const _VoiceCard({
    super.key,
    required this.voice,
    required this.isSelected,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.08)
            : context.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : context.border.withValues(alpha: 0.5),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await service.selectVoice(voice.id);
          if (context.mounted) {
            Get.snackbar(
              'Voice Selected',
              voice.name,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : context.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  voice.gender == 'female'
                      ? Icons.female_rounded
                      : Icons.male_rounded,
                  color: isSelected ? Colors.white : context.textD,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: context.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          voice.language,
                          style: TextStyle(
                              fontSize: 11, color: context.textD),
                        ),
                        if (voice.accent != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${voice.accent}',
                            style: TextStyle(
                                fontSize: 11, color: context.textD),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LUXTTS SECTION
// ═══════════════════════════════════════════════════════════════

class _LuxSection extends StatefulWidget {
  const _LuxSection();

  @override
  State<_LuxSection> createState() => _LuxSectionState();
}

class _LuxSectionState extends State<_LuxSection> {
  late LuxTtsService _service;

  @override
  void initState() {
    super.initState();
    _service = Get.find<LuxTtsService>();
  }

  @override
  Widget build(BuildContext context) {
    final model = TtsCatalog.luxTts;

    return Obx(() {
      final isComplete = _service.downloadedFiles.length >= 4;
      final isDownloading = _service.state.value == LuxTtsState.downloading;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Model card ─────────────────────────────
          _sectionHeader(context, model.name),
          const SizedBox(height: 8),
          _luxModelCard(context, model, isComplete, isDownloading),

          const SizedBox(height: 24),

          // ── File list ──────────────────────────────
          _sectionHeader(context, 'Model Files'),
          const SizedBox(height: 8),
          ...model.files
              .where((f) => !f.id.contains('int8'))
              .map((f) => _luxFileTile(context, f)),

          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textD,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

Widget _luxModelCard(
  BuildContext context,
  LuxTtsModelInfo model,
  bool isComplete,
  bool isDownloading,
) {
  final svc = Get.find<LuxTtsService>();

  return Container(
    decoration: BoxDecoration(
      color: context.bgPanel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.border.withValues(alpha: 0.5)),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${model.totalSizeMb.toInt()} MB total — 48kHz',
                    style: TextStyle(fontSize: 12, color: context.textD),
                  ),
                ],
              ),
            ),
            if (isComplete)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          model.description,
          style: TextStyle(fontSize: 12, color: context.textD, height: 1.4),
        ),
        const SizedBox(height: 12),

        // Progress / action
        if (isDownloading) ...[
          _buildLuxDownloadProgress(context, svc),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                isComplete ? Icons.refresh_rounded : Icons.download_rounded,
                size: 18,
              ),
              label: Text(
                isComplete
                    ? 'Re-download All Files'
                    : 'Download All Files (${model.totalSizeMb.toInt()} MB)',
              ),
              onPressed: () => _handleLuxDownload(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (isComplete) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteAll(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete All Files'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}

Widget _buildLuxDownloadProgress(BuildContext context, LuxTtsService svc) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading...',
                    style: TextStyle(fontSize: 12, color: context.text),
                  ),
                  if (svc.currentFile.value.isNotEmpty)
                    Text(
                      svc.currentFile.value,
                      style: TextStyle(fontSize: 10, color: context.textD),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${(svc.overallProgress.value * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: svc.overallProgress.value.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: context.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => svc.cancelAll(),
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
          ),
        ),
      ],
    ),
  );
}

Future<void> _handleLuxDownload(BuildContext context) async {
  final svc = Get.find<LuxTtsService>();
  try {
    await svc.downloadAll();
    if (context.mounted) {
      Get.snackbar(
        'LuxTTS',
        'All files downloaded successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Get.snackbar(
        'Download Failed',
        'Could not download LuxTTS files: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

void _confirmDeleteAll(BuildContext context) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete LuxTTS Files?',
        style: TextStyle(color: context.text),
      ),
      content: Text(
        'This will remove all downloaded LuxTTS model files (${TtsCatalog.luxTts.totalSizeMb.toInt()} MB).',
        style: TextStyle(color: context.textM),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel', style: TextStyle(color: context.textD)),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Get.find<LuxTtsService>().deleteAll();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            elevation: 0,
          ),
          child: const Text('Delete',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget _luxFileTile(BuildContext context, LuxTtsFileInfo file) {
  final svc = Get.find<LuxTtsService>();

  return Obx(() {
    final isDownloaded = svc.downloadedFiles.contains(file.filename);
    final isDownloading = svc.fileDownloads.containsKey(file.id);
    final dlState = svc.fileDownloads[file.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isDownloaded
                ? Icons.check_circle_rounded
                : Icons.description_outlined,
            size: 18,
            color: isDownloaded ? Colors.green : context.textD,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.text,
                  ),
                ),
                Text(
                  '${file.sizeMb.toStringAsFixed(1)} MB',
                  style: TextStyle(fontSize: 11, color: context.textD),
                ),
                if (isDownloading && dlState != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: dlState.progress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: context.border,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDownloaded)
            Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 18)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  });
}
