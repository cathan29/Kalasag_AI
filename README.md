# Kalasag Flutter

This folder is the standalone Flutter migration of the original React Native app. The React Native source in the repository root is intentionally untouched.

## Included

- Modern demo login screen with email/password validation and password visibility control
- Google and Facebook sign-in buttons presented as coming-soon features
- Five-tab Material 3 interface: Weather, Alerts, Radar, Ready, and SOS
- GPS permission, reverse-geocoded location, Open-Meteo multi-model forecast
- API evidence screen with live GET, HTTP status, parsed data, and handled failure state
- Offline demo alerts by default, with optional live GDACS, USGS, and NASA EONET providers
- Alert filtering, detail pages, and official-source links
- Embedded Windy rain, wind, temperature, and cloud layers
- Persistent saved places, go-bag checklist, family plan, and alert preferences
- OpenStreetMap/Overpass evacuation-center search with radius filters
- Offline verified hotline directory and first-aid/evacuation guides
- Persistent custom emergency contacts with add, edit, delete, validation, and guarded dialer opening
- Android-native SOS flashlight and repeating emergency alert sound with lifecycle cleanup
- Offline rule-based safety guide with urgent escalation and disaster quick prompts
- Light/dark themes and Android/iOS location configuration

## Run

```powershell
cd kalasag_flutter
flutter pub get
flutter run
```

Choose an Android emulator or USB-connected Android device when prompted. Location and network access are required for live weather, radar, alerts, and shelter search. Emergency data and readiness plans work locally.

Live alert API requests are temporarily disabled by default. The Alerts screen uses clearly labeled offline demo records, so navigation and data-passing can be demonstrated without waiting for network providers. To enable the live providers for a run:

```powershell
flutter run --dart-define=ENABLE_LIVE_ALERT_APIS=true
```

## Validate and build

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

The generated debug APK is at `build/app/outputs/flutter-apk/app-debug.apk`.

## Notes

- Email/password sign-in is currently a local demo entry flow and does not authenticate against a backend. Google and Facebook authentication are not implemented yet.
- The Android wrapper uses Gradle 9.1 because this development machine currently uses Java 25.
- Alert preferences are persisted. OS background/push delivery still requires a production notification provider or backend. Live alert refresh is available only when `ENABLE_LIVE_ALERT_APIS=true` is supplied.
- Windy is embedded through its public map page, matching the network-dependent radar behavior of the original app.
- The app has been built, installed, launched, and navigated on an authorized Infinix X6833B running Android 14. Disruptive actions (placing calls, sounding the whistle, and toggling the torch) still require supervised manual verification. Neither tool contacts responders automatically.
- The offline safety guide is bundled guidance, not live or official advice and not an online AI service. A secure server-side provider is still required for the proposed online assistant.
