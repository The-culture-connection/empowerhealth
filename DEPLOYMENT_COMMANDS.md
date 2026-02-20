# Firebase Functions Deployment Commands

## Prerequisites

1. **Ensure you're logged into Firebase:**
   ```bash
   firebase login
   ```

2. **Navigate to project root:**
   ```bash
   cd C:\Users\grace\EmpowerHealth
   ```

3. **Install/update dependencies:**
   ```bash
   cd functions
   npm install
   cd ..
   ```

## Deployment Commands

### 1. Deploy All Functions (Recommended)

Deploys all Cloud Functions including the new HIPAA compliance functions:

```bash
firebase deploy --only functions
```

This will deploy:
- ✅ Existing functions (generateLearningContent, summarizeVisitNotes, etc.)
- ✅ **NEW:** `analyzeVisitSummaryText` (with PHI redaction)
- ✅ **NEW:** `exportUserData` (data export)
- ✅ **NEW:** `deleteUserAccount` (account deletion)

### 2. Deploy Specific Functions Only

If you only want to deploy the new HIPAA compliance functions:

```bash
firebase deploy --only functions:analyzeVisitSummaryText,functions:exportUserData,functions:deleteUserAccount
```

### 3. Deploy Firestore Security Rules

**IMPORTANT:** Deploy the updated security rules:

```bash
firebase deploy --only firestore:rules
```

### 4. Deploy Storage Rules

Deploy the updated Firebase Storage security rules:

```bash
firebase deploy --only storage
```

### 5. Deploy Everything (Functions + Rules)

Deploy all functions, Firestore rules, and Storage rules in one command:

```bash
firebase deploy --only functions,firestore:rules,storage
```

## Important Notes

### Before Deploying

1. **Save the unsaved changes** in `functions/index.js` - The new functions (`analyzeVisitSummaryText`, `exportUserData`, `deleteUserAccount`) need to be saved.

2. **Verify OpenAI API Key Secret:**
   ```bash
   firebase functions:secrets:access OPENAI_API_KEY
   ```
   
   If not set, set it:
   ```bash
   firebase functions:secrets:set OPENAI_API_KEY
   ```
   (When prompted, paste your OpenAI API key)

3. **Check Firebase Project:**
   ```bash
   firebase projects:list
   ```
   
   Ensure you're deploying to the correct project (empower-health-watch).

### After Deployment

1. **Verify Functions are Deployed:**
   - Check Firebase Console: https://console.firebase.google.com/project/empower-health-watch/functions
   - All functions should show as "Active"

2. **Test Functions:**
   - Test from the Flutter app
   - Check function logs: `firebase functions:log`

3. **Monitor Usage:**
   - Check Firebase Console for function invocations
   - Monitor costs (should be minimal on free tier)

## Troubleshooting

### If deployment fails:

1. **Check Node.js version:**
   ```bash
   node --version
   ```
   Should be Node 20 (as specified in package.json)

2. **Clear build cache:**
   ```bash
   cd functions
   rm -rf node_modules
   npm install
   cd ..
   ```

3. **Check for syntax errors:**
   ```bash
   cd functions
   npm run lint
   ```

4. **View detailed logs:**
   ```bash
   firebase deploy --only functions --debug
   ```

## Quick Reference

```bash
# Full deployment
firebase deploy --only functions,firestore:rules,storage

# Functions only
firebase deploy --only functions

# Rules only
firebase deploy --only firestore:rules,storage

# View logs
firebase functions:log

# Test locally (optional)
cd functions
npm run serve
```
