# KALASAG Home Disaster Companion Design

## Intent

Replace the current generic weather dashboard with a professional Philippine disaster companion. The Home screen should feel trustworthy, calm, locally relevant, and intentionally designed rather than assembled from repeated gradient cards.

The visual direction was approved from a high-fidelity mockup: a clean adaptive canvas, a purposeful mascot briefing, compact hazard and readiness information, a rainfall timeline, and one official advisory.

## Goals

- Make the KALASAG mascot prominent and useful instead of a faded watermark.
- Use Philippine hazard concepts and official-source context where real data supports them.
- Make current conditions, risks, readiness, and advisories scannable in seconds.
- Follow the phone system theme automatically with equally considered light and dark modes.
- Use the real KALASAG logo and a consistent professional Material icon system.
- Keep every visible title, tag, label, and message in English.
- Preserve pull-to-refresh, current weather data, alert navigation, location handling, loading states, and bottom navigation.

## Non-goals

- No redesign of Alerts, Map, Ready, SOS, Login, or AI screens.
- No new remote API or fabricated PAGASA data.
- No replacement of the existing mascot identity.
- No duplicate Weather Map or Emergency actions inside Home.
- No Taglish UI copy.

## Anti-goals

- No blue-to-teal decorative gradients.
- No glassmorphism, decorative blobs, neon highlights, or excessive shadows.
- No giant temperature dominating the screen.
- No repeated identical rounded cards for every value.
- No faded mascot watermark.
- No mixed icon families or cartoon icons.
- No claims such as no cyclone signal unless the underlying official alert feed supports that conclusion.

## Theme Behavior

The app continues using `ThemeMode.system`.

Light mode uses a warm white or very light cool-gray canvas, navy primary text, muted secondary text, thin neutral dividers, restrained elevation, and white/surface cards only where grouping materially helps.

Dark mode uses deep charcoal/navy surfaces, off-white primary text, muted blue-gray secondary text, subtle borders, and low elevation. It must not simply invert white cards and must not introduce glowing gradients.

Semantic hazard colors remain stable across themes:

- green for verified normal/safe status;
- yellow for advisory/caution;
- orange for elevated warning;
- red for dangerous/urgent conditions;
- neutral gray when status is unknown or unavailable.

All combinations must meet accessible contrast and remain legible with larger text.

## Screen Hierarchy

### 1. Compact identity header

Use the actual `assets/mascot/kalasagicon-transparent.png` asset as the KALASAG brand mark. Show a short greeting, current location, data freshness/verification state, refresh affordance, notifications, and profile only when those destinations exist in the current app.

Do not invent a new seal or use AI-generated logos. Avoid an oversized app bar.

### 2. Contextual mascot briefing hero

The hero is image-led but not gradient-led. It pairs one concise briefing with one clearly visible mascot image:

- `kalasag-weather-happy.png` for clear/low-risk conditions;
- `kalasag-weather-rain.png` for rain or rainfall advisory;
- `kalasag-weather-storm.png` for severe weather or urgent storm-related alerts.

The current wide compositions already contain negative space for copy and should be cropped responsively with `BoxFit.cover`. Text receives a solid or scrim-backed readable region only when required for contrast. The mascot is never rendered as a low-opacity decoration.

Briefing content is deterministic and derived from current weather and the highest-priority alert. It uses concise English such as current condition plus the most important safety implication. It does not use Gemini to invent live safety claims.

### 3. Hazard status

Show a compact, wrap-capable set of status items rather than generic metric cards. Prioritize:

- official tropical cyclone wind signal when parsed from a current alert;
- official rainfall warning/advisory color when parsed from a current alert;
- calculated heat index when temperature and humidity are sufficient;
- a neutral unavailable/monitoring state when official alert coverage cannot prove an all-clear.

Heat index must be calculated by a tested pure function and labeled as an estimate when it is not supplied directly by an official source. Severity mapping must be centralized and tested. Official alert labels and severity always outrank derived weather risk.

Humidity, wind, temperature, and precipitation remain available as secondary facts but do not become three identical hero cards.

### 4. Are You Ready

Present a compact readiness summary from existing local state:

- Go-Bag completion percentage;
- family plan status;
- emergency contact count.

Use a single section with dividers or a compact row/grid. Each item may navigate to its existing Ready destination when a direct destination already exists. Do not add duplicate primary navigation.

### 5. Hourly Weather Pulse

Replace the horizontal collection of repeated mini-cards with a single scannable timeline for the next six to eight hours. Rain probability is the primary signal, with time, a consistent outlined weather icon, and compact temperature as supporting information.

The timeline must support narrow phones and larger text without horizontal overflow. A horizontally scrollable implementation is acceptable when semantics remain clear.

### 6. Official advisory

Show the highest-priority real alert in one banner with source, severity, title, relative time, and navigation to the existing alert detail screen. Use the source name as text; do not fabricate or generate agency logos.

When there is no reliable alert, use a neutral monitoring message that does not claim an official all-clear. Offline demo alerts must be explicitly labeled as demo content.

### 7. Data attribution

Keep compact forecast attribution and updated time. Official advisory attribution is separate from Open-Meteo forecast attribution.

The existing bottom navigation remains unchanged, with professional Material outlined icons and a filled/selected treatment only for the active destination or urgent state.

## Professional Icon Rules

- Use Material Symbols/Icons already available in Flutter.
- Use outlined icons for normal actions and data.
- Use filled icons only for selected navigation or urgent status.
- Keep a consistent optical size, normally 2024 logical pixels.
- Avoid placing every icon in a colored circle.
- Do not mix Font Awesome, emoji, generated symbols, and Material icons on Home.
- Pair icons with text for safety-critical meaning; never rely on color or icon alone.

## Data and State Rules

- Continue reading weather, location, alerts, local kit, family plan, and emergency contacts from `AppState`.
- Select the mascot and briefing from deterministic weather/alert rules.
- Never use demo alerts for live hazard status, mascot selection, or safety conclusions. Demo content may appear only in the advisory banner with an explicit Practice label.
- A live candidate must not be ended/cancelled, must already be effective when `effectiveAt` exists, and must not be expired. A weather alert is fresh when its latest issued/updated time is within 24 hours or its explicit expiry is still in the future. Cached/stale items may remain visible in the advisory banner with a stale label but cannot drive current hazard status.
- Treat an alert as locally applicable only when a normalized `affectedAreas` value matches the current location label/administrative area, or when a structured coordinate is within a conservative tested distance threshold appropriate to its category. Missing location or missing applicability data produces a neutral monitoring state, never a local all-clear.
- For multiple locally applicable live alerts, rank verified official items before supplementary items, then severity Critical, High, Medium, Low, then latest updated/issued time. A qualifying official alert outranks derived weather risk. Stale or non-local official alerts do not.
- Use structured `officialLevel` only after local applicability is established. Do not scan free-form bulletin text for the highest signal number or rainfall color because one bulletin may describe different levels for different areas. When structured level is absent, show a generic Official advisory status.
- Parse structured official hazard levels conservatively and case-insensitively.
- Home remains English-only. For a non-English alert, show an English wrapper such as Official advisory available plus source, severity, language label, and time; do not translate or reproduce non-English title text on Home. Tapping opens the existing detail screen where original source content may remain.
- If data is missing, render an honest unavailable state rather than zero or safe.
- Preserve loading, location-denied, weather-error, offline-cache, refresh, and alert-detail behaviors.
- Use timestamps and source health where available to distinguish current, stale, demo, and unavailable information.

## Responsive and Accessibility Rules

- Design for approximately 320600 logical-pixel phone widths.
- Use `LayoutBuilder`, wrapping, and flexible text rather than fixed card widths.
- Honor system text scaling without clipping key safety content.
- Provide semantic labels/tooltips for interactive icons.
- Keep touch targets at least 48 logical pixels.
- Hazard information must remain understandable without color.
- Hero crop must keep the mascot face and briefing readable across supported widths.

## Testing

- Widget tests for light and dark theme rendering.
- Widget tests proving the real logo and contextual mascot asset are selected.
- Tests for no redundant Weather Map/Emergency buttons.
- Pure unit tests for heat-index calculation, hazard classification, alert parsing, briefing priority, and mascot selection.
- Widget tests for narrow width and enlarged text without overflow.
- Tests for loading, location error, weather error, no alert, demo alert, official alert, and stale data states.
- Existing navigation and full Flutter tests must remain green.
- Run `flutter analyze`, `flutter test`, a debug Android build, and connected-device visual smoke testing.

## Implementation Boundaries

Refactor the oversized Home implementation into focused private widgets or a dedicated Home module while keeping behavior local to the screen. Extract pure presentation models/selectors for testability. Do not expand this work into unrelated screens or change backend contracts unless a proven data gap requires a separately approved follow-up.
