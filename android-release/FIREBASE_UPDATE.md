# Firebase — Android app `com.empowerhealthwatch`

Project: **empower-health-watch**

## Current status

- `android/app/google-services.json` includes **`com.empowerhealthwatch`** (primary app entry).
- Legacy **`com.example.empowerhealth`** entry may still appear in the same file; release builds use `com.empowerhealthwatch` only.

## SHA-1 fingerprints to register

Firebase Console → Project settings → Your apps → Android **`com.empowerhealthwatch`** → **Add fingerprint**

| Key | SHA-1 |
|-----|-------|
| Debug (local dev) | `EB:DE:9E:CC:09:53:D1:41:98:64:C0:95:AC:01:B0:92:EA:47:C1:12` |
| Release (upload keystore) | `B8:07:B5:10:3E:47:7C:D8:F8:0E:F8:7F:FF:BB:1B:61:A3:DD:52:C1` |
| Play App Signing | *(add after first Play Console upload — see SIGNING.md)* |

After adding fingerprints, re-download `google-services.json` if Firebase prompts you, replace `android/app/google-services.json`, then rebuild.

## If Firebase auth / Google Sign-In fails on release builds

1. Confirm **release SHA-1** above is registered.
2. After Play upload, add **App signing key certificate** SHA-1 from Play Console → Setup → App integrity.
3. Do **not** only find-replace package names in JSON — OAuth client IDs are tied to the Firebase app registration.
