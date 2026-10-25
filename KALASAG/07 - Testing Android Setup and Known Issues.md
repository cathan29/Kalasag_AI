# Testing Android Setup and Known Issues

## Results on 2026-10-25

| Check | Result | Evidence |
|---|---|---|
| Flutter analysis | PASS | `flutter analyze --no-pub`: no issues found |
| Automated tests | PASS | 9 tests passed |
| Dependency resolution | PASS | `flutter pub get`: dependencies resolved; 33 constrained updates are available |
| Flutter doctor | PARTIAL | Flutter SDK passes; Android cmdline-tools are missing and license status is unknown |
| Contact model tests | PASS | Normalization, valid lengths, JSON round trip |
| Debug APK build | PASS | Gradle `assembleDebug`: BUILD SUCCESSFUL; fresh APK created at 2026-10-25 19:39 |
| Physical device detection | BLOCKED | `adb devices -l` returned no devices |
| Physical torch and whistle | NOT RUN | Requires an Android phone |
| Dialer launch | NOT RUN | Requires an Android phone with a dialer |
| End-to-end authentication | BLOCKED | No authentication backend exists |
| AI assistant | BLOCKED | Feature and secure server endpoint do not exist |

## Android setup

- Flutter SDK: `C:\src\flutter_windows_3.41.6-stable\flutter`
- Android SDK: `C:\Users\Cathan\AppData\Local\Android\sdk`
- Application ID: `com.cathan.kalasag`
- Java target: 17
- Required permissions: internet, network state, fine/coarse location, and camera for torch access

Install Android SDK command-line tools and run `flutter doctor --android-licenses` before release/device setup. The current project can still assemble a debug APK, but the doctor warning should be cleared.

## Device procedure

1. Enable Developer options and USB debugging on the phone.
2. Connect with a data-capable USB cable and accept the RSA authorization prompt.
3. Run `adb devices -l` and confirm the device state is `device`, not `unauthorized`.
4. Run `flutter run` from the project root.
5. Exercise permission allowed, denied, and denied-forever paths.
6. Confirm the dialer opens without placing a call.
7. Confirm the torch and sound stop after navigating back, backgrounding, and closing the app.

## Known issues and limitations

- Demo login only; no registration, recovery, session, logout, or emergency profile.
- No AI assistant.
- No remote backend or synchronization.
- Live alerts are disabled by default.
- Radar depends on an external web page.
- Notification settings do not provide OS push delivery.
- Gradle reports deprecated features that will need attention before a future Gradle 10 migration.
- Flutter doctor reports missing Android command-line tools and unknown Android license status.
- Thirty-three dependency updates are outside current constraints and require deliberate compatibility review rather than a bulk upgrade.
- No device was attached, so hardware behavior remains unverified.

