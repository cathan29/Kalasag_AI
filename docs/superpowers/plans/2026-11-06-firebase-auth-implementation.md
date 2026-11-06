# Firebase Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan.

**Goal:** Replace the fake KALASAG login with resilient Firebase Guest, Google, and Email authentication, connect Firebase identity to the Gemini proxy, and preserve offline emergency access.

**Architecture:** Add an injectable auth boundary and ChangeNotifier controller, route the app through an auth/session gate, and keep Firebase SDK details in adapters. Existing Provider, Hive, AppState, and AI controller remain the owners of UI state, readiness data, and conversation history.

**Tech Stack:** Flutter, Dart, Provider, Firebase Core, Firebase Auth, Google Sign-In, Hive, FlutterFire Android configuration, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-06-firebase-auth-design.md`

**Global Constraints:**

- Never embed or expose the Gemini API key in Flutter.
- Preserve all unrelated dirty-worktree changes.
- Emergency and cached readiness features remain reachable without Firebase.
- Facebook stays disabled and unimplemented.
- Readiness data is device-scoped; AI history is cleared on successful account logout/switch.
- Firebase project files must be generated from the real project, never fabricated.

**Review Focus:** Session restoration, anonymous credential linking, account-conflict recovery, safe offline entry, local-data retention/erasure, and Firebase ID-token delivery to the backend.

---

### Task 1: Establish Firebase dependencies and a testable bootstrap boundary

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/settings.gradle.kts`
- Modify: `android/app/build.gradle.kts`
- Create: `lib/auth/firebase_bootstrap.dart`
- Create: `test/auth/firebase_bootstrap_test.dart`
- Generated later: `lib/firebase_options.dart`
- Generated later: `android/app/google-services.json`

**Interfaces:**

- `FirebaseBootstrapResult` identifies ready, missingConfiguration, and failed initialization.
- `FirebaseBootstrap.initialize()` returns a controlled result and never crashes the app entry point.

**Steps:**

1. Write failing tests for missing configuration and initialization failure mapping.
2. Run `flutter test test/auth/firebase_bootstrap_test.dart`; confirm failure.
3. Add `firebase_core`, `firebase_auth`, and `google_sign_in` dependencies plus Google Services Gradle wiring.
4. Implement the bootstrap boundary with injectable initialization for tests.
5. Run the focused test and `flutter analyze`; expect pass.
6. Commit: `feat(auth): add firebase bootstrap boundary`

### Task 2: Build the authentication domain and controller test-first

**Files:**
- Create: `lib/auth/auth_models.dart`
- Create: `lib/auth/auth_service.dart`
- Create: `lib/auth/auth_controller.dart`
- Create: `test/auth/auth_controller_test.dart`
- Create: `test/auth/fakes/fake_auth_service.dart`

**Interfaces:**

- `AuthSession`: signedOut, anonymous, account, offlineEmergency.
- `AuthFailure`: normalized code, message, retryability, and optional credentialConflict.
- `AuthService`: session stream plus guest, Google, email sign-in/register/link, reset, verification, logout, anonymous deletion, and ID-token operations.
- `AuthController`: immutable observable session state and guarded async commands.

**Steps:**

1. Write failing tests for restored sessions, anonymous entry, permanent accounts, busy/error cleanup, cancellation, and offline emergency entry.
2. Add failing tests for guest linking and credential conflicts that keep the anonymous session intact.
3. Add failing tests proving an existing-account switch clears nothing until it succeeds.
4. Run `flutter test test/auth/auth_controller_test.dart`; confirm failures.
5. Implement the smallest domain/controller code to satisfy the tests.
6. Run focused tests and analysis; expect pass.
7. Commit: `feat(auth): add session controller and auth contract`

### Task 3: Implement Firebase Auth, Google linking, and AI token adapters

**Files:**
- Create: `lib/auth/firebase_auth_service.dart`
- Create: `lib/auth/firebase_ai_access_token_provider.dart`
- Create: `test/auth/firebase_auth_service_test.dart`
- Create: `test/auth/firebase_ai_access_token_provider_test.dart`
- Modify: `lib/ai/ai_chat_service.dart` only if injection seams require adjustment

**Interfaces:**

- `FirebaseAuthService` maps Firebase users and exceptions to the domain contract.
- `FirebaseAiAccessTokenProvider.getToken()` returns the current refreshed Firebase ID token or null for offline-emergency/signed-out sessions.

**Steps:**

1. Write failing adapter tests using injectable Firebase/Google facades.
2. Cover anonymous sign-in, email creation/sign-in, verification, reset, logout, Google cancellation, linking, credential-already-in-use, and anonymous deletion.
3. Write failing token-provider tests for signed-in, refresh, signed-out, and provider failure behavior.
4. Run both focused test files; confirm failure.
5. Implement the adapters and normalized error mapping.
6. Run focused tests and analysis; expect pass.
7. Commit: `feat(auth): integrate firebase and google identity`

### Task 4: Replace fixed splash routing with AuthGate and deferred app initialization

**Files:**
- Create: `lib/auth/auth_gate.dart`
- Create: `test/auth/auth_gate_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app_state.dart`
- Modify: `test/app_state_test.dart` if present, otherwise create it

**Interfaces:**

- `AuthGate` maps initializing, signedOut, anonymous/account, and offlineEmergency to deterministic screens.
- `AppState.initializeOnce({required bool allowNetwork})` restores local state once; network/location work is skipped in offline-emergency mode.

**Steps:**

1. Write failing widget tests for every gate state and bootstrap failure.
2. Write failing AppState tests proving initialization is idempotent and offline mode does not request location/network refresh.
3. Run the focused tests; confirm failure.
4. Make `main` async, bootstrap Firebase, provide AuthService/AuthController, and inject the Firebase AI token provider.
5. Replace `SplashGate` timing/navigation with `AuthGate`.
6. Defer AppState initialization until a usable app session exists.
7. Run focused tests, the full Flutter suite, and analysis; expect pass.
8. Commit: `feat(auth): gate app startup by resilient session state`

### Task 5: Replace demonstration login with complete accessible auth UI

**Files:**
- Modify: `lib/login_screen.dart`
- Create: `lib/auth/email_auth_sheet.dart`
- Modify: `test/login_screen_test.dart`
- Create: `test/auth/email_auth_sheet_test.dart`

**Behavior:**

- Action order: Google, Email sign-in, Create account, Guest, disabled Facebook.
- Forgot password is available from email sign-in.
- Registration validates confirmation and sends verification.
- Emergency access offline appears when bootstrap/network state requires it.

**Steps:**

1. Replace demo expectations with failing semantic/widget tests for all actions, validation, progress, errors, cancellation, and disabled Facebook.
2. Add failing keyboard/scroll and accessibility-label coverage.
3. Run focused tests; confirm failure.
4. Implement controller-driven UI with no direct navigation to `HomeShell`.
5. Ensure verification is informative and non-blocking.
6. Run focused tests, full Flutter tests, and analysis; expect pass.
7. Commit: `feat(auth): deliver guest google and email sign in ui`

### Task 6: Add account management, verification, logout, and local erase

**Files:**
- Create: `lib/auth/account_screen.dart`
- Modify: `lib/screens.dart`
- Modify: `lib/app_state.dart`
- Modify: `lib/local_storage_service.dart`
- Create: `test/auth/account_screen_test.dart`
- Create: `test/local_data_lifecycle_test.dart`

**Interfaces:**

- `AppState.eraseAllLocalData()` clears persisted and in-memory readiness state, relevant caches/settings, then notifies listeners.
- Account screen supports guest upgrade, verification refresh/resend, permanent logout, and confirmed erase.

**Steps:**

1. Write failing lifecycle tests proving logout retains readiness data but clears AI history.
2. Write failing tests proving permanent-account erase retains authentication and returns to a clean app.
3. Write failing tests proving anonymous erase deletes the Firebase user before local reset and exposes recoverable failure.
4. Write failing tests for the logout shared-device privacy warning.
5. Add an Account and privacy entry to `ReadyScreen`.
6. Implement lifecycle orchestration without coupling AppState to Firebase.
7. Run focused tests, full tests, and analysis; expect pass.
8. Commit: `feat(auth): add account and local privacy controls`

### Task 7: Configure the real Firebase project and validate Android end-to-end

**Files:**
- Generate: `lib/firebase_options.dart`
- Generate: `android/app/google-services.json`
- Modify: `.gitignore` only if secret/local files require protection
- Modify: `backend/.env.example` only if Firebase Admin setup documentation is incomplete

**Steps:**

1. Confirm or create the Firebase project and register `com.cathan.kalasag`.
2. Obtain debug and intended release SHA-1/SHA-256 fingerprints.
3. Enable Anonymous, Google, and Email/Password providers.
4. Run `flutterfire configure` for the actual project.
5. Confirm backend Firebase Admin verification has valid production credentials without printing secrets.
6. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
7. Run backend tests from `backend`.
8. Build an Android debug APK and install it on device `102742538O013935`.
9. Smoke-test session restoration, Guest, Google, email register/sign-in/reset/verification, guest upgrade, logout retention, erase, offline emergency access, and authenticated AI.
10. Commit: `chore(auth): configure firebase android integration`

### Task 8: Final regression and security review

**Files:**
- Modify only files required by discovered regressions.

**Steps:**

1. Run `flutter analyze`.
2. Run `flutter test`.
3. Run backend tests.
4. Run `flutter build apk --debug`.
5. Confirm no Gemini key, Firebase Admin credential, or backend `.env` is tracked or embedded.
6. Inspect the final diff for unrelated changes and debug-only behavior.
7. Request a focused code/security review and fix confirmed findings.
8. Repeat all gates after fixes.
9. Commit: `test(auth): verify firebase authentication flows`
