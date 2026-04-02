# Setting Up GitHub Actions Workflow

## ✅ What I Just Did

I copied the workflow file from `admindash/.github/workflows/publish-release.yml` to `.github/workflows/publish-release.yml` at the repository root.

## ⚠️ Next Step: Commit and Push

The workflow file is now staged but **not yet committed**. You need to:

1. **Commit the file:**
   ```bash
   git commit -m "Add GitHub Actions workflow for release publishing"
   ```

2. **Push to GitHub:**
   ```bash
   git push origin main
   ```

## After Pushing

Once you push:
1. Go to GitHub → Your repo → **Actions** tab
2. You should see "Publish Release" workflow appear
3. The workflow will run automatically on every push to `main`

## Verify It's Working

After pushing, make a test commit:
```bash
git commit --allow-empty -m "Test: Trigger GitHub Actions workflow"
git push origin main
```

Then check:
- GitHub Actions tab should show the workflow running
- After it completes, check Firestore for commits in the `commits` collection

## Required GitHub Secrets

Make sure these secrets are set in GitHub:
- `FIREBASE_TOKEN` - Get with `firebase login:ci`
- `FIREBASE_PROJECT_ID` - Should be `empower-health-watch`
- `FIREBASE_FUNCTIONS_SECRET_TOKEN` - The secret token you set in Firebase

## Troubleshooting

If the workflow still doesn't appear:
1. Make sure the file is at `.github/workflows/publish-release.yml` (not in `admindash/`)
2. Make sure it's committed and pushed
3. Check GitHub repository settings → Actions → Workflow permissions (should be enabled)
