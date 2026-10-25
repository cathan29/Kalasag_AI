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
- The Gemini key is read only by the Node backend from server environment variables.
- Production AI calls require verified Firebase ID tokens; unauthenticated development mode is rejected when `NODE_ENV=production`.
- The AI endpoint uses Helmet, a 16 KB request limit, per-client rate limiting, a provider timeout, bounded output, signed user-bound context, and sanitized errors.
- AI prompt/response content is not logged or stored by the proxy. Local chat history can be cleared from the sheet.
- The assistant is labeled as a support tool and is instructed not to invent live conditions, locations, citations, phone numbers, or emergency centers.
- Contact and readiness data stays in local Hive storage but is not application-level encrypted.
- The demo login does not authenticate or protect stored data.
- Location is requested for local weather, radar context, and shelters.
- Camera permission is requested only when the flashlight is used.
- Calls open in the dialer and are not placed silently.
- Production release signing is not configured; release currently references debug signing.

Before production, add a privacy notice, finish real Firebase authentication, deploy the proxy with managed secrets and HTTPS, complete live safety evaluations, add remote-data retention/deletion controls, and configure production signing.

