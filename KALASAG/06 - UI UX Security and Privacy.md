# UI UX Security and Privacy

## Design system

The app uses Material 3, a shared light and dark theme, card-based layouts, consistent navigation, and clear status/error surfaces. Safety actions are separated from informational content. New contact forms use validation and the native dialer flow preserves user control.

## Accessibility and usability checks still required

- Small Android screens
- Large system font sizes
- TalkBack labels and reading order
- Color contrast in both themes
- Keyboard and bottom-sheet behavior
- Touch targets and one-handed emergency use

## Security and privacy

- No private API key was found in the audited Flutter configuration.
- Contact and readiness data stays in local Hive storage but is not application-level encrypted.
- The demo login does not authenticate or protect stored data.
- Location is requested for local weather, radar context, and shelters.
- Camera permission is requested only when the flashlight is used.
- Calls open in the dialer and are not placed silently.
- Production release signing is not configured; release currently references debug signing.

Before production, add a privacy notice, retention/deletion controls, authenticated user scoping, secure server-side secrets, dependency review, and production signing.

