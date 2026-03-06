# GitHub Actions Setup Guide

## Required Secrets

For the GitHub Actions workflow to work, you need to set up these secrets in your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

### FIREBASE_TOKEN
- **How to get it:** Run `firebase login:ci` in your terminal
- **What it does:** Authenticates GitHub Actions with Firebase

### FIREBASE_PROJECT_ID
- **Value:** `empower-health-watch` (or your Firebase project ID)
- **What it does:** Specifies which Firebase project to deploy to

### FIREBASE_FUNCTIONS_SECRET_TOKEN
- **How to set it:** 
  ```bash
  # Use the new Firebase secrets system (recommended)
  firebase functions:secrets:set GITHUB_SECRET_TOKEN
  # When prompted, paste your secret token
  
  # Then deploy functions
  firebase deploy --only functions:admindashboard
  ```
- **What it does:** Secures the Cloud Functions from unauthorized calls
- **Recommendation:** Use a long random string (e.g., generate with `openssl rand -hex 32`)
- **Note:** The old `functions:config:set` method is deprecated. Use `functions:secrets:set` instead.

## Workflow Behavior

### On Push to Main Branch

When you push to the `main` branch:

1. **Process Feature Changes**
   - Reads `admindash/FEATURES.md`
   - Calls `processFeatureChanges` Cloud Function
   - Updates feature descriptions in Firestore
   - Adds change history entries

2. **Publish Release**
   - Reads version from `pubspec.yaml`
   - Calls `publishRelease` Cloud Function
   - Creates release document in `releases` collection
   - Creates commit tracking document in `commits` collection
   - Sets channel to **pilot**

### On Production Tag Push

When you push a tag starting with `prod-v*`:

1. Same as push to main, but:
   - Sets channel to **production**
   - Links to production release

## Troubleshooting

### Workflow Not Triggering

1. Check that the workflow file is in `.github/workflows/` directory
2. Verify the file is named `publish-release.yml`
3. Check that you're pushing to the `main` branch
4. Verify the workflow file is committed to the repository

### Feature Changes Not Processing

1. Check that `FEATURES.md` exists in `admindash/` directory
2. Verify the file format matches the expected structure
3. Check GitHub Actions logs for errors
4. Ensure `FIREBASE_FUNCTIONS_SECRET_TOKEN` is set correctly

### Release Not Appearing

1. Verify `pubspec.yaml` exists and has a valid version line
2. Check that the Cloud Function deployed successfully
3. Verify Firestore rules allow reading `releases` collection
4. Check browser console for permission errors

## Testing the Workflow

To test if the workflow is working:

1. Make a small change to `FEATURES.md`
2. Commit and push to main:
   ```bash
   git add admindash/FEATURES.md
   git commit -m "Test feature update"
   git push origin main
   ```
3. Check GitHub Actions tab in your repository
4. Wait for the workflow to complete
5. Check the admin dashboard to see if features updated

## Manual Trigger

You can also manually trigger the workflow:

1. Go to **Actions** tab in GitHub
2. Select **Publish Release** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**
