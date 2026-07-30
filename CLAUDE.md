# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Eburon Edge** — a Flutter app that runs open-source GGUF LLMs locally on-device via `llamadart` (llama.cpp bindings). Mobile-first (Android/iOS), desktop (Windows/macOS/Linux) compiles but needs community polish. Also includes Kokoro-82M TTS via ONNX Runtime.

## Essential Commands

```bash
# Dependencies
flutter pub get

# Hive code generation (after modifying @HiveType/@HiveField annotations)
dart run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run

# Desktop targets
flutter run -d windows|macos|linux

# Build APK (arm64)
flutter build apk --release --target-platform android-arm64

# Build iOS (requires Mac + Xcode)
cd ios && pod install && cd ..
flutter build ios --release

# Regenerate launcher icons
flutter pub run flutter_launcher_icons

# Lint + typecheck
flutter analyze

# Tests
flutter test
```

## Architecture

### State Management: GetX

All services and controllers are singletons registered in `lib/bindings/app_bindings.dart`:
- **Services** via `Get.lazyPut(..., fenix: true)` — async init happens in `SplashScreen._initApp()`
- **Controllers** via `Get.put()` (ThemeController) or `Get.lazyPut()` (ChatController, ModelController)
- Never instantiate directly — always use `Get.find<T>()`

### Service Ownership

| Service | File | Responsibility |
|---------|------|----------------|
| `LlmService` | `lib/services/llm_service.dart` | Model load/unload, streaming generation, token counting. Wraps `LlamaEngine`/`LlamaBackend` from `llamadart` |
| `ModelManager` | `lib/services/model_manager.dart` | Model catalog, download with resume (HTTP Range), import from file/URL, delete |
| `ChatStorageService` | `lib/services/chat_storage_service.dart` | Hive-backed chat persistence + all settings accessors |
| `LocalApiServerService` | `lib/services/local_api_server_service.dart` | OpenAI-compatible HTTP server on port 4891: `GET /healthz`, `GET /v1/models`, `POST /v1/chat/completions` |
| `WakelockService` | `lib/services/wakelock_service.dart` | Screen wake lock + Android foreground service for downloads/inference |
| `KokoroTtsService` | `lib/services/tts/kokoro_tts_service.dart` | Kokoro-82M TTS: G2P → tokenizer → inference → audio playback |
| `LogService` | `lib/services/log_service.dart` | In-app ring-buffer logging (1000 entries) |
| `BackgroundOptimizerService` | `lib/services/background_optimizer_service.dart` | Android battery optimization prompt (static, not a GetX service) |

### Controller Ownership

| Controller | File | Responsibility |
|------------|------|----------------|
| `ChatController` | `lib/controllers/chat_controller.dart` | Chat CRUD, message sending, streaming response, system prompt, temperature |
| `ModelController` | `lib/controllers/model_controller.dart` | Model load/unload, download, import (file picker, URL, directory), catalog management |
| `ThemeController` | `lib/controllers/theme_controller.dart` | Dark/light theme toggle, persisted to Hive |

### Data Flow

1. **App start**: `main.dart` → init Hive + register adapters → `SplashScreen` → init all services sequentially → navigate to `HomeScreen`
2. **Chat**: `ChatController.sendMessage()` → `LlmService.generate()` (stream) → `ChatController` updates `MessageModel.content` → UI rebuilds via `Obx`
3. **Model lifecycle**: `ModelController.loadModel()` → `LlmService.loadModel()` (creates fresh `LlamaBackend`+`LlamaEngine`) → `LlmService._fullTeardown()` on unload (disposes both engine AND backend)
4. **Local API**: `LocalApiServerService` starts an `HttpServer` on port 4891, routes requests to `LlmService.generateChatCompletion()`

### Storage: Hive

Three boxes opened in `main.dart`:
- `chats` — `Box<ChatModel>` (typeId 0)
- `settings` — `Box` for all preferences (system prompt, temperature, GPU config, API server settings, TTS settings)
- `models_meta` — `Box` for custom model catalog persistence

Hive adapters (`ChatModelAdapter`, `MessageModelAdapter`, `MessageRoleAdapter`) are generated via `build_runner`. After modifying `@HiveType`/`@HiveField` annotations, run `dart run build_runner build --delete-conflicting-outputs`.

### Models Directory

- Mobile: `{appDocuments}/EburonEdge/models/`
- Desktop: `{exeDir}/../Shared/models/` (falls back to app documents)
- Models are `.gguf` files. `ModelManager.scanDownloaded()` scans for `.gguf` on init.

### Prompt Format

Hardcoded in `LlmService._buildPrompt()`: `<|system|>...<|end|>`, `<|user|>...<|end|>`, `<|assistant|>`. Not configurable per-model. The newer `generateChatCompletion()` method uses `llamadart`'s built-in chat template API instead.

### Key Constraints

- **Android context size**: hard-capped at 1024 to avoid Low Memory Killer; desktop gets 2048
- **`llamadart` native backends**: configured via `pubspec.yaml` `hooks.user_defines.llamadart.llamadart_native_backends.platforms` — android-arm64 gets `[cpu, vulkan, opencl]`, linux/windows-x64 get `[vulkan]`
- **Wake lock**: critical on mobile — `WakelockService` enables foreground service + wakelock during downloads and inference
- **Default system prompt**: hardcoded in `ChatStorageService` as an uncensored prompt. Any override replaces it entirely.

## Gotchas

1. **Never call `LlmService.loadModel()` without `_fullTeardown()` first** — native state becomes stale. The service does this internally, but any direct engine manipulation must follow the same pattern.
2. **`stopGeneration()` must be called on both LlmService and ChatController** — the controller tracks its own `isGenerating` flag.
3. **Local API server** defaults to loopback (`127.0.0.1`). Toggle `local_api_all_interfaces` in settings for network access.
4. **Model download resume** uses HTTP `Range` headers (`.part` temp file). Cancelling leaves a stale `.part` file.
5. **Hive `.g.dart` files** must be regenerated after model changes — run `dart run build_runner build --delete-conflicting-outputs`.
6. **TTS ONNX inference** uses a MethodChannel (`onnx_inference`) to Android native onnxruntime-mobile. Falls back to test tones on iOS/desktop.

## Testing

Tests in `test/`:
- `widget_test.dart` — trivial smoke test
- `local_api_server_service_test.dart` — integration test for the API server (starts real HTTP server, tests healthz/models/chat endpoints)

Run all: `flutter test`. No integration tests for LLM inference or TTS.

## UI Patterns

- **Responsive layout**: `HomeScreen` switches between desktop layout (sidebar + top bar) and mobile layout (bottom nav + drawer) at 768px breakpoint
- **Theme**: Dark/light via `ThemeController`, persisted in Hive. Design tokens in `AppColors` (ported from FastChatUI CSS variables). Context extensions in `ThemeExt` for convenient color access.
- **Screens** use an `embedded` pattern — screens can be shown full-screen (with back button) or embedded in a tab (no scaffold wrapper)
- **Model loading overlay**: global overlay in `HomeScreen` for import progress; per-card progress in `ModelCard`
