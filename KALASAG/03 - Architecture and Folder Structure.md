# Architecture and Folder Structure

## Application architecture

- `lib/main.dart`: application entry point, provider setup, theme, splash gate.
- `lib/app_state.dart`: ChangeNotifier state coordinator for location, weather, alerts, shelters, readiness plans, saved places, settings, and emergency contacts.
- `lib/services.dart`: HTTP integrations for weather, alert aggregation, and OpenStreetMap shelter data.
- `lib/local_storage_service.dart`: Hive-backed on-device JSON persistence.
- `lib/models.dart`: domain models and serialization.
- `lib/screens.dart`: weather, alerts, radar, and readiness screens.
- `lib/extras.dart`: emergency directory, shelters, notification settings, and main navigation shell.
- `lib/sos_features.dart`: custom contacts and Android emergency-tool UI.
- `lib/login_screen.dart`: demo-only login presentation and validation.
- `lib/ai`: AI message models, controller, Hive history store, secure proxy client, chat sheet, and global floating action button.
- `backend/src/server.js`: authenticated Express proxy for the Gemini Interactions API.
- `backend/src/safety-policy.js`: disaster-safety system policy and emergency-response boundaries.
- `backend/src/conversation-token.js`: user-bound, expiring HMAC conversation context.
- `android/app/src/main/kotlin/com/cathan/kalasag/MainActivity.kt`: platform channel for torch and alert sound.
- `assets/data`: bundled offline hotlines, guides, localities, and bulletin data.
- `test`: unit and widget tests.
- `KALASAG`: this Obsidian vault.

## State and data flow

UI screens read or watch `AppState`. Network services return model objects. `AppState` records loading, error, result, and update timestamps, and serializes local readiness data through Hive. Native device tools are isolated behind the `kalasag/emergency_tools` method channel.

`AiChatController` owns assistant messages, network state, retry/cancel behavior, and the signed context token. It persists only the bounded local transcript through `AiChatStorage`. `GeminiProxyChatService` calls the configured HTTPS proxy with a Firebase ID token; the proxy validates the token, applies rate limits and the safety policy, calls Gemini, and returns sanitized text plus a new signed context token. Gemini secrets never cross into Flutter.

## Constraints

The AI proxy is implemented but not deployed or credentialed. The codebase still has no configured remote app authentication or general data-sync backend. Local Hive data is not synchronized across devices and is not encrypted by the application. The radar view is a network-dependent external web experience.

