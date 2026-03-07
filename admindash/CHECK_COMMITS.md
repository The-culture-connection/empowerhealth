# Check Why Commits Aren't Appearing

## Quick Checks

### 1. Check Function Logs

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease --limit 50
```

Look for:
- `[publishRelease] Received request:` - Shows if function was called
- `[publishRelease] Creating commit document:` - Shows if it's trying to create
- `[publishRelease] Commit document created successfully:` - Shows if it succeeded
- Any error messages

### 2. Check Firestore Console

1. Go to Firebase Console → Firestore Database
2. Look for `commits` collection
3. **Do any documents exist?**
   - If YES: Check the document structure
   - If NO: Function isn't creating them

### 3. Check GitHub Actions Response

1. Go to GitHub → Actions → Latest run
2. Click on "Call publishRelease Cloud Function" step
3. Check the response:
   - HTTP status code (should be 200)
   - Response body (should show `{"result": {"success": true, ...}}`)
   - Any error messages

### 4. Verify Function is Deployed

Make sure the latest function code is deployed:

```bash
cd admindash
firebase deploy --only functions:admindashboard
```

### 5. Test Function Manually

Test if the function works:

```bash
cd admindash
curl -X POST \
  "https://us-central1-empower-health-watch.cloudfunctions.net/publishRelease" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "data": {
      "pubspecVersionLine": "version: 1.0.0+999",
      "commitSha": "test123abc",
      "branch": "main",
      "gitTag": "",
      "featureDossierJson": {"summary":"","categories":[]},
      "environment": "pilot",
      "commitMessage": "Test commit",
      "commitAuthor": "Test User",
      "commitDate": "2026-03-06",
      "railwayDeployment": {
        "deploymentId": "",
        "deploymentUrl": "",
        "status": "success",
        "deployedAt": "2026-03-06T00:00:00Z"
      },
      "secretToken": "YOUR_SECRET_TOKEN"
    }
  }'
```

Then check Firestore for a commit with SHA "test123abc".

## Common Issues

### Issue 1: Function Not Receiving Data Correctly

**Symptom:** Function logs show `commitSha: undefined`

**Fix:** The function now handles both `data.data` and `data` formats

### Issue 2: Function Failing Silently

**Symptom:** No errors in logs, but commits not created

**Fix:** Added logging to track execution. Check logs for `[publishRelease]` messages.

### Issue 3: Permission Error

**Symptom:** Function logs show permission denied

**Fix:** Check Firestore rules allow writes to `commits` collection (should be `allow write: if false;` - only via Cloud Function, which is correct)

### Issue 4: Function Not Deployed

**Symptom:** Old function code is running

**Fix:** Deploy the latest function code

## What I Added

1. **Data unwrapping** - Handles both `data.data` and `data` formats
2. **Logging** - Added console.log statements to track execution
3. **Error handling** - Wrapped commit creation in try/catch with logging

## Next Steps

1. **Deploy the updated function:**
   ```bash
   cd admindash
   firebase deploy --only functions:admindashboard
   ```

2. **Check the logs** after the next workflow run

3. **Verify commits are created** in Firestore
