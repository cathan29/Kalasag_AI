# Gemini AI Assistant

## Verified implementation status

The assistant client, secure proxy, safety policy, persistence, offline
fallback, automated tests, debug build, and physical-device UI smoke test are
complete. 

Live Gemini AI status is now **ACTIVE and VERIFIED LIVE**:
- `GEMINI_API_KEY` configured in untracked `backend/.env` with model `gemini-3.5-flash-lite`.
- Backend proxy running on port 8787 (`http://0.0.0.0:8787/health` -> 200 OK).
- Flutter client wired with `FirebaseAiAccessTokenProvider` in `lib/main.dart` for Firebase ID tokens.
- `AiServiceConfig.fromEnvironment()` defaults to `http://127.0.0.1:8787` with multi-host candidate fallback (`127.0.0.1`, Android emulator `10.0.2.2`, and local Wi-Fi IP `192.168.100.32`).
- UI indicator switches from `Setup required` (orange) to `Secure connection ready` (green).
- Live Filipino & English disaster guidance successfully tested against Gemini 3.5 Flash Lite with valid HMAC-signed conversation tokens.
- Connected Android device (Infinix X6833B) mapped via `adb reverse tcp:8787 tcp:8787`.

## User experience

- Bottom-right `Kalasag AI` floating action button on Weather, Alerts, Radar, and Ready; hidden on SOS to preserve emergency controls.
- Responsive modal sheet titled `Kalasag AI Assistant` with connection/setup status and accessible close control.
- Exact welcome text: “Hi! I'm Kalasag AI, your disaster preparedness assistant. How can I help you stay safe today?”
- Four quick prompts for earthquakes, typhoons, floods, and emergency kits.
- Timestamped message bubbles, Markdown responses, typing indicator, cancel, retry, clear-history confirmation, input validation, and automatic scrolling.
- Local history survives dismissal and app backgrounding. Users can explicitly erase it.
- Offline and error states link directly to the deterministic offline safety guide.

## Architecture and security decision

The implementation uses a server-side proxy instead of placing a Gemini key in Flutter. The app sends an HTTPS request to `POST /v1/chat` with a Firebase ID token. The server verifies the token, applies rate limits and the Kalasag safety policy, calls Gemini, and returns assistant text with an opaque signed context token.

The proxy is stateless for message content: it neither stores nor logs prompts/responses. Conversation continuity uses a short-lived HMAC-signed token tied to the verified user. Production fails closed without authentication. The development bypass is accepted only outside production and requires explicit opt-in from both server and app.

## Safety behavior

The server system policy requires calm, concise English or Filipino disaster guidance. It tells the model to prioritize official local authorities, distinguish general preparedness from current/live facts, avoid diagnosis, escalate immediate danger, and never fabricate current conditions, locations, citations, phone numbers, responder availability, or evacuation centers. The UI independently states that Kalasag AI is a support tool, not an official emergency response service.

## Configuration

1. Copy `backend/.env.example` to untracked `backend/.env`.
2. Set `GEMINI_API_KEY`, a random 32+ character `CONVERSATION_SIGNING_SECRET`, `GOOGLE_CLOUD_PROJECT`, and Firebase Admin Application Default Credentials.
3. Install and verify the server with `npm install --prefix backend`, `npm run check --prefix backend`, and `npm test --prefix backend`.
4. Deploy the proxy behind HTTPS with `NODE_ENV=production`; keep `ALLOW_UNAUTHENTICATED_DEV=false`.
5. Replace the Flutter demo login with Firebase Authentication and provide its current ID token through `AiAccessTokenProvider`.
6. Run Flutter with `--dart-define=KALASAG_AI_BASE_URL=https://your-private-proxy.example`.

Never place the Gemini key, Firebase service-account JSON, signing secret, or a reusable bearer token in Flutter, source control, or a Dart define.

## Verification evidence

- `flutter analyze`: PASS, no issues (0 errors, 0 warnings).
- `flutter test`: PASS, 39 tests.
- `npm run check --prefix backend`: PASS.
- `npm test --prefix backend`: PASS, 8 tests.
- `npm audit --omit=dev --prefix backend`: PASS, 0 vulnerabilities.
- `flutter build apk --debug`: PASS.
- Infinix X6833B Android 14/API 34 install, ADB reverse (`tcp:8787`), and UI smoke test: PASS.
- Live Gemini 3.5 Flash Lite request (`POST /v1/chat`): PASS (tested in Filipino; returned official NDRRMC/PHIVOLCS-compliant Drop-Cover-Hold guidance and signed interaction context).

## Acceptance steps after credentials exist

Test English and Filipino multi-turn preparedness questions, immediate-danger escalation, attempts to elicit invented live alerts/phone numbers/locations, safety-block responses, quota/rate limit behavior, timeout/retry/cancel, network loss, expired Firebase tokens, app restart history, clear history, large text, keyboard layout, and all four non-SOS tabs. Confirm server logs contain metadata only and no chat content.
