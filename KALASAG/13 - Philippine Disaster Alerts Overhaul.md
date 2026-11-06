# Philippine Disaster Alerts Overhaul

Review date: 2026-10-25

## Outcome

Kalasag now has a normalized, source-aware disaster alert pipeline, a backend aggregation endpoint, independent provider health, deduplication, lifecycle fields, cached fallback, real distance filtering, and a redesigned alert list/detail experience. Weather Radar, SOS, and Gemini behavior were not changed.

No Philippine government feed is claimed as integrated unless a stable documented machine-readable interface is available. The app links users directly to authoritative Philippine pages and labels automated international data as supplementary.

## Source policy

- Never present practice data as live.
- Never present saved data as freshly retrieved.
- Preserve an agency's original level separately from Kalasag's visual priority.
- Do not scrape unstable HTML/PDF pages into a safety-critical feed.
- A provider failure must be visible and must not erase successful results from other providers.
- Hazard maps and forecasts are not automatically described as active alerts.

## Build configuration

Preferred production path:

    flutter run --dart-define=KALASAG_ALERTS_BASE_URL=https://your-backend.example

Development-only direct public feeds:

    flutter run --dart-define=ENABLE_LIVE_ALERT_APIS=true

With neither define, Alerts runs in clearly marked practice mode. Push notifications remain disabled until reliable server deployment, background delivery, and end-to-end verification exist.

## Source registry

| Source | Authority and coverage | Integration decision |
|---|---|---|
| DOST-PAGASA | Philippine weather, cyclone, rainfall, flood and marine warnings | Authoritative link. No stable documented public alert API/RSS contract was verified; pages and PDFs are not scraped. |
| DOST-PHIVOLCS Earthquake Information | Philippine earthquake bulletins | Authoritative link. The public bulletin table is not treated as an API. |
| DOST-PHIVOLCS Volcano Bulletins | Philippine volcano status | Authoritative link. HTML is not scraped. |
| DOST-PHIVOLCS Tsunami Information | Philippine tsunami advisories and warnings | Authoritative link. HTML is not scraped. |
| NDRRMC | National multi-hazard coordination and situation reports | Authoritative link. Reports are primarily pages/documents. |
| DENR-MGB | Landslide, flood and geohazard advisories/maps | Authoritative link. Static susceptibility is not a current alert. |
| HazardHunterPH | Government multi-hazard assessment | Verification tool only; not a current alert feed. |
| USGS FDSN Event Web Service | Earthquakes in the Philippine bounding box | Documented API; ingested as supplementary. |
| NASA EONET v3 | Storm, flood, landslide, volcano and wildfire event metadata | Documented API; ingested as supplementary. |
| GDACS Events API | Global multi-hazard reports | Documented GeoJSON API; ingested as supplementary. |

Official verification URLs are exposed in the app and in backend/src/alerts.js.

## Normalized alert contract

Each record carries:

- stable source ID, agency, category, title and description;
- issued, updated, effective, expiry and retrieval timestamps when available;
- original official/source level and separate Kalasag visual priority;
- affected areas and an optional point location;
- source URL, reference number, verification status and language;
- lifecycle: active, watch, ended, cancelled, or exercise;
- source-backed or conservative actions; and
- an explicit saved-copy flag.

Deduplication uses category, normalized title, and issue date. The newest revision wins. Sorting places active records before ended records, then visual priority, then issue time. This is display logic only; it does not redefine agency warning systems.

## Runtime architecture

GET /v1/alerts on the existing Node backend:

1. calls each provider independently with a timeout and one retry;
2. records per-source availability instead of swallowing failures;
3. normalizes provider payloads at the server boundary;
4. filters to Philippine bounds or country attribution;
5. deduplicates and sorts the merged result;
6. caches successful results for five minutes; and
7. serves the last successful response for up to 24 hours when every provider is down, explicitly marked cache.status = stale.

Flutter prefers this endpoint when KALASAG_ALERTS_BASE_URL is set. It persists non-demo results in Hive. If refresh fails, the UI shows saved reports with their retrieval timestamp and warning banner.

## UX behavior

- All PH includes nationwide and unmapped reports.
- Near me only includes reports with coordinates inside the configured radius. It never guesses locality from a vague region label.
- Practice, supplementary, official, and saved-copy provenance are visible.
- Details show source terminology, lifecycle, timestamps, areas, actions, coordinates, and the original report link.
- Empty results explicitly warn that absence from Kalasag does not prove absence of danger.
- Philippine official sources remain one tap away.
- Notification controls do not claim background delivery; push is visibly unavailable.

## Known limitations

- No production alert backend URL has been supplied or deployed.
- No Philippine government CAP/API/RSS interface was verified for automatic ingestion during this review.
- Many advisories lack point coordinates, so they intentionally do not appear under Near me.
- Geographic polygons and province/city boundary matching are not yet implemented.
- No push provider, topic subscription, background worker, or delivery receipt exists.
- Automated data is supplementary and must be confirmed through Philippine authorities or the relevant LGU.

## Verification checklist

- Flutter format and static analysis
- Flutter unit/widget test suite
- Node syntax check and backend tests
- Debug APK build
- Manual device check: mode banner, filters, All PH/Near me, details, links, refresh, saved fallback, source health

Live provider smoke tests should be run from the deployed backend environment and logged with timestamps. They must not be replaced by mocked success claims.
