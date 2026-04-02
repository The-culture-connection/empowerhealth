# iOS Build Fix - Phase Script Execution Failed

## Problem
The `Generated.xcconfig` and `flutter_export_environment.sh` files contain Windows paths but you're building on Mac. These need to be regenerated with Mac paths.

## Solution

### Step 1: Clean Flutter Build Files
```bash
cd ios
rm -rf Flutter/Generated.xcconfig
rm -rf Flutter/flutter_export_environment.sh
rm -rf Flutter/ephemeral
cd ..
flutter clean
```

### Step 2: Regenerate Flutter Files (on Mac)
```bash
flutter pub get
```

This will regenerate the files with correct Mac paths.

### Step 3: Update CocoaPods
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Step 4: Clean Xcode Build
In Xcode:
1. Product → Clean Build Folder (Shift+Cmd+K)
2. Close Xcode
3. Delete `ios/DerivedData` if it exists

### Step 5: Rebuild
```bash
flutter build ios
```

Or build from Xcode:
1. Open `ios/Runner.xcworkspace` (NOT .xcodeproj)
2. Select your device
3. Product → Build (Cmd+B)

## Common Issues

### If pods fail to install:
```bash
cd ios
pod repo update
pod install --repo-update
```

### If FLUTTER_ROOT is still wrong:
1. Check your Flutter installation path on Mac
2. Verify it's in your PATH: `which flutter`
3. The Generated.xcconfig should auto-detect it

### If code signing fails:
1. Open Xcode → Runner target → Signing & Capabilities
2. Select your development team
3. Ensure "Automatically manage signing" is checked
