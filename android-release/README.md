# Android release & Play Store upload

Repeatable checklist for **EmpowerHealth Watch** (`com.empowerhealthwatch`).

| Doc | Purpose |
|-----|---------|
| [app-identity.md](./app-identity.md) | Package name, Firebase project |
| [SIGNING.md](./SIGNING.md) | SHA-1 fingerprints, keystore backup |
| [RELEASES.md](./RELEASES.md) | Log each upload (version, date, track) |
| [FIREBASE_UPDATE.md](./FIREBASE_UPDATE.md) | Firebase `google-services.json` |

---

## Quick start (repeat every release)

```powershell
# From repo root — first time only creates keystore + keystore.properties (gitignored)
.\android-release\scripts\build-release.ps1
```

1. Bump `version:` in **`pubspec.yaml`** (e.g. `1.0.1+20`)
2. Run **`build-release.ps1`**
3. Upload **`android-release/builds/empowerhealthwatch-x.y.z+N.aab`** to Play Console
4. Add a row to **`RELEASES.md`**

---

## One-time setup

### 1. Firebase

- Android app **`com.empowerhealthwatch`** registered
- Debug + **release** SHA-1 in Firebase (see SIGNING.md)
- `android/app/google-services.json` downloaded from Firebase

### 2. Upload keystore

```powershell
.\android-release\scripts\create-keystore.ps1
```

**Back up** `android-release/keystore/upload-keystore.jks` and `keystore.properties` securely.

### 3. Play Console

- Create app with application ID **`com.empowerhealthwatch`**
- Enable Play App Signing on first upload

---

## Manual build (if you prefer)

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
# Output: build\app\outputs\bundle\release\app-release.aab
# Copy to android-release/builds/ with versioned name (build-release.ps1 does this automatically)
```

### Troubleshooting

- **`null cannot be cast to non-null type kotlin.String`** in `build.gradle.kts`: usually `keystore.properties` is missing or passwords were truncated (Java treats `#` as a comment). Regenerate with `create-keystore.ps1` (passwords exclude `#`) or escape `#` as `\#`.
- **Firebase / Google Sign-In on release**: add release SHA-1 (and later Play App Signing SHA-1) — see [FIREBASE_UPDATE.md](./FIREBASE_UPDATE.md).

---

## Folder layout

```
android-release/
├── README.md
├── app-identity.md
├── SIGNING.md
├── RELEASES.md
├── FIREBASE_UPDATE.md
├── keystore.properties.example
├── scripts/
│   ├── create-keystore.ps1
│   └── build-release.ps1
├── keystore/          ← gitignored
├── keystore.properties ← gitignored
└── builds/            ← gitignored (archived AABs)
```
