# UI UX Audit and Redesign

## Completion status

The shared design system, dashboard, alerts language, primary navigation, weather map shell, preparedness storage status, emergency contacts, SOS tools, and AI placement were redesigned and verified by analysis, automated tests, debug build, and targeted physical-device inspection. This is a substantial completed overhaul, but not a claim that every accessibility or external-service path is finished.

## Audit findings

| Area | Finding | Resolution |
|---|---|---|
| Design system | Colors, radii, spacing, typography, fields, and buttons were inconsistently hardcoded | Added centralized tokens and comprehensive Material 3 component themes |
| Dashboard | Provider/model text and an API-evidence action competed with safety information | Rebuilt around location, weather, safety status, quick access, hourly forecast, and outlook; moved attribution to a quiet footer |
| Alerts | Default demo data was labeled “Live” | Practice data is now explicitly labeled and cannot be mistaken for a current advisory |
| Weather map | Small header, generic dropdown, fragile delayed controller setup, no loading/error treatment | Added a robust controller lifecycle, nearly full-screen map, layer chips, progress/error states, location/title actions, and map-information sheet |
| Radar/playback | The app could not synchronize custom Flutter controls with a cross-origin Windy embed | Retained Windy's real native forecast play/pause/timeline instead of building fake controls |
| Navigation | “Now” and “Radar” were less clear than the actual destinations | Renamed them Home and Map; standardized icons and selected states |
| Preparedness | “Hive offline storage” exposed an implementation detail | Replaced with plain-language offline availability and save-error messaging |
| Emergency contacts | Primary call action was hidden in a menu | Added a visible dialer button while retaining confirmation and never auto-calling |
| SOS tools | Labels were wordy and technical | Simplified to direct flashlight and emergency-sound actions with a persistent offline/safety notice |
| AI assistant | Floating button could cover critical controls | Hidden on SOS and Map; remains available on Home, Alerts, and Ready |
| Accessibility | Several controls lacked a consistent minimum size and hierarchy | Theme now standardizes 48–52 px controls, stronger contrast, semantics, readable hierarchy, and SafeArea behavior |

## Design system

- Primary: professional blue #1769D2
- Brand navy: #102A43
- Secondary: restrained teal #0E8A92
- Danger: #D64550, used only for real emergency actions
- Success: #218A61
- Page padding: 20 px; spacing scale: 4, 8, 12, 16, 24, 32 px
- Radii: 10, 16, and 24 px
- Flat bordered cards, 52 px primary buttons, 48 px icon targets, filled form fields, consistent dialogs and sheets
- Reusable components: page header, status pill, and contextual notice

## Weather map and Windy decision

The existing integration is Windy's official map embed loaded through webview_flutter, not a licensed custom Map Forecast API instance with an application-owned key. Windy's embed supplies the real interactive map, supported forecast layers, legend, attribution, and its own play/pause timeline.

Kalasag exposes Rain, Wind, Temperature, and Clouds because those are the layers configured and verified for this embed. The app does not expose a “Radar” layer, invent historical frames, scrape Windy, or call undocumented internals.

The playback UI visible inside Windy changes genuine forecast time states. It is explicitly described as forecast guidance, not historical radar observation. A Flutter-owned timeline was rejected because cross-origin embed state cannot be reliably synchronized. Official references:

- https://api.windy.com/map-forecast/docs
- https://api.windy.com/map-forecast/tutorials/parameters
- https://embed.windy.com/

## Responsive and accessibility decisions

The redesigned surfaces use SafeArea, scrollable page layouts, horizontally scrollable layer/hour controls, bounded text, adaptive progress indicators, keyboard-aware existing sheets, Material minimum targets, semantic weather summaries, descriptive tooltips, and stronger light/dark contrast. The device test covered a 1080 × 2460 Android screen. Comprehensive small-screen, large-text, landscape, and TalkBack passes remain outstanding.

## Verification

- flutter analyze: PASS, no issues.
- flutter test: PASS, 25 tests.
- flutter build apk --debug: PASS.
- Infinix X6833B install/launch: PASS.
- Dashboard layout and accessibility hierarchy: PASS.
- Windy map, layer controls, legend, attribution, and native play control visible: PASS.
- Complete timed play/pause/seek cycle: NOT RUN.
- AI/SOS backend behavior remains unchanged.

## Known limitations

- Windy is a network-dependent external WebView and can change independently.
- Kalasag cannot inspect or programmatically assert every internal Windy frame transition.
- The current app has demo login only; registration, profile, session, and logout screens do not yet exist to redesign.
- Full large-text, TalkBack, reduced-motion, denial-state, and disruptive emergency-tool testing remains pending.
- Two legacy private screen implementations remain temporarily in screens.dart as migration references and are excluded from the active navigation.
