# Current Development Status and Remaining Tasks

## Implementation matrix

| Feature | Current status | Problems found | Required action | Priority |
|---|---|---|---|---|
| Authentication | Partial demo | Any valid email and six-character password enters; no identity provider, registration, recovery, profile, session, or logout | Select and configure a real backend, then add full account lifecycle | High |
| Dashboard and weather | Implemented, partially verified | Live Open-Meteo and GPS exist; needs real-device permission and offline-state testing | Test permissions, network loss, refresh, and text scaling | High |
| Alerts | Partial | Clearly labeled offline demo records are the default; live providers require a build flag | Validate providers and present provenance and freshness consistently | High |
| Weather map | Partial | Embedded Windy web page depends on network and external behavior | Real-device interaction and failure testing | High |
| Preparedness hub | Implemented, partially verified | Local guides, go-bag, family plan, hotlines, and shelter search exist | Content review against current official sources and offline manual testing | Critical |
| Emergency contacts | Implemented in this audit | Persistent CRUD, validation, duplicate prevention, delete confirmation, and guarded dialer added | Widget and physical-device tests | Critical |
| SOS flashlight | Implemented, device test blocked | Android native torch control and cleanup added | Test permission denial, unavailable flash, and lifecycle on a phone | Critical |
| Emergency whistle | Implemented, device test blocked | Android repeating alert tone and cleanup added | Test volume, backgrounding, interruptions, and stop behavior on a phone | Critical |
| Safety assistant | Offline fallback implemented | Bundled rule-based guidance is physically verified; no online AI provider or server endpoint | Provide a secure server-side provider for online responses; never place a private key in Flutter | High |
| Backend | Missing for accounts and sync | Hive is local only | Choose backend only after requirements and credentials are available | Critical |
| Offline persistence | Implemented, partially verified | Hive stores readiness data and contacts; no automated restart integration test | Add integration test and test migration/corruption handling | Critical |
| Android device integration | Implemented, partially verified | Authorized Infinix X6833B detected; build/install/launch, login, weather, alerts, and offline guide verified | Manually verify disruptive torch, whistle, and dialer actions plus denial/lifecycle paths | Critical |

## Ordered remaining work

1. Manually verify contacts, dialer, torch, whistle, embedded radar, lifecycle, and permission-denial paths on the connected phone.
2. Connect GitHub tooling, create the private `kalasag-app` repository, and push `main`.
3. Decide the authentication/backend provider and supply development configuration without committing secrets.
4. Implement registration, recovery, persistent session, logout, emergency profile, and user-scoped remote data.
5. Add the online AI assistant through a secure server-side endpoint while retaining the verified offline fallback.
6. Review all preparedness and hotline content with current authoritative sources.
7. Add integration coverage for Hive restart persistence, corruption, denial paths, offline mode, and large text.
8. Configure production signing and build a release artifact.

