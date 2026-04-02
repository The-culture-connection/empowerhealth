# Testing the publishRelease Function

## Current Status

The function has been deployed successfully as an HTTP function. No log entries means it hasn't been called yet.

## How to Test

### Option 1: Trigger via GitHub Actions (Recommended)

1. **Make a commit and push to trigger the workflow:**
   ```bash
   git add .
   git commit -m "Test: Trigger publishRelease function"
   git push origin main
   ```

2. **Check GitHub Actions:**
   - Go to your GitHub repository
   - Click on the "Actions" tab
   - Look for the "Publish Release" workflow run
   - Check if it completed successfully

3. **Check Function Logs:**
   ```bash
   cd admindash
   firebase functions:log --only admindashboard:publishRelease
   ```

4. **Check Firestore:**
   - Go to Firebase Console → Firestore Database
   - Look for the `commits` collection
   - You should see a new document with the commit SHA

### Option 2: Test Manually with curl

You can test the function directly using curl:

```bash
curl -X POST \
  "https://us-central1-empower-health-watch.cloudfunctions.net/publishRelease" \
  -H "Content-Type: application/json" \
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
      "commitDate": "2026-03-07",
      "railwayDeployment": {
        "deploymentId": "",
        "deploymentUrl": "",
        "status": "success",
        "deployedAt": "2026-03-07T00:00:00Z"
      },
      "secretToken": "YOUR_SECRET_TOKEN_HERE"
    }
  }'
```

Replace `YOUR_SECRET_TOKEN_HERE` with your actual secret token from Firebase.

## What to Look For

### In Function Logs:
- `[publishRelease] Received request:` - Function was called
- `[publishRelease] Creating commit document:` - Creating commit
- `[publishRelease] Commit document created successfully:` - Commit created
- `[publishRelease] Function completed successfully:` - Function finished

### In Firestore:
- Check the `commits` collection for a document with ID matching the commit SHA
- Check the `releases` collection for a document with the build number

### In GitHub Actions:
- Workflow should complete successfully
- No errors in the "Call publishRelease Cloud Function" step
- Response should show `{"result": {"success": true, ...}}`

## Troubleshooting

If the function still doesn't create commits:

1. **Check the secret token:**
   - Make sure it matches in both Firebase and GitHub Secrets
   - Verify it's set correctly: `firebase functions:secrets:access GITHUB_SECRET_TOKEN`

2. **Check the workflow:**
   - Make sure the workflow file is in `.github/workflows/publish-release.yml`
   - Verify the workflow triggers on `push` to `main`

3. **Check function permissions:**
   - The function should have write access to Firestore
   - Check Firestore rules allow writes to `commits` collection

4. **Check function logs for errors:**
   ```bash
   firebase functions:log
   ```
   Look for any error messages related to `publishRelease`
