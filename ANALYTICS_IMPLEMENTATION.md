# Analytics Event Tracking Implementation Guide

## Overview
Comprehensive analytics event tracking has been implemented across the EmpowerHealth platform. The system tracks 30+ events with automatic user lifecycle context attachment for cohort analysis and research outcomes.

## Implementation Status

### ✅ Completed

1. **Analytics Service** (`lib/services/analytics_service.dart`)
   - Created comprehensive Flutter analytics service
   - User lifecycle context helper function
   - Helper methods for all 30+ events
   - Session ID management

2. **Cloud Function Updates** (`admindash/functions/src/index.ts`)
   - Updated `logAnalyticsEvent` to extract and enrich metadata with lifecycle context
   - Added 'app' feature to valid features list
   - Enhanced metadata processing for cohort analysis

3. **Event Tracking Added To:**
   - ✅ Learning Modules - View, start, complete, video, quiz tracking
   - ✅ After Visit Summary - Creation tracking
   - ✅ Birth Plan Builder - Completion tracking
   - ✅ Community Forums - Post creation tracking

4. **Documentation**
   - ✅ Updated FEATURES.md with comprehensive analytics expansion details

### 📝 Recommended Next Steps

To complete full event tracking coverage, add analytics calls to the following locations:

#### Provider Search Events
**File:** `lib/providers/provider_search_entry_screen.dart`
- Add `logProviderSearchInitiated()` when search is submitted (line ~286)
- Add `logProviderFilterApplied()` when filters change

**File:** `lib/providers/provider_profile_screen.dart`
- Add `logProviderProfileViewed()` when profile screen opens
- Add `logProviderContactClicked()` when contact button tapped
- Add `logProviderSaved()` when favorite/save button clicked
- Add `logProviderReviewViewed()` when reviews section viewed

#### Journal Events
**File:** `lib/Journal/Journal_screen.dart`
- Add `logJournalEntryCreated()` when entry is saved (around line ~1100)
- Add `logJournalEntryUpdated()` when entry is modified
- Add `logJournalEntryDeleted()` when entry is deleted
- Add `logJournalMoodSelected()` when mood indicator is selected
- Add `logJournalEntryShared()` when share action occurs

#### After Visit Summary Events (Additional)
**File:** `lib/appointments/upload_visit_summary_screen.dart`
- ✅ Already added: `logVisitSummaryCreated()` 
- Add `logVisitSummaryEdited()` when summary is edited
- Add `logVisitSummaryExportedPdf()` when PDF export is triggered
- Add `logVisitSummarySharedProvider()` when share with provider action occurs
- Add `logVisitSummaryVoiceNoteAdded()` when voice note is attached

**File:** `lib/visits/visit_summary_screen.dart`
- Add tracking for view, edit, export, share actions

#### Birth Plan Events (Additional)
**File:** `lib/birthplan/comprehensive_birth_plan_screen.dart`
- ✅ Already added: `logBirthPlanCompleted()`
- Add `logBirthPlanStarted()` when screen first opens
- Add `logBirthPlanTemplateSelected()` if templates are used
- Add `logBirthPlanUpdated()` when plan is saved as draft
- Add `logBirthPlanSharedProvider()` when share action occurs
- Add `logBirthPlanDownloadedPdf()` when PDF download occurs

**File:** `lib/birthplan/birth_plan_display_screen.dart`
- Add `logBirthPlanDownloadedPdf()` when PDF export button clicked
- Add `logBirthPlanSharedProvider()` when share button clicked

#### Learning Modules Events (Additional)
**File:** `lib/Home/Learning Modules/learning_modules_screen_v2.dart`
- ✅ Already added: View and start tracking in detail screen
- Add `logLearningModuleCompleted()` when user finishes reading (track scroll position or time spent)
- Add `logLearningModuleVideoPlayed()` if video content exists
- Add `logLearningModuleVideoCompleted()` when video finishes

#### Community Events (Additional)
**File:** `lib/Community/post_detail_screen.dart`
- Add `logCommunityPostViewed()` when post detail opens
- Add `logCommunityReplyCreated()` when reply is posted
- Add `logCommunityPostLiked()` when like button clicked
- Add `logCommunityPostReported()` when report action occurs
- Add `logCommunitySupportRequest()` if support request feature exists

#### Survey/Micro Measures Events
**File:** `lib/Home/Learning Modules/learning_module_detail_screen.dart`
- ✅ Already added: `logLearningModuleQuizSubmitted()` and `logConfidenceSignalSubmitted()`

**File:** `lib/Home/Learning Modules/module_survey_dialog.dart`
- Add `logHelpfulnessSurveySubmitted()` when helpfulness survey is completed
- Add `logMilestoneCheckinSubmitted()` when milestone check-in is submitted

#### System Metrics Events
**File:** `lib/main.dart` or app initialization
- Add `logSessionStarted()` when app initializes
- Add `logSessionEnded()` when app goes to background (use lifecycle observer)

**File:** Each screen/widget
- Add `logScreenView()` in `initState()` or `didChangeDependencies()` for each major screen

**File:** Notification handlers
- Add `logNotificationReceived()` when notification is received
- Add `logNotificationOpened()` when notification is tapped

## Usage Examples

### Basic Event Tracking
```dart
import '../services/analytics_service.dart';
import '../services/database_service.dart';

final analytics = AnalyticsService();
final databaseService = DatabaseService();
final userId = FirebaseAuth.instance.currentUser?.uid;

if (userId != null) {
  final userProfile = await databaseService.getUserProfile(userId);
  
  // Track an event
  await analytics.logLearningModuleViewed(
    moduleId: 'module_123',
    moduleTopic: 'Prenatal Nutrition',
    userProfile: userProfile,
  );
}
```

### Event with Custom Parameters
```dart
await analytics.logProviderSearchInitiated(
  searchRadius: 25.0,
  insuranceFilter: 'medicaid',
  providerType: 'obgyn',
  telehealth: true,
  acceptingNewPatients: true,
  userProfile: userProfile,
);
```

### Tracking Completion with Time
```dart
final startTime = DateTime.now();
// ... user interaction ...
final timeSpent = DateTime.now().difference(startTime).inSeconds;

await analytics.logLearningModuleCompleted(
  moduleId: moduleId,
  moduleTopic: topic,
  timeSpentSeconds: timeSpent,
  completionStatus: 'completed',
  userProfile: userProfile,
);
```

## User Lifecycle Context

The analytics service automatically attaches the following context to every event:
- `user_id` - Authenticated user ID
- `cohort_type` - 'navigator' or 'self_directed' (derived from hasPrimaryProvider)
- `navigator` - Boolean
- `self_directed` - Boolean
- `pregnancy_week` - Calculated from due date
- `trimester` - First/Second/Third Trimester
- `session_id` - Unique session identifier
- `timestamp` - Event timestamp
- Optional: `provider_selected`, `appointment_upcoming`, `postpartum_phase`

## Event Naming Convention

All events follow the pattern: `feature_action_object`

Examples:
- `learning_module_completed`
- `provider_profile_viewed`
- `birth_plan_shared_provider`
- `journal_entry_created`
- `community_post_created`

## Cloud Function Processing

The Cloud Function (`logAnalyticsEvent`) automatically:
1. Validates the feature ID
2. Generates anonymized user ID (SHA-256 hash with salt)
3. Extracts user lifecycle context from metadata
4. Enriches event metadata with lifecycle context
5. Writes to both `analytics_events` (anonymized) and `analytics_events_private` (admin-only)

## Derived Metrics

The system supports calculation of research outcome metrics:
- **Health Understanding Impact**: Module completion rates, visit summary usage, confidence scores
- **Self Advocacy Confidence**: Journal frequency, documentation rates, next step action rates
- **Care Navigation Success**: Provider search success, contact rates, match rates
- **Care Preparation**: Birth plan completion, pre-appointment module usage
- **Engagement Pathway**: Feature usage frequency, session patterns, cohort comparisons
- **Community Support**: Peer interaction rates, support requests, engagement scores

## Testing

To test analytics tracking:
1. Enable debug logging in `analytics_service.dart` (temporarily remove try-catch or add print statements)
2. Check Cloud Function logs in Firebase Console
3. Query `analytics_events` collection in Firestore
4. Verify lifecycle context is attached to events
5. Test with different user profiles (navigator vs self-directed)

## Notes

- Analytics failures are silently caught to prevent breaking the app
- Session IDs persist for the duration of the browser/app session
- User lifecycle context is derived from UserProfile when available
- All events include timestamp for temporal analysis
- Events support both anonymized and unanonymized views (admin-only for unanonymized)
