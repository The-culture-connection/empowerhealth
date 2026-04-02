# Fix IAM Permissions for Storage Trigger

## Errors

### Error 1: Authentication (401 UNAUTHENTICATED)
```
Request is missing required authentication credential. Expected OAuth 2 access token
```

### Error 2: Eventarc Service Agent Permissions
```
Permission denied while using the Eventarc Service Agent
Invalid resource state for "": Permission denied while using the Eventarc Service Agent
```

## Solutions

### Step 1: Authenticate with Firebase/Google Cloud

First, make sure you're logged in:

```bash
# Login to Firebase
firebase login

# If that doesn't work, try:
firebase login --reauth

# Also login to Google Cloud (if gcloud is installed)
gcloud auth login
```

### Step 2: Grant Eventarc Service Agent Permissions

The Eventarc Service Agent needs the `Eventarc Service Agent` role. This is required for 2nd generation Cloud Functions with Storage triggers.

**Option A: Using Google Cloud Console (Easiest)**

1. Go to [Google Cloud Console IAM](https://console.cloud.google.com/iam-admin/iam?project=empower-health-watch)

2. Find the service account: `PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com`
   - Or search for: "Eventarc Service Agent"

3. Click the edit icon (pencil) next to that service account

4. Click "ADD ANOTHER ROLE"

5. Add this role:
   - `Eventarc Service Agent` (roles/eventarc.serviceAgent)

6. Click "SAVE"

**Option B: Using gcloud CLI**

```bash
# Get your project number
PROJECT_NUMBER=$(gcloud projects describe empower-health-watch --format="value(projectNumber)")

# Grant Eventarc Service Agent role
gcloud projects add-iam-policy-binding empower-health-watch \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com" \
  --role="roles/eventarc.serviceAgent"
```

### Step 3: Grant Storage Permissions

You also need to grant the Cloud Functions service agent permission to access Storage:

### Option 1: Using Google Cloud Console (Recommended)

1. Go to [Google Cloud Console IAM](https://console.cloud.google.com/iam-admin/iam?project=empower-health-watch)

2. Find the service account with email format:
   ```
   PROJECT_NUMBER-compute@developer.gserviceaccount.com
   ```
   Or search for: `Cloud Functions Service Agent`

3. Click the edit icon (pencil) next to that service account

4. Click "ADD ANOTHER ROLE"

5. Add these roles:
   - `Storage Object Admin` (roles/storage.objectAdmin) - **This is the main one you need**
   - `Storage Admin` (roles/storage.admin) - Alternative if Object Admin doesn't work

6. Click "SAVE"

7. Also find and grant permissions to:
   - `PROJECT_NUMBER@cloudservices.gserviceaccount.com` - Add `Storage Object Admin` role

### Option 2: Using gcloud CLI (if installed)

```bash
# Get your project number
PROJECT_NUMBER=$(gcloud projects describe empower-health-watch --format="value(projectNumber)")

# Grant Storage permissions to Cloud Functions service agent
gcloud projects add-iam-policy-binding empower-health-watch \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Grant permissions to Cloud Services service agent
gcloud projects add-iam-policy-binding empower-health-watch \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudservices.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### Option 3: Alternative - Use Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/empower-health-watch/settings/iam)
2. Navigate to Project Settings > Users and permissions
3. Add the service accounts with the roles mentioned above

## After Fixing Permissions

1. **Wait a few minutes** - If this is your first time using 2nd gen functions, permissions may take a few minutes to propagate.

2. **Try deploying again:**
```bash
firebase deploy --only functions
```

3. **If you still get errors**, try:
```bash
# Re-authenticate
firebase login --reauth

# Then deploy again
firebase deploy --only functions
```

## Quick Fix Summary

For the **Eventarc Service Agent** error, you need to grant:
- Role: `Eventarc Service Agent` (roles/eventarc.serviceAgent)
- To: `PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com`

For the **Storage access** error, you need to grant:
- Role: `Storage Object Admin` (roles/storage.objectAdmin)
- To: `PROJECT_NUMBER-compute@developer.gserviceaccount.com`

## Note

If you don't have access to modify IAM policies, you'll need to ask a project owner/admin to grant these permissions.

