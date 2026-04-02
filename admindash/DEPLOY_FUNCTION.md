# Deploy Updated Function

## What I Fixed

1. **Data unwrapping** - Function now handles both `data.data` and `data` formats (for HTTP calls vs SDK calls)
2. **Added logging** - Console.log statements to track:
   - When function is called
   - What data it receives
   - When commit document is created
   - Any errors
   - When function completes

## Deploy the Function

```bash
cd admindash
firebase deploy --only functions:admindashboard
```

## After Deployment

1. **Check the logs** after the next workflow run:
   ```bash
   firebase functions:log --only admindashboard:publishRelease --limit 20
   ```

2. **Look for these log messages:**
   - `[publishRelease] Received request:` - Function was called
   - `[publishRelease] Creating commit document:` - About to create commit
   - `[publishRelease] Commit document created successfully:` - Commit was created
   - `[publishRelease] Function completed successfully:` - Function finished

3. **Check Firestore** - Look for commits in the `commits` collection

## If Commits Still Don't Appear

1. Check the logs for errors
2. Verify the function is receiving the data correctly (check `hasDataWrapper` and `commitSha` in logs)
3. Check if there are any permission errors
4. Verify the secret token matches
