/**
 * Analytics Service
 * Handles all analytics event tracking with user lifecycle context
 */

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/pregnancy_utils.dart';

/// Queued analytics event
class _QueuedEvent {
  final String eventName;
  final String feature;
  final Map<String, dynamic>? parameters;
  final int? durationMs;
  final UserProfile? userProfile;
  final DateTime queuedAt;
  int retryCount;

  _QueuedEvent({
    required this.eventName,
    required this.feature,
    this.parameters,
    this.durationMs,
    this.userProfile,
  })  : queuedAt = DateTime.now(),
        retryCount = 0;
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Use us-central1 region explicitly to match deployed functions
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
  String? _sessionId;
  
  // Event queue for when auth is not ready
  final List<_QueuedEvent> _eventQueue = [];
  bool _isFlushingQueue = false;
  bool _authReady = false;
  
  // TODO: App Check is currently failing for iOS app
  // Error: "App not registered: 1:725364003316:ios:f627cbea909c143e8229a1"
  // This is separate from auth race condition and should not block analytics queueing
  // To fix: Register iOS app in Firebase Console → App Check → Manage apps
  
  AnalyticsService._internal() {
    // Listen for auth state changes to flush queued events
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && !_authReady) {
        _authReady = true;
        _flushEventQueue();
      } else if (user == null) {
        _authReady = false;
      }
    });
  }
  
  /// Wait for initial auth resolution
  /// Returns the authenticated user once auth state is resolved, or null if not authenticated
  Future<User?> waitForInitialAuthResolution() async {
    // First check if user is already available with valid token
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Verify token is ready
        await currentUser.getIdToken();
        _authReady = true;
        return currentUser;
      } catch (e) {
        // Token not ready yet, wait for auth state change
        print('📊 Analytics: Token not ready, waiting for auth state...');
      }
    }
    
    // Wait for auth state to resolve (first event from stream)
    try {
      final resolvedUser = await FirebaseAuth.instance.authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
      
      if (resolvedUser != null) {
        try {
          // Verify token is ready
          await resolvedUser.getIdToken();
          _authReady = true;
          print('✅ Analytics: Auth resolved, token ready');
        } catch (e) {
          // Token still not ready, but user exists - mark as ready anyway
          // The function will handle token refresh
          _authReady = true;
          print('⚠️ Analytics: Auth resolved but token not ready yet: $e');
        }
      } else {
        print('📊 Analytics: Auth resolved - no authenticated user');
      }
      
      return resolvedUser;
    } catch (e) {
      // Timeout or error - return current user or null
      print('⚠️ Analytics: Auth resolution timeout/error: $e');
      final fallbackUser = FirebaseAuth.instance.currentUser;
      if (fallbackUser != null) {
        _authReady = true;
      }
      return fallbackUser;
    }
  }
  
  /// Flush queued events when auth becomes available
  Future<void> _flushEventQueue() async {
    if (_isFlushingQueue || _eventQueue.isEmpty) return;
    _isFlushingQueue = true;
    
    print('📊 Analytics: Flushing ${_eventQueue.length} queued events');
    
    final eventsToFlush = List<_QueuedEvent>.from(_eventQueue);
    _eventQueue.clear();
    
    for (final event in eventsToFlush) {
      try {
        await _sendEvent(
          eventName: event.eventName,
          feature: event.feature,
          parameters: event.parameters,
          durationMs: event.durationMs,
          userProfile: event.userProfile,
          status: 'sent (queued)',
        );
      } catch (e) {
        // If still failing, re-queue with retry limit
        if (event.retryCount < 3) {
          event.retryCount++;
          _eventQueue.add(event);
          print('📊 Analytics: [retrying] Re-queued event "${event.eventName}" (retry ${event.retryCount}/3)');
        } else {
          print('📊 Analytics: [dropped] Event "${event.eventName}" after 3 retries');
        }
      }
    }
    
    _isFlushingQueue = false;
    
    // If there are still events in queue (retries), try again after delay
    if (_eventQueue.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () => _flushEventQueue());
    }
  }

  /// Get or create session ID (persists for browser/app session)
  String getSessionId() {
    if (_sessionId == null) {
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString()}';
    }
    return _sessionId!;
  }

  String _generateRandomString() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(9, (index) => chars[(random + index) % chars.length]).join();
  }

  /// Get user lifecycle context from user profile
  Future<Map<String, dynamic>> getUserLifecycleContext(UserProfile? userProfile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Analytics: No authenticated user - returning empty context');
      return {
        'session_id': getSessionId(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    final context = <String, dynamic>{
      'user_id': user.uid,
      'session_id': getSessionId(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (userProfile != null) {
      // Calculate pregnancy week from due date
      int? pregnancyWeek;
      String? trimester;
      
      if (userProfile.dueDate != null && userProfile.isPregnant) {
        final now = DateTime.now();
        final dueDate = userProfile.dueDate!;
        final difference = dueDate.difference(now).inDays;
        pregnancyWeek = ((280 - difference) / 7).ceil();
        if (pregnancyWeek < 0) pregnancyWeek = 0;
        if (pregnancyWeek > 40) pregnancyWeek = 40;
        
        trimester = PregnancyUtils.calculateTrimester(userProfile.dueDate);
      } else if (userProfile.pregnancyStage != null) {
        // Try to extract trimester from pregnancyStage string
        final stage = userProfile.pregnancyStage!.toLowerCase();
        if (stage.contains('first')) {
          trimester = 'First Trimester';
        } else if (stage.contains('second')) {
          trimester = 'Second Trimester';
        } else if (stage.contains('third')) {
          trimester = 'Third Trimester';
        } else {
          trimester = userProfile.pregnancyStage;
        }
      }

      context['pregnancy_week'] = pregnancyWeek;
      context['trimester'] = trimester;
      
      // Optional fields - derive from profile or set defaults
      context['cohort_type'] = userProfile.hasPrimaryProvider ? 'navigator' : 'self_directed';
      context['navigator'] = userProfile.hasPrimaryProvider;
      context['self_directed'] = !userProfile.hasPrimaryProvider;
      
      // Postpartum phase
      if (userProfile.isPostpartum && userProfile.childAgeMonths != null) {
        if (userProfile.childAgeMonths! < 3) {
          context['postpartum_phase'] = 'early';
        } else if (userProfile.childAgeMonths! < 6) {
          context['postpartum_phase'] = 'mid';
        } else {
          context['postpartum_phase'] = 'late';
        }
      }
      
      // Provider selected (if they have a primary provider)
      context['provider_selected'] = userProfile.hasPrimaryProvider;
    }

    return context;
  }

  /// Log an analytics event with user lifecycle context
  /// Events are queued if auth is not ready, then sent when auth becomes available
  Future<void> logEvent({
    required String eventName,
    required String feature,
    Map<String, dynamic>? parameters,
    int? durationMs,
    UserProfile? userProfile,
  }) async {
    try {
      // Check if user is authenticated and auth is ready
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null || !_authReady) {
        // Queue event for later when auth is ready
        _eventQueue.add(_QueuedEvent(
          eventName: eventName,
          feature: feature,
          parameters: parameters,
          durationMs: durationMs,
          userProfile: userProfile,
        ));
        print('📊 Analytics: Queued event "$eventName" (auth not ready, ${_eventQueue.length} in queue)');
        return;
      }
      
      // Auth is ready, send immediately
      await _sendEvent(
        eventName: eventName,
        feature: feature,
        parameters: parameters,
        durationMs: durationMs,
        userProfile: userProfile,
        status: 'sent',
      );
    } catch (e) {
      // Best-effort: never crash the app
      print('⚠️ Analytics: Error queuing event "$eventName": $e');
    }
  }
  
  /// Internal method to actually send an event to Cloud Function
  Future<void> _sendEvent({
    required String eventName,
    required String feature,
    Map<String, dynamic>? parameters,
    int? durationMs,
    UserProfile? userProfile,
    required String status, // 'sent', 'sent (queued)', 'retrying'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('📊 Analytics: [$status] Event "$eventName" for feature "$feature"');
      print('📊 Analytics: User ID: ${user.uid}');
      
      // Force refresh auth token to ensure it's valid
      String? token;
      try {
        token = await user.getIdToken(true); // Force refresh
        if (token == null) {
          throw Exception('No token available');
        }
      } catch (e) {
        print('❌ Analytics: Token refresh failed: $e');
        throw Exception('Token refresh failed: $e');
      }
      
      // Get user lifecycle context
      final lifecycleContext = await getUserLifecycleContext(userProfile);
      
      // Merge parameters with lifecycle context
      final metadata = {
        ...lifecycleContext,
        ...(parameters ?? {}),
      };

      // Call Cloud Function
      final callable = _functions.httpsCallable(
        'logAnalyticsEvent',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      
      final result = await callable.call({
        'eventName': eventName,
        'feature': feature,
        'metadata': metadata,
        'durationMs': durationMs,
        'sessionId': getSessionId(),
      });
      
      // Only log success if function actually succeeded
      if (result.data != null && result.data['success'] != false) {
        print('✅ Analytics: [$status] Event "$eventName" logged successfully');
      } else {
        print('⚠️ Analytics: [$status] Event "$eventName" call returned unexpected result: ${result.data}');
        throw Exception('Function returned unexpected result');
      }
    } catch (e, stackTrace) {
      final errorString = e.toString().toLowerCase();
      
      // If unauthenticated error, queue for retry instead of failing
      if (errorString.contains('unauthenticated') || errorString.contains('permission')) {
        print('📊 Analytics: Retrying event "$eventName" (auth issue)');
        // Re-queue the event
        _eventQueue.add(_QueuedEvent(
          eventName: eventName,
          feature: feature,
          parameters: parameters,
          durationMs: durationMs,
          userProfile: userProfile,
        ));
        // Try to flush queue after a delay
        Future.delayed(const Duration(seconds: 2), () => _flushEventQueue());
        return;
      }
      
      // Log other errors but don't crash
      print('❌ Analytics: [$status] Error sending event "$eventName" (feature: "$feature"):');
      print('❌ Error: $e');
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        print('⚠️ Analytics: Cloud Function "logAnalyticsEvent" not found - may need deployment');
      } else if (errorString.contains('timeout') || errorString.contains('deadline')) {
        print('⚠️ Analytics: Request timeout - Cloud Function may be slow or unavailable');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        print('⚠️ Analytics: Service unavailable - check network connection');
      }
      
      // Don't throw - analytics shouldn't break the app
    }
  }

  // ========== Learning Modules Events ==========
  
  Future<void> logLearningModuleViewed({
    required String moduleId,
    String? moduleTopic,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_viewed',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleStarted({
    required String moduleId,
    String? moduleTopic,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_started',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleCompleted({
    required String moduleId,
    String? moduleTopic,
    int? timeSpentSeconds,
    String? completionStatus,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_completed',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (moduleTopic != null) 'module_topic': moduleTopic,
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
        if (completionStatus != null) 'completion_status': completionStatus,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleVideoPlayed({
    required String moduleId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_video_played',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleVideoCompleted({
    required String moduleId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_video_completed',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logLearningModuleQuizSubmitted({
    required String moduleId,
    int? quizScore,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'learning_module_quiz_submitted',
      feature: 'learning-modules',
      parameters: {
        'module_id': moduleId,
        if (quizScore != null) 'quiz_score': quizScore,
      },
      userProfile: userProfile,
    );
  }

  // ========== After Visit Summary Events ==========
  
  Future<void> logVisitSummaryCreated({
    required String summaryId,
    String? appointmentType,
    String? providerType,
    int? timeToComplete,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_created',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
        if (appointmentType != null) 'appointment_type': appointmentType,
        if (providerType != null) 'provider_type': providerType,
        if (timeToComplete != null) 'time_to_complete': timeToComplete,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryEdited({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_edited',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryExportedPdf({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_exported_pdf',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
        'exported': true,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummarySharedProvider({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_shared_provider',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
        'shared_with_provider': true,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logVisitSummaryVoiceNoteAdded({
    required String summaryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'visit_summary_voice_note_added',
      feature: 'appointment-summarizing',
      parameters: {
        'summary_id': summaryId,
      },
      userProfile: userProfile,
    );
  }

  // ========== Birth Plan Builder Events ==========
  
  Future<void> logBirthPlanStarted({
    String? templateId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_started',
      feature: 'birth-plan-generator',
      parameters: {
        if (templateId != null) 'template_id': templateId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanTemplateSelected({
    required String templateId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_template_selected',
      feature: 'birth-plan-generator',
      parameters: {
        'template_id': templateId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanCompleted({
    int? completionTime,
    int? sectionsCompleted,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_completed',
      feature: 'birth-plan-generator',
      parameters: {
        if (completionTime != null) 'completion_time': completionTime,
        if (sectionsCompleted != null) 'sections_completed': sectionsCompleted,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanUpdated({
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_updated',
      feature: 'birth-plan-generator',
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanSharedProvider({
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_shared_provider',
      feature: 'birth-plan-generator',
      parameters: {
        'shared': true,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logBirthPlanDownloadedPdf({
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'birth_plan_downloaded_pdf',
      feature: 'birth-plan-generator',
      userProfile: userProfile,
    );
  }

  // ========== Provider Search Events ==========
  
  Future<void> logProviderSearchInitiated({
    double? searchRadius,
    String? insuranceFilter,
    String? providerType,
    bool? telehealth,
    bool? acceptingNewPatients,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_search_initiated',
      feature: 'provider-search',
      parameters: {
        if (searchRadius != null) 'search_radius': searchRadius,
        if (insuranceFilter != null) 'insurance_filter': insuranceFilter,
        if (providerType != null) 'provider_type': providerType,
        if (telehealth != null) 'telehealth': telehealth,
        if (acceptingNewPatients != null) 'accepting_new_patients': acceptingNewPatients,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderFilterApplied({
    String? filterType,
    String? filterValue,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_filter_applied',
      feature: 'provider-search',
      parameters: {
        if (filterType != null) 'filter_type': filterType,
        if (filterValue != null) 'filter_value': filterValue,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderProfileViewed({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_profile_viewed',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderContactClicked({
    required String providerId,
    String? contactMethod,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_contact_clicked',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
        if (contactMethod != null) 'contact_method': contactMethod,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderSaved({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_saved',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logProviderReviewViewed({
    required String providerId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'provider_review_viewed',
      feature: 'provider-search',
      parameters: {
        'provider_id': providerId,
      },
      userProfile: userProfile,
    );
  }

  // ========== Journal Events ==========
  
  Future<void> logJournalEntryCreated({
    String? moodType,
    int? entryLength,
    String? reflectionType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_created',
      feature: 'journal',
      parameters: {
        if (moodType != null) 'mood_type': moodType,
        if (entryLength != null) 'entry_length': entryLength,
        if (reflectionType != null) 'reflection_type': reflectionType,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryUpdated({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_updated',
      feature: 'journal',
      parameters: {
        'entry_id': entryId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryDeleted({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_deleted',
      feature: 'journal',
      parameters: {
        'entry_id': entryId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logJournalMoodSelected({
    required String moodType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_mood_selected',
      feature: 'journal',
      parameters: {
        'mood_type': moodType,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logJournalEntryShared({
    required String entryId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'journal_entry_shared',
      feature: 'journal',
      parameters: {
        'entry_id': entryId,
      },
      userProfile: userProfile,
    );
  }

  // ========== Community Forums Events ==========
  
  Future<void> logCommunityPostCreated({
    String? topicCategory,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_created',
      feature: 'community',
      parameters: {
        if (topicCategory != null) 'topic_category': topicCategory,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostViewed({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_viewed',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityReplyCreated({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_reply_created',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostLiked({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_liked',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunityPostReported({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_post_reported',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logCommunitySupportRequest({
    required String threadId,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'community_support_request',
      feature: 'community',
      parameters: {
        'thread_id': threadId,
      },
      userProfile: userProfile,
    );
  }

  // ========== Surveys / Micro Measures Events ==========
  
  Future<void> logConfidenceSignalSubmitted({
    int? understandMeaningScore,
    int? knowNextStepScore,
    int? confidenceScore,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'confidence_signal_submitted',
      feature: 'user-feedback',
      parameters: {
        if (understandMeaningScore != null) 'understand_meaning_score': understandMeaningScore,
        if (knowNextStepScore != null) 'know_next_step_score': knowNextStepScore,
        if (confidenceScore != null) 'confidence_score': confidenceScore,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logHelpfulnessSurveySubmitted({
    int? helpfulnessRating,
    bool? tookNextStep,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'helpfulness_survey_submitted',
      feature: 'user-feedback',
      parameters: {
        if (helpfulnessRating != null) 'helpfulness_rating': helpfulnessRating,
        if (tookNextStep != null) 'took_next_step': tookNextStep,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logMilestoneCheckinSubmitted({
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'milestone_checkin_submitted',
      feature: 'user-feedback',
      userProfile: userProfile,
    );
  }

  // ========== System Metrics Events ==========
  
  Future<void> logSessionStarted({
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'session_started',
      feature: 'app',
      userProfile: userProfile,
    );
  }

  Future<void> logSessionEnded({
    int? durationSeconds,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'session_ended',
      feature: 'app',
      parameters: {
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      },
      durationMs: durationSeconds != null ? durationSeconds * 1000 : null,
      userProfile: userProfile,
    );
  }

  Future<void> logScreenView({
    required String screenName,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'screen_view',
      feature: 'app',
      parameters: {
        'screen_name': screenName,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logNotificationOpened({
    required String notificationId,
    String? notificationType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'notification_opened',
      feature: 'app',
      parameters: {
        'notification_id': notificationId,
        if (notificationType != null) 'notification_type': notificationType,
      },
      userProfile: userProfile,
    );
  }

  Future<void> logNotificationReceived({
    required String notificationId,
    String? notificationType,
    UserProfile? userProfile,
  }) async {
    await logEvent(
      eventName: 'notification_received',
      feature: 'app',
      parameters: {
        'notification_id': notificationId,
        if (notificationType != null) 'notification_type': notificationType,
      },
      userProfile: userProfile,
    );
  }
}
