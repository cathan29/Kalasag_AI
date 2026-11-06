# Kalasag Documentation Hub

Last verified: 2026-11-06

Kalasag is an Android-focused disaster-readiness application. This vault records verified behavior, incomplete requirements, tests, and engineering decisions. A screen existing is not treated as proof that its feature works.

## Notes

- [[01 - Project Overview and Proposal Requirements]]
- [[02 - Current Development Status and Remaining Tasks]]
- [[03 - Architecture and Folder Structure]]
- [[04 - Features and User Flows]]
- [[05 - Backend APIs Offline and Data Design]]
- [[06 - UI UX Security and Privacy]]
- [[07 - Testing Android Setup and Known Issues]]
- [[08 - Bugs Fixes and Change Log]]
- [[09 - Final Project Completion Report]]
- [[10 - GitHub and Android Development Environment]]
- [[11 - Gemini AI Assistant]]
- [[12 - UI UX Audit and Redesign]]
- [[13 - Philippine Disaster Alerts Overhaul]]

## Latest verified update

- **Gemini AI Assistant Fully Configured & Live-Verified (2026-11-07)**:
  - Gemini proxy running locally on port 8787 with `gemini-3.5-flash-lite` credentials.
  - Flutter client updated with smart local defaults (`http://127.0.0.1:8787`), emulator and LAN fallback (`10.0.2.2`, `192.168.100.32`), and `FirebaseAiAccessTokenProvider`.
  - Assistant bottom sheet transitioned from `Setup required` to `Secure connection ready` (green indicator).
  - Physical Android phone (Infinix X6833B) mapped via `adb reverse tcp:8787 tcp:8787`.
  - Live query in Filipino verified (`POST /v1/chat`): returned NDRRMC/PHIVOLCS-aligned Drop-Cover-Hold guidance and signed interaction context.
- **Authentication & UI Consistency**:
  - Standardized authentication layouts with shared AuthLayout: Login and Sign Up
    share identical stationary header height, identical dark navy panel start
    position, and identical owl mascot placement.
  - Cleaned and harmonized kalasag-ready-transparent.png: removed 65,765 background
    noise pixels, balanced ambient blue lighting, and added a soft contact shadow.
  - Restored permanent guest account access and official 4-color Google logo.
  - Full test suite: 39/39 Flutter tests passed, 8/8 backend tests passed, 0 analyze issues.

## Status legend

- PASS: verified by an executed test or inspection with adequate evidence.
- FAIL: executed and did not satisfy its acceptance criteria.
- BLOCKED: requires unavailable hardware, credentials, service, or environment access.
- NOT RUN: not yet exercised.
