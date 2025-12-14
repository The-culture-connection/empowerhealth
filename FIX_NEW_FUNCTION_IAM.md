# Fix IAM Permissions for processVisitSummaryPDF

## The Problem
The new function `processVisitSummaryPDF` is getting 401 errors because Cloud Run doesn't have IAM permissions set.

## Solution: Set IAM Permissions in Google Cloud Console

1. Go to: https://console.cloud.google.com/run?project=empower-health-watch
2. Find the service: `processvisitsummarypdf` (lowercase)
3. Click on it
4. Go to **"Security"** tab
5. Click **"Add Principal"**
6. Add:
   - **Principal**: `allUsers`
   - **Role**: `Cloud Run Invoker`
7. Click **"Save"**

## Why This Happens
New Cloud Run services need IAM permissions to allow invocations. Firebase should set this automatically, but sometimes it doesn't. The working functions (`generateBirthPlan`, etc.) already have these permissions set.

## Alternative: Check if App Check is the Issue
1. Go to Firebase Console → App Check
2. Check if enforcement is enabled
3. If enabled, either disable it or ensure your app has App Check tokens

