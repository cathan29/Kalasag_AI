# KALASAG Firebase Authentication Design

## Objective

Replace the demonstration login with Firebase Authentication while preserving KALASAG's offline-first emergency features and device-local readiness data.

## Approved Scope

- Firebase Anonymous Authentication for Continue as Guest.
- Google Sign-In as the primary account option.
- Email/password registration and sign-in, email verification, and password reset.
- Persistent native sessions and logout.
- Guest upgrades through Firebase credential linking.
- Firebase ID tokens for the existing Gemini proxy.
- Facebook displayed as disabled and marked Coming soon.
- Logout retains readiness data but clears local AI conversation history.
- A separate confirmed action erases all local data.

Remote synchronization of readiness data is out of scope.

## Product Rules

Authentication and email verification never block SOS, emergency guidance, local alerts, or offline emergency features. An unverified email account receives a visible, non-blocking reminder with resend and refresh actions.

When Firebase is unavailable or unconfigured, the authentication screen offers Emergency access offline. This local-only session opens the existing app shell but limits the user to cached/local SOS, emergency contacts, preparedness guides, family plan, go-bag, and other device-resident features. Google, email, AI, and network-dependent data clearly remain unavailable. Returning online does not silently create an account; the user must choose Guest, Google, or Email.

Guest entry creates or resumes a Firebase anonymous session. The account screen emphasizes upgrading the guest account. Google and email upgrades link credentials to retain the Firebase UID. A normal logout action is not shown to anonymous users because signing out can orphan that temporary account.

If an upgrade credential already belongs to another Firebase account, the app explains the conflict before signing into the existing account. Device-local readiness data remains available because it is not account-scoped; the app must not claim that the anonymous Firebase identity was preserved in this conflict case.

Logging out a permanent account signs out Firebase and Google, clears local AI conversation history, retains readiness data, and returns to authentication. The confirmation explains that readiness data is shared on this device and offers erase instead for privacy.

Erase all local data is separately confirmed and clears readiness state, relevant caches/settings, and AI history. A permanent account remains signed in and returns to a clean app shell. For an anonymous session, the app first deletes the Firebase anonymous user while online, then clears local data and returns to authentication. If account deletion fails, the app reports the failure and does not pretend the identity was removed; local erasure remains a separately confirmable recovery choice.

During a credential conflict, the current anonymous session remains active while the user reviews the warning. The app attempts the switch only after confirmation. AI history is cleared only after sign-in to the existing account succeeds. A failed switch leaves the anonymous session and local data intact and retryable.

## Architecture

Introduce an `AuthService` interface so Firebase SDK calls are isolated from UI and replaceable by a deterministic fake in tests. `FirebaseAuthService` owns Firebase Auth and Google Sign-In integration, error normalization, credential linking, verification, password reset, token retrieval, and logout.

An `AuthController` using ChangeNotifier exposes initializing, signed-out, anonymous, authenticated, and offline-emergency states plus operation progress and user-facing errors. It listens to Firebase auth-state changes and provides guest, Google, email, verification, reset, linking, logout, and explicit offline-emergency operations.

Replace the fixed splash-to-login transition with `AuthGate`: initialization shows a branded loader, signed-out shows authentication, and a guest/account session shows `HomeShell`. Local `AppState` initializes once after a usable session exists, avoiding location permission prompts before entry choice.

Add a Firebase implementation of `AiAccessTokenProvider` that retrieves the current Firebase ID token. The Gemini API key remains only in the backend environment. Anonymous users also receive Firebase ID tokens.

Add an account surface reachable from the main app. It shows session and verification status, supports guest upgrade, permanent-account logout, and explicit local-data erasure.

## UI Flow

The KALASAG authentication screen presents:

1. Continue with Google.
2. Sign in with email.
3. Create an account.
4. Continue as Guest.
5. Facebook, disabled with a Coming soon label.

Email flows use focused, keyboard-safe forms with inline validation, accessible labels, progress states, and normalized Firebase errors. Registration sends verification and enters the app without blocking emergency functionality.

## Platform Setup

Implementation is Android-first while keeping Dart abstractions portable. Firebase configuration must be generated for the real Firebase project:

- register Android package `com.cathan.kalasag`;
- add debug/release SHA-1 and SHA-256 fingerprints for Google Sign-In;
- enable Anonymous, Google, and Email/Password providers;
- run FlutterFire configuration to generate platform files and `lib/firebase_options.dart`;
- never commit backend `.env` or embed the Gemini key in Flutter.

## Error Handling

Normalize invalid credentials, account conflicts, weak passwords, disabled providers, cancelled Google flows, network failures, rate limits, and anonymous-auth quotas. Cancellation is non-fatal. Every operation must release its busy state and remain retryable.

Missing Firebase configuration produces a controlled setup state instead of a crash, with offline emergency entry offered where feasible.

## Testing

- Unit-test `AuthController` with a fake service.
- Widget-test `AuthGate`, all auth actions, and disabled Facebook.
- Verify email verification is non-blocking.
- Verify logout clears AI history but retains readiness data.
- Verify erase-all independently.
- Test Firebase-backed AI token retrieval through injection.
- Keep existing Flutter and backend tests passing.
- Run analysis, Flutter tests, backend tests, Android build, and device smoke testing.

## Out of Scope

- Facebook authentication.
- Readiness-data cloud sync.
- Role-based accounts or social profiles.
- Gemini fine-tuning.
