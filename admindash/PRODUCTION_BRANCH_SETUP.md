# Production Branch Setup

## Overview

The system now supports a `production` branch that works exactly like the `main` branch, but with the following differences:

1. **Channel**: Releases from the `production` branch are marked as `channel: 'production'`
2. **Current Release**: Production releases appear in the "Current Release" section
3. **Update Tags**: Updates from production branch are tagged with `[production]`

## What Was Updated

### 1. GitHub Actions Workflow

**File**: `.github/workflows/publish-release.yml`

- Added `production` branch to the trigger list
- Updated environment detection to recognize `production` branch as production channel

**Changes:**
```yaml
on:
  push:
    branches:
      - main
      - production  # ← Added
    tags:
      - 'prod-v*'
```

```yaml
# Determine environment
if [[ "${{ github.ref }}" == refs/tags/prod-v* ]] || [[ "${{ github.ref }}" == refs/heads/production ]]; then
  echo "channel=production" >> $GITHUB_OUTPUT
else
  echo "channel=pilot" >> $GITHUB_OUTPUT
fi
```

### 2. Cloud Function

**File**: `admindash/functions/src/index.ts`

- Updated channel detection to recognize `production` branch
- Added automatic tagging of updates with `[production]` or `[pilot]` based on channel

**Changes:**
```typescript
// Determine channel based on git tag or branch
let channel: 'pilot' | 'production' = 'pilot';
if (gitTag && gitTag.startsWith('prod-v')) {
  channel = 'production';
} else if (branch === 'production') {
  channel = 'production';  // ← Added
}

// Tag updates with channel
const taggedNewUpdates = newUpdates.map((update: string) => {
  if (channel === 'production' && !update.includes('[production]')) {
    return `[production] ${update}`;
  } else if (channel === 'pilot' && !update.includes('[pilot]') && !update.includes('[production]')) {
    return `[pilot] ${update}`;
  }
  return update;
});
```

### 3. Frontend Display

**File**: `admindash/src/app/pages/TechnologyOverview.tsx`

- Updated "Latest Updates" feed to show production/pilot tags
- Updated feature cards to show production/pilot badges
- Updated feature detail modal to show production/pilot tags with color coding

**Visual Changes:**
- **Production updates**: Green badge with "Production" label
- **Pilot updates**: Orange badge with "Pilot" label
- Color-coded bullet points (green for production, orange for pilot, purple for untagged)

## How It Works

### Flow for Production Branch

```
Push to production branch
    ↓
GitHub Actions Workflow Triggers
    ↓
1. Parse pubspec.yaml (version)
2. Get commit info (SHA, message, author, date)
3. Load FEATURES.md
4. Determine channel = "production" (from branch name)
    ↓
Call publishRelease Cloud Function
    ↓
1. Validate secret token
2. Parse version and create release document
3. Set channel = "production"
4. Process FEATURES.md:
   - Extract howItWorks
   - Extract recentUpdates
   - Tag updates with [production]
   - Update feature documents
    ↓
Release appears in:
- "Current Release" section (via getCurrentProductionRelease)
- Deployment History
- Latest Updates feed (with [production] tag)
```

### Current Release Section

The "Current Release" section uses `getCurrentProductionRelease()` which:
- Queries `releases` collection
- Filters by `channel == 'production'`
- Orders by `buildNumber DESC`
- Returns the latest production release

So when you push to the `production` branch, that release will automatically appear in the "Current Release" section.

## Update Tags

Updates are now automatically tagged based on the channel:

- **Production branch** → Updates tagged with `[production]`
- **Main branch** → Updates tagged with `[pilot]`
- **Tags (prod-v*)** → Updates tagged with `[production]`

The tags are displayed as badges in:
- Latest Updates feed
- Feature cards (preview)
- Feature detail modal (full view)

## Testing

1. **Push to production branch**:
   ```bash
   git checkout production
   git push origin production
   ```

2. **Verify in Admin Dashboard**:
   - Check "Current Release" section - should show the production release
   - Check "Latest Updates" feed - updates should have green "Production" badges
   - Check feature cards - updates should show "PROD" badges
   - Click on an update - should open feature detail modal with production tag

3. **Verify in Firestore**:
   - Check `releases` collection - latest production release should have `channel: 'production'`
   - Check `technology_features` collection - `recentUpdates` should have `[production]` prefix

## Notes

- Production releases will always appear in "Current Release" section (replacing previous production release)
- Pilot releases (from `main` branch) will appear in "Deployment History" but not in "Current Release"
- Updates are tagged automatically - no manual tagging needed
- The system preserves existing tags, so updates won't be double-tagged
