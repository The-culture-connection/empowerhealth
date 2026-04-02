# Setting Up the Secret Token (New Method)

Firebase has deprecated the old `functions.config()` system. We now use the new **params** system.

## Step 1: Set the Secret Token

Use the new Firebase params command:

```bash
cd admindash
firebase functions:secrets:set GITHUB_SECRET_TOKEN
```

When prompted, paste your secret token:
```
c23a31a448acfd2dec13be3be0df677d88a5726de26a5c3280d4ab11f2f9fc0d
```

## Step 2: Set the Same Token in GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `FIREBASE_FUNCTIONS_SECRET_TOKEN`
5. Value: `c23a31a448acfd2dec13be3be0df677d88a5726de26a5c3280d4ab11f2f9fc0d`
6. Click **Add secret**

## Step 3: Deploy Functions

After setting the secret, deploy your functions:

```bash
cd admindash
firebase deploy --only functions:admindashboard
```

## Important Notes

- **Use the SAME token** in both places (Firebase and GitHub)
- The token you generated: `c23a31a448acfd2dec13be3be0df677d88a5726de26a5c3280d4ab11f2f9fc0d` is perfect
- The new params system is more secure and is the recommended approach
- Secrets are encrypted and stored securely by Firebase

## Verify It's Set

You can verify the secret is set:

```bash
firebase functions:secrets:access GITHUB_SECRET_TOKEN
```

This will show you the secret value (be careful with this command in shared environments).
