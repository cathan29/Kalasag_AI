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

- Firebase Android configuration is installed locally for `com.cathan.kalasag`.
- Google sign-in, anonymous guest access, and email signup with verification
  link are wired into the responsive login UI.
- Debug build and full Flutter tests pass; the build was installed on the
  authorized Infinix X6833B.
- Auth/login changes are pushed to GitHub `main` in commit `54746b3`.
- Firebase Console provider enablement and SHA fingerprint setup remain
  required before claiming end-to-end auth success.

## Status legend

- PASS: verified by an executed test or inspection with adequate evidence.
- FAIL: executed and did not satisfy its acceptance criteria.
- BLOCKED: requires unavailable hardware, credentials, service, or environment access.
- NOT RUN: not yet exercised.
