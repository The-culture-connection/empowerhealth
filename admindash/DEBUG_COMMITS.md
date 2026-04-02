# Debug: Commits Not Appearing in Database

## Issue
Workflow runs successfully, but commits aren't appearing in Firestore `commits` collection.

## Steps to Debug

### 1. Check Cloud Function Logs

```bash
cd admindash
firebase functions:log --only admindashboard:publishRelease --limit 20
```

Look for:
- Function execution logs
- Any error messages
- Whether the function was called
- Whether commits were created

### 2. Check Firestore Directly

Go to Firebase Console → Firestore Database:
1. Look for `commits` collection
2. Check if documents exist (they might be there but not visible due to permissions)
3. Check the document structure

### 3. Check Function Execution

The function creates commits at line 890 in `admindash/functions/src/index.ts`:

```typescript
await db.collection('commits').doc(commitSha).set({
  commitSha,
  commitMessage: commitMessage || '',
  commitAuthor: commitAuthor || '',
  commitDate: commitDate ? admin.firestore.Timestamp.fromDate(new Date(commitDate)) : admin.firestore.FieldValue.serverTimestamp(),
  branch: branch || 'main',
  gitTag: gitTag || null,
  buildNumber,
  fullVersion,
  channel,
  releaseDocId: buildNumber.toString(),
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
}, { merge: true });
```

### 4. Verify Workflow is Calling Function Correctly

Check the GitHub Actions workflow logs:
1. Go to GitHub → Actions → Latest run
2. Check the "Call publishRelease Cloud Function" step
3. Look for:
   - HTTP response code (should be 200)
   - Response body
   - Any error messages

### 5. Check Function Response

The function should return a response. Check if the workflow is getting a successful response.

### 6. Test Function Manually

Test the function directly:

```bash
cd admindash
firebase functions:call publishRelease \
  --data '{
    "data": {
      "pubspecVersionLine": "version: 1.0.0+1",
      "commitSha": "test123",
      "branch": "main",
      "gitTag": "",
      "featureDossierJson": {"summary":"","categories":[]},
      "environment": "pilot",
      "commitMessage": "Test commit",
      "commitAuthor": "Test User",
      "commitDate": "2026-03-06",
      "railwayDeployment": {
        "deploymentId": "",
        "deploymentUrl": "",
        "status": "success",
        "deployedAt": "2026-03-06T00:00:00Z"
      },
      "secretToken": "YOUR_SECRET_TOKEN"
    }
  }' \
  --project empower-health-watch
```

Then check Firestore for a commit with SHA "test123".

### 7. Check Function Code

Verify the function is deployed with the latest code:

```bash
cd admindash
firebase deploy --only functions:admindashboard
```

### 8. Common Issues

1. **Function not deployed** - Make sure the latest code is deployed
2. **Silent errors** - Function might be failing silently
3. **Permission issues** - Function might not have write permissions
4. **Data format issues** - Data might not be in the expected format
5. **Function not being called** - Workflow might not be calling the function correctly

## Quick Fix: Add Logging

Add console.log statements to the function to see what's happening:

```typescript
console.log('Creating commit document:', commitSha);
await db.collection('commits').doc(commitSha).set({...});
console.log('Commit document created successfully');
```

Then check the logs again.
