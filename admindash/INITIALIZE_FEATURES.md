# Initialize Features Collection

## Problem

The `technology_features` collection doesn't exist yet, and the GitHub Actions workflow might not be passing `featuresMarkdown` correctly.

## Solution

We've added debug logging to both the workflow and the Cloud Function. However, to get started immediately, you can manually initialize the features collection.

## Option 1: Wait for Next Commit

The next time you push to `main`, check the GitHub Actions logs to see:
- If FEATURES.md is being found
- If it's being encoded/decoded correctly
- If it's being passed to the Cloud Function

Then check the Cloud Function logs to see:
- If `featuresMarkdown` is being received
- What its value is
- Why it might not be processing

## Option 2: Manual Initialization (Quick Start)

If you want to initialize the features collection immediately, you can:

1. **Download serviceAccountKey.json** from Firebase Console:
   - Go to Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save it as `admindash/serviceAccountKey.json` (add to .gitignore!)

2. **Run the initialization script**:
   ```bash
   cd admindash
   npx ts-node scripts/initialize-features.ts
   ```

This will:
- Read FEATURES.md
- Parse all features
- Create/update documents in `technology_features` collection
- Add change history entries

## Debugging the Workflow

The workflow now includes debug output that will show:
- Whether FEATURES.md is found
- The length of the content
- Whether it's being included in the request

Check the GitHub Actions logs for the "Load FEATURES.md" and "Call publishRelease Cloud Function" steps.

## Next Steps

1. **Check GitHub Actions logs** on the next commit to see if FEATURES.md is being loaded
2. **Check Cloud Function logs** to see if `featuresMarkdown` is being received
3. **Manually initialize** if you want to get started immediately
