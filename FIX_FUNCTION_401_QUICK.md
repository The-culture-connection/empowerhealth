# Quick Fix for analyzeVisitSummaryPDF 401 Error

## Why Only This Function?

All your functions use the same configuration, so this is likely a deployment quirk where this specific function didn't get proper IAM permissions set during deployment. This can happen if:
- The function was deployed during a network interruption
- There was a temporary IAM service issue during deployment
- The function was created before other functions and has different default settings

## Solution 1: Check Security Tab (Cloud Run)

1. In the Cloud Run service page, click the **"Security"** tab (not "Permissions")
2. Look for **"Invoke permissions"** or **"IAM"** section
3. Check if `allUsers` or `allAuthenticatedUsers` has the `Cloud Run Invoker` role
4. If not, click **"Add Principal"** and add:
   - Principal: `allUsers`
   - Role: `Cloud Run Invoker`

## Solution 2: Check App Check (Firebase Console)

1. Go to [Firebase Console](https://console.firebase.google.com/project/empower-health-watch/appcheck)
2. Check if App Check enforcement is enabled
3. If enabled, either:
   - Temporarily disable enforcement for testing
   - Or ensure your app has App Check tokens configured

## Solution 3: Redeploy Function (Easiest - Try This First!)

Sometimes redeploying automatically fixes IAM permissions:

```bash
firebase deploy --only functions:analyzeVisitSummaryPDF
```

This will redeploy the function and should automatically set the correct IAM permissions.

## Solution 4: Compare with Working Function

Check the `generateBirthPlan` function's Security tab to see what permissions it has, then match those for `analyzeVisitSummaryPDF`.

