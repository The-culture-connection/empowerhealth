# Fix Google Sign-In Error Code 10 - Step 2

You've updated `google-services.json`, but you're still getting error 10. This usually means the app needs to be completely rebuilt. Follow these steps:

## Step 1: Completely Uninstall the App

**IMPORTANT:** You must uninstall the app completely, not just stop it.

1. On your Android device/emulator:
   - Go to Settings → Apps → EmpowerHealth
   - Tap **Uninstall**
   - OR long-press the app icon → Uninstall

## Step 2: Clean Build

Run these commands in order:

```bash
# From project root
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

## Step 3: Verify google-services.json Location

Make sure `google-services.json` is in the correct location:
- ✅ `android/app/google-services.json`
- ❌ NOT in `android/google-services.json`

## Step 4: Verify SHA-1 Matches

The SHA-1 in your `google-services.json` is: `36ccd5b6c8d4b009101eb52655daa7b0d8f39e8e`

Verify this matches what's in Firebase Console:
1. Go to Firebase Console → Project Settings → Your apps
2. Check the SHA-1 fingerprint listed there
3. If it doesn't match, you need to:
   - Get the correct SHA-1 from your keystore
   - Add it to Firebase
   - Download a new google-services.json

## Step 5: Rebuild and Install

```bash
flutter run
```

**OR** if using Android Studio:
1. Build → Clean Project
2. Build → Rebuild Project
3. Run the app

## Step 6: Test Again

After the app is freshly installed, try Google Sign-In again.

## Still Not Working?

### Check 1: Verify Package Name
- Your package name: `com.example.empowerhealth`
- Make sure this EXACTLY matches in:
  - `android/app/build.gradle.kts` (applicationId)
  - `android/app/src/main/AndroidManifest.xml` (package)
  - Firebase Console (Android app package name)

### Check 2: Verify OAuth Client in Firebase
1. Go to Firebase Console → Authentication → Sign-in method
2. Make sure **Google** is **Enabled**
3. Click on **Google** to see configuration
4. Check that **Support email** is set

### Check 3: Check Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **empower-health-watch**
3. Go to **APIs & Services** → **Credentials**
4. Look for OAuth 2.0 Client IDs
5. You should see:
   - An Android client with package `com.example.empowerhealth`
   - A Web client

### Check 4: Try Adding Web Client ID Explicitly

The code has been updated to explicitly use the web client ID. If it still doesn't work, the issue might be:
- SHA-1 mismatch
- Package name mismatch
- App not fully uninstalled/reinstalled

## Alternative: Get Fresh SHA-1

If you're unsure about the SHA-1:

**For Debug builds:**
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**For Release builds (if you have a release keystore):**
```bash
keytool -list -v -keystore "path/to/your/release.keystore" -alias your_alias
```

Then add ALL SHA-1 fingerprints (debug + release) to Firebase Console.

## Last Resort: Check Logs

If still failing, check the full error in logcat:
```bash
adb logcat | grep -i "google\|oauth\|sign"
```

Look for more specific error messages that might indicate what's wrong.

