# Fix Google Sign-In Error Code 10 (DEVELOPER_ERROR)

Error code 10 means the OAuth client is not properly configured in Firebase Console. Follow these steps:

## Step 1: Get Your SHA-1 Fingerprint

### Option A: Using Android Studio
1. Open Android Studio
2. Go to **Build** → **Generate Signed Bundle / APK**
3. Select **Android App Bundle** or **APK**
4. Click **Next**
5. Use the debug keystore (usually located at `~/.android/debug.keystore` on Mac/Linux or `C:\Users\YourUsername\.android\debug.keystore` on Windows)
6. Default password is `android`
7. Click **Next** and you'll see the SHA-1 fingerprint

### Option B: Using Command Line (Windows PowerShell)
```powershell
cd android
.\gradlew signingReport
```

### Option C: Using Keytool directly
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Look for the line that says `SHA1:` and copy that value.

## Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **empower-health-watch**
3. Click the ⚙️ gear icon → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app (package: `com.example.empowerhealth`)
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

**IMPORTANT:** After adding the SHA-1:
- Download the **updated** `google-services.json` file
- Replace the existing one at `android/app/google-services.json`

## Step 3: Verify OAuth Client Configuration

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Make sure **Google** is enabled
3. Click on **Google** to see the configuration
4. Ensure **Support email** is set

## Step 4: Check Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **empower-health-watch**
3. Go to **APIs & Services** → **Credentials**
4. Look for **OAuth 2.0 Client IDs**
5. You should see an Android client with package name `com.example.empowerhealth`
6. If it's missing, Firebase should create it automatically after you add the SHA-1

## Step 5: Update google-services.json

After adding SHA-1, the `google-services.json` file should have an `oauth_client` array with entries. It should look like this:

```json
"oauth_client": [
  {
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.empowerhealth",
      "certificate_hash": "YOUR_SHA1_HASH"
    }
  },
  {
    "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

## Step 6: Optional - Add Web Client ID to Code

If you want to be explicit, you can add the web client ID to your Google Sign-In configuration. First, get the web client ID from Firebase Console:

1. Firebase Console → **Authentication** → **Sign-in method** → **Google** → **Web SDK configuration**
2. Copy the **Web client ID**

Then update `lib/services/auth_service.dart`:

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Add this
);
```

However, this is usually **not necessary** if the google-services.json is properly configured.

## Step 7: Clean and Rebuild

After updating google-services.json:

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## Troubleshooting

- **Still getting error 10?** Make sure you downloaded the NEW google-services.json after adding SHA-1
- **Error persists?** Try uninstalling the app completely and reinstalling
- **SHA-1 not showing up?** Make sure you're using the correct keystore (debug vs release)
- **Multiple SHA-1s?** Add both debug and release SHA-1 fingerprints to Firebase

## For Release Builds

Remember to add your **release** keystore SHA-1 as well when you're ready to publish!

