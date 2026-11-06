# Home Disaster Companion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic gradient-heavy weather Home with an adaptive Philippine disaster companion centered on contextual mascot guidance, honest local hazard status, readiness, rainfall, and official advisories.

**Architecture:** Keep `WeatherScreen` as the AppState/navigation wrapper in `lib/screens.dart`, extract pure deterministic safety presentation into `lib/home/home_insight.dart`, and render the new responsive UI in `lib/home/home_dashboard.dart`. This isolates testable risk decisions from Flutter layout while preserving existing services, navigation, refresh, error states, and bottom navigation.

**Tech Stack:** Flutter, Dart, Provider, Material 3, existing AppState/models/assets, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-07-home-disaster-companion-design.md`

## Global Constraints

- Follow `ThemeMode.system`; light and dark Home layouts must both be intentionally styled.
- Use the real `assets/mascot/kalasagicon-transparent.png` logo and existing happy/rain/storm mascot assets.
- All Home titles, tags, labels, and messages are English-only.
- No decorative blue-to-teal gradients, glassmorphism, faded mascot watermark, giant temperature, repeated generic cards, or duplicate Map/Emergency content actions.
- Use Material outlined icons for normal actions/data and filled icons only for selected navigation or urgent state.
- Never fabricate PAGASA data or claim a local all-clear without applicable structured official data.
- Demo, stale, non-local, future-effective, ended, or expired alerts cannot drive live hazard status or mascot safety conclusions.
- Preserve loading, location error, weather error, refresh, alert detail, data attribution, accessibility, and existing bottom navigation.
- Preserve unrelated repository changes and never expose backend secrets.

## Review Focus

- Missing or broad `affectedAreas` must produce neutral monitoring status, not a false local warning or all-clear; Task 1 pins this.
- Non-English official alerts must use an English wrapper on Home without translating or exposing foreign-language title text; Task 1 pins this.
- Large text and 320 logical-pixel width must not overflow the hero, hazards, readiness, timeline, or advisory; Task 2 pins this.
- Dark mode must retain readable hero/hazard semantics without introducing gradient/glow decoration; Task 2 pins this.
- Cached official data with failed live refresh must remain visible as stale but must not control current hazard/mascot state; Tasks 1 and 3 pin this.

---

### Task 1: Deterministic Home safety presentation

**Files:**
- Create: `lib/home/home_insight.dart`
- Test: `test/home/home_insight_test.dart`

**Interfaces:**
- Consumes: `WeatherSnapshot`, `GeoPoint`, `AlertItem`, `KitItem`.
- Produces: `enum HomeMascotMood { happy, rain, storm }`.
- Produces: `enum HomeHazardTone { neutral, safe, caution, warning, danger }`.
- Produces: immutable `HomeHazardItem`, `HomeAdvisorySummary`, `HomeReadinessSummary`, and `HomePresentation`.
- Produces: `HomePresentationInput` with required `WeatherSnapshot weather`, `GeoPoint location`, `List<AlertItem> alerts`, `List<KitItem> kit`, `Map<String, String> familyPlan`, `int emergencyContactCount`, `bool alertsFromCache`, `bool alertsDemoMode`, `double alertRadiusKm`, `DateTime? weatherUpdated`, `DateTime? alertsUpdated`, and `DateTime now`.
- Produces: `HomePresentation buildHomePresentation(HomePresentationInput input)`.
- Produces: `double? calculateHeatIndexCelsius({required double? temperatureCelsius, required double? relativeHumidity})`.

- [ ] **Step 1: Write failing heat-index and category tests**

Add tests named:

- `returns null when temperature or humidity is unavailable`;
- `calculates representative tropical heat index values`;
- `maps 2732 C to Caution, 3341 C to Extreme Caution, 4251 C to Danger, and 52+ C to Extreme Danger`.

Assert the four PAGASA bands exactly. Use a tested NOAA/Rothfusz-compatible calculation and label the result `Estimated heat index` because Open-Meteo does not supply an official PAGASA station value.

- [ ] **Step 2: Run the focused tests to verify red**

Run: `flutter test test/home/home_insight_test.dart`

Expected: FAIL because `home_insight.dart` and its interfaces do not exist.

- [ ] **Step 3: Implement heat index interfaces**

Implement `calculateHeatIndexCelsius` and centralized PAGASA classification in `lib/home/home_insight.dart`. Values below 27 C remain neutral current-condition information rather than a heat hazard.

- [ ] **Step 4: Write failing alert applicability and priority tests**

Cover:

- official local active unexpired alert outranks derived weather;
- demo, ended, expired, future-effective, stale, and non-local alerts do not drive live hazards or mascot mood;
- `officialLevel` is used only after local applicability is established;
- free-form title/description is never scanned for the highest signal/color;
- severity tie-break order is Critical, High, Medium, Low, then latest updated/issued time;
- missing location/applicability yields Monitoring official updates;
- cached stale alert remains an advisory summary with stale state;
- non-English alert yields English `Official advisory available` summary without its original title.

- [ ] **Step 5: Write failing readiness and mascot tests**

Assert go-bag percentage uses completed items over total items, family plan is ready only when all three existing fields are non-empty, emergency contacts use the supplied count, and mood priority is severe local alert then rain then happy.

- [ ] **Step 6: Implement `buildHomePresentation`**

Use injected `DateTime now` for deterministic freshness tests. Match normalized affected-area text against the current location label. When `affectedAreas` is empty and both coordinates exist, local applicability requires distance less than or equal to `alertRadiusKm`; clamp that input to 10200 km. Generate concise English deterministic briefing copy.

- [ ] **Step 7: Run focused tests and analysis**

Run: `flutter test test/home/home_insight_test.dart`

Expected: PASS.

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/home/home_insight.dart test/home/home_insight_test.dart
git commit -m 'feat(home): add deterministic disaster briefing model'
```

### Task 2: Adaptive Home dashboard UI

**Files:**
- Create: `lib/home/home_dashboard.dart`
- Test: `test/home/home_dashboard_test.dart`

**Interfaces:**
- Consumes: `HomePresentation model`, `Future<void> Function() onRefresh`, `VoidCallback? onOpenAdvisory`, and `bool isRefreshing`.
- Produces: `HomeDashboard`, a stateless responsive widget with no Provider or navigation dependency.

- [ ] **Step 1: Write failing identity and hierarchy widget tests**

Assert the widget renders the real KALASAG logo, location/data status, selected contextual mascot asset, Hazard Status, Are You Ready?, Hourly Weather Pulse, Official Advisory, source/time, and forecast attribution in that order. Assert it does not render Weather map or Emergency content buttons.

- [ ] **Step 2: Write failing theme and icon tests**

Pump the same model under `KalasagTheme.light()` and `KalasagTheme.dark()`. Assert both settle without exceptions, all normal data/action icons are Material outlined variants, and no Home container uses a `LinearGradient`.

- [ ] **Step 3: Write failing responsive/accessibility tests**

Pump at 320�720 and 600�1000 logical pixels with text scale 1.0 and 1.6. Assert no Flutter overflow/error, semantic labels exist for refresh and advisory actions, and interactive controls meet a 48 logical-pixel target.

- [ ] **Step 4: Run widget tests to verify red**

Run: `flutter test test/home/home_dashboard_test.dart`

Expected: FAIL because `HomeDashboard` does not exist.

- [ ] **Step 5: Implement the dashboard hierarchy**

Build focused private widgets for compact header, mascot briefing hero, wrap-capable hazard status, readiness summary, hourly timeline, advisory banner, and attribution. Use `Theme.of(context).colorScheme`, `LayoutBuilder`, `Wrap`, flexible text, thin borders, and restrained elevation. Use no decorative gradient.

- [ ] **Step 6: Implement contextual mascot framing**

Map happy/rain/storm moods to the three approved existing assets. Use `BoxFit.cover` plus responsive alignment/crop that keeps the face visible; add only a theme-aware solid/scrim text region needed for contrast, never opacity watermark treatment.

- [ ] **Step 7: Run focused tests and analysis**

Run: `flutter test test/home/home_dashboard_test.dart`

Expected: PASS.

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/home/home_dashboard.dart test/home/home_dashboard_test.dart
git commit -m 'feat(home): build adaptive disaster companion dashboard'
```

### Task 3: Integrate Home with AppState and existing navigation

**Files:**
- Modify: `lib/screens.dart` current `WeatherScreen` and obsolete private weather widgets only
- Test: `test/home/weather_screen_test.dart`
- Modify: `test/navigation_data_passing_test.dart` only if existing fixtures need the new Home wrapper

**Interfaces:**
- Consumes: `buildHomePresentation(HomePresentationInput input)` from Task 1.
- Consumes: `HomeDashboard` from Task 2.
- Preserves: `WeatherScreen` public class consumed by `HomeShell`.

- [ ] **Step 1: Write failing wrapper state tests**

Cover initial loading, location denied, weather unavailable, saved/cached weather, fresh official local alert, cached stale alert, demo alert, and no-applicable-alert states. Assert refresh still awaits weather and alert refresh together.

- [ ] **Step 2: Write failing navigation/readiness tests**

Assert an applicable advisory opens the existing `AlertDetailScreen`, readiness values come from current `AppState.kit`, `familyPlan`, and `emergencyContacts`, and no duplicate route to Radar/SOS is introduced.

- [ ] **Step 3: Run wrapper tests to verify red**

Run: `flutter test test/home/weather_screen_test.dart`

Expected: FAIL because `WeatherScreen` still renders the legacy composition.

- [ ] **Step 4: Replace legacy composition with model adapter**

Keep existing guard states and `RefreshIndicator`. Build `HomePresentationInput` from current weather, location, alerts, cache/demo flags, readiness state, update times, and current time, then render `HomeDashboard`. Pass the current alert-detail navigation callback only when a summary has a source alert.

- [ ] **Step 5: Remove obsolete Home-only private widgets**

Delete `_CurrentWeatherCard`, repeated metric/hourly card code, Quick access buttons, and any Home-only imports made unused. Do not change other screens or bottom navigation.

- [ ] **Step 6: Run focused and regression tests**

Run: `flutter test test/home/weather_screen_test.dart test/navigation_data_passing_test.dart`

Expected: PASS.

Run: `flutter test`

Expected: all tests pass.

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/screens.dart test/home/weather_screen_test.dart test/navigation_data_passing_test.dart
git commit -m 'feat(home): integrate Philippine disaster companion'
```

### Task 4: Android visual verification and final regression

**Files:**
- Modify only files required by confirmed test/device regressions.

**Interfaces:**
- Consumes the completed Home screen from Tasks 13.
- Produces no new product interface.

- [ ] **Step 1: Run complete static and automated gates**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 2: Build Android debug APK**

Run: `flutter build apk --debug`

Expected: successful APK build with no missing asset.

- [ ] **Step 3: Smoke-test on the connected Android phone**

Verify light and dark system themes, narrow portrait layout, mascot switching fixtures/states where practical, refresh, advisory navigation, location/weather errors, scrolling, bottom navigation, and AI floating action button coexistence. Capture screenshots for both themes.

- [ ] **Step 4: Inspect final diff and assets**

Confirm the real KALASAG logo is used, no new generated logo/agency logo is committed, no Home `LinearGradient` remains, all Home copy is English, and no backend secret or `.env` change is included.

- [ ] **Step 5: Request focused code and visual review**

Review the full feature diff against the spec, with particular attention to false local hazard claims, stale/demo handling, overflow, dark-mode contrast, and alert-detail behavior. Fix only confirmed findings, then repeat Steps 13.

- [ ] **Step 6: Commit verified fixes if any**

```bash
git add <confirmed-fix-files>
git commit -m 'fix(home): polish verified disaster dashboard'
```

## Reference

The heat-index effect bands are fixed to the official PAGASA four-tier classification: 2732 C Caution, 3341 C Extreme Caution, 4251 C Danger, and 52 C and beyond Extreme Danger.
