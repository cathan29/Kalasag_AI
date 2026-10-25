# Backend APIs Offline and Data Design

## Backend status

An application server now exists specifically for Gemini access. It is not deployed and has no supplied Gemini/Firebase credentials. There is still no remote user database or configured authentication provider, so account and multi-device persistence requirements remain incomplete.

## API integrations

- Open-Meteo supplies weather forecast data without an embedded private key.
- Alert service supports GDACS, USGS, and NASA EONET, but live fetching is disabled by default and demo records are returned unless `ENABLE_LIVE_ALERT_APIS=true` is supplied.
- OpenStreetMap Overpass supplies nearby shelter data.
- Windy is embedded as an external network-dependent map page.
- Google Maps URLs are opened externally for directions.
- `backend` exposes `POST /v1/chat`, verifies Firebase ID tokens in production, enforces a 12-request-per-minute limit, applies the Kalasag safety policy, and calls the Gemini Interactions API with `gemini-3.5-flash-lite` by default.

External responses require continued schema, timeout, provenance, and rate-limit monitoring. Demo alerts must remain visibly labeled.

## Local database design

Hive box: `kalasag_local_data`

State key: `readiness_state`

AI history key: `ai_chat_history_v1`

The JSON document contains saved places, go-bag checklist, family plan, notification preferences, alert radius, emergency contacts, and last-save time. Emergency contacts contain an ID, name, normalized phone number, and optional relationship.

AI history is capped at 40 messages and stored only on device. Server-side conversational continuity uses a 24-hour HMAC-signed token bound to the verified Firebase user ID. The proxy does not maintain a transcript database and logs no prompt or response text.

## Offline boundaries

Core guide and hotline content is bundled. Locally edited readiness information and AI history are stored on the device. Current weather, external maps, shelter lookup, live alerts, and Gemini responses are not available offline. The AI error surface explicitly links to the offline preparedness guide.

