# Migration Guide: Fix ADMIN Collection Document IDs

## Problem

Your ADMIN collection documents are currently keyed by auto-generated IDs (like `ASftE2NiYG8sQzQfd48x`) instead of user uids. This causes role resolution to fail when checking by uid.

## Solution

Migrate all ADMIN documents to use the user's Firebase Auth uid as the document ID.

## Option 1: Manual Migration (Recommended for small datasets)

1. Go to Firebase Console → Firestore Database
2. Open the `ADMIN` collection
3. For each document:
   - Note the document ID (e.g., `ASftE2NiYG8sQzQfd48x`)
   - Check the `uid` field in the document data
   - Create a new document with ID = `uid` value
   - Copy all data from the old document to the new one
   - Delete the old document

## Option 2: Automated Migration Script

1. **Install Firebase Admin SDK:**
   ```bash
   cd admindash
   npm install firebase-admin
   ```

2. **Get Service Account Key:**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file securely

3. **Update the script:**
   - Open `scripts/migrate-admin-docs.js`
   - Replace `'your-project-id'` with your actual Firebase project ID
   - Uncomment and update the service account path if using Option 1

4. **Run the migration:**
   ```bash
   # Set service account path (Windows PowerShell)
   $env:GOOGLE_APPLICATION_CREDENTIALS="path\to\service-account-key.json"
   
   # Or set it in the script directly
   node scripts/migrate-admin-docs.js
   ```

## Option 3: Use Admin Dashboard (After Fix)

Once you fix one admin user manually, you can use the Admin Dashboard to reassign roles, which will automatically create documents with the correct uid-based IDs.

## Verification

After migration, verify:
1. All ADMIN documents have document IDs matching the `uid` field
2. Role resolution works (check browser console)
3. Access is granted correctly

## Current Issue

Your debug output shows:
- User uid: `pPw9YOT2DGWLDqREGPPRAef6zh82`
- ADMIN document ID: `ASftE2NiYG8sQzQfd48x` ❌ (should be `pPw9YOT2DGWLDqREGPPRAef6zh82`)
- Email: `osrgnoi@gmail.com` ✓

The email fallback is working, but we should fix the document structure for consistency and performance.
