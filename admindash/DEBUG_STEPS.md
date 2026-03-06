# Debug Steps: Commits Not Showing

## Critical Check #1: Workflow File Location ⚠️

**The workflow file MUST be at the repository root, NOT in admindash!**

**Correct location:**
```
.github/workflows/publish-release.yml  (at repo root)
```

**Wrong location:**
```
admindash/.github/workflows/publish-release.yml
```

**To fix:**
1. Check if `.github/workflows/publish-release.yml` exists at repo root
2. If not, copy it from `admindash/.github/workflows/publish-release.yml`
3. Commit and push the file at the root location

## Check #2: GitHub Actions Workflow

1. Go to GitHub → Your repo → **Actions** tab
2. **Is "Publish Release" workflow running?**
   - ✅ If YES: Check the logs for errors
   - ❌ If NO: The workflow file is in the wrong location (see Check #1)

## Check #3: Cloud Function Execution

Check if the function is being called:

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease --limit 10
```

Look for:
- Recent function executions
- Any error messages
- Whether commits were created

## Check #4: Firestore Database

1. Go to Firebase Console → Firestore Database
2. Look for `commits` collection
3. **Do documents exist?**
   - ✅ If YES: Check document structure matches expected format
   - ❌ If NO: Function isn't being called or is failing

## Check #5: Firestore Index

The commits query needs an index. Deploy it:

```bash
cd admindash
firebase deploy --only firestore:indexes
```

**Note:** If you get an error about an unnecessary index, that's okay - the commits index will still be created.

## Check #6: Browser Console

1. Open admin dashboard
2. Press F12 → Console tab
3. Look for errors:
   - "Failed to load commits"
   - "Missing or insufficient permissions"
   - "Index not found"

## Most Likely Issues

### Issue 1: Workflow Not Running (90% of cases)
**Symptom:** No workflow appears in GitHub Actions
**Fix:** Move workflow file to `.github/workflows/` at repo root

### Issue 2: Function Not Being Called
**Symptom:** Workflow runs but no commits in Firestore
**Fix:** 
- Check `FIREBASE_FUNCTIONS_SECRET_TOKEN` secret matches in both places
- Check `FIREBASE_PROJECT_ID` is correct
- Check function name is `publishRelease` (not `publishRelease` with wrong codebase)

### Issue 3: Index Error
**Symptom:** Browser console shows "index not found"
**Fix:** Deploy indexes: `firebase deploy --only firestore:indexes`

## Quick Test

Test the function manually:

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
    "secretToken": "YOUR_SECRET_TOKEN_HERE"
  }' \
  --project empower-health-watch
```

Then check Firestore - you should see a commit with SHA "test123abc".
