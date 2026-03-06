# Feature Tracking System - Complete Summary

## Overview

This system automatically tracks changes to 9 platform features, processes them on every GitHub push, displays them in the admin dashboard, and tracks analytics for each feature.

## Components

### 1. FEATURES.md
**Location:** `admindash/FEATURES.md`

A markdown document that serves as the single source of truth for:
- Feature descriptions (how each feature currently works)
- Change history (all modifications with dates, commit SHAs, and descriptions)

**How to use:**
1. Edit the "Current Functionality" section to update feature descriptions
2. Add entries to "Change History" when features are modified:
   ```
   - **2024-01-15** - **abc123def** - **Enhanced search**: Added new filter options
   ```

### 2. Feature Processing Script
**Location:** `admindash/scripts/process-feature-changes.js`

**What it does:**
- Parses FEATURES.md
- Extracts feature descriptions and change history
- Updates Firestore `technology_features` collection
- Adds change history entries to `technology_features/{featureId}/change_history`

**When it runs:**
- Automatically on every GitHub push (via GitHub Actions)
- Manually when publishing production releases

### 3. GitHub Actions Workflow
**Location:** `admindash/.github/workflows/publish-release.yml`

**What it does:**
- Triggers on push to `main` branch or `prod-v*` tags
- Processes feature changes from FEATURES.md
- Calls `publishRelease` Cloud Function
- Updates deployment history

### 4. Production Release Scripts
**Locations:**
- `admindash/scripts/publish-production-release.sh` (Mac/Linux)
- `admindash/scripts/publish-production-release.ps1` (Windows)

**What they do:**
- Extract commit information (SHA, message, date, author)
- Read version from `pubspec.yaml`
- Process feature changes from FEATURES.md
- Call `publishRelease` Cloud Function to publish to production

**How to use:**
```bash
# Windows
cd admindash
.\scripts\publish-production-release.ps1

# Mac/Linux
cd admindash
chmod +x scripts/publish-production-release.sh
./scripts/publish-production-release.sh
```

### 5. Cloud Functions

#### `publishRelease`
- Publishes releases to Firestore `releases` collection
- Creates/updates `technology_features` documents
- Adds change history entries
- Links features to releases

#### `logAnalyticsEvent`
- Tracks user interactions with features
- Stores anonymized and private analytics
- Validates feature IDs

#### `getFeatureAnalytics`
- Aggregates analytics for specific features
- Calculates KPIs (active users, adoption rate, engagement trends)
- Returns usage statistics

### 6. Frontend Integration

**Files:**
- `admindash/src/lib/features.ts` - Feature data management
- `admindash/src/lib/featureAnalytics.ts` - Analytics functions
- `admindash/src/app/pages/TechnologyOverview.tsx` - Display features and analytics

**What users see:**
- Platform Features Catalog with all 9 features
- Feature descriptions (editable via FEATURES.md or admin dashboard)
- Change history for each feature
- Analytics and KPIs for each feature
- Deployment history with commit links

## Feature IDs

The system uses these standardized feature IDs:

| Feature Name | Feature ID |
|-------------|------------|
| Provider Search | `provider-search` |
| Authentication and Onboarding | `authentication-onboarding` |
| User Feedback | `user-feedback` |
| Appointment Summarizing | `appointment-summarizing` |
| Journal | `journal` |
| Learning Modules | `learning-modules` |
| Birth Plan Generator | `birth-plan-generator` |
| Community | `community` |
| Profile Editing | `profile-editing` |

## Workflow

### When You Make Changes to Features

1. **Edit FEATURES.md**
   - Update "Current Functionality" section
   - Add entry to "Change History"

2. **Commit and Push**
   ```bash
   git add admindash/FEATURES.md
   git commit -m "Updated Provider Search feature"
   git push
   ```

3. **Automatic Processing**
   - GitHub Actions workflow triggers
   - Feature changes are processed
   - Firestore is updated
   - Release is published (if on main branch)

### When You Deploy to Production

1. **Run Production Release Script**
   ```bash
   cd admindash
   ./scripts/publish-production-release.sh
   ```

2. **What Happens**
   - Latest commit info is extracted
   - Feature changes from FEATURES.md are processed
   - Release is published to production channel
   - All metadata is stored in Firestore

## Analytics Tracking

### In Mobile App (Flutter)

Add analytics tracking when users interact with features:

```dart
import 'package:firebase_functions/firebase_functions.dart';

// When user starts using a feature
await FirebaseFunctions.instance
  .httpsCallable('logAnalyticsEvent')
  .call({
    'eventName': 'feature_view_start',
    'feature': 'provider-search',
    'metadata': {'searchType': 'location'},
  });

// When user completes an action
await FirebaseFunctions.instance
  .httpsCallable('logAnalyticsEvent')
  .call({
    'eventName': 'feature_completion',
    'feature': 'provider-search',
    'metadata': {'resultsCount': 10},
    'durationMs': 5000,
  });
```

### Analytics Events

- `feature_view_start` - User starts viewing/using a feature
- `feature_view_end` - User stops viewing/using a feature
- `feature_completion` - User completes a feature action
- `feature_export` - User exports data from a feature
- `feature_share` - User shares content from a feature

### Analytics Displayed

For each feature, the dashboard shows:
- **Active Users** - Number of unique users in date range
- **Adoption Rate** - Percentage of total users using the feature
- **Engagement Trend** - Daily active users over time
- **Usage by Week** - Weekly usage statistics
- **KPIs:**
  - Completion Rate
  - Export Rate
  - Average Duration
  - Total Views
  - Total Completions
  - Total Exports

## Data Flow

```
FEATURES.md (Source of Truth)
    ↓
GitHub Push / Manual Script
    ↓
process-feature-changes.js
    ↓
Firestore (technology_features collection)
    ↓
Admin Dashboard (Technology Overview Page)
    ↓
Users View Features, Changes, Analytics
```

## Next Steps

1. **Initial Setup:**
   - Review and update FEATURES.md with current feature descriptions
   - Add any recent changes to change history
   - Push to GitHub to trigger initial processing

2. **Add Analytics to Mobile App:**
   - Integrate `logAnalyticsEvent` calls in Flutter app
   - Track user interactions with all 9 features
   - Test analytics collection

3. **Deploy First Production Release:**
   - Run `publish-production-release.sh`
   - Verify data appears in admin dashboard
   - Check deployment history

4. **Ongoing Maintenance:**
   - Update FEATURES.md whenever features change
   - Use production release script for deployments
   - Monitor analytics in admin dashboard
