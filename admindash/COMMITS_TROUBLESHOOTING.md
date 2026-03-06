# Commits Not Showing - Troubleshooting Guide

## Most Common Issue: Workflow File Location ⚠️

**CRITICAL:** The GitHub Actions workflow file MUST be at the repository root, NOT in `admindash/`!

**Correct location:**
```
.github/workflows/publish-release.yml  (at repo root)
```

**Wrong location:**
```
admindash/.github/workflows/publish-release.yml
```

**To check:**
1. Look in your repo root for `.github/workflows/publish-release.yml`
2. If it doesn't exist there, copy it from `admindash/.github/workflows/`
3. Commit and push it at the root location

## Step-by-Step Debugging

### Step 1: Check GitHub Actions

1. Go to your GitHub repository
2. Click **Actions** tab
3. **Is "Publish Release" workflow running?**
   - ✅ If YES: Continue to Step 2
   - ❌ If NO: The workflow file is in the wrong location (see above)

### Step 2: Check Workflow Logs

1. Click on the latest workflow run
2. Check each step:
   - ✅ "Parse pubspec.yaml" - Did it find the version?
   - ✅ "Get commit SHA" - Did it get the commit?
   - ✅ "Call publishRelease" - Did it call the function?
   - ❌ Any red X marks? Check the error message

### Step 3: Check Cloud Function Logs

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease --limit 10
```

Look for:
- Function execution
- Any errors
- Whether commits were created

### Step 4: Check Firestore Database

1. Go to Firebase Console → Firestore Database
2. Look for `commits` collection
3. **Do documents exist?**
   - ✅ If YES: Check document structure
   - ❌ If NO: Function isn't being called or is failing

### Step 5: Check Browser Console

1. Open admin dashboard
2. Press F12 → Console tab
3. Look for errors:
   - "Failed to load commits"
   - "Missing or insufficient permissions"
   - "Index not found"

**Note:** Firebase will auto-create single-field indexes when needed, so index errors should resolve automatically.

## Common Issues & Fixes

### Issue 1: Workflow Not Running
**Symptom:** No workflow appears in GitHub Actions
**Fix:** Move workflow file to `.github/workflows/` at repo root

### Issue 2: Function Not Being Called
**Symptom:** Workflow runs but no commits in Firestore
**Fix:** 
- Check `FIREBASE_FUNCTIONS_SECRET_TOKEN` secret matches in both places
- Check `FIREBASE_PROJECT_ID` is correct
- Check the workflow includes `--codebase admindashboard` flag

### Issue 3: Permission Error
**Symptom:** Browser console shows "Missing or insufficient permissions"
**Fix:** 
```bash
cd admindash
firebase deploy --only firestore:rules
```

### Issue 4: Index Error (Usually Auto-Resolves)
**Symptom:** Browser console shows "index not found"
**Fix:** Firebase will auto-create the index. Wait a few minutes and refresh.

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
  --project empower-health-watch \
  --codebase admindashboard
```

Then check Firestore - you should see a commit with SHA "test123abc".

## What I Fixed

1. ✅ Fixed `commits.ts` to handle index errors gracefully (falls back to `createdAt`)
2. ✅ Added `--codebase admindashboard` flag to workflow
3. ✅ Removed unnecessary single-field indexes (Firebase auto-creates them)
4. ✅ Created troubleshooting guides

## Next Steps

1. **Verify workflow file location** - Most important!
2. **Check GitHub Actions** - Is it running?
3. **Check Firestore** - Are commits being created?
4. **Check browser console** - Any errors?

If commits still don't show after checking all of the above, share:
- Screenshot of GitHub Actions workflow run
- Any error messages from browser console
- Whether commits exist in Firestore
