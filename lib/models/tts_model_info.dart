/// Represents a TTS voice embedding — stored in bundled assets, not downloaded.
class TtsVoiceInfo {
  final String id; // e.g. "af_heart"
  final String name; // e.g. "Heart"
  final double sizeMb; // file size in MB
  final String language; // "en-US", "ja-JP", etc.
  final String gender; // "female", "male"
  final String? accent; // "American", "British", etc.

  const TtsVoiceInfo({
    required this.id,
    required this.name,
    this.sizeMb = 0.522,
    this.language = 'en-US',
    this.gender = 'female',
    this.accent,
   });

  Map<String, dynamic> toJson() => {
     'id': id,
     'name': name,
     'sizeMb': sizeMb,
     'language': language,
     'gender': gender,
     'accent': accent,
    };

  factory TtsVoiceInfo.fromJson(Map<String, dynamic> json) => TtsVoiceInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 0.522,
    language: (json['language'] as String?) ?? 'en-US',
    gender: (json['gender'] as String?) ?? 'female',
    accent: json['accent'] as String?,
    );
}

/// Represents a Kokoro-82M ONNX model that can be downloaded.
class TtsModelInfo {
  final String id; // "kokoro-82m"
  final String name; // "Kokoro 82M"
  final String description;
  final String modelUrl; // URL to the ONNX model file
  final double sizeMb; // model file size in MB

  const TtsModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.modelUrl,
    required this.sizeMb,
    });
}

/// LuxTTS model component file — currently unavailable (HuggingFace bucket removed).
class LuxTtsFileInfo {
  final String id;
  final String name;
  final double sizeMb;

  const LuxTtsFileInfo({
    required this.id,
    required this.name,
    required this.sizeMb,
    });

  String get filename => id;
}

/// LuxTTS model info — multi-file TTS model.
class LuxTtsModelInfo {
  final String id;
  final String name;
  final String description;
  final List<LuxTtsFileInfo> files;
  final double totalSizeMb;

  const LuxTtsModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.files,
    required this.totalSizeMb,
    });
}

/// Built-in TTS model catalog — Kokoro-82M ONNX + LuxTTS (placeholder).
class TtsCatalog {
  static const String _baseUrl =
       'https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0';

   /// Default Kokoro-82M ONNX model.
  static const TtsModelInfo defaultModel = TtsModelInfo(
    id: 'kokoro-82m',
    name: 'Kokoro 82M',
    description:
         'High-quality, lightweight TTS model. 82M parameters, Apache 2.0 license. '
         'Generates natural speech at 24kHz with real-time ONNX Runtime inference.',
    modelUrl: '$_baseUrl/kokoro-v1.0.onnx',
    sizeMb: 310.0,
    );

   /// All available voices — bundled in assets/voices.json, not downloaded individually.
   /// The Kokoro package reads these directly from the Flutter asset bundle.
  static const List<TtsVoiceInfo> voices = [
     // ── American English Female ──
    TtsVoiceInfo(id: 'af_alloy', name: 'Alloy', accent: 'American'),
    TtsVoiceInfo(id: 'af_aoede', name: 'Aoede', accent: 'American'),
    TtsVoiceInfo(id: 'af_bella', name: 'Bella', accent: 'American'),
    TtsVoiceInfo(id: 'af_heart', name: 'Heart', accent: 'American'),
    TtsVoiceInfo(id: 'af_jessica', name: 'Jessica', accent: 'American'),
    TtsVoiceInfo(id: 'af_kore', name: 'Kore', accent: 'American'),
    TtsVoiceInfo(id: 'af_nicole', name: 'Nicole', accent: 'American'),
    TtsVoiceInfo(id: 'af_nova', name: 'Nova', accent: 'American'),
    TtsVoiceInfo(id: 'af_river', name: 'River', accent: 'American'),
    TtsVoiceInfo(id: 'af_sarah', name: 'Sarah', accent: 'American'),
    TtsVoiceInfo(id: 'af_sky', name: 'Sky', accent: 'American'),
     // ── American English Male ──
    TtsVoiceInfo(id: 'am_adam', name: 'Adam', gender: 'male', accent: 'American'),
    TtsVoiceInfo(id: 'am_echo', name: 'Echo', gender: 'male', accent: 'American'),
    TtsVoiceInfo(id: 'am_floyd', name: 'Floyd', gender: 'male', accent: 'American'),
    TtsVoiceInfo(id: 'am_michael', name: 'Michael', gender: 'male', accent: 'American'),
    TtsVoiceInfo(id: 'am_reed', name: 'Reed', gender: 'male', accent: 'American'),
     // ── British English Female ──
    TtsVoiceInfo(id: 'bf_emma', name: 'Emma', accent: 'British'),
    TtsVoiceInfo(id: 'bf_isabella', name: 'Isabella', accent: 'British'),
    TtsVoiceInfo(id: 'bf_lily', name: 'Lily', accent: 'British'),
     // ── British English Male ──
    TtsVoiceInfo(id: 'bm_jorge', name: 'Jorge', gender: 'male', accent: 'British'),
    TtsVoiceInfo(id: 'bm_lewis', name: 'Lewis', gender: 'male', accent: 'British'),
    TtsVoiceInfo(id: 'bm_thomas', name: 'Thomas', gender: 'male', accent: 'British'),
     // ── Spanish Female ──
    TtsVoiceInfo(id: 'sf_dora', name: 'Dora', accent: 'Spanish'),
    TtsVoiceInfo(id: 'sf_emilia', name: 'Emilia', accent: 'Spanish'),
     // ── Italian Female ──
    TtsVoiceInfo(id: 'if_sara', name: 'Sara', language: 'it-IT', accent: 'Italian'),
     // ── Italian Male ──
    TtsVoiceInfo(id: 'im_nicola', name: 'Nicola', gender: 'male', language: 'it-IT', accent: 'Italian'),
     // ── Portuguese Female ──
    TtsVoiceInfo(id: 'pf_dora', name: 'Dora', language: 'pt-PT', accent: 'Portuguese'),
     // ── Portuguese Male ──
    TtsVoiceInfo(id: 'pm_alex', name: 'Alex', gender: 'male', language: 'pt-PT', accent: 'Portuguese'),
    TtsVoiceInfo(id: 'pm_santa', name: 'Santa', gender: 'male', language: 'pt-PT', accent: 'Portuguese'),
     // ── Japanese Female ──
    TtsVoiceInfo(id: 'jf_alpha', name: 'Alpha (Japanese)', language: 'ja-JP', accent: 'Japanese'),
    TtsVoiceInfo(id: 'jf_jenny', name: 'Jenny (Japanese)', language: 'ja-JP', accent: 'Japanese'),
    TtsVoiceInfo(id: 'jf_nikki', name: 'Nikki (Japanese)', language: 'ja-JP', accent: 'Japanese'),
    TtsVoiceInfo(id: 'jf_tebukuro', name: 'Tebukuro (Japanese)', language: 'ja-JP', accent: 'Japanese'),
     // ── Japanese Male ──
    TtsVoiceInfo(id: 'jm_kumo', name: 'Kumo (Japanese)', gender: 'male', language: 'ja-JP', accent: 'Japanese'),
     // ── Chinese Female ──
    TtsVoiceInfo(id: 'zf_xiaobei', name: 'Xiaobei', language: 'zh-CN', accent: 'Chinese'),
    TtsVoiceInfo(id: 'zf_xiaoxiao', name: 'Xiaoxiao', language: 'zh-CN', accent: 'Chinese'),
    TtsVoiceInfo(id: 'zf_xiaoni', name: 'Xiaoni', language: 'zh-CN', accent: 'Chinese'),
   ];

   /// Get voice by ID
  static TtsVoiceInfo? getVoice(String id) {
    try {
      return voices.firstWhere((v) => v.id == id);
      } catch (_) {
      return null;
      }
    }

   /// Default voice
  static TtsVoiceInfo get defaultVoice =>
       voices.firstWhere((v) => v.id == 'af_heart', orElse: () => voices.first);

   /// Group voices by accent
  static Map<String, List<TtsVoiceInfo>> get voicesByAccent {
    final map = <String, List<TtsVoiceInfo>>{};
    for (final v in voices) {
      final key = v.accent ?? 'Other';
      map.putIfAbsent(key, () => []).add(v);
      }
    return map;
    }

   /// Human-readable labels for each accent key
  static Map<String, String> get accentLabels => {
       'American': 'American',
       'British': 'British',
       'Spanish': 'Spanish',
       'French': 'French',
       'Japanese': 'Japanese',
       'Chinese': 'Chinese',
       'Korean': 'Korean',
       'Hindi': 'Hindi',
       'Portuguese': 'Portuguese',
    };

   // ── LuxTTS — currently unavailable (bucket removed) ────────────
   /// LuxTTS model — ZipVoice-based TTS with voice cloning.
   /// NOTE: The HuggingFace bucket has been removed.
  static const LuxTtsModelInfo luxTts = LuxTtsModelInfo(
    id: 'lux-tts',
    name: 'LuxTTS',
    description:
         'ZipVoice-based TTS with high-quality voice cloning. '
         '48kHz output. Currently unavailable — model source bucket has been removed.',
    totalSizeMb: 0,
    files: [],
    );
}
