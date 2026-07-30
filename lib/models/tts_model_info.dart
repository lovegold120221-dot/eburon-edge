/// Represents a TTS voice embedding file that can be downloaded.
class TtsVoiceInfo {
  final String id; // e.g. "af_heart"
  final String name; // e.g. "Heart (American Female)"
  final String url; // full download URL
  final double sizeMb; // file size in MB
  final String language; // "en-US", "ja-JP", etc.
  final String gender; // "female", "male"
  final String? accent; // "American", "British", etc.

  const TtsVoiceInfo({
    required this.id,
    required this.name,
    required this.url,
    this.sizeMb = 0.522,
    this.language = 'en-US',
    this.gender = 'female',
    this.accent,
  });

  String get filename => '$id.bin';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'sizeMb': sizeMb,
    'language': language,
    'gender': gender,
    'accent': accent,
  };

  factory TtsVoiceInfo.fromJson(Map<String, dynamic> json) => TtsVoiceInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 0.522,
    language: (json['language'] as String?) ?? 'en-US',
    gender: (json['gender'] as String?) ?? 'female',
    accent: json['accent'] as String?,
  );
}

/// Represents a TTS model that can be downloaded and used for inference.
class TtsModelInfo {
  final String id; // "kokoro-82m"
  final String name; // "Kokoro 82M"
  final String description;
  final String modelUrl; // URL to the ONNX model file
  final double sizeMb; // model file size in MB
  final String? tokenizerUrl; // URL to tokenizer.json
  final String? configUrl; // URL to config.json

  const TtsModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.modelUrl,
    required this.sizeMb,
    this.tokenizerUrl,
    this.configUrl,
  });

  String get filename => '$id.onnx';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'modelUrl': modelUrl,
    'sizeMb': sizeMb,
    'tokenizerUrl': tokenizerUrl,
    'configUrl': configUrl,
  };

  factory TtsModelInfo.fromJson(Map<String, dynamic> json) => TtsModelInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    modelUrl: json['modelUrl'] as String,
    sizeMb: (json['sizeMb'] as num).toDouble(),
    tokenizerUrl: json['tokenizerUrl'] as String?,
    configUrl: json['configUrl'] as String?,
  );
}

/// Built-in TTS model catalog — Kokoro-82M ONNX
class TtsCatalog {
  static const String _baseUrl =
      'https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0';

  /// Default Kokoro-82M ONNX model (82 MB).
  static const TtsModelInfo defaultModel = TtsModelInfo(
    id: 'kokoro-82m',
    name: 'Kokoro 82M',
    description:
        'High-quality, lightweight TTS model. 82M parameters, Apache 2.0 license. '
        'Generates natural speech at 24kHz with real-time ONNX Runtime inference. '
        'Download the model + a voice file to start.',
    modelUrl: '$_baseUrl/kokoro-v1.0.onnx',
    sizeMb: 82.0,
  );

  /// All available voices from the Kokoro-82M ONNX repository
  static const List<TtsVoiceInfo> voices = [
    // ── American English Female ──
    TtsVoiceInfo(
      id: 'af_heart',
      name: 'Heart',
      url: '$_baseUrl/voices/af_heart.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_alloy',
      name: 'Alloy',
      url: '$_baseUrl/voices/af_alloy.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_aoede',
      name: 'Aoede',
      url: '$_baseUrl/voices/af_aoede.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_bella',
      name: 'Bella',
      url: '$_baseUrl/voices/af_bella.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_jessica',
      name: 'Jessica',
      url: '$_baseUrl/voices/af_jessica.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_kore',
      name: 'Kore',
      url: '$_baseUrl/voices/af_kore.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_nicole',
      name: 'Nicole',
      url: '$_baseUrl/voices/af_nicole.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_nova',
      name: 'Nova',
      url: '$_baseUrl/voices/af_nova.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_river',
      name: 'River',
      url: '$_baseUrl/voices/af_river.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_sarah',
      name: 'Sarah',
      url: '$_baseUrl/voices/af_sarah.bin',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'af_sky',
      name: 'Sky',
      url: '$_baseUrl/voices/af_sky.bin',
      accent: 'American',
    ),

    // ── American English Male ──
    TtsVoiceInfo(
      id: 'am_adam',
      name: 'Adam',
      url: '$_baseUrl/voices/am_adam.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_echo',
      name: 'Echo',
      url: '$_baseUrl/voices/am_echo.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_eric',
      name: 'Eric',
      url: '$_baseUrl/voices/am_eric.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_fenrir',
      name: 'Fenrir',
      url: '$_baseUrl/voices/am_fenrir.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_liam',
      name: 'Liam',
      url: '$_baseUrl/voices/am_liam.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_michael',
      name: 'Michael',
      url: '$_baseUrl/voices/am_michael.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_onyx',
      name: 'Onyx',
      url: '$_baseUrl/voices/am_onyx.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_puck',
      name: 'Puck',
      url: '$_baseUrl/voices/am_puck.bin',
      gender: 'male',
      accent: 'American',
    ),
    TtsVoiceInfo(
      id: 'am_santa',
      name: 'Santa',
      url: '$_baseUrl/voices/am_santa.bin',
      gender: 'male',
      accent: 'American',
    ),

    // ── British English Female ──
    TtsVoiceInfo(
      id: 'bf_alice',
      name: 'Alice',
      url: '$_baseUrl/voices/bf_alice.bin',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bf_emma',
      name: 'Emma',
      url: '$_baseUrl/voices/bf_emma.bin',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bf_isabella',
      name: 'Isabella',
      url: '$_baseUrl/voices/bf_isabella.bin',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bf_lily',
      name: 'Lily',
      url: '$_baseUrl/voices/bf_lily.bin',
      accent: 'British',
    ),

    // ── British English Male ──
    TtsVoiceInfo(
      id: 'bm_daniel',
      name: 'Daniel',
      url: '$_baseUrl/voices/bm_daniel.bin',
      gender: 'male',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bm_fable',
      name: 'Fable',
      url: '$_baseUrl/voices/bm_fable.bin',
      gender: 'male',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bm_george',
      name: 'George',
      url: '$_baseUrl/voices/bm_george.bin',
      gender: 'male',
      accent: 'British',
    ),
    TtsVoiceInfo(
      id: 'bm_lewis',
      name: 'Lewis',
      url: '$_baseUrl/voices/bm_lewis.bin',
      gender: 'male',
      accent: 'British',
    ),

    // ── European Female ──
    TtsVoiceInfo(
      id: 'ef_dora',
      name: 'Dora (Spanish)',
      url: '$_baseUrl/voices/ef_dora.bin',
      accent: 'Spanish',
    ),
    TtsVoiceInfo(
      id: 'em_alex',
      name: 'Alex (Romanian)',
      url: '$_baseUrl/voices/em_alex.bin',
      gender: 'male',
      accent: 'Romanian',
    ),
    TtsVoiceInfo(
      id: 'em_santa',
      name: 'Santa (Turkish)',
      url: '$_baseUrl/voices/em_santa.bin',
      gender: 'male',
      accent: 'Turkish',
    ),

    // ── French ──
    TtsVoiceInfo(
      id: 'ff_siwis',
      name: 'Siwis (French)',
      url: '$_baseUrl/voices/ff_siwis.bin',
      language: 'fr-FR',
      accent: 'French',
    ),

    // ── Japanese ──
    TtsVoiceInfo(
      id: 'jf_alpha',
      name: 'Alpha (Japanese)',
      url: '$_baseUrl/voices/jf_alpha.bin',
      language: 'ja-JP',
      accent: 'Japanese',
    ),
    TtsVoiceInfo(
      id: 'jf_gongitsune',
      name: 'Gongitsune (Japanese)',
      url: '$_baseUrl/voices/jf_gongitsune.bin',
      language: 'ja-JP',
      accent: 'Japanese',
    ),
    TtsVoiceInfo(
      id: 'jf_nezumi',
      name: 'Nezumi (Japanese)',
      url: '$_baseUrl/voices/jf_nezumi.bin',
      language: 'ja-JP',
      accent: 'Japanese',
    ),
    TtsVoiceInfo(
      id: 'jf_tebukuro',
      name: 'Tebukuro (Japanese)',
      url: '$_baseUrl/voices/jf_tebukuro.bin',
      language: 'ja-JP',
      accent: 'Japanese',
    ),
    TtsVoiceInfo(
      id: 'jm_kumo',
      name: 'Kumo (Japanese)',
      url: '$_baseUrl/voices/jm_kumo.bin',
      language: 'ja-JP',
      gender: 'male',
      accent: 'Japanese',
    ),

    // ── Chinese ──
    TtsVoiceInfo(
      id: 'zf_xiaobei',
      name: 'Xiaobei (Chinese)',
      url: '$_baseUrl/voices/zf_xiaobei.bin',
      language: 'zh-CN',
      accent: 'Chinese',
    ),
    TtsVoiceInfo(
      id: 'zf_xiaoni',
      name: 'Xiaoni (Chinese)',
      url: '$_baseUrl/voices/zf_xiaoni.bin',
      language: 'zh-CN',
      accent: 'Chinese',
    ),
    TtsVoiceInfo(
      id: 'zf_xiaoxiao',
      name: 'Xiaoxiao (Chinese)',
      url: '$_baseUrl/voices/zf_xiaoxiao.bin',
      language: 'zh-CN',
      accent: 'Chinese',
    ),

    // ── Miscellaneous ──
    TtsVoiceInfo(
      id: 'hf_alpha',
      name: 'Alpha (HF)',
      url: '$_baseUrl/voices/hf_alpha.bin',
    ),
    TtsVoiceInfo(
      id: 'hf_beta',
      name: 'Beta (HF)',
      url: '$_baseUrl/voices/hf_beta.bin',
    ),
    TtsVoiceInfo(
      id: 'hm_omega',
      name: 'Omega (HF)',
      url: '$_baseUrl/voices/hm_omega.bin',
      gender: 'male',
    ),
    TtsVoiceInfo(
      id: 'hm_psi',
      name: 'Psi (HF)',
      url: '$_baseUrl/voices/hm_psi.bin',
      gender: 'male',
    ),
    TtsVoiceInfo(
      id: 'if_sara',
      name: 'Sara (Italian)',
      url: '$_baseUrl/voices/if_sara.bin',
      language: 'it-IT',
      accent: 'Italian',
    ),
    TtsVoiceInfo(
      id: 'im_nicola',
      name: 'Nicola (Italian)',
      url: '$_baseUrl/voices/im_nicola.bin',
      language: 'it-IT',
      gender: 'male',
      accent: 'Italian',
    ),
    TtsVoiceInfo(
      id: 'pf_dora',
      name: 'Dora (Portuguese)',
      url: '$_baseUrl/voices/pf_dora.bin',
      language: 'pt-PT',
      accent: 'Portuguese',
    ),
    TtsVoiceInfo(
      id: 'pm_alex',
      name: 'Alex (Portuguese)',
      url: '$_baseUrl/voices/pm_alex.bin',
      language: 'pt-PT',
      gender: 'male',
      accent: 'Portuguese',
    ),
    TtsVoiceInfo(
      id: 'pm_santa',
      name: 'Santa (Portuguese)',
      url: '$_baseUrl/voices/pm_santa.bin',
      language: 'pt-PT',
      gender: 'male',
      accent: 'Portuguese',
    ),
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
}
