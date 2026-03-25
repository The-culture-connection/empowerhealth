# Fix App Check to Enable Analytics

## Problem
Analytics events are being rejected by the Cloud Function because App Check enforcement is enabled, but the iOS app is not registered. Events are never reaching Firestore.

## Quick Fix: Disable App Check Enforcement (Temporary)

**Option 1: Disable App Check Enforcement for Cloud Functions**

1. Go to [Firebase Console → App Check](https://console.firebase.google.com/project/empower-health-watch/appcheck)
2. Click on **"APIs"** tab (or look for "Enforcement" section)
3. Find **"Cloud Functions"** in the list
4. Click the toggle to **disable enforcement** (or set to "Unenforced")
5. Save changes

This will allow events to flow through immediately while you set up App Check properly.

## Proper Fix: Register iOS App in App Check

**Option 2: Register iOS App for App Check**

1. Go to [Firebase Console → App Check](https://console.firebase.google.com/project/empower-health-watch/appcheck)
2. Click on **"Apps"** tab
3. Click **"Register app"** or find your iOS app
4. Select **iOS** platform
5. Enter your iOS app ID: `1:725364003316:ios:f627cbea909c143e8229a1`
   - Or find it in: Firebase Console → Project Settings → Your apps → iOS app
6. Choose **DeviceCheck** provider (for production) or **Debug token** (for development)
7. For development, you'll need to:
   - Get the debug token from your app logs
   - Add it to Firebase Console → App Check → Apps → Your iOS app → Debug tokens
8. Save and wait a few minutes for propagation

## Where to View Analytics Data

**Important:** Your custom analytics write to **Firestore**, NOT the Firebase Analytics Dashboard!

To view your analytics:

1. Go to [Firebase Console → Firestore Database](https://console.firebase.google.com/project/empower-health-watch/firestore)
2. Look for these collections:
   - `analytics_events` - Anonymized events (public)
   - `analytics_events_private` - Private events with user IDs (admin only)

3. You should see events like:
   - `session_started`
   - `screen_view`
   - `learning_module_viewed`
   - etc.

## Verify It's Working

After fixing App Check:

1. Open your app and perform some actions
2. Check Firestore → `analytics_events` collection
3. You should see new documents appearing
4. Check the app logs - you should see:
   - `✅ Analytics: Event "session_started" logged successfully`
   - Instead of: `⚠️ Analytics: Event failed - likely App Check issue`

## Current Status

- ✅ Events are being sent from the app
- ✅ Error handling is working (no retry loops)
- ❌ Cloud Function is rejecting requests (App Check)
- ❌ No events reaching Firestore
- ❌ Nothing in Firebase Analytics Dashboard (expected - we use Firestore, not GA4)

## Next Steps

1. **Immediate:** Disable App Check enforcement (Option 1 above)
2. **Verify:** Check Firestore `analytics_events` collection
3. **Long-term:** Register iOS app in App Check (Option 2 above)
4. **Re-enable:** Turn App Check enforcement back on after registration
