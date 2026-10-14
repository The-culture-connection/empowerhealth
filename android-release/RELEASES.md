# Release history

Log each Play Store upload here. Copy a row from the template for every release.

| Date | Version (pubspec) | versionName | versionCode | AAB filename | Play track | Notes |
|------|-------------------|-------------|-------------|--------------|------------|-------|
| 2026-05-21 | 1.0.0+19 | 1.0.0 | 19 | empowerhealthwatch-1.0.0+19.aab | internal | First release build; package `com.empowerhealthwatch` |

## Template (copy for next release)

```
| YYYY-MM-DD | x.y.z+N | x.y.z | N | empowerhealthwatch-x.y.z+N.aab | internal/production | |
```

**Rules**
- Bump `version:` in root `pubspec.yaml` before each upload (`1.0.1+20` = name 1.0.1, code 20).
- versionCode must always increase on Play Console.
- Archive AAB under `android-release/builds/`.
