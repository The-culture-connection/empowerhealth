# Firebase Config Migration Guide

## What Changed?

Firebase is deprecating the old `functions.config()` system in favor of a new **params** system. This is a **good thing** - it's more secure and easier to use.

## Timeline

- **March 2026**: Old system will be shut down
- **Before then**: You need to migrate all projects
- **Good news**: The migration is straightforward and already done for the admin dashboard!

## What This Means for Your Projects

### ✅ Already Fixed
- **Admin Dashboard Functions** - Already migrated to the new system

### ⚠️ Needs Migration
- **Mobile App Functions** (if they use `functions.config()`)
- **Any other Firebase projects** using the old config

## How to Migrate (Simple 3-Step Process)

### Step 1: Export Your Current Config

```bash
cd your-project-directory
firebase functions:config:export
```

This creates a `.runtimeconfig.json` file with all your current config values.

### Step 2: Update Your Code

**Old Way:**
```typescript
const config = functions.config();
const mySecret = config.myapp?.secret_token;
```

**New Way:**
```typescript
import { defineString } from 'firebase-functions/params';

const mySecret = defineString('MYAPP_SECRET_TOKEN');
const secretValue = mySecret.value();
```

### Step 3: Set Secrets Using New Method

```bash
# For secrets (sensitive data)
firebase functions:secrets:set MYAPP_SECRET_TOKEN
# When prompted, paste your secret value

# For regular config (non-sensitive)
firebase functions:config:set myapp.secret_token="value" --project your-project
# Actually, for non-sensitive values, you can use environment variables or params
```

## Migration Examples

### Example 1: Secret Token

**Before:**
```typescript
const config = functions.config();
const token = config.github?.secret_token;
```

**After:**
```typescript
import { defineString } from 'firebase-functions/params';

const githubSecretToken = defineString('GITHUB_SECRET_TOKEN');
const token = githubSecretToken.value();
```

**Set it:**
```bash
firebase functions:secrets:set GITHUB_SECRET_TOKEN
```

### Example 2: API URL (Non-Sensitive)

**Before:**
```typescript
const config = functions.config();
const apiUrl = config.api?.base_url || 'https://api.example.com';
```

**After:**
```typescript
import { defineString } from 'firebase-functions/params';

const apiBaseUrl = defineString('API_BASE_URL', { 
  default: 'https://api.example.com' 
});
const apiUrl = apiBaseUrl.value();
```

**Set it (optional if using default):**
```bash
firebase functions:secrets:set API_BASE_URL
```

### Example 3: Multiple Config Values

**Before:**
```typescript
const config = functions.config();
const dbUrl = config.database?.url;
const apiKey = config.api?.key;
```

**After:**
```typescript
import { defineString } from 'firebase-functions/params';

const dbUrl = defineString('DATABASE_URL');
const apiKey = defineString('API_KEY');

// Use them
const url = dbUrl.value();
const key = apiKey.value();
```

## Quick Migration Checklist

For each project:

1. ✅ **Export current config**: `firebase functions:config:export`
2. ✅ **Update imports**: Add `import { defineString } from 'firebase-functions/params';`
3. ✅ **Replace config calls**: Change `functions.config()` to `defineString()`
4. ✅ **Set secrets**: Use `firebase functions:secrets:set SECRET_NAME`
5. ✅ **Test locally**: `firebase emulators:start`
6. ✅ **Deploy**: `firebase deploy --only functions`

## Benefits of New System

1. **More Secure**: Secrets are encrypted and managed separately
2. **Better Type Safety**: TypeScript support is better
3. **Easier Management**: Clear separation between secrets and config
4. **Future-Proof**: Won't break in March 2026

## For Your Mobile App Functions

If your mobile app functions use `functions.config()`, you'll need to:

1. Check what config values they use
2. Migrate them using the same pattern
3. Set the secrets using the new method
4. Deploy

**Example migration for mobile app:**

If you have:
```typescript
const config = functions.config();
const openaiKey = config.openai?.api_key;
```

Change to:
```typescript
import { defineString } from 'firebase-functions/params';

const openaiApiKey = defineString('OPENAI_API_KEY');
const openaiKey = openaiApiKey.value();
```

Then set it:
```bash
firebase functions:secrets:set OPENAI_API_KEY
```

## Automated Migration Tool

Firebase provides a tool to help:

```bash
firebase functions:config:export
```

This exports your config to a file, then you can use the migration guide to convert it.

## Need Help?

- **Firebase Docs**: https://firebase.google.com/docs/functions/config-env#migrate-config
- **Admin Dashboard**: Already migrated ✅
- **Other Projects**: Follow the examples above

## Summary

- **Don't panic!** You have until March 2026
- **It's not a rewrite** - just changing how you access config
- **Admin dashboard is done** - already using the new system
- **Other projects** - follow the migration steps above
- **It's actually better** - more secure and easier to manage

The migration is straightforward - it's mostly find-and-replace with a few adjustments.
