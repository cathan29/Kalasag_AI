# Bugs Fixes and Change Log

## 2026-10-25

### Added emergency contact management

- Added persistent contact model and JSON serialization.
- Added create, view, edit, and delete operations to `AppState`.
- Added phone normalization, length validation, and duplicate prevention.
- Added explicit call confirmation and native dialer launch failure feedback.
- Files: `lib/models.dart`, `lib/app_state.dart`, `lib/sos_features.dart`, `lib/extras.dart`.

### Added offline Android safety tools

- Added torch control through an Android platform channel.
- Added runtime camera permission and no-flash error behavior.
- Added repeating emergency alert sound with start and stop controls.
- Added cleanup when leaving the screen or stopping the activity.
- Files: `lib/sos_features.dart`, `android/app/src/main/kotlin/com/cathan/kalasag/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`.

### Improved failure handling

- Hotline and contact calls now report when no dialer can open the request.
- No code places a telephone call automatically.

### Tests

- Added `test/emergency_contact_test.dart`.
- Flutter analysis passed with no issues.
- All 9 automated tests passed.
- Android debug build passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Physical-device smoke tests are now recorded in [[07 - Testing Android Setup and Known Issues]].

### Established source control and Android device development

- Audited the tree for secrets and machine-local files before staging.
- Strengthened `.gitignore` for environment files, signing material, service configuration, local Obsidian session state, generated output, and personal submission bundles.
- Initialized Git on `main` and created baseline commit `3f213ce` (`chore: establish Kalasag development baseline`).
- Installed checksum-verified Android command-line tools 22.0 and accepted all required SDK licenses.
- Cleared all `flutter doctor -v` issues.
- Detected and authorized Infinix X6833B on Android 14/API 34.
- Built, installed, launched, and smoke-tested the app on the phone.

### Added offline safety guide

- Added deterministic offline guidance for earthquakes, floods, typhoons, fire, evacuation, and basic bleeding first aid.
- Added urgent-phrase escalation and explicit non-live/non-official labeling.
- Added a Ready-screen entry point and quick prompts.
- Added three new automated checks; all 12 tests pass.
- Physically verified the Ready entry, warning, and Earthquake response on the Infinix device.

### Implemented Gemini AI Survival Assistant

- Added a global, accessible bottom-right assistant button on all non-SOS tabs.
- Added a responsive chat sheet with the required welcome copy, four quick prompts, Markdown messages, timestamps, typing/cancel/retry/clear controls, persistent history, keyboard-safe layout, and offline-guide fallback.
- Added typed error handling for missing setup, authentication, connectivity, timeout, rate limit, quota, safety, malformed response, and server failures.
- Added a secure Node.js proxy using Firebase ID-token verification, server-only Gemini secrets, rate limiting, Helmet, bounded requests/responses, provider timeouts, sanitized logging/errors, and signed per-user conversation context.
- Added an English/Filipino disaster-safety policy that forbids fabricated live conditions, responder contacts, locations, citations, and medical diagnosis.
- Selected `gemini-3.5-flash-lite` as the configurable default and used the Gemini Interactions API for multi-turn continuity.
- Added 11 Flutter AI tests and 4 backend tests. All 23 Flutter tests and all backend checks pass; the production dependency audit reports zero vulnerabilities.
- Rebuilt and installed the debug APK. Physically verified the global entry point and complete unconfigured-state chat sheet on the Infinix X6833B.
- Live Gemini validation remains explicitly blocked until credentials, HTTPS deployment, Firebase configuration, and real authentication are supplied.

