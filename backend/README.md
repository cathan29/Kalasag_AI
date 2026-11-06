# Kalasag Gemini proxy

This service keeps `GEMINI_API_KEY` on the server and exposes `POST /v1/chat` plus the read-only `GET /v1/alerts` aggregation endpoint. Chat requires a Firebase Authentication ID token in production. Alert reads contain public disaster metadata and are rate limited.

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

## Alert aggregation

`GET /v1/alerts` calls USGS, NASA EONET, and GDACS independently, normalizes Philippine-area records, reports source health, deduplicates revisions, and caches the latest successful response. Philippine government pages are included as verification links; the service does not scrape unstable HTML or PDFs.

Point Flutter to this deployment with:

    flutter run --dart-define=KALASAG_ALERTS_BASE_URL=https://your-private-proxy.example

If every provider fails, the service returns a saved response for up to 24 hours with `cache.status` set to `stale`; otherwise it returns HTTP 503. No push delivery is implemented.
