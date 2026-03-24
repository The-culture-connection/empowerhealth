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

The **admin dashboard** (web) uses Firebase email/password sign-in. Dashboard access is granted only when the signed-in user has a role document in Firestore: `ADMIN` (full access), `RESEARCH_PARTNERS` (anonymized data views), or `COMMUNITY_MANAGERS` (content and messaging). Only **admins** may assign or revoke roles from the Users & Roles page. New role holders must already have a mobile app profile (`users` collection, matched by email); otherwise onboarding shows an error asking the admin to ensure the person has registered in the app first.

### How the feature works
- **Mobile app**: Sign-up, sign-in, password reset, onboarding, and care survey flows behave as before; user profiles live under `users/{uid}`.
- **Admin dashboard sign-in**: `signInWithEmailAndPassword` runs first; `onAuthStateChanged` then sets `loading` to true until Firestore role resolution finishes (`ADMIN` / `RESEARCH_PARTNERS` / `COMMUNITY_MANAGERS` by uid, with email fallback). The login page waits for that resolution before redirecting, so users are not sent to protected routes with `userProfile` still null (fixes the previous “click Sign In twice” behavior).
- **Route guards**: `RoleRoute` shows a loading state while auth is resolving, and also if a Firebase session exists but the profile object is not yet hydrated.
- **Users & Roles (admin only)**: Admin enters the person’s email and picks a role. The dashboard first looks up `users` by email; if there is no Firestore profile yet, it calls the Cloud Function **`lookupAuthUserByEmail`** (Admin SDK) so users who exist in **Firebase Authentication** but not yet in `users` can still receive a role. If neither resolves, the UI explains that no account was found. On success, it writes the role document with **document id = that user’s uid** to the correct collection (`ADMIN`, `RESEARCH_PARTNERS`, or `COMMUNITY_MANAGERS`) and records an `audit_logs` entry.

### Change History
- **2024-12-14** - **xyz789abc** - **Biometric authentication**: Added support for fingerprint and face recognition login for faster access.
- **2024-12-08** - **mno321pqr** - **Onboarding improvements**: Streamlined the onboarding flow to reduce completion time by 30%.
- **2025-03-23** - **528a0258** - **Sign-in analytics**: On successful Google, Apple, or email sign-in, the app logs `sign_in_completed` (feature `authentication-onboarding`) for the realtime analytics pipeline.
- **2026-03-24** - **admindash-auth-roles** - **Admin dashboard auth & Users & Roles**: Stabilized login (redirect only after role resolution), tightened `RoleRoute` loading for session edge cases, and restricted role onboarding to admins with a required `users` profile lookup before writing role documents.
- **2026-03-24** - **admindash-lookup-auth** - **Auth-based role onboarding**: Added callable `lookupAuthUserByEmail` and client `findUserForRoleAssignment` so admins can assign roles using Firebase Auth accounts even when no `users/{uid}` document exists yet; fixed duplicate React keys on the Users & Roles table.
- **2026-03-24** - **admindash-role-list-keys** - **Users & Roles table**: Normalized `getUsersByRole` so `uid` and `role` always come from the document id and collection when legacy role documents omit those fields (fixes `undefined-undefined` React keys).

---

## 3. User Feedback

### Current Functionality
The User Feedback system encompasses two main components: Care Check-in surveys and Learning Module reviews. Care Check-in allows users to provide feedback about their healthcare experiences, including questions about care quality, communication, and satisfaction. Learning Module reviews enable users to rate and review educational content, providing ratings for understanding, next steps clarity, and confidence levels. This feedback is aggregated to improve content quality and track user engagement with educational materials.

### Change History
- **2024-12-13** - **uvw456rst** - **Feedback analytics dashboard**: Added real-time analytics for care check-in responses to help identify trends.
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 4. Appointment Summarizing

### Current Functionality
The Appointment Summarizing feature (After Visit Summary) allows users to upload PDF visit summaries or enter text notes from medical appointments. The system uses AI to process and summarize these documents, extracting key information, medications, recommendations, and next steps. Summaries are simplified to a 6th-grade reading level for accessibility. Users can view, edit, and manage their visit summaries, which are stored securely and can be referenced for future appointments or shared with other healthcare providers.

### Change History
- **2024-12-13** - **uvw456rst** - **Feedback analytics dashboard**: Added real-time analytics for care check-in responses to help identify trends.
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 5. Journal

### Current Functionality
The Journal feature provides users with a private space to record thoughts, experiences, and notes related to their healthcare journey. Users can create journal entries with text content, attach files or images, and organize entries by date. The journal supports emotional content analysis to identify significant moments or areas of confusion. Entries are stored securely and can be searched, filtered, and reviewed over time to track progress and patterns.

### Change History
- *No changes tracked yet*
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 6. Learning Modules

### Current Functionality
The Learning Modules feature provides educational content tailored to users' needs and pregnancy/postpartum journey. Modules cover topics such as pregnancy health, postpartum care, patient rights, and self-advocacy. Content is generated using AI to ensure it's at a 6th-grade reading level and culturally appropriate. Users can complete modules, track progress, receive personalized recommendations, and provide feedback. The system includes task management for learning goals and tracks completion rates and engagement metrics.

### Change History
- *No changes tracked yet*
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 7. Birth Plan Generator

### Current Functionality
The Birth Plan Generator helps users create personalized birth plans by guiding them through preferences for labor, delivery, and postpartum care. Users can specify preferences for pain management, delivery positions, who should be present, feeding preferences, and postpartum care. The system uses AI to generate comprehensive birth plans based on user inputs, which can be exported as PDFs and shared with healthcare providers. Plans can be updated as preferences change and are stored securely for reference.

### How the feature works
After a plan is generated and saved to the `birth_plans` collection, the app can show a qualitative feedback dialog (`QualitativeSurveyDialog`). Submissions are stored under `technology_features/birth-plan-generator/qualitative_surveys` (Firestore rules must allow authenticated users to **create** documents there; deploy uses `admindash/firestore.rules`, which must include the same `qualitative_surveys` subcollection rules as the root rules file).

### Change History
- *No changes tracked yet*
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.
- **2026-03-24** - **rules-qual-surveys** - **Firestore qualitative surveys**: Aligned `admindash/firestore.rules` with root rules so `technology_features/{featureId}/qualitative_surveys` allows authenticated mobile creates (fixes permission errors when submitting birth plan completion feedback).

---

## 8. Community

### Current Functionality
The Community feature provides a forum where users can share experiences, ask questions, and support each other. Users can create posts, reply to others' posts, like content, and report inappropriate material. Posts are organized by topics and can be searched. The community fosters peer support and information sharing while maintaining moderation capabilities. Users can engage in discussions about pregnancy, postpartum, healthcare experiences, and related topics in a safe, supportive environment.

### Change History
- *No changes tracked yet*
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 9. Profile Editing

### Current Functionality
The Profile Editing feature allows users to manage their account information, preferences, and settings. Users can update their display name, email, profile picture, and personal information. The system includes privacy settings, notification preferences, and account management options. Users can view their activity history, manage connected accounts, and control data sharing preferences. Profile changes are tracked for audit purposes and synced across the platform.

### Change History
- **2025-03-23** - **528a0258** - **Profile save analytics**: On successful profile save from the edit profile screen, the app logs `profile_updated` (feature `profile-editing`) for the realtime analytics pipeline.
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.

---

## 10. Analytics and Event Tracking

### Current Functionality
The Analytics and Event Tracking system provides comprehensive tracking of user interactions and app usage patterns across all platform features. The system tracks 30+ distinct events covering Learning Modules, After Visit Summary, Birth Plan Builder, Provider Search, Journal, Community Forums, Surveys/Micro Measures, and System Metrics. Events flow through two complementary paths: (1) **callable analytics** — a Cloud Function (`logAnalyticsEvent`) that handles anonymization server-side and writes to `analytics_events` (anonymized) and `analytics_events_private` (admin-only); (2) **realtime mobile pipeline** — the Flutter app writes enriched documents to `analytics_events` with `source: mobile`, time keys, platform, app version, and sanitized metadata, then a **Firestore trigger** (`onAnalyticsEventCreated`) aggregates into summary documents for dashboards without scanning raw events. The trigger **skips** `source: cloud_function` rows so totals are not double-counted when both paths write for the same user action. The admin dashboard can subscribe to `analytics_summary/global` for live totals alongside existing callable `getAnalyticsData` queries. The system generates unique session IDs for each app session and automatically attaches user lifecycle context (user_id, cohort_type, navigator, self_directed, pregnancy_week, trimester, session_id, timestamp) to every event for cohort analysis and research outcomes. Reference docs: `docs/analytics-system-overview.md` (full system summary), `docs/mobile-analytics-inventory.md` (event inventory and gaps), `docs/realtime-analytics.md` (schema and deployment notes).

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
- `learning_module_survey_submitted` - One of two **surveys** (not quizzes): `survey_context` = `qualitative_feedback` (module detail qualitative dialog) or `module_archive_gate` (dialog before archiving)

**After Visit Summary (6 events):**
- `visit_summary_created` - New summary uploaded/created
- `visit_summary_viewed` - User opened an existing summary from the list (`summary_id`)
- `visit_summary_edited` - Summary modified
- `visit_summary_exported_pdf` - PDF export generated
- `visit_summary_shared_provider` - Summary shared with provider
- `visit_summary_voice_note_added` - Voice note attached

**Birth Plan Builder (8 events):**
- `birth_plan_started` - Plan creation initiated
- `birth_plan_template_selected` - Template chosen
- `birth_plan_completed` - Plan finalized
- `birth_plan_updated` - Plan modified
- `birth_plan_viewed` - Saved plan opened on display screen
- `birth_plan_exported` - Plan shared via system share sheet (`export_type`: `pdf_share` | `text_share`)
- `birth_plan_shared_provider` - Plan shared with provider (dedicated flow; helper when wired)
- `birth_plan_downloaded_pdf` - PDF downloaded (legacy helper name)

**Provider Search (7 events):**
- `provider_search_initiated` - Search started
- `provider_filter_applied` - Filter used
- `provider_profile_viewed` - Profile detail viewed
- `provider_contact_clicked` - Contact action taken
- `provider_saved` - Provider favorited
- `provider_review_viewed` - Review read
- `provider_review_submitted` - User submitted a new review

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
- **Session Management** - Session IDs persist for browser/app session duration; `session_ended` is logged after persisting duration to `user_sessions`, then in-memory session state is cleared so the `session_ended` event keeps the same `sessionId` as `session_started`. **App lifecycle**: background (`paused`) ends the session; returning from background starts a new session (`session_started` with `entry_point: app_resume`). **Feature lifecycle**: `feature_session_started` / `feature_session_ended` bracket time in a feature surface; main tabs emit these when switching tabs (`entry_source: main_tab`), and key flows wrap `FeatureSessionScope` (auth screens, provider search hub + entry, visit summary upload, birth plan builder, care navigation survey) with ref-counting so nested provider routes share one logical session.

**E. Realtime aggregation (dashboard summaries):**
- **Trigger** - Cloud Function `onAnalyticsEventCreated` on `analytics_events/{eventId}` (region `us-central1`) updates atomic counters via merge + `FieldValue.increment`
- **Summary collections** (admin read-only in Firestore rules; written only by Functions):
  - `analytics_summary/global` — e.g. `totalEvents`, `lastEventName`, first-class “today*” counters where mapped (posts, journal entries, visit summaries, birth plans, provider searches, sessions, screen views, profile updates, sign-ins)
  - `analytics_summary_daily/{YYYY-MM-DD}` — `countsByEventName`, `countsByFeature`, plus mapped daily fields
  - `analytics_feature_summary/{feature}` — per-feature totals and `countsByEventName`
  - `analytics_summary_hourly/{YYYY-MM-DD-HH}` — optional hourly rollups
- **Admin UI** - Analytics page (`src/app/pages/Analytics.tsx`) now follows the Figma analytics layout using **real data from `analytics_events`** with date-range filtering (`7d`, `30d`, `90d`, `all`) and optional feature filter. The page no longer has anonymized/unanonymized tabs; it presents one holistic dashboard (overview metrics, feature table, funnels, trends, community, mood, outcomes, abandonment, screen-time) plus a CSV export for raw rows in the selected range.
- **Export shape** - "Export Data" downloads rows with: `eventName`, `feature`, `duration` (`durationMs`), `timestamp`, and `source`.
- **Holistic report + dictionary UI** - Analytics now includes a single “User Journey + Outcome Effectiveness” report block (executive summary, cohort segmentation, funnel, feature effectiveness, engagement depth, outcome metrics, behavior correlations, and recommendations) for both anonymized and unanonymized tabs. A dedicated subpage `/analytics/info` documents tracked events and what user behavior each event measures.
- **Analytics Info (by feature)** - The `/analytics/info` page lists events **per backend feature id** in lifecycle order: **Lifecycle — start** (`feature_session_started` or tab/session entry), **Action** (feature-specific events), **Lifecycle — end** (`feature_session_ended` or tab exit). Status remains `Tracked` / `Partial` / `Needs Implementation` with implementation notes.
- **Learning/Community instrumentation reliability** - `learning_module_completed` is now emitted from list-based "done/archive" actions in Learning Modules (not only detail-screen exits), and `community_post_liked` / `community_post_replied` now still emit even when profile hydration fails (best-effort profile, fallback null).
- **Technology Overview updates feed** - The "Latest Updates" feed (`src/app/pages/TechnologyOverview.tsx`) merges top-level `recentUpdates` with each feature's `change_history` entries, sorts by newest timestamp first, and supports expanding from the initial 10-row preview to all available updates.
- **Commit detail "Feature changes"** - When viewing a commit from the Technology Overview commit list, associated rows are resolved from `technology_features/{id}/change_history` by matching the real Git SHA from `commits` to each entry's `version` (7-char prefix set on publish), normalized SHA prefixes, optional `commitSha` from FEATURES.md, and `releaseBuildNumber` when the dossier path wrote entries without a Git SHA (`commitMatchesChangeHistoryEntry` in `src/lib/features.ts`).
- **Technology area navigation** - The admin Technology hub (`TechnologyLayout.tsx`) no longer includes a separate "System Reliability" tab or `/technology/system-status` route; the main sidebar entry for System Status (which pointed at a non-existent path) was removed for consistency.
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
- **2026-03-24** - **e7496270** - **Debug content seed**: Added test feature update payload for dashboard propagation verification.
- **2026-03-23** - **local20260323** - **Latest Updates feed expansion**: Updated Technology Overview to remove hard 10-item truncation in data assembly, keep newest-first ordering, and add a clickable "Show all updates / Show fewer updates" toggle so admins can view the full update stream.
- **2026-03-24** - **commit-feature-changes** - **Commit detail feature changes**: Fixed Technology Overview commit modal so "Feature changes" populates by matching Firestore `change_history` to the selected commit (version prefix, SHA normalization, release build) and scanning all `technology_features` docs, not only visible ones.
- **2026-03-24** - **admin-tech-nav** - **Technology hub navigation**: Removed the System Reliability sub-tab, `/technology/system-status` route, and `SystemStatus.tsx` page; updated Technology header copy; removed broken main-nav "System Status" link.
- **2026-03-24** - **admindash-analytics-ui** - **Admin Analytics page & callables**: Migrated `getAnalyticsData`, `getFeatureAnalytics`, `generateReport`, `uploadBuildVersion`, `processFeatureChanges`, and `runHealthCheckNow` to Firebase callable `CallableRequest` (`request.auth`) so Gen-2 functions stop returning false "User must be authenticated". Added `avgDurationMs` to `getAnalyticsData`, ISO-serialized date ranges from the client, token refresh before callables, and wired `Analytics.tsx` to real charts from `analytics_summary_daily`, `analytics_feature_summary`, and 30-day event rollups.
- **2026-03-24** - **admindash-holistic-report** - **Journey + Outcome report and Analytics Info page**: Replaced the second analytics chart with a holistic report panel (cohorts, funnel, outcomes, recommendations), added `/analytics/info` event glossary page, expanded analytics payload to return `holisticReport` and `eventCounts`, and added required event names (`provider_selected_success`, `screen_time_spent`, `feature_time_spent`, `community_post_replied`, `community_post_liked`, `learning_module_completed`, `flow_abandoned`) to dashboard analytics typings/documentation.
- **2026-03-24** - **mobile-analytics-wiring** - **Runtime event instrumentation**: Wired the missing holistic-report events in Flutter (`provider_selected_success`, `screen_time_spent`, `feature_time_spent`, `community_post_replied`, `community_post_liked`, `learning_module_completed`, `flow_abandoned`) by instrumenting provider selection, tab dwell time, feature dwell time, community interactions, and learning-module exit behavior.
- **2026-03-24** - **analytics-figma-rebuild** - **Figma-matched analytics page + export**: Rebuilt `Analytics.tsx` to match the Figma analytics page using real Firestore event data, removed anonymized/unanonymized toggle UI, added date-range + feature filters, and implemented CSV export with `eventName`, `feature`, `durationMs`, `timestamp`, and `source` for all events in range.
- **2026-03-24** - **analytics-info-status-update** - **Analytics event implementation statuses**: Updated `/analytics/info` to replace the old “New Required” state with explicit `Tracked` / `Partial` / `Needs Implementation` statuses and added per-event implementation notes to reflect actual runtime wiring.
- **2026-03-24** - **analytics-mobile-instrumentation-fixes** - **Module completion + community engagement tracking**: Added `learning_module_completed` logging to Learning Modules list completion/archive flows and hardened `community_post_liked` / `community_post_replied` logging to avoid being skipped when user profile lookup fails.
- **2026-03-24** - **analytics-session-feature-lifecycle** - **Session end + feature_session_* + Analytics Info layout**: Fixed `session_ended` to log duration from `endSession()` before clearing session id, emit `session_ended` on app background and auth-wrapper dispose, restart session on resume; added `logFeatureSessionStarted` / `logFeatureSessionEnded`, `FeatureSessionScope` (ref-counted) on auth, provider search, visit summary upload, birth plan builder, and care survey; main navigation emits feature session start/end per tab. Rebuilt `/analytics/info` into per-feature sections ordered lifecycle start → actions → lifecycle end.
- **2026-03-24** - **analytics-system-overview-doc** - **Architecture documentation**: Added `docs/analytics-system-overview.md` describing the entire analytical tracking stack (client paths, callable vs mobile Firestore, aggregation trigger, collections, admin surfaces, security, and key file references).
- **2026-03-24** - **analytics-event-expansion-20260324** - **New tracked events**: Added `provider_review_submitted`, `visit_summary_viewed`, `learning_module_survey_submitted` (replacing quiz naming; two survey contexts), `birth_plan_viewed`, and `birth_plan_exported` (PDF/text share on display screen). Wired Flutter instrumentation; updated `/analytics/info` and analytics docs.

