# Quick Debug: Commits Not Showing

## Step 1: Check GitHub Actions Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. Look for "Publish Release" workflow
4. **Is it running?** If not, the workflow file is in the wrong location

**Workflow file MUST be at:**
```
.github/workflows/publish-release.yml  (at repository root)
```

**NOT at:**
```
admindash/.github/workflows/publish-release.yml
```

## Step 2: Check Workflow Logs

If the workflow is running:
1. Click on the latest workflow run
2. Check each step:
   - ✅ "Parse pubspec.yaml" - Did it find the version?
   - ✅ "Get commit SHA" - Did it get the commit?
   - ✅ "Call publishRelease" - Did it call the function?
   - ❌ Any red X marks?

## Step 3: Check Cloud Function Logs

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease --limit 10
```

Look for:
- Function execution
- Any errors
- Whether commits were created

## Step 4: Check Firestore Directly

Go to Firebase Console → Firestore Database:
1. Look for `commits` collection
2. **Do documents exist?**
3. If yes, check the document structure
4. If no, the function isn't being called or is failing

## Step 5: Check Browser Console

1. Open the admin dashboard
2. Press F12 to open DevTools
3. Go to Console tab
4. Look for errors like:
   - "Failed to load commits"
   - "Missing or insufficient permissions"
   - "Index not found"

## Step 6: Deploy Firestore Index

The commits query needs an index. Deploy it:

```bash
cd admindash
firebase deploy --only firestore:indexes
```

## Most Common Issues

### Issue 1: Workflow Not Running
**Fix:** Move workflow file to `.github/workflows/` at repo root

### Issue 2: Function Not Being Called
**Fix:** Check secrets are set correctly, especially `FIREBASE_FUNCTIONS_SECRET_TOKEN`

### Issue 3: Index Error
**Fix:** Deploy the index: `firebase deploy --only firestore:indexes`

### Issue 4: Permission Error
**Fix:** Deploy rules: `firebase deploy --only firestore:rules`

## Quick Test

Test if the function works manually:

```bash
cd admindash
firebase functions:call publishRelease \
  --data '{
    "pubspecVersionLine": "version: 1.0.0+1",
    "commitSha": "test123abc",
    "branch": "main",
    "gitTag": "",
    "featureDossierJson": {"summary":"Test","categories":[]},
    "environment": "pilot",
    "commitMessage": "Test commit message",
    "commitAuthor": "Test User",
    "commitDate": "2024-01-15",
    "railwayDeployment": {
      "deploymentId": null,
      "deploymentUrl": null,
      "status": "success",
      "deployedAt": "2024-01-15T00:00:00Z"
    },
    "secretToken": "your-secret-token-here"
  }' \
  --project empower-health-watch
```

Then check Firestore - you should see a commit document with SHA "test123abc".
