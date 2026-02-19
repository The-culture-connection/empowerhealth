import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

class FirebaseFunctionsService {
  // Use default instance - functions will auto-detect their region
  // This matches how the working birth plan function is called
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Verify project ID matches
  String get _projectId {
    try {
      return Firebase.app().options.projectId ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Generate AI-powered learning module content
  Future<Map<String, dynamic>> generateLearningContent({
    required String topic,
    required String trimester,
    required String moduleType,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateLearningContent').call({
        'topic': topic,
        'trimester': trimester,
        'moduleType': moduleType,
        'userProfile': userProfile,
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

  // Analyze PDF directly with OpenAI (no text extraction) - NEW FUNCTION NAME
  Future<Map<String, dynamic>> analyzeVisitSummaryPDF({
    required String storagePath,
    required String downloadUrl,
    required String appointmentDate,
    String? educationLevel,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      // COMPREHENSIVE AUTH CHECK - Method 1: Ensure user is actually signed in
      print('🔍 Step 1: Checking authentication state...');
      var user = _auth.currentUser;
      
      // If user is null, wait for auth state to be ready
      if (user == null) {
        print('⚠️ User is null, waiting for auth state...');
        try {
          user = await _auth.authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 5));
          print('✅ Auth state received: ${user?.uid}');
        } catch (e) {
          print('❌ Auth state timeout or error: $e');
          throw Exception('🔒 Not signed in. Please log in before analyzing PDFs.');
        }
      }
      
      if (user == null) {
        throw Exception('🔒 Not signed in. Please log in before analyzing PDFs.');
      }
      
      // Log auth details
      print('👤 AUTH user: ${user.uid} / ${user.email ?? "no email"}');
      
      // COMPREHENSIVE AUTH CHECK - Method 2: Verify project ID matches
      print('🔍 Step 2: Verifying Firebase project configuration...');
      final projectId = _projectId;
      print('📦 Project ID: $projectId');
      if (projectId != 'empower-health-watch') {
        throw Exception('⚠️ Project ID mismatch! Expected: empower-health-watch, Got: $projectId. Function calls will fail.');
      }
      print('✅ Project ID matches: empower-health-watch');
      
      // COMPREHENSIVE AUTH CHECK - Method 3: Force token refresh
      print('🔍 Step 3: Refreshing authentication token...');
      String? token;
      try {
        token = await user.getIdToken(true); // Force refresh
        print('🔑 AUTH token present: ${token != null} (${token?.length ?? 0} chars)');
        if (token == null) {
          throw Exception('🔒 Could not obtain authentication token. Please log in again.');
        }
      } catch (e) {
        print('❌ Token refresh failed: $e');
        throw Exception('🔒 Authentication token error. Please log in again.');
      }
      
      print('🤖 Starting PDF analysis with OpenAI...');
      print('👤 User ID: ${user.uid}');
      print('📄 Storage path: $storagePath');
      
      // Use default instance - same as birth plan function
      print('🔍 Step 4: Setting up function call...');
      print('📞 Calling Firebase Function: analyzeVisitSummaryPDF');
      print('🔐 Auth state: ${_auth.currentUser != null ? "Authenticated as ${_auth.currentUser!.uid}" : "Not authenticated"}');
      
      // Use default instance - matches how generateBirthPlan works
      final callable = _functions.httpsCallable(
        'analyzeVisitSummaryPDF',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 300),
        ),
      );
      
      print('📤 Sending request with auth token...');
      final result = await callable.call({
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'appointmentDate': appointmentDate,
        'educationLevel': educationLevel,
        'userProfile': userProfile,
      });
      
      print('✅ PDF analysis completed successfully');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ Error analyzing PDF: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Provide user-friendly error messages with emojis
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Analysis timed out. The PDF may be too large. Please try again.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      } else if (errorString.contains('ai') || errorString.contains('openai')) {
        throw Exception('🤖 AI analysis failed. Please try again in a moment.');
      }
      
      throw Exception('❌ Failed to analyze PDF: $e');
    }
  }

  // Analyze manual text input (privacy-safe pathway)
  Future<Map<String, dynamic>> analyzeVisitSummaryText({
    required String text,
    required String appointmentDate,
    String? educationLevel,
    Map<String, dynamic>? userProfile,
    bool saveOriginalText = false,
  }) async {
    try {
      // Auth check
      var user = _auth.currentUser;
      if (user == null) {
        user = await _auth.authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5));
      }
      
      if (user == null) {
        throw Exception('🔒 Not signed in. Please log in before analyzing text.');
      }

      final callable = _functions.httpsCallable(
        'analyzeVisitSummaryText',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 300),
        ),
      );

      final result = await callable.call({
        'text': text,
        'appointmentDate': appointmentDate,
        'educationLevel': educationLevel,
        'userProfile': userProfile,
        'saveOriginalText': saveOriginalText,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('❌ Failed to analyze text: $e');
    }
  }

  // Upload file to Firebase Storage and trigger analysis
  Future<Map<String, dynamic>> uploadVisitSummaryFile({
    required String fileName,
    required Uint8List fileData,
    required String appointmentDate,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      print('📤 Starting file upload to Firebase Storage...');
      
      // Convert file data to base64
      final base64Data = base64.encode(fileData);
      
      final callable = _functions.httpsCallable(
        'uploadVisitSummaryFile',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120), // 2 minute timeout for upload
        ),
      );
      
      final result = await callable.call({
        'fileName': fileName,
        'fileData': base64Data,
        'appointmentDate': appointmentDate,
        'userProfile': userProfile,
      });
      
      print('✅ File uploaded successfully');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ Error uploading file: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Provide user-friendly error messages with emojis
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Upload timed out. Please check your connection and try again.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      } else if (errorString.contains('quota') || errorString.contains('storage')) {
        throw Exception('💾 Storage quota exceeded. Please contact support.');
      } else if (errorString.contains('invalid') && errorString.contains('file')) {
        throw Exception('❌ Invalid file type. Please upload a PDF file.');
      }
      
      // Extract error message from Firebase error if available
      if (errorString.contains('pdf text is required')) {
        throw Exception('📄 Could not extract text from PDF. The file might be image-based or encrypted.');
      } else if (errorString.contains('appointment date')) {
        throw Exception('📅 Appointment date is required.');
      }
      
      throw Exception('❌ Upload failed: ${e.toString()}');
    }
  }

  // Check upload status
  Future<Map<String, dynamic>> checkUploadStatus({
    required String uploadId,
    required String userId,
  }) async {
    try {
      // This would query Firestore to check the upload status
      // For now, we'll use a simple implementation
      // You may want to add a dedicated function for this
      return {'status': 'processing'};
    } catch (e) {
      throw Exception('❌ Failed to check upload status: $e');
    }
  }

  // Summarize after-visit PDF (kept for backward compatibility)
  Future<Map<String, dynamic>> summarizeAfterVisitPDF({
    required String pdfText,
    required String appointmentDate,
    String? educationLevel,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      print('🔵 Calling summarizeAfterVisitPDF function...');
      print('🔵 PDF text length: ${pdfText.length}');
      print('🔵 Appointment date: $appointmentDate');
      
      final callable = _functions.httpsCallable(
        'summarizeAfterVisitPDF',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 300), // 5 minute timeout for large PDFs
        ),
      );
      
      final result = await callable.call({
        'pdfText': pdfText,
        'appointmentDate': appointmentDate,
        'educationLevel': educationLevel,
        'userProfile': userProfile,
      });
      
      print('✅ Function call successful');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ Error calling summarizeAfterVisitPDF: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Provide more specific error messages with emojis
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Request timed out. The PDF may be too large. Please try with a smaller PDF or contact support.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      } else if (errorString.contains('not found') || errorString.contains('404')) {
        throw Exception('❌ Function not found. Please contact support.');
      } else if (errorString.contains('ai') || errorString.contains('openai')) {
        throw Exception('🤖 AI analysis failed. Please try again in a moment.');
      }
      
      throw Exception('❌ Failed to summarize PDF: $e');
    }
  }
}


