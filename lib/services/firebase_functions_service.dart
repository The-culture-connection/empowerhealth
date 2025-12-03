import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Generate AI-powered learning module content
  Future<Map<String, dynamic>> generateLearningContent({
    required String topic,
    required String trimester,
    required String moduleType,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateLearningContent').call({
        'topic': topic,
        'trimester': trimester,
        'moduleType': moduleType,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate learning content: $e');
    }
  }

  // Summarize appointment/visit notes
  Future<Map<String, dynamic>> summarizeVisitNotes({
    required String visitNotes,
    String? providerInstructions,
    String? medications,
    String? diagnoses,
    String? emotionalFlags,
  }) async {
    try {
      final result = await _functions.httpsCallable('summarizeVisitNotes').call({
        'visitNotes': visitNotes,
        'providerInstructions': providerInstructions,
        'medications': medications,
        'diagnoses': diagnoses,
        'emotionalFlags': emotionalFlags,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to summarize visit notes: $e');
    }
  }

  // Generate personalized birth plan
  Future<Map<String, dynamic>> generateBirthPlan({
    required Map<String, dynamic> preferences,
    String? medicalHistory,
    String? concerns,
    String? supportPeople,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateBirthPlan').call({
        'preferences': preferences,
        'medicalHistory': medicalHistory,
        'concerns': concerns,
        'supportPeople': supportPeople,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate birth plan: $e');
    }
  }

  // Generate appointment checklist
  Future<Map<String, dynamic>> generateAppointmentChecklist({
    required String appointmentType,
    required String trimester,
    String? concerns,
    String? lastVisit,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateAppointmentChecklist').call({
        'appointmentType': appointmentType,
        'trimester': trimester,
        'concerns': concerns,
        'lastVisit': lastVisit,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate appointment checklist: $e');
    }
  }

  // Analyze emotional content
  Future<Map<String, dynamic>> analyzeEmotionalContent({
    String? journalEntry,
    String? visitNotes,
  }) async {
    try {
      final result = await _functions.httpsCallable('analyzeEmotionalContent').call({
        'journalEntry': journalEntry,
        'visitNotes': visitNotes,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to analyze emotional content: $e');
    }
  }

  // Generate "Know Your Rights" content
  Future<Map<String, dynamic>> generateRightsContent({
    required String topic,
    String? state,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateRightsContent').call({
        'topic': topic,
        'state': state,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate rights content: $e');
    }
  }

  // Simplify text to 6th grade level
  Future<Map<String, dynamic>> simplifyText({
    required String text,
    String? context,
  }) async {
    try {
      final result = await _functions.httpsCallable('simplifyText').call({
        'text': text,
        'context': context,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to simplify text: $e');
    }
  }
}

