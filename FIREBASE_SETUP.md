# Firebase Setup Guide for EmpowerHealth

This guide will help you configure Firebase for your EmpowerHealth app.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select your existing project
3. Follow the setup wizard to create your project

## Step 2: Add Android App to Firebase

1. In the Firebase Console, click the Android icon to add an Android app
2. Enter your Android package name: `com.example.empowerhealth`
3. Download the `google-services.json` file
4. Place it in: `android/app/google-services.json`

### Update Android build files:

**android/build.gradle.kts** (project level):
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**android/app/build.gradle.kts**:
Add at the bottom of the file:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## Step 3: Add iOS App to Firebase

1. In the Firebase Console, click the iOS icon to add an iOS app
2. Enter your iOS bundle ID: `com.example.empowerhealth`
3. Download the `GoogleService-Info.plist` file
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### Update iOS configuration:

Open `ios/Runner.xcworkspace` in Xcode and drag the `GoogleService-Info.plist` file into the Runner folder.

## Step 4: Update Firebase Configuration

Open `lib/services/firebase_service.dart` and replace the placeholder values with your Firebase configuration:

```dart
static FirebaseOptions _getFirebaseOptions() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return const FirebaseOptions(
      apiKey: 'YOUR_ANDROID_API_KEY',           // From google-services.json
      appId: 'YOUR_ANDROID_APP_ID',             // From google-services.json
      messagingSenderId: 'YOUR_SENDER_ID',      // From google-services.json
      projectId: 'YOUR_PROJECT_ID',             // From google-services.json
      storageBucket: 'YOUR_STORAGE_BUCKET',     // From google-services.json
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const FirebaseOptions(
      apiKey: 'YOUR_IOS_API_KEY',               // From GoogleService-Info.plist
      appId: 'YOUR_IOS_APP_ID',                 // From GoogleService-Info.plist
      messagingSenderId: 'YOUR_SENDER_ID',      // From GoogleService-Info.plist
      projectId: 'YOUR_PROJECT_ID',             // From GoogleService-Info.plist
      storageBucket: 'YOUR_STORAGE_BUCKET',     // From GoogleService-Info.plist
      iosBundleId: 'com.example.empowerhealth',
    );
  }
}
```

## Step 5: Enable Firebase Services

In the Firebase Console:

1. **Authentication:**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password" provider

2. **Firestore Database:**
   - Go to Firestore Database
   - Click "Create database"
   - Start in test mode (for development)
   - Choose your location

### Firestore Security Rules (for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only read and write their own profile
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Fix Gradle Memory Issue

Since you encountered a Gradle memory error, create or update `android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true
```

## Step 7: Install Dependencies

Run the following command to install all dependencies:

```bash
flutter pub get
```

## Step 8: Run the App

```bash
flutter run
```

## Troubleshooting

### "JAVA_HOME is set to an invalid directory"
- Ensure JAVA_HOME points to: `C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot`
- Restart your terminal/IDE after setting the environment variable

### "Gradle daemon failed"
- Reduce memory in `gradle.properties` as shown above
- Clean build: `flutter clean && flutter pub get`

### Firebase initialization errors
- Double-check all configuration values
- Ensure `google-services.json` and `GoogleService-Info.plist` are in the correct locations
- Make sure you've enabled Authentication and Firestore in Firebase Console

## Database Structure

The app uses the following Firestore structure:

```
users/
  {userId}/
    - name
    - age
    - isPregnant
    - dueDate
    - isPostpartum
    - childAgeMonths
    - zipCode
    - insuranceType
    - raceEthnicity
    - languagePreference
    - maritalStatus
    - educationLevel
    - pregnancyStage
    - chronicConditions []
    - medications []
    - allergies []
    - hasDoula
    - hasPartner
    - hasSupportPerson
    - hasPrimaryProvider
    - hasTransportation
    - needsChildcare
    - enrolledInWIC
    - hasMentalHealthSupport
    - hasAccessToFood
    - hasStableHousing
    - providerPreferences []
    - birthPreference
    - interestedInBreastfeeding
    - healthLiteracyGoals []
    - createdAt
    - updatedAt
```

## Next Steps

After Firebase is configured:

1. Test the sign-up flow
2. Complete the profile creation
3. Verify data is saved to Firestore
4. Update security rules for production
5. Consider adding additional Firebase services (Storage, Cloud Functions, etc.)

## Support

For more information:
- [Flutter Firebase Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)






