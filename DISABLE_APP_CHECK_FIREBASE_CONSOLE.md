# Disable App Check Enforcement in Firebase Console

## Step-by-Step Instructions

### 1. Go to Firebase Console
Navigate to: https://console.firebase.google.com/project/empower-health-watch/appcheck

### 2. Click on "APIs" Tab
Look for the "APIs" tab at the top of the App Check page.

### 3. Find "Cloud Functions"
In the list of APIs, find **"Cloud Functions"** (or "Cloud Functions (Callable)").

### 4. Disable Enforcement
- Click on the **"Cloud Functions"** row
- You should see an enforcement toggle or dropdown
- Set it to **"Unenforced"** or toggle it **OFF**
- Click **"Save"** or confirm the change

### 5. Verify
- The status should show "Unenforced" for Cloud Functions
- Wait 1-2 minutes for changes to propagate

### 6. Test
After disabling:
1. Open your Flutter app
2. Perform some actions that trigger analytics
3. Check Firestore → `analytics_events` collection
4. You should see events appearing

## Alternative: Disable for All APIs (If Needed)

If you want to disable App Check completely:

1. Go to App Check → **Settings**
2. Find **"Enforcement"** section
3. Disable enforcement for all APIs
4. Save

## Important Notes

- **App Check enforcement is a Firebase Console setting**, not in the code
- The Cloud Function code only requires **authentication** (user UID), not App Check
- Disabling enforcement allows requests through even if App Check tokens are invalid
- This is safe for development/testing
- For production, you should properly configure App Check instead of disabling it

## Verification

After disabling, check your app logs. You should see:
- `✅ Analytics: Event "session_started" logged successfully`
- Instead of: `⚠️ Analytics: Event failed - likely App Check issue`

And in Firestore:
- Documents appearing in `analytics_events` collection
- Documents appearing in `analytics_events_private` collection
