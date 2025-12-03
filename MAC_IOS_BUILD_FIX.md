# Mac/iOS Thread 1 Error Fix Guide

## 🔍 Common Thread 1 Errors on Mac/iOS

Thread 1 errors during initialization typically indicate:
- CocoaPods issues
- Missing dependencies
- Xcode configuration problems
- Firebase iOS setup issues
- Info.plist permission issues

## ✅ Step-by-Step Fix

### Step 1: Clean iOS Build

```bash
# Navigate to project
cd /path/to/EmpowerHealth

# Clean Flutter
flutter clean

# Clean iOS build
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
cd ..
```

### Step 2: Install/Update CocoaPods

```bash
# Check if CocoaPods is installed
pod --version

# If not installed or outdated:
sudo gem install cocoapods

# Update CocoaPods repo
pod repo update
```

### Step 3: Install Pod Dependencies

```bash
cd ios
pod install
cd ..
```

**If pod install fails:**
```bash
# Try with verbose output
pod install --verbose

# Or try updating pods
pod update
```

### Step 4: Check Xcode Configuration

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **In Xcode:**
   - Select **Runner** in project navigator
   - Go to **Signing & Capabilities**
   - Ensure **Team** is selected
   - Check **Bundle Identifier** is unique

3. **Clean Build Folder:**
   - Xcode menu: **Product → Clean Build Folder** (Shift+Cmd+K)

4. **Check Deployment Target:**
   - Minimum iOS version should be 12.0 or higher

### Step 5: Fix Info.plist Permissions

Add required permissions for Firebase and file access:

```xml
<!-- Add to ios/Runner/Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to upload visit summaries</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos</string>

<key>NSDocumentPickerUsageDescription</key>
<string>We need access to documents to upload PDF visit summaries</string>

<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

### Step 6: Check Firebase iOS Configuration

1. **Verify GoogleService-Info.plist exists:**
   ```bash
   ls ios/Runner/GoogleService-Info.plist
   ```

2. **If missing:**
   - Download from Firebase Console
   - Place in `ios/Runner/` directory
   - Add to Xcode project (drag into Runner folder)

3. **Check Podfile includes Firebase:**
   ```ruby
   # ios/Podfile should have:
   pod 'Firebase/Core'
   pod 'Firebase/Auth'
   pod 'Firebase/Firestore'
   ```

### Step 7: Rebuild

```bash
# Get dependencies
flutter pub get

# Install pods
cd ios
pod install
cd ..

# Run on iOS simulator
flutter run -d ios
```

## 🔧 Specific Thread 1 Error Solutions

### Error: "Thread 1: signal SIGABRT"

**Cause:** App crash on launch, usually missing configuration

**Fix:**
1. Check `GoogleService-Info.plist` is in project
2. Verify Bundle ID matches Firebase project
3. Check Info.plist has all required keys

### Error: "Thread 1: EXC_BAD_ACCESS"

**Cause:** Memory access issue, often from native plugins

**Fix:**
```bash
# Reinstall pods
cd ios
pod deintegrate
pod install
cd ..
```

### Error: "Thread 1: dyld: Library not loaded"

**Cause:** Missing or incompatible framework

**Fix:**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Error: "Thread 1: Fatal error: Unexpectedly found nil"

**Cause:** Firebase not initialized properly

**Fix:**
1. Check `main.dart` initializes Firebase:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

2. Verify `GoogleService-Info.plist` is correct

## 📱 iOS Simulator Issues

### If Simulator Won't Start:

```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
open -a Simulator

# Or use specific device
flutter run -d "iPhone 15 Pro"
```

### If Build Fails on Simulator:

1. **Reset Simulator:**
   - Simulator menu: **Device → Erase All Content and Settings**

2. **Check Architecture:**
   ```bash
   # Use x86_64 for Intel Macs
   # Use arm64 for Apple Silicon Macs
   flutter run -d ios --release
   ```

## 🍎 Apple Silicon (M1/M2/M3) Specific Fixes

If you have Apple Silicon Mac:

```bash
# Install Rosetta (if needed)
softwareupdate --install-rosetta

# Use arch command for Intel pods
arch -x86_64 pod install

# Or use native arm64
pod install
```

## 🔐 Code Signing Issues

### Error: "No signing certificate found"

**Fix:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select **Runner** → **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your **Team**
5. Xcode will create certificates automatically

### Error: "Provisioning profile not found"

**Fix:**
1. In Xcode: **Preferences → Accounts**
2. Add your Apple ID
3. Download profiles: **Download Manual Profiles**
4. Select in **Signing & Capabilities**

## 📋 Complete Fix Checklist

Run these commands in order:

```bash
# 1. Clean everything
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
cd ..

# 2. Get Flutter dependencies
flutter pub get

# 3. Update CocoaPods
pod repo update

# 4. Install pods
cd ios
pod install
cd ..

# 5. Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 6. Open in Xcode and clean
open ios/Runner.xcworkspace
# Then: Product → Clean Build Folder (Shift+Cmd+K)

# 7. Run Flutter
flutter run -d ios
```

## 🚨 Quick Emergency Fix

If nothing works, try this nuclear option:

```bash
# Complete reset
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter pub get
cd ios && pod deintegrate && pod install && cd ..
flutter run -d ios
```

## 📝 Common Issues & Solutions

### Issue: "CocoaPods not installed"
```bash
sudo gem install cocoapods
```

### Issue: "Permission denied for pod install"
```bash
sudo chown -R $(whoami) ~/Library/Caches/CocoaPods
sudo chown -R $(whoami) ~/.cocoapods
```

### Issue: "Firebase not found"
```bash
# Check Podfile has Firebase
# Then:
cd ios
pod install
cd ..
```

### Issue: "GoogleService-Info.plist not found"
- Download from Firebase Console
- Place in `ios/Runner/`
- Add to Xcode project

## 🎯 Most Common Fix

**90% of Thread 1 errors are fixed by:**

```bash
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter run -d ios
```

## 📞 Still Having Issues?

Check the exact error message:
1. **Copy full error from Xcode console**
2. **Check which thread/function is failing**
3. **Look for missing framework/library**

Common patterns:
- `dyld` errors → Missing framework
- `SIGABRT` → Configuration issue
- `EXC_BAD_ACCESS` → Memory issue
- `nil` errors → Firebase not initialized

---

**Run these commands on your Mac and share the specific error message if issues persist!**

