# Technology Dashboard Implementation Guide

## Overview

The Technology Dashboard is a dynamic, auto-updating system that tracks releases from GitHub, displays build versions from `pubspec.yaml`, shows Railway deployment status, and monitors system health.

## Architecture

### Firestore Collections

1. **`releases`** (docId: `buildNumber`)
   - Stores release information with production/pilot channels
   - Fields: `fullVersion`, `versionName`, `buildNumber`, `channel`, `git`, `railway`, `featureDossier`, `createdAt`, `createdBy`

2. **`system_health`** (docId: `serviceKey`)
   - Tracks health status for various services
   - Service keys: `railway_api`, `firebase`, `analytics_jobs`, `fcm_sender`
   - Fields: `name`, `status`, `lastCheckedAt`, `lastHealthyAt`, `details`, `metrics`

3. **`incidents`** (optional)
   - Tracks system outages and incidents
   - Fields: `severity`, `summary`, `startedAt`, `resolvedAt`, `releaseVersion`

### Cloud Functions

1. **`publishRelease`** (HTTPS Callable)
   - Called from GitHub Actions
   - Parses `pubspec.yaml` version
   - Determines channel (pilot vs production) based on Git tags
   - Upserts release document
   - Logs audit event

2. **`pollSystemHealth`** (Scheduled - every 5 minutes)
   - Checks Railway API health
   - Checks Firebase read/write
   - Checks analytics job freshness
   - Checks notification queue depth
   - Updates `system_health` collection

3. **`runHealthCheckNow`** (HTTPS Callable - Admin only)
   - Manual trigger for health checks
   - Same logic as `pollSystemHealth`

### GitHub Actions Workflow

**File**: `.github/workflows/publish-release.yml`

**Triggers**:
- Push to `main` branch → Pilot release
- Tag matching `prod-v*` → Production release

**Steps**:
1. Checkout code
2. Parse `pubspec.yaml` to extract version
3. Get commit SHA, branch, and Git tag
4. Load feature dossier JSON
5. Determine environment (pilot/production)
6. Call `publishRelease` Cloud Function

**Required Secrets**:
- `FIREBASE_TOKEN`: Firebase authentication token
- `FIREBASE_FUNCTIONS_SECRET_TOKEN`: Secret token for Cloud Function authentication
- `FIREBASE_PROJECT_ID`: Firebase project ID

### Frontend Pages

1. **Technology Overview** (`/technology`)
   - Shows current production and pilot releases
   - Displays release history (last 13)
   - Feature dossier viewer with search
   - Mismatch warning if pilot is ahead of production

2. **System Status** (`/system-status`)
   - Status tiles for each service
   - Recent incidents list
   - Live metrics (queue depth, job runs, error rate, uptime)
   - Manual health check button (Admin only)

## Production Marking Rules

- **Pilot**: Any push to `main` branch
- **Production**: Any Git tag matching `prod-v*` (e.g., `prod-v1.2.3+13`)

## Setup Instructions

### 1. Configure Firebase Functions

Set the following configuration:

```bash
firebase functions:config:set github.secret_token="your-secret-token"
firebase functions:config:set railway.health_url="https://your-railway-api.com/health"
```

### 2. Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### 3. Set Up GitHub Actions Secrets

In your GitHub repository settings, add:
- `FIREBASE_TOKEN`
- `FIREBASE_FUNCTIONS_SECRET_TOKEN`
- `FIREBASE_PROJECT_ID`

### 4. Create Feature Dossier File

Create a `feature-dossier.json` file in your Flutter app root:

```json
{
  "summary": "Release summary",
  "categories": [
    {
      "name": "Learning Modules",
      "items": [
        {
          "name": "Feature Name",
          "description": "Feature description",
          "status": "New",
          "tags": ["learning"]
        }
      ]
    }
  ],
  "notes": "Optional notes",
  "knownIssues": []
}
```

### 5. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

## Usage

### Publishing a Release

1. **Pilot Release**: Push to `main` branch
   ```bash
   git push origin main
   ```

2. **Production Release**: Create and push a production tag
   ```bash
   git tag prod-v1.2.3+13
   git push origin prod-v1.2.3+13
   ```

### Manual Health Check

Admins can trigger a health check from the System Status page by clicking "Run Health Check".

## RBAC

- **Admin**: Full access to all features
- **Research Partner**: Read-only access to releases and system status
- **Community Manager**: Read-only access to releases and system status

## Troubleshooting

### Releases Not Appearing

1. Check GitHub Actions workflow logs
2. Verify `publishRelease` Cloud Function logs
3. Ensure `pubspec.yaml` has correct version format: `version: 1.2.3+13`
4. Verify feature dossier JSON is valid

### Health Checks Failing

1. Check `pollSystemHealth` scheduled function logs
2. Verify Railway API health endpoint is accessible
3. Check Firebase permissions
4. Verify service account has necessary permissions

### GitHub Actions Failing

1. Verify all secrets are set correctly
2. Check Firebase token is valid
3. Ensure `pubspec.yaml` exists and has version line
4. Verify feature dossier file exists or workflow handles missing file
