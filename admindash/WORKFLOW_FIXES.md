# GitHub Actions Workflow Fixes

## What Was Fixed

### 1. Added `processFeatureChanges` Cloud Function
- **Location:** `admindash/functions/src/index.ts`
- **Purpose:** Processes FEATURES.md and updates Firestore on every push
- **Called from:** GitHub Actions workflow

### 2. Updated GitHub Actions Workflow
- **File:** `admindash/.github/workflows/publish-release.yml`
- **Changes:**
  - Added step to process feature changes BEFORE publishing release
  - Added commit details extraction (message, author, date)
  - Passes commit metadata to both Cloud Functions
  - Installs `jq` for JSON processing

### 3. Enhanced Commit Tracking
- **New Collection:** `commits` - tracks all GitHub commits
- **Enhanced:** `releases` collection now includes commit message and author
- **Frontend:** Displays commit messages and authors in deployment history

### 4. Updated Frontend
- **File:** `admindash/src/app/pages/TechnologyOverview.tsx`
- **Changes:**
  - Displays commit message in deployment history table
  - Shows commit author
  - Clickable commit links

## How It Works Now

### On Every Push to Main:

1. **GitHub Actions Triggers**
   - Workflow runs automatically

2. **Process Feature Changes**
   - Reads `admindash/FEATURES.md`
   - Calls `processFeatureChanges` Cloud Function
   - Updates all feature descriptions
   - Adds new change history entries
   - Links changes to commit SHA

3. **Publish Release**
   - Reads version from `pubspec.yaml`
   - Calls `publishRelease` Cloud Function
   - Creates release with commit metadata
   - Creates commit tracking document
   - Sets channel to **pilot**

4. **Data Appears in Dashboard**
   - Features updated with new descriptions
   - Change history shows commit links
   - Deployment history shows commit messages
   - All linked to GitHub commits

## Required Setup

### 1. Set GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `FIREBASE_TOKEN` - Get with `firebase login:ci`
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_FUNCTIONS_SECRET_TOKEN` - Random secure token

### 2. Set Firebase Function Secret

```bash
firebase functions:config:set github.secret_token="your-secret-token-here"
firebase deploy --only functions
```

### 3. Deploy New Cloud Function

```bash
cd admindash
firebase deploy --only functions:processFeatureChanges
```

## Testing

1. Make a change to `FEATURES.md`
2. Commit and push:
   ```bash
   git add admindash/FEATURES.md
   git commit -m "Updated feature descriptions"
   git push origin main
   ```
3. Check GitHub Actions tab - workflow should run
4. Check admin dashboard - features should update

## Troubleshooting

### Workflow Not Running
- Check `.github/workflows/publish-release.yml` exists
- Verify you're pushing to `main` branch
- Check GitHub Actions tab for errors

### Features Not Updating
- Verify `FEATURES.md` format is correct
- Check Cloud Function logs in Firebase Console
- Ensure `processFeatureChanges` function is deployed

### Commits Not Showing
- Verify commit metadata is being passed to Cloud Functions
- Check `commits` collection in Firestore
- Ensure Firestore rules allow reading `commits` collection
