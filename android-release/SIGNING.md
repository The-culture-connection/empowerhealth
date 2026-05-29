# Signing credentials (local only — gitignored)

**Back up these files securely** (password manager + offline copy). You cannot update the app on Play Store without them.

| Item | Value |
|------|--------|
| Keystore file | `android-release/keystore/upload-keystore.jks` |
| Key alias | `upload` |
| Store password | *(in `keystore.properties` — not committed)* |
| Key password | *(same as store password unless you set otherwise)* |

## SHA-1 fingerprints

Add both to Firebase → Android app `com.empowerhealthwatch` → Project settings → SHA certificate fingerprints.

### Debug (local `flutter run`)

```
EB:DE:9E:CC:09:53:D1:41:98:64:C0:95:AC:01:B0:92:EA:47:C1:12
```

Regenerate: `cd android && .\gradlew signingReport` → Variant **debug**

### Release (upload keystore)

```
B8:07:B5:10:3E:47:7C:D8:F8:0E:F8:7F:FF:BB:1B:61:A3:DD:52:C1
```

Regenerate after new keystore:

```powershell
keytool -list -v -keystore android-release\keystore\upload-keystore.jks -alias upload
```

### Play App Signing (after first upload)

Play Console → **Setup** → **App integrity** → copy **App signing key certificate** SHA-1 into Firebase as well.

## Regenerate keystore (only if lost — Play Store cannot accept new key for same app)

```powershell
.\android-release\scripts\create-keystore.ps1
```
