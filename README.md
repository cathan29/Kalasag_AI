# Kalasag Flutter

This folder is the standalone Flutter migration of the original React Native app. The React Native source in the repository root is intentionally untouched.

## Included

- Modern demo login screen with email/password validation and password visibility control
- Google and Facebook sign-in buttons presented as coming-soon features
- Five-tab Material 3 interface: Weather, Alerts, Radar, Ready, and SOS
- GPS permission, reverse-geocoded location, Open-Meteo multi-model forecast
- API evidence screen with live GET, HTTP status, parsed data, and handled failure state
- Clearly labeled practice alerts by default, with a normalized backend feed or optional direct supplementary providers
- Alert provenance, source health, saved fallback, distance/category filters, detailed lifecycle fields, and Philippine official-source links
- Embedded Windy rain, wind, temperature, and cloud layers
- Persistent saved places, go-bag checklist, family plan, and alert preferences
- OpenStreetMap/Overpass evacuation-center search with radius filters
- Offline verified hotline directory and first-aid/evacuation guides
- Persistent custom emergency contacts with add, edit, delete, validation, and guarded dialer opening
- Android-native SOS flashlight and repeating emergency alert sound with lifecycle cleanup
- Offline rule-based safety guide with urgent escalation and disaster quick prompts
- Global Kalasag AI chat sheet with suggested questions, Markdown responses, local history, retry/cancel controls, and offline-guide fallback
- Secure Node.js Gemini proxy with Firebase ID-token verification, rate limiting, signed conversation context, and sanitized errors
- Professional safety-first design system and dashboard with concise demo/live status language
- Nearly full-screen Windy forecast map with supported layer switching and native forecast playback controls
- Light/dark themes and Android/iOS location configuration

## Run

```powershell
cd kalasag_flutter
flutter pub get
flutter run
```

Choose an Android emulator or USB-connected Android device when prompted. Location and network access are required for live weather, radar, alerts, and shelter search. Emergency data and readiness plans work locally.

## Google sign-in Firebase setup

The login screen is wired to Firebase Authentication and Google Sign-In. To
enable it for Android, use the real Firebase project configuration:

1. Register the Android app with package name `com.cathan.kalasag` in Firebase
   Console.
2. Enable **Google** under Authentication > Sign-in method.
3. Add the debug and release SHA-1/SHA-256 fingerprints under Project settings.
4. Download `google-services.json` into `android/app/`. This file is ignored by
   Git and must not be fabricated or committed.
5. Run `flutter clean`, `flutter pub get`, then `flutter run`.

The app starts safely when Firebase is not configured, but Google sign-in will
show a setup error until the real configuration is present. Facebook remains
disabled and labeled “Coming soon”.

The preferred alert configuration is:

    flutter run --dart-define=KALASAG_ALERTS_BASE_URL=https://your-private-proxy.example

Live alert API requests are disabled by default. The Alerts screen uses clearly labeled practice records. Direct supplementary providers can be enabled for development:

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

## Kalasag AI setup

The Flutter app never contains a Gemini API key. Copy `backend/.env.example` to an untracked `backend/.env`, configure the server-side values, and follow `backend/README.md`. Production requests require a Firebase Authentication ID token and an HTTPS proxy deployment.

Run the Flutter client against that deployment with:

```powershell
flutter run --dart-define=KALASAG_AI_BASE_URL=https://your-private-proxy.example
```

The current demo login does not issue Firebase credentials, so production AI requests intentionally fail closed until real authentication is connected. For isolated local development only, the proxy and app support an unauthenticated development switch; both sides must opt in, and the server refuses this mode when `NODE_ENV=production`.

Backend verification:

```powershell
npm install --prefix backend
npm run check --prefix backend
npm test --prefix backend
npm audit --omit=dev --prefix backend
```

## Notes

- Email/password sign-in is currently a local demo entry flow and does not authenticate against a backend. Google and Facebook authentication are not implemented yet.
- The Android wrapper uses Gradle 9.1 because this development machine currently uses Java 25.
- Alert preferences are persisted. OS background/push delivery still requires a production notification provider or backend. Live alert refresh is available only when `ENABLE_LIVE_ALERT_APIS=true` is supplied.
- Windy is embedded through its public map page, matching the network-dependent radar behavior of the original app.
- The app has been built, installed, launched, and navigated on an authorized Infinix X6833B running Android 14. Disruptive actions (placing calls, sounding the whistle, and toggling the torch) still require supervised manual verification. Neither tool contacts responders automatically.
- The online assistant UI and secure proxy are implemented, but no live Gemini request has been claimed or verified because production credentials, deployment, Firebase configuration, and real app authentication have not been supplied.
- The bundled offline safety guide remains available when the assistant is offline or unavailable. Neither assistant is an official emergency response service.
