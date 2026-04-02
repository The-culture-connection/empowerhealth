# Admin Dashboard Setup Guide

## Overview

This guide covers setting up the EmpowerHealth Admin Dashboard, including Firebase configuration, authentication, RBAC, and Railway integration.

## Prerequisites

- Node.js 18+ and npm/pnpm
- Firebase project with:
  - Authentication enabled (Email/Password)
  - Firestore database
  - Storage bucket (optional)
  - Cloud Functions (for production features)

## 1. Environment Variables

Create a `.env.local` file in the `admindash/` directory with the following Firebase configuration:

```env
# Firebase Web Config (Required)
VITE_FIREBASE_API_KEY=your-api-key-here
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
VITE_FIREBASE_APP_ID=your-app-id

# Optional
VITE_FIREBASE_MEASUREMENT_ID=your-measurement-id
VITE_FUNCTIONS_URL=https://us-central1-your-project.cloudfunctions.net

# Optional Client-Safe Variables
VITE_APP_ENV=local
VITE_GITHUB_REPO_URL=https://github.com/The-culture-connection/empowerhealth
```

**Important Notes:**
- Never commit `.env.local` to version control
- All `VITE_*` variables are exposed to the browser
- Do NOT put secrets (like API tokens) in `VITE_*` variables

## 2. Getting Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon) → General
4. Scroll to "Your apps" section
5. Click the web app icon (`</>`) or create a new web app
6. Copy the Firebase configuration object
7. Paste values into `.env.local`

## 3. Installing Dependencies

```bash
cd admindash
npm install
# or
pnpm install
```

## 4. Running Locally

```bash
npm run dev
# or
pnpm dev
```

The app will be available at `http://localhost:5173` (or the port shown in terminal).

## 5. Creating an Admin User

### Step 1: Create User in Firebase Authentication

1. Go to Firebase Console → Authentication → Users
2. Click "Add user"
3. Enter email and password
4. Copy the User UID (shown after creation)

### Step 2: Assign Admin Role

1. Go to Firebase Console → Firestore Database
2. Navigate to the `ADMIN` collection
3. Click "Add document"
4. Set Document ID to the User UID (from Step 1)
5. Add fields:
   - `email`: user's email address
   - `displayName`: user's name (optional)
   - `role`: "admin"
   - `createdAt`: current timestamp
   - `createdBy`: "system" or your UID

### Alternative: Using Firebase CLI

```bash
firebase firestore:set ADMIN/<USER_UID> '{
  "email": "admin@example.com",
  "displayName": "Admin User",
  "role": "admin",
  "createdAt": "2024-01-01T00:00:00Z",
  "createdBy": "system"
}'
```

## 6. Role-Based Access Control (RBAC)

### Role Collections

The dashboard uses three Firestore collections for roles:

- **`ADMIN`**: Full system access
- **`RESEARCH_PARTNERS`**: Read-only access to anonymized analytics and exports
- **`COMMUNITY_MANAGERS`**: Content management and push notifications, limited analytics

### Role Assignment

Each role collection uses the user's UID as the document ID. To assign a role:

1. Create a document in the appropriate collection (`ADMIN`, `RESEARCH_PARTNERS`, or `COMMUNITY_MANAGERS`)
2. Document ID = User UID
3. Document fields:
   ```json
   {
     "uid": "<user-uid>",
     "email": "user@example.com",
     "displayName": "User Name",
     "role": "admin|research_partner|community_manager",
     "createdAt": "<timestamp>",
     "createdBy": "<admin-uid>"
   }
   ```

### Role Resolution

The system checks roles in priority order:
1. `ADMIN` collection
2. `RESEARCH_PARTNERS` collection
3. `COMMUNITY_MANAGERS` collection

If a user is found in multiple collections, the highest priority role is used.

## 7. Railway Configuration

### A) Public Health URL (No Secret Needed)

This is the public URL that Cloud Functions will ping to check service health.

1. Go to Railway Dashboard
2. Select your project → Service
3. Go to Settings → Domains
4. Copy the public domain (e.g., `https://your-service.up.railway.app`)
5. Ensure your service has a `/health` endpoint that returns HTTP 200 when healthy

**For Vite SPA (no backend):**
- You cannot add a `/health` endpoint to a static Vite app
- Options:
  1. Monitor Firebase/Functions endpoints directly from Cloud Functions
  2. Create a separate "monitor" service on Railway (Express) that exposes `/health`

**Storage:**
- Store in Firebase Functions config: `firebase functions:config:set railway.health_url="https://your-service.up.railway.app/health"`
- Or use environment variable in Railway: `RAILWAY_HEALTH_URL=https://your-service.up.railway.app/health`

### B) Railway API Token (Secret - Server-Side Only)

Only needed if you want to query Railway's API for deployment status, metrics, etc.

#### Creating the Token

1. Go to Railway Dashboard
2. Click your profile (top right) → Account Settings
3. Find "Tokens" or "API Tokens"
4. Click "Create Token"
5. Name it (e.g., "empowerhealth-admin-dashboard")
6. Copy the token immediately (you won't be able to view it again)

#### Where to Store It

**Option 1: Firebase Functions Secrets (Recommended)**
```bash
firebase functions:secrets:set RAILWAY_API_TOKEN
# Paste token when prompted
```

Then in your Cloud Functions code:
```typescript
import { defineSecret } from 'firebase-functions/v2';

const railwayApiToken = defineSecret('RAILWAY_API_TOKEN');
```

**Option 2: Railway Variables (For Railway Services)**
1. Railway Dashboard → Project → Service → Variables
2. Add: `RAILWAY_API_TOKEN=<your-token>` (mark as SECRET)

**Option 3: GitHub Actions Secrets (For CI/CD)**
1. GitHub repo → Settings → Secrets and variables → Actions
2. Add: `RAILWAY_API_TOKEN` with your token value

**⚠️ Important:**
- Do NOT put `RAILWAY_API_TOKEN` in `.env.local` or any `VITE_*` variable
- The token will be exposed to browsers if in `VITE_*` variables
- Keep it server-side only (Cloud Functions, Railway Variables, or GitHub Secrets)

## 8. Setting Firebase Project

Before deploying, you need to set your Firebase project:

**Option 1: Using Firebase CLI (Recommended)**
```bash
# From the admindash directory
firebase use --add
# Select your project from the list, or enter project ID
# Give it an alias (e.g., "default")
```

**Option 2: Manual Configuration**
1. Edit `.firebaserc` file
2. Replace `"your-project-id"` with your actual Firebase project ID (from `.env.local` as `VITE_FIREBASE_PROJECT_ID`)

**Verify project is set:**
```bash
firebase projects:list
firebase use
```

## 9. Firestore Security Rules

Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules
```

The rules enforce:
- Only authenticated users with admin dashboard roles can read `releases` and `system_health`
- Only admins can write to role collections
- Only Cloud Functions can write to `releases` and `system_health`

## 10. Firestore Indexes

Deploy indexes for optimized queries:

```bash
firebase deploy --only firestore:indexes
```

Required indexes:
- `releases`: `channel` + `buildNumber` (desc)
- `releases`: `buildNumber` (desc)
- `incidents`: `startedAt` (desc)

## 11. Cloud Functions Setup

### Install Dependencies

```bash
cd functions
npm install
```

### Configure Secrets

```bash
# Set Railway API token (if using)
firebase functions:secrets:set RAILWAY_API_TOKEN

# Set Railway health URL
firebase functions:config:set railway.health_url="https://your-service.up.railway.app/health"

# Set GitHub secret token (for publishRelease)
firebase functions:config:set github.secret_token="your-secret-token"
```

### Deploy Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

## 12. Troubleshooting

### "Missing required Firebase environment variables"

- Ensure `.env.local` exists in `admindash/` directory
- Check that all `VITE_FIREBASE_*` variables are set
- Restart the dev server after changing `.env.local`

### "Access Denied" after login

- Verify user UID exists in `ADMIN`, `RESEARCH_PARTNERS`, or `COMMUNITY_MANAGERS` collection
- Check Firestore rules are deployed
- Ensure document ID matches user UID exactly

### Releases not showing

- Check Firestore rules allow read access for your role
- Verify `releases` collection exists and has data
- Check browser console for Firestore errors
- Ensure Firestore indexes are deployed

### System Health not updating

- Verify Cloud Function `pollSystemHealth` is deployed and running
- Check Cloud Function logs for errors
- Ensure `RAILWAY_HEALTH_URL` is configured correctly
- Verify Railway service has `/health` endpoint

### Railway API errors

- Ensure `RAILWAY_API_TOKEN` is set as a Firebase secret (not in `.env.local`)
- Verify token is valid and not expired
- Check Cloud Function logs for detailed error messages

### "No currently active project" error

- Run `firebase use --add` to set your project
- Or edit `.firebaserc` and replace `"your-project-id"` with your actual project ID
- Verify with `firebase use`

## 13. Development Workflow

1. **Local Development:**
   ```bash
   npm run dev
   ```

2. **Build for Production:**
   ```bash
   npm run build
   ```

3. **Deploy to Firebase Hosting:**
   ```bash
   firebase deploy --only hosting
   ```

4. **Deploy Functions:**
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

## 14. Security Checklist

- [ ] `.env.local` is in `.gitignore`
- [ ] No secrets in `VITE_*` environment variables
- [ ] `RAILWAY_API_TOKEN` stored as Firebase secret (not in `.env.local`)
- [ ] Firestore rules deployed and tested
- [ ] User roles assigned correctly
- [ ] RBAC enforced in UI and Firestore rules

## 15. Support

For issues or questions:
- Check Firebase Console logs
- Review Cloud Function logs
- Check browser console for client-side errors
- Verify Firestore rules and indexes are deployed
