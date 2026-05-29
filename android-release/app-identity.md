# EmpowerHealth Watch — Android app identity

## Play Store / Android application ID

| Field | Value |
|--------|--------|
| **Package name (applicationId)** | `com.empowerhealthwatch` |
| **App display name** | EmpowerHealth |
| **Firebase project** | `empower-health-watch` |
| **Version** | See root `pubspec.yaml` (`version: x.y.z+build`) |

## Where it is defined in the repo

- `android/app/build.gradle.kts` — `namespace`, `applicationId`
- `android/app/src/main/AndroidManifest.xml` — `package`
- `android/app/src/main/kotlin/com/empowerhealthwatch/MainActivity.kt`

## Previous package (do not use for new Play listings)

- `com.example.empowerhealth` — retired; was debug/placeholder only.

## Firebase (required after package change)

1. [Firebase Console](https://console.firebase.google.com/) → project **empower-health-watch**
2. **Add app** → Android → package name **`com.empowerhealthwatch`**
3. Add **SHA-1** (debug for testing; upload key SHA-1 for release — see `README.md`)
4. Download **`google-services.json`** → replace `android/app/google-services.json`
5. If using Google Sign-In: Google Cloud Console → OAuth Android client for **`com.empowerhealthwatch`** with matching SHA-1

Until step 4 is done, Firebase Auth / FCM may fail on Android builds with the new package.

## iOS (unchanged for now)

- Bundle ID is still `com.example.empowerhealth` in Xcode / `GoogleService-Info.plist`
- Align to `com.empowerhealthwatch` separately when ready for App Store
