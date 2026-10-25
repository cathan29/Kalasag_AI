# Backend APIs Offline and Data Design

## Backend status

There is no application server, remote user database, or authentication provider. Account and multi-device persistence requirements are therefore not complete.

## API integrations

- Open-Meteo supplies weather forecast data without an embedded private key.
- Alert service supports GDACS, USGS, and NASA EONET, but live fetching is disabled by default and demo records are returned unless `ENABLE_LIVE_ALERT_APIS=true` is supplied.
- OpenStreetMap Overpass supplies nearby shelter data.
- Windy is embedded as an external network-dependent map page.
- Google Maps URLs are opened externally for directions.

External responses require continued schema, timeout, provenance, and rate-limit monitoring. Demo alerts must remain visibly labeled.

## Local database design

Hive box: `kalasag_local_data`

State key: `readiness_state`

The JSON document contains saved places, go-bag checklist, family plan, notification preferences, alert radius, emergency contacts, and last-save time. Emergency contacts contain an ID, name, normalized phone number, and optional relationship.

## Offline boundaries

Core guide and hotline content is bundled. Locally edited readiness information is stored on the device. Current weather, external maps, shelter lookup, and live alerts are not available offline. The missing AI assistant must explicitly redirect offline users to the preparedness hub.

