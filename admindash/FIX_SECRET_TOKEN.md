# Fix: Invalid Secret Token Error

## Problem

The function is being called successfully, but the secret token validation is failing:

```
[publishRelease] Error: { code: 'permission-denied', message: 'Invalid secret token' }
```

## Solution

The secret token in GitHub Actions must match the one stored in Firebase. Check both:

### 1. Check Firebase Secret Token

```bash
cd admindash
firebase functions:secrets:access GITHUB_SECRET_TOKEN
```

### 2. Check GitHub Actions Secret

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Find `FIREBASE_FUNCTIONS_SECRET_TOKEN`
4. Verify it matches the Firebase secret

### 3. If They Don't Match

**Option A: Update GitHub Secret to Match Firebase**

1. Copy the value from Firebase (step 1)
2. Go to GitHub → Settings → Secrets → Actions
3. Click on `FIREBASE_FUNCTIONS_SECRET_TOKEN`
4. Click **Update**
5. Paste the Firebase secret token value
6. Click **Update secret**

**Option B: Update Firebase Secret to Match GitHub**

1. Copy the value from GitHub Secrets
2. Set it in Firebase:
   ```bash
   cd admindash
   firebase functions:secrets:set GITHUB_SECRET_TOKEN
   ```
3. When prompted, paste the GitHub secret token value

### 4. Verify the Fix

After updating, make another commit and push. The logs should show:

```
[publishRelease] Received request: {...}
[publishRelease] Creating commit document: ...
[publishRelease] Commit document created successfully: ...
[publishRelease] Function completed successfully: {...}
```

## Important Notes

- **Use the SAME token** in both places (Firebase and GitHub)
- The token should be a long random string (e.g., `c23a31a448acfd2dec13be3be0df677d88a5726de26a5c3280d4ab11f2f9fc0d`)
- Secrets are case-sensitive
- Make sure there are no extra spaces or newlines when copying
