# GitHub Actions Setup - Complete Guide

## Overview

The GitHub Actions workflow automatically processes feature changes and publishes releases on every push to the `main` branch. Here's how to set it up and verify it's working.

## Required Setup

### 1. GitHub Secrets

Go to your GitHub repository:
1. Navigate to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these three secrets:

#### FIREBASE_TOKEN
```bash
# Run this command locally to get the token:
firebase login:ci
# Copy the token and paste it as the secret value
```

#### FIREBASE_PROJECT_ID
- **Value:** `empower-health-watch`
- This is your Firebase project ID

#### FIREBASE_FUNCTIONS_SECRET_TOKEN
```bash
# Generate a secure random token:
openssl rand -hex 32

# Or use any long random string
# This token secures your Cloud Functions from unauthorized access
```

### 2. Firebase Function Secret

Set the secret token in Firebase Functions config:

```bash
cd admindash
firebase functions:config:set github.secret_token="your-secret-token-here"
firebase deploy --only functions
```

**Important:** Use the same token you set in GitHub Secrets for `FIREBASE_FUNCTIONS_SECRET_TOKEN`.

### 3. Deploy New Cloud Function

Deploy the `processFeatureChanges` function:

```bash
cd admindash
firebase deploy --only functions:processFeatureChanges
```

Or deploy all functions:

```bash
firebase deploy --only functions:admindashboard
```

## How It Works

### On Push to Main Branch

1. **GitHub Actions Workflow Triggers**
   - File: `.github/workflows/publish-release.yml`
   - Runs automatically on every push to `main`

2. **Process Feature Changes**
   - Reads `admindash/FEATURES.md`
   - Calls `processFeatureChanges` Cloud Function
   - Updates all 9 feature descriptions in Firestore
   - Adds change history entries from FEATURES.md
   - Links changes to commit SHA

3. **Publish Release**
   - Reads version from `pubspec.yaml`
   - Calls `publishRelease` Cloud Function
   - Creates release document in `releases` collection
   - Creates commit tracking document in `commits` collection
   - Includes commit message, author, and date
   - Sets channel to **pilot**

### Data Flow

```
Push to main branch
    ↓
GitHub Actions Workflow
    ↓
Read FEATURES.md
    ↓
Call processFeatureChanges()
    ↓
Update technology_features collection
    ↓
Call publishRelease()
    ↓
Create release + commit documents
    ↓
Admin Dashboard displays updates
```

## Verifying It Works

### 1. Check Workflow Runs

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see "Publish Release" workflow runs
4. Click on a run to see detailed logs

### 2. Test Feature Updates

1. Edit `admindash/FEATURES.md`:
   ```markdown
   ## 1. Provider Search
   
   ### Current Functionality
   [Update this description]
   
   ### Change History
   - **2024-01-15** - **abc123def** - **Test update**: Testing feature tracking
   ```

2. Commit and push:
   ```bash
   git add admindash/FEATURES.md
   git commit -m "Test feature update"
   git push origin main
   ```

3. Check GitHub Actions - workflow should run
4. Wait 1-2 minutes for processing
5. Check admin dashboard - feature should be updated

### 3. Check Firestore

1. Go to Firebase Console → Firestore Database
2. Check `technology_features` collection
3. Verify feature descriptions are updated
4. Check `change_history` subcollection for new entries
5. Check `releases` collection for new release
6. Check `commits` collection for commit tracking

## Troubleshooting

### Workflow Not Running

**Problem:** Workflow doesn't trigger on push

**Solutions:**
- Verify `.github/workflows/publish-release.yml` exists
- Check you're pushing to `main` branch (not `master`)
- Verify the workflow file is committed to the repository
- Check GitHub Actions tab for any errors

### Feature Changes Not Processing

**Problem:** Features don't update after push

**Solutions:**
- Check GitHub Actions logs for errors
- Verify `FEATURES.md` format is correct
- Ensure `processFeatureChanges` function is deployed
- Check Cloud Function logs in Firebase Console
- Verify `FIREBASE_FUNCTIONS_SECRET_TOKEN` matches in both places

### Permission Errors

**Problem:** "Missing or insufficient permissions" errors

**Solutions:**
- Deploy updated Firestore rules:
  ```bash
  cd admindash
  firebase deploy --only firestore:rules
  ```
- Verify you have a role document in `ADMIN` collection
- Check that your email is in the fallback list (if no role document)

### Commits Not Showing

**Problem:** Commit messages not appearing in dashboard

**Solutions:**
- Verify commit metadata is being passed in workflow
- Check `commits` collection in Firestore
- Ensure `releases` documents include `git.commitMessage`
- Check browser console for errors

## Manual Testing

You can manually test the Cloud Functions:

### Test processFeatureChanges

```bash
cd admindash
# Read FEATURES.md
FEATURES_CONTENT=$(cat FEATURES.md | jq -Rs .)
COMMIT_SHA=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --format=%B | jq -Rs .)
COMMIT_DATE=$(git log -1 --format=%ci | cut -d' ' -f1)
COMMIT_AUTHOR=$(git log -1 --format=%an)

firebase functions:call processFeatureChanges \
  --data "{
    \"commitSha\": \"$COMMIT_SHA\",
    \"commitMessage\": $COMMIT_MESSAGE,
    \"commitDate\": \"$COMMIT_DATE\",
    \"commitAuthor\": \"$COMMIT_AUTHOR\",
    \"featuresMarkdown\": $FEATURES_CONTENT,
    \"secretToken\": \"your-secret-token\"
  }"
```

## Next Steps

1. **Set up GitHub Secrets** (if not done)
2. **Deploy Cloud Functions** (including `processFeatureChanges`)
3. **Make a test push** to verify everything works
4. **Monitor GitHub Actions** for successful runs
5. **Check admin dashboard** to see updates

Once set up, every push to main will automatically:
- ✅ Update feature descriptions from FEATURES.md
- ✅ Track commit history
- ✅ Publish releases
- ✅ Display commit messages and authors
- ✅ Link everything to GitHub commits
