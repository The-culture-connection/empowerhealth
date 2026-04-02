# Troubleshooting: Commits Not Showing Up

## Quick Checklist

### 1. Check GitHub Actions Workflow

Go to your GitHub repository → **Actions** tab:
- ✅ Is the workflow running?
- ✅ Did it complete successfully?
- ✅ Check the logs for any errors

**Common issues:**
- Workflow file not in correct location (should be `.github/workflows/publish-release.yml` at repo root)
- Secrets not set correctly
- Firebase authentication failing

### 2. Check Cloud Function Logs

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease
```

Look for:
- Function execution logs
- Any error messages
- Whether the function was called

### 3. Check Firestore Database

Go to Firebase Console → Firestore Database:
- Check if `commits` collection exists
- Check if documents are being created
- Look at the document structure

**Expected document structure:**
```json
{
  "commitSha": "abc123...",
  "commitMessage": "Your commit message",
  "commitAuthor": "Your name",
  "commitDate": Timestamp,
  "branch": "main",
  "buildNumber": 123,
  "fullVersion": "1.2.3+123",
  "channel": "pilot"
}
```

### 4. Check Firestore Rules

Make sure you can read the `commits` collection:

```bash
cd admindash
firebase deploy --only firestore:rules
```

The rules should allow authenticated users to read commits.

### 5. Check Frontend Console

Open browser DevTools (F12) → Console tab:
- Look for any errors
- Check network requests to Firestore
- Verify the `commits` collection query is running

### 6. Verify Workflow File Location

The workflow file MUST be at:
```
.github/workflows/publish-release.yml
```

NOT at:
```
admindash/.github/workflows/publish-release.yml
```

If it's in the wrong place, move it:
```bash
# From repository root
mkdir -p .github/workflows
cp admindash/.github/workflows/publish-release.yml .github/workflows/publish-release.yml
git add .github/workflows/publish-release.yml
git commit -m "Move workflow to correct location"
git push
```

### 7. Test the Cloud Function Manually

You can test if the function works:

```bash
cd admindash
firebase functions:call publishRelease \
  --data '{
    "pubspecVersionLine": "version: 1.0.0+1",
    "commitSha": "test123",
    "branch": "main",
    "gitTag": "",
    "featureDossierJson": {"summary":"Test","categories":[]},
    "environment": "pilot",
    "commitMessage": "Test commit",
    "commitAuthor": "Test User",
    "commitDate": "2024-01-15",
    "railwayDeployment": {
      "deploymentId": null,
      "deploymentUrl": null,
      "status": "success",
      "deployedAt": "2024-01-15T00:00:00Z"
    },
    "secretToken": "your-secret-token-here"
  }'
```

## Common Issues and Fixes

### Issue: Workflow Not Running

**Symptoms:** No workflow appears in GitHub Actions tab

**Fix:**
1. Check workflow file is at `.github/workflows/publish-release.yml` (repo root)
2. Check file is committed to repository
3. Check you're pushing to `main` branch
4. Verify workflow syntax is correct

### Issue: Workflow Fails on Firebase Auth

**Symptoms:** Workflow runs but fails with authentication error

**Fix:**
1. Check `FIREBASE_TOKEN` secret is set correctly
2. Regenerate token: `firebase login:ci`
3. Update GitHub secret with new token

### Issue: Cloud Function Not Being Called

**Symptoms:** Workflow runs but function never executes

**Fix:**
1. Check `FIREBASE_PROJECT_ID` secret is correct
2. Check `FIREBASE_FUNCTIONS_SECRET_TOKEN` matches in both places
3. Check function name is correct: `publishRelease`
4. Check codebase name: `admindashboard`

### Issue: Commits Created But Not Showing

**Symptoms:** Documents exist in Firestore but frontend shows nothing

**Fix:**
1. Check Firestore rules allow reading `commits` collection
2. Check browser console for permission errors
3. Verify you're logged in to the dashboard
4. Check the query in `commits.ts` is correct

### Issue: Permission Denied Errors

**Symptoms:** "Missing or insufficient permissions" errors

**Fix:**
1. Deploy updated Firestore rules:
   ```bash
   cd admindash
   firebase deploy --only firestore:rules
   ```
2. Check your user has a role document in `ADMIN` collection
3. Verify your email is in the fallback admin list (if no role doc)

## Step-by-Step Debugging

### Step 1: Verify Workflow Runs

1. Go to GitHub → Actions tab
2. Look for "Publish Release" workflow
3. Click on the latest run
4. Check if it completed successfully
5. Review logs for errors

### Step 2: Check Function Execution

1. Go to Firebase Console → Functions
2. Find `publishRelease` function
3. Check execution logs
4. Look for recent invocations
5. Check for errors

### Step 3: Verify Data in Firestore

1. Go to Firebase Console → Firestore Database
2. Look for `commits` collection
3. Check if documents exist
4. Verify document structure matches expected format

### Step 4: Test Frontend Query

1. Open dashboard in browser
2. Open DevTools → Console
3. Look for errors loading commits
4. Check Network tab for Firestore requests
5. Verify requests are successful

### Step 5: Check Firestore Rules

1. Go to Firebase Console → Firestore → Rules
2. Verify `commits` collection has read rules
3. Check rules allow authenticated users to read

## Quick Test

Run this to see if commits are being created:

```bash
# Check Firestore directly
firebase firestore:get commits --limit 5
```

Or check in Firebase Console:
1. Go to Firestore Database
2. Click on `commits` collection
3. See if documents exist

## Still Not Working?

If none of the above helps, check:

1. **Workflow file location** - Must be at repo root `.github/workflows/`
2. **Secrets** - All three secrets must be set correctly
3. **Function deployment** - Functions must be deployed
4. **Firestore rules** - Rules must allow reading commits
5. **Browser cache** - Try hard refresh (Ctrl+Shift+R)

Let me know what you find and I can help debug further!
