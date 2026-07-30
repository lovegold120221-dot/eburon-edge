# Eburon Edge — Agent Instructions

## Repo at a glance

Flutter app (`eburon_edge`) that runs open-source GGUF LLMs locally on-device via `llamadart` (llama.cpp bindings). Mobile-first; desktop (Windows/macOS/Linux) compiles but needs community polish. Also includes Kokoro-82M TTS (ONNX/TFLite).

- **Entry point:** `lib/main.dart`
- **State management:** GetX — all services/controllers are singletons registered in `lib/bindings/app_bindings.dart`
- **Storage:** Hive (`chats` box for ChatModel, `settings` box for preferences, `models_meta` for custom model catalog)
- **LLM engine:** `LlmService` wraps `LlamaEngine`/`LlamaBackend` from `llamadart`
- **Local API server:** OpenAI-compatible HTTP server on port `4891` — see `LocalApiServerService`
- **Model catalog:** `assets/models_catalog.json` + persisted custom models in Hive `models_meta` key `custom_models`
- **TTS:** Kokoro-82M via `KokoroTtsService` — ONNX Runtime (Android) or TFLite fallback

## Essential commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Hive .g.dart codegen
flutter run                                                 # Run on connected device
flutter run -d windows|macos|linux                          # Desktop target
flutter build apk --release --target-platform android-arm64 # APK arm64
flutter build ios --release                                 # iOS (requires Mac + Xcode)
cd ios && pod install && cd ..                              # iOS prerequisite
flutter pub run flutter_launcher_icons                      # Regenerate launcher icons
flutter analyze                                             # Lint + typecheck
flutter test                                                # All tests
```

CI builds APK via `.github/workflows/build-apk.yml` (runs `flutter build apk --release --target-platform android-arm64`). No pre-commit hooks.

## Architecture

- **GetX DI:** Services via `Get.lazyPut` (fenix: true), controllers via `Get.put`/`Get.lazyPut`. Never instantiate directly — always use `Get.find<T>()`.
- **Hive adapters** must be registered before opening boxes (done in `main.dart` lines 41-43). After modifying `@HiveType`/`@HiveField` annotations, run `dart run build_runner build --delete-conflicting-outputs`.
- **LlmService** creates a fresh `LlamaBackend`+`LlamaEngine` per `loadModel()`. Must call `_fullTeardown()` before loading a new model — native state cannot be reused.
- **Android context size** hard-capped at 1024 to avoid Low Memory Killer; desktop gets 2048.
- **Wake lock** is critical on mobile — `WakelockService` enables foreground service + wakelock during downloads and inference.
- **Prompt format** is hardcoded in `LlmService._buildPrompt()`: `<|system|>...<|end|>`, `<|user|>...<|end|>`, `<|assistant|>`. Not configurable per-model.
- **`llamadart` native backends** are configured via `pubspec.yaml` `hooks.user_defines.llamadart.llamadart_native_backends.platforms` — android-arm64 gets `[cpu, vulkan, opencl]`, linux/windows-x64 get `[vulkan]`.

## Service ownership

| Service | Responsibility |
|---------|---------------|
| `LlmService` | Model load/unload, streaming generation, token counting |
| `ModelManager` | Model catalog, download with resume (HTTP Range), import from file/URL, delete |
| `ChatStorageService` | Hive-backed chat persistence + all settings accessors |
| `LocalApiServerService` | HTTP server: `GET /healthz`, `GET /v1/models`, `POST /v1/chat/completions` |
| `WakelockService` | Screen wake lock + Android foreground service |
| `KokoroTtsService` | Kokoro-82M TTS: G2P → tokenizer → inference (ONNX/TFLite) → audio playback |
| `LogService` | In-app ring-buffer logging (1000 entries) |
| `BackgroundOptimizerService` | Android battery optimization prompt (static, not a GetX service) |

## Models directory

- Mobile: `{appDocuments}/EburonEdge/models/`
- Desktop: `{exeDir}/../Shared/models/` (falls back to app docs if not found)

Models are `.gguf` files. `ModelManager.scanDownloaded()` scans for `.gguf` on init.

## TTS model files

Kokoro TTS requires two file types downloaded separately:
- **ONNX model** (`kokoro-82m.onnx`, ~82 MB) — from HuggingFace `onnx-community/Kokoro-82M-v1.0-ONNX`
- **Voice embeddings** (`*.bin`, ~0.5 MB each) — one per voice, stored alongside the ONNX model

Root-level `kokoro-simplified.onnx`, `kokoro-v1.0.onnx`, `voices-v1.0.bin` are legacy files.

## Gotchas

1. **Never call `LlmService.loadModel()` without `_fullTeardown()` first** — native state becomes stale.
2. **`stopGeneration()` must be called on both LlmService and ChatController** — the controller tracks its own `isGenerating` flag.
3. **Local API server** defaults to loopback (`127.0.0.1`). Toggle `local_api_all_interfaces` in settings for network access.
4. **Model download resume** uses HTTP `Range` headers (`.part` temp file). Cancelling leaves a stale `.part` file.
5. **Default system prompt** is hardcoded in `ChatStorageService` as an uncensored prompt. Any override replaces it entirely.
6. **Hive `.g.dart` files** must be regenerated after model changes — run `dart run build_runner build --delete-conflicting-outputs`.
7. **TTS ONNX inference** uses a MethodChannel (`onnx_inference`) to Android native onnxruntime-mobile. Falls back to test tones on iOS/desktop.

## Testing

Tests in `test/`:
- `widget_test.dart` — trivial smoke test (just `expect(true, isTrue)`)
- `local_api_server_service_test.dart` — integration test for the API server (starts real HTTP server, tests healthz/models/chat endpoints)

Run all: `flutter test`. No integration tests for LLM inference or TTS.
