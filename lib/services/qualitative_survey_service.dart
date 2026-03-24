/**
 * Qualitative Survey Service
 * Handles saving qualitative surveys to Firestore subcollection
 * technology_features/{featureId}/qualitative_surveys/{surveyId}
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_profile.dart';
import 'database_service.dart';
import 'analytics_service.dart';

class QualitativeSurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  /// Map feature names to technology feature IDs
  String _getTechnologyFeatureId(String feature) {
    const mapping = {
      'appointment-summarizing': 'appointment-summarizing',
      'authentication-onboarding': 'authentication-onboarding',
      'birth-plan-generator': 'birth-plan-generator',
      'community': 'community',
      'journal': 'journal',
      'learning-modules': 'learning-modules',
      'profile-editing': 'profile-editing',
      'provider-search': 'provider-search',
      'user-feedback': 'user-feedback',
      'app': 'app',
    };
    return mapping[feature] ?? feature;
  }

  /// Get anonymized user ID (same logic as AnalyticsService)
  Future<String> _getAnonUserId(String userId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final userDoc = await userDocRef.get();

    if (userDoc.exists && userDoc.data() != null && userDoc.data()!['anonUserId'] != null) {
      return userDoc.data()!['anonUserId'] as String;
    } else {
      // Generate a deterministic anonUserId using SHA-256 hash of UID + salt
      const salt = 'empowerhealth-analytics-salt';
      final bytes = utf8.encode('$userId-$salt');
      final digest = sha256.convert(bytes);
      final anonUserId = digest.toString();

      // Save to user profile for future use
      await userDocRef.set({'anonUserId': anonUserId}, SetOptions(merge: true));
      return anonUserId;
    }
  }

  /// Get user lifecycle context
  Future<Map<String, dynamic>> _getUserLifecycleContext(UserProfile? userProfile) async {
    if (userProfile == null) {
      return {};
    }

    final context = <String, dynamic>{};

    // Cohort type
    if (userProfile.hasPrimaryProvider != null && userProfile.hasPrimaryProvider!) {
      context['cohortType'] = 'navigator';
      context['navigator'] = true;
      context['self_directed'] = false;
    } else {
      context['cohortType'] = 'self_directed';
      context['navigator'] = false;
      context['self_directed'] = true;
    }

    // Pregnancy week and trimester
    if (userProfile.dueDate != null) {
      final now = DateTime.now();
      final dueDate = userProfile.dueDate!;
      final weeksSinceLMP = (now.difference(dueDate.subtract(const Duration(days: 280))).inDays / 7).round();
      final gestationalWeek = weeksSinceLMP.clamp(0, 42);
      
      context['gestationalWeek'] = gestationalWeek;
      
      if (gestationalWeek < 13) {
        context['trimester'] = 'First';
      } else if (gestationalWeek < 27) {
        context['trimester'] = 'Second';
      } else if (gestationalWeek < 42) {
        context['trimester'] = 'Third';
      } else {
        context['trimester'] = 'Postpartum';
      }
    }

    return context;
  }

  /// Save qualitative survey to Firestore
  /// 
  /// [feature] - Feature name (e.g., 'birth-plan-generator', 'community')
  /// [questions] - List of question-answer pairs: [{'question': string, 'answer': int (1-5)}]
  /// [userProfile] - Optional user profile for lifecycle context
  /// [sourceId] - Optional source ID (e.g., moduleId, planId, postId)
  Future<void> saveQualitativeSurvey({
    required String feature,
    required List<Map<String, dynamic>> questions,
    UserProfile? userProfile,
    String? sourceId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        print('⚠️ QualitativeSurvey: Cannot save survey without authenticated user ID.');
        return;
      }

      final anonUserId = await _getAnonUserId(userId);
      final lifecycleContext = await _getUserLifecycleContext(userProfile);
      final technologyFeatureId = _getTechnologyFeatureId(feature);
      final sessionId = AnalyticsService().getSessionId();

      final surveyData = {
        'userId': userId,
        'anonUserId': anonUserId,
        'feature': feature,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': sessionId,
        'cohortType': lifecycleContext['cohortType'],
        'gestationalWeek': lifecycleContext['gestationalWeek'],
        'trimester': lifecycleContext['trimester'],
        'questions': questions,
        if (sourceId != null) 'sourceId': sourceId,
      };

      // Save to technology_features/{featureId}/qualitative_surveys subcollection
      await _firestore
          .collection('technology_features')
          .doc(technologyFeatureId)
          .collection('qualitative_surveys')
          .add(surveyData);

      print('✅ QualitativeSurvey: Survey saved to technology_features/$technologyFeatureId/qualitative_surveys');
    } catch (e) {
      print('❌ QualitativeSurvey: Error saving survey: $e');
      rethrow;
    }
  }
}
