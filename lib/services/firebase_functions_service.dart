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

  /// Removes one reply from a community post. Server verifies caller is the
  /// reply author or the post author. [replyId] is preferred; legacy clients
  /// may send [legacyContent] + [legacyCreatedAtSeconds] when [replyId] is absent.
  Future<void> deleteCommunityReply({
    required String postId,
    String? replyId,
    String? legacyContent,
    int? legacyCreatedAtSeconds,
  }) async {
    try {
      final payload = <String, dynamic>{'postId': postId};
      if (replyId != null && replyId.isNotEmpty) {
        payload['replyId'] = replyId;
      }
      if (legacyContent != null) {
        payload['legacyContent'] = legacyContent;
      }
      if (legacyCreatedAtSeconds != null) {
        payload['legacyCreatedAtSeconds'] = legacyCreatedAtSeconds;
      }
      await _functions.httpsCallable('deleteCommunityReply').call(payload);
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
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

  // Analyze manual text input (with redaction)
  Future<Map<String, dynamic>> analyzeVisitSummaryText({
    required String visitText,
    required String appointmentDate,
    String? educationLevel,
    Map<String, dynamic>? userProfile,
    bool saveOriginalText = false,
  }) async {
    try {
      print('🔵 Calling analyzeVisitSummaryText function...');
      print('🔵 Visit text length: ${visitText.length}');
      print('🔵 Appointment date: $appointmentDate');
      print('🔵 Save original text: $saveOriginalText');
      
      final callable = _functions.httpsCallable(
        'analyzeVisitSummaryText',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 300),
        ),
      );
      
      final result = await callable.call({
        'visitText': visitText,
        'appointmentDate': appointmentDate,
        'educationLevel': educationLevel,
        'userProfile': userProfile,
        'saveOriginalText': saveOriginalText,
      });
      
      print('✅ Function call successful');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ Error calling analyzeVisitSummaryText: $e');
      print('❌ Stack trace: $stackTrace');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Request timed out. Please try again.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      }
      
      throw Exception('❌ Failed to analyze visit notes: $e');
    }
  }

  // Search providers using Firebase function
  Future<Map<String, dynamic>> searchProviders({
    required String zip,
    required String city,
    required String healthPlan,
    required List<String> providerTypeIds,
    required int radius,
    String? specialty,
    bool includeNpi = false,
    bool? acceptsPregnantWomen,
    bool? acceptsNewborns,
    bool? telehealth,
  }) async {
    try {
      print('🔵 [FirebaseFunctions] Calling searchProviders function...');
      print('🔵 [FirebaseFunctions] ZIP: $zip, City: $city, Health Plan: $healthPlan');
      print('🔵 [FirebaseFunctions] Provider type IDs: $providerTypeIds');
      print('🔵 [FirebaseFunctions] Provider type IDs count: ${providerTypeIds.length}');
      print('🔵 [FirebaseFunctions] ProviderTypeIDsDelimited (will be): "${providerTypeIds.join(',')}"');
      print('🔵 [FirebaseFunctions] Radius: $radius, Include NPI: $includeNpi');
      
      // Build payload
      final payload = {
        'zip': zip,
        'city': city,
        'healthPlan': healthPlan,
        'providerTypeIds': providerTypeIds,
        'radius': radius,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        'includeNpi': includeNpi,
        if (acceptsPregnantWomen != null) 'acceptsPregnantWomen': acceptsPregnantWomen,
        if (acceptsNewborns != null) 'acceptsNewborns': acceptsNewborns,
        if (telehealth != null) 'telehealth': telehealth,
      };
      
      print('🔵 [FirebaseFunctions] Full payload: ${payload.toString()}');
      print('🔵 [FirebaseFunctions] Payload providerTypeIds type: ${providerTypeIds.runtimeType}');
      print('🔵 [FirebaseFunctions] Payload providerTypeIds value: ${payload['providerTypeIds']}');
      print('🔵 [FirebaseFunctions] ProviderTypeIDsDelimited in payload: "${(payload['providerTypeIds'] as List).join(',')}"');
      
      final callable = _functions.httpsCallable(
        'searchProviders',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );
      
      final result = await callable.call(payload);
      
      print('✅ [FirebaseFunctions] searchProviders call successful');
      print('✅ [FirebaseFunctions] Found ${result.data['count']} providers');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ [FirebaseFunctions] Error calling searchProviders: $e');
      print('❌ [FirebaseFunctions] Stack trace: $stackTrace');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Request timed out. Please try again.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      }
      
      throw Exception('❌ Failed to search providers: $e');
    }
  }

  // OhioMaximusSearch - Builds the correct Ohio Medicaid API URL from user inputs
  Future<Map<String, dynamic>> ohioMaximusSearch({
    required String zip,
    required String radius,
    String? city,
    required String healthPlan,
    required dynamic providerType, // Can be String or List<String>
    String state = "OH",
  }) async {
    try {
      print('🔵 [FirebaseFunctions] Calling OhioMaximusSearch function...');
      print('🔵 [FirebaseFunctions] ZIP: $zip, Radius: $radius, City: $city');
      print('🔵 [FirebaseFunctions] Health Plan: $healthPlan');
      print('🔵 [FirebaseFunctions] Provider Type: $providerType');
      print('🔵 [FirebaseFunctions] State: $state');
      
      final payload = {
        'zip': zip,
        'radius': radius.toString(),
        if (city != null && city.isNotEmpty) 'city': city,
        'healthPlan': healthPlan,
        'providerType': providerType,
        'state': state,
      };
      
      print('🔵 [FirebaseFunctions] Full payload: ${payload.toString()}');
      
      final callable = _functions.httpsCallable(
        'OhioMaximusSearch',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      
      final result = await callable.call(payload);
      
      print('✅ [FirebaseFunctions] OhioMaximusSearch call successful');
      print('✅ [FirebaseFunctions] Generated URL: ${result.data['url']}');
      print('✅ [FirebaseFunctions] Parameters: ${result.data['parameters']}');
      
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ [FirebaseFunctions] Error calling OhioMaximusSearch: $e');
      print('❌ [FirebaseFunctions] Stack trace: $stackTrace');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || errorString.contains('deadline exceeded')) {
        throw Exception('⏱️ Request timed out. Please try again.');
      } else if (errorString.contains('unavailable') || errorString.contains('unreachable')) {
        throw Exception('🌐 Service temporarily unavailable. Please try again in a few moments.');
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        throw Exception('🔒 Permission denied. Please ensure you are logged in.');
      }
      
      throw Exception('❌ Failed to generate Ohio Maximus URL: $e');
    }
  }

  // Admin function to add or update a provider manually (backend only)
  Future<Map<String, dynamic>> addProvider({
    required String name,
    String? specialty,
    String? practiceName,
    String? npi,
    List<Map<String, dynamic>>? locations,
    List<String>? providerTypes,
    List<String>? specialties,
    String? phone,
    String? email,
    String? website,
    bool mamaApproved = false,
    List<Map<String, dynamic>>? identityTags,
    bool? acceptsPregnantWomen,
    bool? acceptsNewborns,
    bool? telehealth,
  }) async {
    try {
      print('🔵 [FirebaseFunctions] Calling addProvider function...');
      
      final callable = _functions.httpsCallable(
        'addProvider',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      
      final result = await callable.call({
        'name': name,
        if (specialty != null) 'specialty': specialty,
        if (practiceName != null) 'practiceName': practiceName,
        if (npi != null) 'npi': npi,
        if (locations != null) 'locations': locations,
        if (providerTypes != null) 'providerTypes': providerTypes,
        if (specialties != null) 'specialties': specialties,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        'mamaApproved': mamaApproved,
        if (identityTags != null) 'identityTags': identityTags,
        if (acceptsPregnantWomen != null) 'acceptsPregnantWomen': acceptsPregnantWomen,
        if (acceptsNewborns != null) 'acceptsNewborns': acceptsNewborns,
        if (telehealth != null) 'telehealth': telehealth,
      });
      
      print('✅ [FirebaseFunctions] addProvider call successful');
      return result.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      print('❌ [FirebaseFunctions] Error calling addProvider: $e');
      print('❌ [FirebaseFunctions] Stack trace: $stackTrace');
      throw Exception('❌ Failed to add provider: $e');
    }
  }
}


