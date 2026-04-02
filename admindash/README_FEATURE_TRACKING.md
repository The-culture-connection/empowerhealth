# Feature Tracking and Deployment System

This system tracks changes to platform features, processes them on every GitHub push, and displays them in the admin dashboard.

## Overview

The feature tracking system consists of:

1. **FEATURES.md** - A markdown document that tracks all features and their changes
2. **process-feature-changes.js** - Script that parses FEATURES.md and updates Firestore
3. **GitHub Actions Workflow** - Automatically processes feature changes on every push
4. **Terminal Scripts** - Manual production release publishing
5. **Analytics Tracking** - Tracks user activity for each feature

## How It Works

### 1. Documenting Features

Edit `FEATURES.md` to add or update feature descriptions and change history:

```markdown
## 1. Provider Search

### Current Functionality
[Description of how the feature works]

### Change History
- **2024-01-15** - **abc123def** - **Enhanced search filters**: Added ability to filter providers by insurance type and distance radius.
```

### 2. Automatic Processing on GitHub Push

When you push to GitHub:
1. GitHub Actions workflow triggers
2. `process-feature-changes.js` runs automatically
3. Feature documents in Firestore are updated
4. Change history is added to `technology_features/{featureId}/change_history`
5. Release is published via `publishRelease` Cloud Function

### 3. Manual Production Release

To publish a production release manually:

**Windows (PowerShell):**
```powershell
cd admindash
.\scripts\publish-production-release.ps1
```

**Mac/Linux (Bash):**
```bash
cd admindash
chmod +x scripts/publish-production-release.sh
./scripts/publish-production-release.sh
```

This will:
- Extract commit information
- Process feature changes from FEATURES.md
- Call `publishRelease` Cloud Function
- Update deployment history

### 4. Analytics Tracking

Each feature automatically tracks:
- Active users
- Adoption rate
- Engagement trends
- Usage by week
- KPIs (completion rate, export rate, average duration, etc.)

Analytics are displayed in the Technology Overview page under each feature.

## Feature IDs

The system uses these feature IDs:

- `provider-search` - Provider Search
- `authentication-onboarding` - Authentication and Onboarding
- `user-feedback` - User Feedback (Care Check-in + Learning Reviews)
- `appointment-summarizing` - Appointment Summarizing (After Visit Summary)
- `journal` - Journal
- `learning-modules` - Learning Modules
- `birth-plan-generator` - Birth Plan Generator
- `community` - Community
- `profile-editing` - Profile Editing

## Adding Analytics to Mobile App

In your Flutter app, call the analytics function when users interact with features:

```dart
// Example: When user starts viewing provider search
await logFeatureEvent(
  'provider-search',
  'feature_view_start',
  metadata: {'searchType': 'location'}
);

// Example: When user completes a search
await logFeatureEvent(
  'provider-search',
  'feature_completion',
  metadata: {'resultsCount': 10},
  durationMs: 5000
);
```

## Viewing Feature Data

1. Go to Technology Overview page in admin dashboard
2. Click on any feature in the Platform Features Catalog
3. View:
   - Feature description (editable)
   - Change history
   - Analytics and KPIs
   - Engagement trends

## Editing Feature Descriptions

Feature descriptions can be edited in two ways:

1. **Via FEATURES.md** - Edit the "Current Functionality" section and push to GitHub
2. **Via Admin Dashboard** - Use the Feature Edit Modal (Admin only)

Changes from FEATURES.md will overwrite manual edits on the next GitHub push.
