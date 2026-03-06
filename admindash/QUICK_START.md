# Quick Start - GitHub Workflow Setup

## ⚠️ CRITICAL: Workflow File Location

The GitHub Actions workflow file **MUST** be at the repository root, not in `admindash/`.

**Current location:** `admindash/.github/workflows/publish-release.yml`  
**Required location:** `.github/workflows/publish-release.yml` (at repository root)

### To Fix:

1. **Copy the workflow file to repository root:**
   ```bash
   # From repository root
   mkdir -p .github/workflows
   cp admindash/.github/workflows/publish-release.yml .github/workflows/publish-release.yml
   ```

2. **Commit and push:**
   ```bash
   git add .github/workflows/publish-release.yml
   git commit -m "Move workflow to repository root"
   git push origin main
   ```

## Required Setup (5 minutes)

### 1. GitHub Secrets (3 minutes)

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add:
- `FIREBASE_TOKEN` - Run `firebase login:ci` to get it
- `FIREBASE_PROJECT_ID` - Value: `empower-health-watch`
- `FIREBASE_FUNCTIONS_SECRET_TOKEN` - Generate with `openssl rand -hex 32`

### 2. Firebase Secret (1 minute)

```bash
cd admindash
# Use the SAME token from GitHub Secrets
firebase functions:config:set github.secret_token="your-secret-token-here"
firebase deploy --only functions:admindashboard
```

### 3. Test (1 minute)

```bash
# Make a small change
echo "Test" >> admindash/FEATURES.md
git add admindash/FEATURES.md
git commit -m "Test workflow"
git push origin main
```

Then check:
- GitHub Actions tab → Should see workflow running
- Wait 1-2 minutes
- Check admin dashboard → Features should update

## What's Already Done ✅

- ✅ Cloud Functions deployed (`processFeatureChanges` + updated `publishRelease`)
- ✅ Workflow file created (needs to be moved to root)
- ✅ Frontend displays commit messages
- ✅ Firestore rules updated
- ✅ All code is ready

## What You Need to Do

1. **Move workflow file to repository root** (see above)
2. **Set GitHub Secrets** (see above)
3. **Set Firebase secret** (see above)
4. **Test with a push** (see above)

Once these 3 steps are done, every push to main will automatically:
- Process feature changes from FEATURES.md
- Track GitHub commits
- Display commit messages and authors
- Update feature descriptions
- Publish releases
