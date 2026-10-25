# Testing Android Setup and Known Issues

## Results on 2026-10-25

| Check | Result | Evidence |
|---|---|---|
| Flutter analysis | PASS | `flutter analyze --no-pub`: no issues found |
| Automated Flutter tests | PASS | 23 tests passed, including AI controller, service, storage, widget, error, retry, and Markdown behavior |
| Backend checks | PASS | Node syntax checks and 4 tests passed; production dependency audit found 0 vulnerabilities |
| Dependency resolution | PASS | `flutter pub get`: dependencies resolved; 33 constrained updates are available |
| Flutter doctor | PASS | No issues found; command-line tools 22.0 installed and all Android SDK licenses accepted |
| Contact model tests | PASS | Normalization, valid lengths, JSON round trip |
| Debug APK build | PASS | Fresh debug APK built and installed on 2026-10-25 |
| Physical device detection | PASS | Infinix X6833B, Android 14/API 34, ADB state `device` |
| Physical app smoke test | PASS | Installed and launched `com.cathan.kalasag`; login validation/demo flow, weather, alerts, and offline guide rendered without app-scoped fatal errors |
| Offline safety guide | PASS | Ready entry, warning label, and Earthquake response verified on device |
| Physical torch and whistle | NOT RUN | Connected phone available; disruptive actions intentionally require supervised manual verification |
| Dialer launch | NOT RUN | Connected phone available; avoid opening or placing calls without supervised verification |
| End-to-end authentication | BLOCKED | No authentication backend exists |
| AI client and proxy contract | PASS | Proxy/client tests cover authentication failure, no client key, signed context, quota mapping, retry, offline, persistence, and HTTP response contract |
| Physical AI UI smoke test | PASS | Global FAB, setup status, exact welcome/disclaimer, four prompts, composer, and close control verified on Infinix X6833B |
| Live Gemini response | BLOCKED | No Gemini key, deployed HTTPS proxy, Firebase project, or real app ID token was supplied; no live response is claimed |

## Android setup

- Flutter SDK: `C:\src\flutter_windows_3.41.6-stable\flutter`
- Android SDK: `C:\Users\Cathan\AppData\Local\Android\sdk`
- Application ID: `com.cathan.kalasag`
- Java target: 17
- Required permissions: internet, network state, fine/coarse location, and camera for torch access

Android command-line tools 22.0 are installed at the standard `cmdline-tools/latest` location. The downloaded official package matched SHA-256 `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`. All Android SDK licenses are accepted and `flutter doctor -v` reports no issues.

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
- AI UI and secure proxy are implemented, but production credentials, Firebase app authentication, deployment, and a live provider acceptance test remain outstanding.
- No remote backend or synchronization.
- Live alerts are disabled by default.
- Radar depends on an external web page.
- Notification settings do not provide OS push delivery.
- Gradle reports deprecated features that will need attention before a future Gradle 10 migration.
- Thirty-three dependency updates are outside current constraints and require deliberate compatibility review rather than a bulk upgrade.
- Initial device launch logged Infinix vendor GPU-format warnings and a slow first frame; the UI still rendered and no Flutter fatal error was found.
- Torch, whistle, dialer, denial, backgrounding, and interruption behavior remain manually unverified.

