# GitHub and Android Development Environment

## Local Git baseline

- Repository root: `C:\projects\KALASAG\kalasag_flutter`
- Branch: `main`
- Initial commit: `3f213ce chore: establish Kalasag development baseline`
- Security audit: no credential files, API tokens, signing keys, or machine-local SDK paths were staged.
- Personal ZIP/DOCX submission artifacts remain on disk and are ignored, not deleted.
- GitHub target name: `kalasag-app`
- Remote status: not created. GitHub CLI is not installed and no GitHub connection was confirmed, so no remote URL was guessed and nothing was published.

When authenticated GitHub tooling is available, create a **private** `kalasag-app` repository, add it as `origin`, verify visibility, then push `main`. Never create a public repository or force-push.

## Android toolchain

- Flutter: 3.41.6 stable
- Dart: 3.11.4
- Android SDK: `C:\Users\Cathan\AppData\Local\Android\sdk`
- Command-line tools: 22.0 at `cmdline-tools\latest`
- Build tools: 37.0.0
- Java: Eclipse Temurin 25.0.4
- Gradle wrapper: 9.1.0
- Licenses: all accepted
- `flutter doctor -v`: no issues found

The official Android command-line tools archive was accepted by checksum before installation. Verified SHA-256: `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`.

## Connected device evidence

- Model: Infinix X6833B
- Serial: `102742538O013935`
- Android: 14 / API 34
- Architecture: android-arm64
- ADB state: `device` (authorized)
- Application ID: `com.cathan.kalasag`

Verified on device:

- Debug APK build, installation, process start, and foreground activity
- Empty-login validation and valid demo-login navigation
- Live weather dashboard rendering
- Offline demo-alert list rendering
- Ready to Offline safety guide navigation
- Earthquake quick-prompt guidance
- No app-scoped fatal, unhandled Flutter, or ANR log entry during these checks

Still requires supervised manual checks:

- Torch enable/disable, denial, unavailable-flash, and lifecycle cleanup
- Whistle volume, stop control, backgrounding, and interruption behavior
- Contact/hotline dialer opening without placing a call
- Radar gestures and network-failure behavior
- Location permission denial and denied-forever behavior

## Reproduction commands

```powershell
flutter doctor -v
flutter devices
adb devices -l
flutter analyze
flutter test
flutter run -d 102742538O013935
```
