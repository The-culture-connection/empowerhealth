/// Realtime analytics (Firestore `analytics_events`) — constants aligned with
/// [docs/mobile-analytics-inventory.md](../../docs/mobile-analytics-inventory.md).

/// Pipeline version written on mobile-originated events; aggregation trigger only
/// processes docs with matching [RealtimeAnalyticsConfig.mobileSource] value.
const int kRealtimeAnalyticsAggregationVersion = 1;

/// Value for `source` on client-written `analytics_events` (aggregated).
const String kMobileAnalyticsSource = 'mobile';

/// Value set by Cloud Function `logAnalyticsEvent` (not aggregated — avoids double count).
const String kCloudFunctionAnalyticsSource = 'cloud_function';

/// Backend feature IDs (must match Cloud Function allowlist).
const Set<String> kValidFeatureIds = {
  'provider-search',
  'authentication-onboarding',
  'user-feedback',
  'appointment-summarizing',
  'journal',
  'learning-modules',
  'birth-plan-generator',
  'community',
  'profile-editing',
  'app',
};

/// Event names referenced in the inventory / AnalyticsService (for docs and dashboards).
abstract class InventoryEventNames {
  static const sessionStarted = 'session_started';
  static const sessionEnded = 'session_ended';
  static const featureSessionStarted = 'feature_session_started';
  static const featureSessionEnded = 'feature_session_ended';
  static const screenView = 'screen_view';
  static const notificationOpened = 'notification_opened';
  static const notificationReceived = 'notification_received';

  static const providerSearchInitiated = 'provider_search_initiated';
  static const providerFilterApplied = 'provider_filter_applied';
  static const providerProfileViewed = 'provider_profile_viewed';
  static const providerContactClicked = 'provider_contact_clicked';
  static const providerSaved = 'provider_saved';
  static const providerReviewViewed = 'provider_review_viewed';
  static const providerReviewSubmitted = 'provider_review_submitted';
  static const providerSelectedSuccess = 'provider_selected_success';

  static const learningModuleViewed = 'learning_module_viewed';
  static const learningModuleStarted = 'learning_module_started';
  static const learningModuleCompleted = 'learning_module_completed';
  /// Learning modules use surveys (not quizzes). See `survey_context` on events.
  static const learningModuleSurveySubmitted = 'learning_module_survey_submitted';

  static const visitSummaryCreated = 'visit_summary_created';
  static const visitSummaryViewed = 'visit_summary_viewed';
  static const birthPlanCompleted = 'birth_plan_completed';
  static const birthPlanViewed = 'birth_plan_viewed';
  static const birthPlanExported = 'birth_plan_exported';
  static const journalEntryCreated = 'journal_entry_created';
  static const journalMoodSelected = 'journal_mood_selected';
  static const communityPostCreated = 'community_post_created';
  static const communityPostReplied = 'community_post_replied';
  static const communityPostLiked = 'community_post_liked';
  static const microMeasureSubmitted = 'micro_measure_submitted';
  static const screenTimeSpent = 'screen_time_spent';
  static const featureTimeSpent = 'feature_time_spent';
  static const flowAbandoned = 'flow_abandoned';
}
