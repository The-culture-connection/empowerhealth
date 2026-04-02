# Fix Cloud Run 401 Unauthorized Error for analyzeVisitSummaryPDF

## Problem
The function `analyzeVisitSummaryPDF` is returning 401 "The request was not authorized to invoke this service" at the Cloud Run level, before the function code even runs.

## Root Cause
The Cloud Run service backing the Firebase Function doesn't have the correct IAM permissions to allow Firebase callable function invocations.

## Solution Options

### Option 1: Fix via Firebase Console (Recommended)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `empower-health-watch`
3. Navigate to **Cloud Run** → **Services**
4. Find the service: `analyzevisitsummarypdf`
5. Click on the service name
6. Go to **Permissions** tab
7. Click **Grant Access**
8. Add principal: `allUsers`
9. Role: `Cloud Run Invoker`
10. Click **Save**

**Note:** For Firebase callable functions, you can also use `allAuthenticatedUsers` instead of `allUsers` if you want to restrict to authenticated users only. However, Firebase handles authentication for callable functions, so `allUsers` is typically fine.

### Option 2: Fix via gcloud CLI (if installed)

```bash
gcloud run services add-iam-policy-binding analyzevisitsummarypdf \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Option 3: Redeploy Function (May Auto-Fix)

Sometimes redeploying the function can reset IAM permissions:

```bash
firebase deploy --only functions:analyzeVisitSummaryPDF
```

## Why This Happens

Firebase 2nd gen functions run on Cloud Run. When a function is deployed, Cloud Run needs IAM permissions to allow invocations. Sometimes these permissions don't get set correctly, especially if:
- The function was created manually
- There were deployment errors
- IAM permissions were changed manually

## Verification

After fixing, test the function from your Flutter app. The 401 error should be gone, and you should see the function's own logs (not just Cloud Run rejection logs).

## Alternative: Check App Check

If the above doesn't work, check if App Check enforcement is enabled:
1. Go to Firebase Console → **App Check**
2. Check if enforcement is enabled for Cloud Functions
3. If enabled, either:
   - Disable enforcement (for testing)
   - Or ensure your app has App Check properly configured

