# Environment Setup Guide

## Quick Start

1. **Copy the template file:**
   ```bash
   cp env.template .env.local
   ```

2. **Fill in your Firebase credentials:**
   - Open `.env.local` in a text editor
   - Replace all placeholder values with your actual Firebase project credentials

## Where to Get Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)
3. Click the gear icon ⚙️ next to "Project Overview"
4. Select **Project Settings**
5. Scroll down to the **"Your apps"** section
6. Click on your web app (or click **"Add app"** > **Web icon** `</>` to create one)
7. You'll see a `firebaseConfig` object that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef...",
  measurementId: "G-XXXXXXXXXX"
};
```

8. Copy each value to the corresponding variable in `.env.local`:

| Firebase Config | .env.local Variable |
|----------------|---------------------|
| `apiKey` | `VITE_FIREBASE_API_KEY` |
| `authDomain` | `VITE_FIREBASE_AUTH_DOMAIN` |
| `projectId` | `VITE_FIREBASE_PROJECT_ID` |
| `storageBucket` | `VITE_FIREBASE_STORAGE_BUCKET` |
| `messagingSenderId` | `VITE_FIREBASE_MESSAGING_SENDER_ID` |
| `appId` | `VITE_FIREBASE_APP_ID` |
| `measurementId` | `VITE_FIREBASE_MEASUREMENT_ID` |

## Cloud Functions URL

The `VITE_FUNCTIONS_URL` is optional. If you leave it empty, the app will try to auto-detect it.

To find your Functions URL:
1. Go to Firebase Console > Functions
2. Look at the URL of any deployed function
3. It will be in the format: `https://REGION-PROJECT-ID.cloudfunctions.net`
4. Copy the base URL (without the function name)

Example:
- Function URL: `https://us-central1-my-project.cloudfunctions.net/uploadBuildVersion`
- Base URL: `https://us-central1-my-project.cloudfunctions.net`

## Example .env.local File

```env
VITE_FIREBASE_API_KEY=AIzaSyExample1234567890abcdefghijklmnop
VITE_FIREBASE_AUTH_DOMAIN=my-empowerhealth-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=my-empowerhealth-project
VITE_FIREBASE_STORAGE_BUCKET=my-empowerhealth-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789012
VITE_FIREBASE_APP_ID=1:123456789012:web:abcdef1234567890
VITE_FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX
VITE_FUNCTIONS_URL=https://us-central1-my-empowerhealth-project.cloudfunctions.net
```

## Important Notes

- ⚠️ **Never commit `.env.local` to git** - it contains sensitive credentials
- ✅ The `.gitignore` file already excludes `.env.local`
- 🔄 Restart your dev server after changing `.env.local`
- 📝 Use `.env.production` for production builds (similar format)

## Troubleshooting

**Error: "Missing required Firebase environment variables"**
- Make sure `.env.local` exists in the `admindash/` directory
- Check that all variables start with `VITE_`
- Verify no typos in variable names
- Restart the dev server after creating/editing `.env.local`

**Error: "Firebase initialization error"**
- Double-check your credentials are correct
- Make sure your Firebase project has the required services enabled:
  - Authentication
  - Firestore
  - Storage
  - Functions
