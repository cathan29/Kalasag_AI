# Gemini AI Assistant

## Verified implementation status

The assistant client, secure proxy, safety policy, persistence, offline fallback, automated tests, debug build, and physical-device UI smoke test are complete. Live Gemini behavior is **BLOCKED**, not failed: the project has no supplied API key, Firebase project/authentication, or deployed HTTPS proxy. No live provider response is claimed.

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

- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, 23 tests.
- `npm run check --prefix backend`: PASS.
- `npm test --prefix backend`: PASS, 4 tests.
- `npm audit --omit=dev --prefix backend`: PASS, 0 vulnerabilities.
- `flutter build apk --debug`: PASS.
- Infinix X6833B Android 14/API 34 install and UI smoke test: PASS for the global button and setup-required sheet.
- Live Gemini request: BLOCKED pending credentials, real Firebase auth, and HTTPS deployment.

## Acceptance steps after credentials exist

Test English and Filipino multi-turn preparedness questions, immediate-danger escalation, attempts to elicit invented live alerts/phone numbers/locations, safety-block responses, quota/rate limit behavior, timeout/retry/cancel, network loss, expired Firebase tokens, app restart history, clear history, large text, keyboard layout, and all four non-SOS tabs. Confirm server logs contain metadata only and no chat content.
