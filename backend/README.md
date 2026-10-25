# Kalasag Gemini proxy

This service keeps `GEMINI_API_KEY` on the server and exposes only `POST /v1/chat` to the Flutter app. Production requests require a Firebase Authentication ID token. Conversation context is represented by a short-lived HMAC-signed token bound to the authenticated user; the proxy does not store or log chat text.

## Local configuration

1. Copy `.env.example` to `.env` and keep `.env` uncommitted.
2. Set `GEMINI_API_KEY` from Google AI Studio.
3. Generate a random `CONVERSATION_SIGNING_SECRET` of at least 32 characters.
4. Set `GOOGLE_CLOUD_PROJECT` and Application Default Credentials for Firebase token verification.
5. Run `npm install`, then `npm start`.

For isolated local development only, `ALLOW_UNAUTHENTICATED_DEV=true` may be used while `NODE_ENV` is not `production`. The server refuses to start with that bypass in production.

Run Flutter against an HTTPS deployment:

```powershell
flutter run --dart-define=KALASAG_AI_BASE_URL=https://your-private-proxy.example
```

Until real app authentication supplies a Firebase ID token, production chat requests intentionally fail closed. Do not embed the Gemini key, a service-account file, or a reusable bearer token in Flutter or `--dart-define` values.
