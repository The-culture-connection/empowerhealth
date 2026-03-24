# Platform Features Documentation

This document tracks all platform features, their current functionality, and change history.

## 1. Provider Search

### Current Functionality
The Provider Search feature allows users to find healthcare providers based on various criteria including location, specialty, identity tags, and user reviews. Users can search for providers, view detailed provider profiles with ratings and reviews, filter by specific criteria such as "Mama Approved" status, and save favorite providers for quick access. The search integrates with provider identity claims and allows users to submit new providers for review. The system tracks provider reviews, ratings, and user interactions to help users make informed healthcare decisions.

### Change History
- **2024-12-15** - **abc123def** - **Enhanced search filters**: Added medicaid directory from a new api.
- **2024-12-10** - **def456ghi** - **Provider reviews integration**: Integrated user reviews directly into provider search results for better decision-making.
- **2026-03-23** - **def456ghi** - **Provider reviews integration**: Checking feature updating
---

## 2. Authentication and Onboarding

### Current Functionality
The Authentication and Onboarding system handles user account creation, login, password management, and initial user setup. Users can sign up with email and password, reset forgotten passwords, and complete an onboarding flow that collects initial preferences and needs. The system supports role-based access control for admin dashboard users and maintains user profiles with preferences and settings. Onboarding includes care survey collection to personalize the user experience.

### Change History
- **2024-12-14** - **xyz789abc** - **Biometric authentication**: Added support for fingerprint and face recognition login for faster access.
- **2024-12-08** - **mno321pqr** - **Onboarding improvements**: Streamlined the onboarding flow to reduce completion time by 30%.
- **2025-03-23** - **528a0258** - **Sign-in analytics**: On successful Google, Apple, or email sign-in, the app logs `sign_in_completed` (feature `authentication-onboarding`) for the realtime analytics pipeline.

---

## 3. User Feedback

### Current Functionality
The User Feedback system encompasses two main components: Care Check-in surveys and Learning Module reviews. Care Check-in allows users to provide feedback about their healthcare experiences, including questions about care quality, communication, and satisfaction. Learning Module reviews enable users to rate and review educational content, providing ratings for understanding, next steps clarity, and confidence levels. This feedback is aggregated to improve content quality and track user engagement with educational materials.

### Change History
- **2024-12-13** - **uvw456rst** - **Feedback analytics dashboard**: Added real-time analytics for care check-in responses to help identify trends.

---

## 4. Appointment Summarizing

### Current Functionality
The Appointment Summarizing feature (After Visit Summary) allows users to upload PDF visit summaries or enter text notes from medical appointments. The system uses AI to process and summarize these documents, extracting key information, medications, recommendations, and next steps. Summaries are simplified to a 6th-grade reading level for accessibility. Users can view, edit, and manage their visit summaries, which are stored securely and can be referenced for future appointments or shared with other healthcare providers.

### Change History
- **2024-12-13** - **uvw456rst** - **Feedback analytics dashboard**: Added real-time analytics for care check-in responses to help identify trends.

---

## 5. Journal

### Current Functionality
The Journal feature provides users with a private space to record thoughts, experiences, and notes related to their healthcare journey. Users can create journal entries with text content, attach files or images, and organize entries by date. The journal supports emotional content analysis to identify significant moments or areas of confusion. Entries are stored securely and can be searched, filtered, and reviewed over time to track progress and patterns.

### Change History
- *No changes tracked yet*

---

## 6. Learning Modules

### Current Functionality
The Learning Modules feature provides educational content tailored to users' needs and pregnancy/postpartum journey. Modules cover topics such as pregnancy health, postpartum care, patient rights, and self-advocacy. Content is generated using AI to ensure it's at a 6th-grade reading level and culturally appropriate. Users can complete modules, track progress, receive personalized recommendations, and provide feedback. The system includes task management for learning goals and tracks completion rates and engagement metrics.

### Change History
- *No changes tracked yet*

---

## 7. Birth Plan Generator

### Current Functionality
The Birth Plan Generator helps users create personalized birth plans by guiding them through preferences for labor, delivery, and postpartum care. Users can specify preferences for pain management, delivery positions, who should be present, feeding preferences, and postpartum care. The system uses AI to generate comprehensive birth plans based on user inputs, which can be exported as PDFs and shared with healthcare providers. Plans can be updated as preferences change and are stored securely for reference.

### Change History
- *No changes tracked yet*

---

## 8. Community

### Current Functionality
The Community feature provides a forum where users can share experiences, ask questions, and support each other. Users can create posts, reply to others' posts, like content, and report inappropriate material. Posts are organized by topics and can be searched. The community fosters peer support and information sharing while maintaining moderation capabilities. Users can engage in discussions about pregnancy, postpartum, healthcare experiences, and related topics in a safe, supportive environment.

### Change History
- *No changes tracked yet*

---

## 9. Profile Editing

### Current Functionality
The Profile Editing feature allows users to manage their account information, preferences, and settings. Users can update their display name, email, profile picture, and personal information. The system includes privacy settings, notification preferences, and account management options. Users can view their activity history, manage connected accounts, and control data sharing preferences. Profile changes are tracked for audit purposes and synced across the platform.

### Change History
- **2025-03-23** - **528a0258** - **Profile save analytics**: On successful profile save from the edit profile screen, the app logs `profile_updated` (feature `profile-editing`) for the realtime analytics pipeline.

---

## 10. Analytics and Event Tracking

### Current Functionality
The Analytics and Event Tracking system provides comprehensive tracking of user interactions and app usage patterns across all platform features. The system tracks 30+ distinct events covering Learning Modules, After Visit Summary, Birth Plan Builder, Provider Search, Journal, Community Forums, Surveys/Micro Measures, and System Metrics. Events flow through two complementary paths: (1) **callable analytics** — a Cloud Function (`logAnalyticsEvent`) that handles anonymization server-side and writes to `analytics_events` (anonymized) and `analytics_events_private` (admin-only); (2) **realtime mobile pipeline** — the Flutter app writes enriched documents to `analytics_events` with `source: mobile`, time keys, platform, app version, and sanitized metadata, then a **Firestore trigger** (`onAnalyticsEventCreated`) aggregates into summary documents for dashboards without scanning raw events. The trigger **skips** `source: cloud_function` rows so totals are not double-counted when both paths write for the same user action. The admin dashboard can subscribe to `analytics_summary/global` for live totals alongside existing callable `getAnalyticsData` queries. The system generates unique session IDs for each app session and automatically attaches user lifecycle context (user_id, cohort_type, navigator, self_directed, pregnancy_week, trimester, session_id, timestamp) to every event for cohort analysis and research outcomes. Reference docs: repo `docs/mobile-analytics-inventory.md` (event inventory and gaps), `docs/realtime-analytics.md` (schema and deployment notes).

### How the feature works
The analytics system uses a three-layer data architecture:

**A. User Lifecycle Context** - Automatically attached to every event:
- `user_id` - Authenticated user ID
- `cohort_type` - Derived from user profile (navigator/self_directed)
- `navigator` - Boolean indicating if user has primary provider
- `self_directed` - Boolean indicating self-directed care
- `pregnancy_week` - Calculated from due date
- `trimester` - First/Second/Third trimester
- `session_id` - Unique session identifier
- `timestamp` - Event timestamp
- Optional: `provider_selected`, `appointment_upcoming`, `postpartum_phase`

**B. Event Taxonomy** - 30+ events organized by feature:

**Learning Modules (6 events):**
- `learning_module_viewed` - Module detail page viewed
- `learning_module_started` - User begins reading module
- `learning_module_completed` - Module fully read
- `learning_module_video_played` - Video content started
- `learning_module_video_completed` - Video finished
- `learning_module_quiz_submitted` - Survey/quiz completed with scores

**After Visit Summary (5 events):**
- `visit_summary_created` - New summary uploaded/created
- `visit_summary_edited` - Summary modified
- `visit_summary_exported_pdf` - PDF export generated
- `visit_summary_shared_provider` - Summary shared with provider
- `visit_summary_voice_note_added` - Voice note attached

**Birth Plan Builder (6 events):**
- `birth_plan_started` - Plan creation initiated
- `birth_plan_template_selected` - Template chosen
- `birth_plan_completed` - Plan finalized
- `birth_plan_updated` - Plan modified
- `birth_plan_shared_provider` - Plan shared
- `birth_plan_downloaded_pdf` - PDF downloaded

**Provider Search (6 events):**
- `provider_search_initiated` - Search started
- `provider_filter_applied` - Filter used
- `provider_profile_viewed` - Profile detail viewed
- `provider_contact_clicked` - Contact action taken
- `provider_saved` - Provider favorited
- `provider_review_viewed` - Review read

**Journal (5 events):**
- `journal_entry_created` - New entry written
- `journal_entry_updated` - Entry modified
- `journal_entry_deleted` - Entry removed
- `journal_mood_selected` - Mood indicator used
- `journal_entry_shared` - Entry shared

**Community Forums (6 events):**
- `community_post_created` - New post published
- `community_post_viewed` - Post detail viewed
- `community_reply_created` - Reply posted
- `community_post_liked` - Post liked
- `community_post_reported` - Post reported
- `community_support_request` - Support requested

**Surveys/Micro Measures (3 events):**
- `confidence_signal_submitted` - Confidence survey completed (understand_meaning_score, know_next_step_score, confidence_score)
- `helpfulness_survey_submitted` - Helpfulness rating submitted
- `milestone_checkin_submitted` - Milestone check-in completed

**System Metrics (5 events):**
- `session_started` - App session begins
- `session_ended` - App session ends
- `screen_view` - Screen/page viewed
- `notification_opened` - Notification tapped
- `notification_received` - Notification delivered

**Authentication / profile (instrumented in app for realtime summaries):**
- `sign_in_completed` - Successful sign-in (parameters: `method` — google, apple, email)
- `profile_updated` - Profile saved from edit profile screen

**C. Implementation Architecture:**
- **Flutter Analytics Service** (`lib/services/analytics_service.dart`) - Client-side service with helper methods for each event type
- **Dual Tracking System**:
  - **Custom Firestore Analytics** - Cloud Function (`logAnalyticsEvent`) that:
    - Validates events and features
    - Generates anonymized user IDs (SHA-256 hash with salt)
    - Extracts and enriches metadata with lifecycle context
    - Writes to both `analytics_events` (anonymized) and `analytics_events_private` (admin-only)
    - Tags callable-written rows with `source: cloud_function` (and `aggregationVersion`) so aggregation only counts mobile rows
  - **Realtime mobile writes** (`lib/services/analytics/realtime_analytics_service.dart`) - After a successful callable log, the client also writes a full-schema `analytics_events` document with `source: mobile`, `aggregationVersion`, `dateKey` / `hourKey` / `monthKey`, `platform`, `environment`, `appVersion`, `clientTimestamp`, and mirrored copies under `technology_features/{featureId}/analytics_events` where applicable
  - **Firebase Analytics (Standard Dashboard)** - Logs all events to Firebase Analytics dashboard for real-time insights and standard analytics reports
- **Event Parameters** - Each event includes feature-specific parameters (module_id, summary_id, provider_id, etc.) merged with lifecycle context
- **Session Management** - Session IDs persist for browser/app session duration

**E. Realtime aggregation (dashboard summaries):**
- **Trigger** - Cloud Function `onAnalyticsEventCreated` on `analytics_events/{eventId}` (region `us-central1`) updates atomic counters via merge + `FieldValue.increment`
- **Summary collections** (admin read-only in Firestore rules; written only by Functions):
  - `analytics_summary/global` — e.g. `totalEvents`, `lastEventName`, first-class “today*” counters where mapped (posts, journal entries, visit summaries, birth plans, provider searches, sessions, screen views, profile updates, sign-ins)
  - `analytics_summary_daily/{YYYY-MM-DD}` — `countsByEventName`, `countsByFeature`, plus mapped daily fields
  - `analytics_feature_summary/{feature}` — per-feature totals and `countsByEventName`
  - `analytics_summary_hourly/{YYYY-MM-DD-HH}` — optional hourly rollups
- **Admin UI** - Analytics page (`src/app/pages/Analytics.tsx`) can show a live banner from `analytics_summary/global` alongside existing callable `getAnalyticsData` results
- **Local dev** - Optional Firestore emulator: Flutter `--dart-define=USE_FIREBASE_EMULATOR=true` (see `docs/realtime-analytics.md`)

**D. Derived Metrics & Reports:**
The system supports calculation of outcome metrics for research:
- **Health Understanding Impact**: learning_module_completion_rate, visit_summary_usage_rate, birth_plan_completion_rate, confidence_signal_avg
- **Self Advocacy Confidence**: journal_frequency, visit_summary_documentation_rate, milestone_checkin_completion, helpfulness_rating, next_step_action_rate
- **Care Navigation Success**: provider_search_success_rate, provider_contact_rate, average_search_refinements, successful_provider_match_rate
- **Care Preparation**: birth_plan_completion_rate, learning_module_usage_pre_appointment, journal_usage_pre_milestone
- **Engagement Pathway**: Feature usage frequency, session frequency, modules completed, segmented by navigator/self_directed cohorts
- **Community Support**: peer_interaction_rate, support_request_rate, reply_rate, community_engagement_score

Events follow Firebase naming convention: `feature_action_object` (e.g., `learning_module_completed`, `provider_profile_viewed`).

### Change History
- **2024-12-19** - **analytics_initial** - **App open tracking**: Added automatic tracking of app opens with session ID generation. Events are logged with metadata including timestamp, user agent, and platform information. Integrated with existing Cloud Function-based analytics infrastructure for server-side anonymization.
- **2025-03-07** - **analytics_expansion** - **Comprehensive event tracking**: Expanded analytics system to track 30+ events across all platform features. Added user lifecycle context (cohort_type, navigator, self_directed, pregnancy_week, trimester) automatically attached to every event. Implemented Flutter analytics service with helper methods for Learning Modules (6 events), After Visit Summary (5 events), Birth Plan Builder (6 events), Provider Search (6 events), Journal (5 events), Community Forums (6 events), Surveys/Micro Measures (3 events), and System Metrics (5 events). Updated Cloud Function to extract and enrich metadata with lifecycle context for cohort analysis. Events support derived metrics calculation for research outcomes including Health Understanding Impact, Self Advocacy Confidence, Care Navigation Success, Care Preparation, Engagement Pathway, and Community Support reports.
- **2025-03-07** - **analytics_auth_fix** - **Fixed authentication and App Check issues**: Resolved analytics events not being logged to Firestore due to Firebase Functions v2 context structure mismatch. Updated `logAnalyticsEvent` Cloud Function to use correct v2 `CallableRequest` format (`request.auth.uid` instead of `context.auth.uid`). Disabled App Check enforcement (`enforceAppCheck: false`) to allow analytics without App Check registration. Implemented event queuing system in Flutter app to handle auth race conditions at startup. Added comprehensive error handling to distinguish App Check failures from authentication errors. Events now successfully write to `analytics_events` and `analytics_events_private` collections in Firestore using authenticated user's UID for data correlation.
- **2025-03-07** - **analytics_dual_tracking** - **Dual analytics tracking**: Added Firebase Analytics (standard dashboard) tracking alongside existing custom Firestore analytics. All events are now logged to both systems simultaneously - custom Firestore collections for detailed analysis with user lifecycle context, and Firebase Analytics dashboard for real-time insights and standard reports. Firebase Analytics events include feature, lifecycle context (cohort_type, trimester, pregnancy_week, navigator, self_directed), and event-specific parameters. Both systems operate independently, so events are logged to Firebase Analytics even if the Cloud Function fails, ensuring comprehensive tracking coverage.
- **2025-03-23** - **528a0258** - **Realtime Firestore summaries and mobile schema**: Added `RealtimeAnalyticsService` for normalized `analytics_events` writes (`source: mobile`, time keys, platform, app version, sanitized metadata) and Cloud Function `onAnalyticsEventCreated` to aggregate into `analytics_summary/global`, `analytics_summary_daily/{dateKey}`, `analytics_feature_summary/{feature}`, and `analytics_summary_hourly/{hourKey}` without double-counting callable rows (`source: cloud_function`). Extended Firestore rules for summary collections (admin read, client no write). Admin Analytics page shows live totals from `analytics_summary/global`. Optional Firestore emulator support via `USE_FIREBASE_EMULATOR`. Documented in `docs/realtime-analytics.md` and inventory in `docs/mobile-analytics-inventory.md`. Fixed invalid JSON in `firestore.indexes.json` (trailing comma) blocking deploy. Instrumented `sign_in_completed` on login and `profile_updated` on profile save.

---

## How to Add Changes

When modifying any feature, add an entry to the "Change History" section for that feature in the following format:

```
- **[Date]** - **[Commit SHA]** - **[Description]**: [Detailed description of changes]
```

Example:
```
- **2024-01-15** - **abc123def** - **Enhanced search filters**: Added ability to filter providers by insurance type and distance radius. Improved search performance by 40%.
```
I am not seeing the changes to the features document on the webapp: 
3. Update Feature Summaries and Changes
Method 1: Edit FEATURES.md (Recommended)
Edit admindash/FEATURES.md to update feature descriptions and add change history.

To update a feature description:

## 1. Provider Search

### Current Functionality
[Update this section with new description]

### Change History
- **2024-01-15** - **abc123def** - **Enhanced search**: Added new filters
To add a change entry:

- **[YYYY-MM-DD]** - **[commit-sha]** - **[Title]**: [Description]
After editing FEATURES.md:

git add admindash/FEATURES.md
git commit -m "Updated feature descriptions"
git push
Changes are automatically processed on push and appear in the dashboard.

This is what I see, but the feature updates I do not think are wired for analytics: 
The Analytics and Event Tracking system provides comprehensive tracking of user interactions and app usage patterns across all platform features. The system tracks 30+ distinct events covering Learning Modules, After Visit Summary, Birth Plan Builder, Provider Search, Journal, Community Forums, Surveys/Micro Measures, and System Metrics. Events flow through two complementary paths: (1) **callable analytics** — a Cloud Function (`logAnalyticsEvent`) that handles anonymization server-side and writes to `analytics_events` (anonymized) and `analytics_events_private` (admin-only); (2) **realtime mobile pipeline** — the Flutter app writes enriched documents to `analytics_events` with `source: mobile`, time keys, platform, app version, and sanitized metadata, then a **Firestore trigger** (`onAnalyticsEventCreated`) aggregates into summary documents for dashboards without scanning raw events. The trigger **skips** `source: cloud_function` rows so totals are not double-counted when both paths write for the same user action. The admin dashboard can subscribe to `analytics_summary/global` for live totals alongside existing callable `getAnalyticsData` queries. The system generates unique session IDs for each app session and automatically attaches user lifecycle context (user_id, cohort_type, navigator, self_directed, pregnancy_week, trimester, session_id, timestamp) to every event for cohort analysis and research outcomes. Reference docs: repo `docs/mobile-analytics-inventory.md` (event inventory and gaps), `docs/realtime-analytics.md` (schema and deployment notes).
### How the feature works
The analytics system uses a three-layer data architecture:
**A. User Lifecycle Context** - Automatically attached to every event:
- `user_id` - Authenticated user ID
- `cohort_type` - Derived from user profile (navigator/self_directed)
- `navigator` - Boolean indicating if user has primary provider
- `self_directed` - Boolean indicating self-directed care
- `pregnancy_week` - Calculated from due date
- `trimester` - First/Second/Third trimester
- `session_id` - Unique session identifier
- `timestamp` - Event timestamp
- Optional: `provider_selected`, `appointment_upcoming`, `postpartum_phase`
**B. Event Taxonomy** - 30+ events organized by feature:
**Learning Modules (6 events):**
- `learning_module_viewed` - Module detail page viewed
- `learning_module_started` - User begins reading module
- `learning_module_completed` - Module fully read
- `learning_module_video_played` - Video content started
- `learning_module_video_completed` - Video finished
- `learning_module_quiz_submitted` - Survey/quiz completed with scores
**After Visit Summary (5 events):**
- `visit_summary_created` - New summary uploaded/created
- `visit_summary_edited` - Summary modified
- `visit_summary_exported_pdf` - PDF export generated
- `visit_summary_shared_provider` - Summary shared with provider
- `visit_summary_voice_note_added` - Voice note attached
**Birth Plan Builder (6 events):**
- `birth_plan_started` - Plan creation initiated
- `birth_plan_template_selected` - Template chosen
- `birth_plan_completed` - Plan finalized
- `birth_plan_updated` - Plan modified
- `birth_plan_shared_provider` - Plan shared
- `birth_plan_downloaded_pdf` - PDF downloaded
**Provider Search (6 events):**
- `provider_search_initiated` - Search started
- `provider_filter_applied` - Filter used
- `provider_profile_viewed` - Profile detail viewed
- `provider_contact_clicked` - Contact action taken
- `provider_saved` - Provider favorited
- `provider_review_viewed` - Review read
**Journal (5 events):**
- `journal_entry_created` - New entry written
- `journal_entry_updated` - Entry modified
- `journal_entry_deleted` - Entry removed
- `journal_mood_selected` - Mood indicator used
- `journal_entry_shared` - Entry shared
**Community Forums (6 events):**
- `community_post_created` - New post published
- `community_post_viewed` - Post detail viewed
- `community_reply_created` - Reply posted
- `community_post_liked` - Post liked
- `community_post_reported` - Post reported
- `community_support_request` - Support requested
**Surveys/Micro Measures (3 events):**
- `confidence_signal_submitted` - Confidence survey completed (understand_meaning_score, know_next_step_score, confidence_score)
- `helpfulness_survey_submitted` - Helpfulness rating submitted
- `milestone_checkin_submitted` - Milestone check-in completed
**System Metrics (5 events):**
- `session_started` - App session begins
- `session_ended` - App session ends
- `screen_view` - Screen/page viewed
- `notification_opened` - Notification tapped
- `notification_received` - Notification delivered
**Authentication / profile (instrumented in app for realtime summaries):**
- `sign_in_completed` - Successful sign-in (parameters: `method` — google, apple, email)
- `profile_updated` - Profile saved from edit profile screen
**C. Implementation Architecture:**
- **Flutter Analytics Service** (`lib/services/analytics_service.dart`) - Client-side service with helper methods for each event type
- **Dual Tracking System**:
- **Custom Firestore Analytics** - Cloud Function (`logAnalyticsEvent`) that:
- Validates events and features
- Generates anonymized user IDs (SHA-256 hash with salt)
- Extracts and enriches metadata with lifecycle context
- Writes to both `analytics_events` (anonymized) and `analytics_events_private` (admin-only)
- Tags callable-written rows with `source: cloud_function` (and `aggregationVersion`) so aggregation only counts mobile rows
- **Realtime mobile writes** (`lib/services/analytics/realtime_analytics_service.dart`) - After a successful callable log, the client also writes a full-schema `analytics_events` document with `source: mobile`, `aggregationVersion`, `dateKey` / `hourKey` / `monthKey`, `platform`, `environment`, `appVersion`, `clientTimestamp`, and mirrored copies under `technology_features/{featureId}/analytics_events` where applicable
- **Firebase Analytics (Standard Dashboard)** - Logs all events to Firebase Analytics dashboard for real-time insights and standard analytics reports
- **Event Parameters** - Each event includes feature-specific parameters (module_id, summary_id, provider_id, etc.) merged with lifecycle context
- **Session Management** - Session IDs persist for browser/app session duration
**E. Realtime aggregation (dashboard summaries):**
- **Trigger** - Cloud Function `onAnalyticsEventCreated` on `analytics_events/{eventId}` (region `us-central1`) updates atomic counters via merge + `FieldValue.increment`
- **Summary collections** (admin read-only in Firestore rules; written only by Functions):
- `analytics_summary/global` — e.g. `totalEvents`, `lastEventName`, first-class “today*” counters where mapped (posts, journal entries, visit summaries, birth plans, provider searches, sessions, screen views, profile updates, sign-ins)
- `analytics_summary_daily/{YYYY-MM-DD}` — `countsByEventName`, `countsByFeature`, plus mapped daily fields
- `analytics_feature_summary/{feature}` — per-feature totals and `countsByEventName`
- `analytics_summary_hourly/{YYYY-MM-DD-HH}` — optional hourly rollups
- **Admin UI** - Analytics page (`src/app/pages/Analytics.tsx`) can show a live banner from `analytics_summary/global` alongside existing callable `getAnalyticsData` results
- **Local dev** - Optional Firestore emulator: Flutter `--dart-define=USE_FIREBASE_EMULATOR=true` (see `docs/realtime-analytics.md`)
**D. Derived Metrics & Reports:**
The system supports calculation of outcome metrics for research:
- **Health Understanding Impact**: learning_module_completion_rate, visit_summary_usage_rate, birth_plan_completion_rate, confidence_signal_avg
- **Self Advocacy Confidence**: journal_frequency, visit_summary_documentation_rate, milestone_checkin_completion, helpfulness_rating, next_step_action_rate
- **Care Navigation Success**: provider_search_success_rate, provider_contact_rate, average_search_refinements, successful_provider_match_rate
- **Care Preparation**: birth_plan_completion_rate, learning_module_usage_pre_appointment, journal_usage_pre_milestone
- **Engagement Pathway**: Feature usage frequency, session frequency, modules completed, segmented by navigator/self_directed cohorts
- **Community Support**: peer_interaction_rate, support_request_rate, reply_rate, community_engagement_score
Events follow Firebase naming convention: `feature_action_object` (e.g., `learning_module_completed`, `provider_profile_viewed`).