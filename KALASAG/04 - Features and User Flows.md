# Features and User Flows

## Authentication flow

Current flow is a clearly labeled demonstration. It validates email shape and minimum password length, waits briefly, then enters the app. It does not prove identity and does not persist a session. Registration, password recovery, profile editing, and logout are not implemented.

## Emergency contacts and SOS flow

Users open SOS, choose My contacts, then add a name, phone number, and optional relationship. Numbers are normalized to a dialable form, constrained to 7 through 15 digits, checked for duplicates, and saved locally. Users can view, edit, or delete each contact. Tapping a contact shows a confirmation; confirmation opens the native dialer and never places the call automatically.

Users can also open Safety tools. The flashlight requests Android camera permission when first needed, reports unavailable hardware or denial, and turns off when the screen or app is left. The whistle plays a repeating device alert tone until stopped and is also released on exit. Neither tool contacts emergency services.

## Offline functionality

Bundled preparedness guides and hotlines load from assets. Hive persists saved places, go-bag state, family plan, alert preferences, and emergency contacts. The Ready tab also opens an offline safety guide with earthquake, flood, typhoon, fire, evacuation, and basic first-aid responses. It escalates urgent phrases toward emergency services and is explicitly labeled as bundled, non-live, non-official guidance.

Live weather, live alert providers, shelter search, radar, directions, and a future online AI assistant require network access. No private AI key is embedded in Flutter.

## Implemented screens

- Weather dashboard and forecast
- Alert list, filters, details, and settings
- Embedded weather radar
- Readiness guides, go-bag, family plan, and shelter search
- Verified hotline directory and first-aid guidance
- Custom emergency contacts
- Flashlight and emergency alert sound
- Offline safety guide with quick prompts and urgent escalation

