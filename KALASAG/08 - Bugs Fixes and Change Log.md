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
- Physical-device tests remain blocked as recorded in [[07 - Testing Android Setup and Known Issues]].

