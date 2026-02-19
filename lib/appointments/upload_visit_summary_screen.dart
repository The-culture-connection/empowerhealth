import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';

class UploadVisitSummaryScreen extends StatefulWidget {
  const UploadVisitSummaryScreen({super.key});

  @override
  State<UploadVisitSummaryScreen> createState() => _UploadVisitSummaryScreenState();
}

class _UploadVisitSummaryScreenState extends State<UploadVisitSummaryScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _selectedPDF;
  String? _pdfFileName;
  DateTime? _selectedDate;
  UserProfile? _userProfile;
  String? _generatedSummary;
  bool _isLoading = false;
  String? _currentStep; // Track current processing step
  double _uploadProgress = 0.0; // Track upload progress
  int _inputMethod = 0; // 0 = PDF, 1 = Manual text
  final TextEditingController _manualTextController = TextEditingController();
  bool _saveOriginalText = false; // Default: privacy-minimizing

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final privacySettings = doc.data()?['privacySettings'] ?? {};
        setState(() {
          _saveOriginalText = privacySettings['saveOriginalDocuments'] ?? false;
        });
      }
    } catch (e) {
      // Silently fail - use default
    }
  }

  @override
  void dispose() {
    _manualTextController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final profile = await _databaseService.getUserProfile(userId);
        setState(() {
          _userProfile = profile;
        });
      } catch (e) {
        // Silently fail - user profile is optional for visit summary
        if (mounted) {
          print('Warning: Could not load user profile: $e');
        }
      }
    }
  }

  Future<void> _pickPDF() async {
    try {
      print('📄 Opening file picker...');
      
      // On Android, use withData: true to get bytes directly (more reliable)
      // Add timeout to prevent hanging
      FilePickerResult? result;
      
      try {
        // Try with document picker first (better for Android 10+)
        // Use FileType.any on Android emulator as it's more reliable
        result = await FilePicker.platform.pickFiles(
          type: Platform.isAndroid ? FileType.any : FileType.custom,
          allowedExtensions: Platform.isAndroid ? null : ['pdf'],
          withData: true, // Load file data directly - more reliable on Android
          allowMultiple: false,
        ).timeout(
          const Duration(seconds: 60), // Increased timeout for emulator
          onTimeout: () {
            print('⏱️ File picker timed out after 60 seconds');
            throw TimeoutException('⏱️ File picker timed out. Please try again.');
          },
        );
        print('📄 File picker completed (first attempt)');
      } catch (e) {
        if (e is TimeoutException) {
          print('⏱️ Timeout: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('⏱️ File picker timed out. Please try again.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _pickPDF(),
                ),
              ),
            );
          }
          return;
        }
        print('❌ Error with custom file type: $e');
        print('📄 Trying fallback: any file type...');
        // Fallback: try picking any file
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            withData: true,
            allowMultiple: false,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏱️ File picker fallback timed out');
              throw TimeoutException('⏱️ File picker timed out. Please try again.');
            },
          );
          print('📄 File picker completed (fallback attempt)');
        } catch (e2) {
          if (e2 is TimeoutException) {
            print('⏱️ Fallback timeout: $e2');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('⏱️ File picker timed out. Please try again.'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _pickPDF(),
                  ),
                ),
              );
            }
            return;
          }
          print('❌ Fallback also failed: $e2');
          rethrow;
        }
      }

      print('📄 File picker returned: ${result != null}');
      print('📄 File picker result: ${result != null ? "File selected" : "Cancelled"}');
      
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        print('📄 Result files count: ${result.files.length}');
        print('📄 File name: ${pickedFile.name}');
        print('📄 File path: ${pickedFile.path}');
        print('📄 File size: ${pickedFile.size} bytes');
        print('📄 File extension: ${pickedFile.extension}');
        print('📄 Has bytes: ${pickedFile.bytes != null}');
        
        // Check if it's a PDF (more lenient check for Android)
        final fileName = pickedFile.name.toLowerCase();
        final extension = pickedFile.extension?.toLowerCase() ?? '';
        final isPdf = extension == 'pdf' || fileName.endsWith('.pdf');
        
        if (!isPdf) {
          print('❌ Selected file is not a PDF: $fileName (extension: $extension)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Please select a PDF file. Selected: ${pickedFile.name}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _pickPDF(),
                ),
              ),
            );
          }
          return;
        }
        
        File? finalFile;
        
        // Prefer using bytes (more reliable on Android)
        if (pickedFile.bytes != null) {
          print('📄 Saving file from bytes...');
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}');
          await tempFile.writeAsBytes(pickedFile.bytes!);
          finalFile = tempFile;
          print('📄 Temp file created: ${tempFile.path}');
        } else if (pickedFile.path != null) {
          print('📄 Using file path: ${pickedFile.path}');
          final file = File(pickedFile.path!);
          
          // Verify file exists
          if (await file.exists()) {
            finalFile = file;
            print('📄 File exists and verified');
          } else {
            print('❌ File does not exist at path: ${pickedFile.path}');
            throw Exception('Selected file does not exist. Please try again.');
          }
        } else {
          print('❌ Both file path and bytes are null!');
          throw Exception('Could not access file data. Please try selecting the file again.');
        }
        
        // Update state with the file
        if (finalFile != null) {
          setState(() {
            _selectedPDF = finalFile;
            _pdfFileName = pickedFile.name;
          });
          
          print('📄 State updated with PDF file: $_pdfFileName');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF selected: $_pdfFileName'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        print('📄 File picker cancelled by user or no file selected');
        // Don't show error for user cancellation - it's expected behavior
        // Only show message if it seems like an error occurred
      }
    } catch (e, stackTrace) {
      print('❌ Error selecting PDF: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting PDF: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _pickPDF(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _processPDF() async {
    if (_selectedPDF == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Please select both date and PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Please log in to upload files'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedSummary = null;
      _currentStep = '📤 Preparing upload...';
      _uploadProgress = 0.0;
    });

    try {
      print('📄 Starting PDF upload to Firebase Storage...');
      
      // Read PDF file
      setState(() => _currentStep = '📄 Reading PDF file...');
      final pdfBytes = await _selectedPDF!.readAsBytes();
      print('📄 PDF size: ${pdfBytes.length} bytes');

      // Create storage path: visit_summaries/{userId}/{timestamp}_{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = _pdfFileName ?? 'visit_summary.pdf';
      final storagePath = 'visit_summaries/$userId/$timestamp\_$fileName';
      
      // Create storage reference
      final storageRef = _storage.ref().child(storagePath);
      
      // Upload to Firebase Storage with progress tracking
      print('📤 Uploading file to Firebase Storage: $storagePath');
      setState(() => _currentStep = '📤 Uploading to cloud...');
      
      final uploadTask = storageRef.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'userId': userId,
            'appointmentDate': _selectedDate!.toIso8601String(),
            'fileName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
          _currentStep = '📤 Uploading... ${(progress * 100).toStringAsFixed(0)}%';
        });
      });

      // Wait for upload to complete
      final uploadSnapshot = await uploadTask;
      final downloadUrl = await uploadSnapshot.ref.getDownloadURL();
      
      print('✅ File uploaded successfully');
      print('📥 Download URL: $downloadUrl');

      // Save metadata to Firestore
      setState(() => _currentStep = '💾 Saving file information...');
      final uploadDocRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('file_uploads')
          .add({
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'appointmentDate': Timestamp.fromDate(_selectedDate!),
        'fileSize': pdfBytes.length,
        'status': 'uploaded',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ File metadata saved to Firestore with ID: ${uploadDocRef.id}');

      // Now analyze the PDF with OpenAI
      setState(() => _currentStep = '🤖 Analyzing PDF with AI... This may take a minute.');
      
      // Prepare user profile data for context
      final userProfileData = _userProfile != null ? {
        'pregnancyStage': _userProfile!.pregnancyStage,
        'trimester': _userProfile!.pregnancyStage,
        'concerns': [],
        'birthPlanPreferences': _userProfile!.birthPreference != null ? [_userProfile!.birthPreference!] : [],
        'culturalPreferences': [],
        'traumaInformedPreferences': [],
        'learningStyle': 'visual',
        'chronicConditions': _userProfile!.chronicConditions,
        'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
      } : null;

      // COMPREHENSIVE AUTH CHECK before calling function
      print('🔍 Pre-call auth check...');
      var currentUser = _auth.currentUser;
      
      // If user is null, wait for auth state (max 5 seconds)
      if (currentUser == null) {
        print('⚠️ User is null, waiting for auth state...');
        try {
          currentUser = await _auth.authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          print('❌ Auth state timeout: $e');
          // For testing: try anonymous sign-in
          if (kDebugMode) {
            print('🧪 Debug mode: Attempting anonymous sign-in for testing...');
            try {
              final cred = await _auth.signInAnonymously();
              currentUser = cred.user;
              print('✅ Anonymous sign-in successful: ${currentUser?.uid}');
            } catch (anonError) {
              print('❌ Anonymous sign-in failed: $anonError');
              throw Exception('🔒 Not signed in. Please log in before uploading PDFs.');
            }
          } else {
            throw Exception('🔒 Not signed in. Please log in before uploading PDFs.');
          }
        }
      }
      
      if (currentUser == null) {
        throw Exception('🔒 User session expired. Please log in again.');
      }
      
      // Force token refresh before calling function
      try {
        await currentUser.getIdToken(true);
        print('✅ Auth token refreshed');
      } catch (e) {
        print('⚠️ Token refresh warning: $e');
      }
      
      print('👤 Current user: ${currentUser.uid}');
      print('📅 Appointment date: ${_selectedDate!.toIso8601String()}');
      
      // Call Firebase Function to analyze PDF
      final analysisResult = await _functionsService.analyzeVisitSummaryPDF(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        appointmentDate: _selectedDate!.toIso8601String(),
        educationLevel: _userProfile?.educationLevel,
        userProfile: userProfileData,
      );

      print('✅ PDF analysis completed successfully');

      // Update upload status
      await uploadDocRef.update({
        'status': 'analyzed',
        'summaryId': analysisResult['summaryId'],
        'analyzedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _generatedSummary = analysisResult['summary'];
        _isLoading = false;
        _currentStep = null;
        _uploadProgress = 0.0;
        // Clear selected file to show success state
        _selectedPDF = null;
        _pdfFileName = null;
      });

      // Show success message with counts
      final todosCount = (analysisResult['todos'] as List?)?.length ?? 0;
      final modulesCount = (analysisResult['learningModules'] as List?)?.length ?? 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Analysis complete! ${todosCount > 0 ? "📝 $todosCount todos added. " : ""}${modulesCount > 0 ? "📚 $modulesCount learning modules created." : ""}'
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = null;
        _uploadProgress = 0.0;
      });
      
      if (mounted) {
        final errorMessage = e.toString();
        String userFriendlyMessage = errorMessage;
        
        // Provide user-friendly error messages with emojis
        final lowerMessage = errorMessage.toLowerCase();
        if (lowerMessage.contains('unable to resolve host') || 
            lowerMessage.contains('network') ||
            lowerMessage.contains('connection') ||
            lowerMessage.contains('unavailable') ||
            lowerMessage.contains('no address associated')) {
          userFriendlyMessage = '🌐 Network connection error. Please check your internet connection and try again.';
        } else if (lowerMessage.contains('permission') || lowerMessage.contains('unauthorized')) {
          userFriendlyMessage = '🔒 Permission denied. Please ensure you are logged in and try again.';
        } else if (lowerMessage.contains('quota') || lowerMessage.contains('storage')) {
          userFriendlyMessage = '💾 Storage quota exceeded. Please contact support.';
        } else if (lowerMessage.contains('cancel')) {
          userFriendlyMessage = '❌ Upload cancelled.';
        } else {
          userFriendlyMessage = '❌ Upload failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _processPDF(),
            ),
          ),
        );
      }
      
      print('❌ Upload error: $e');
    }
  }

  Future<void> _processManualText() async {
    if (_manualTextController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Please enter text and select date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Please log in to analyze visit notes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedSummary = null;
      _currentStep = '🤖 Analyzing your notes...';
    });

    try {
      final userText = _manualTextController.text.trim();
      
      // Prepare user profile data for context
      final userProfileData = _userProfile != null ? {
        'pregnancyStage': _userProfile!.pregnancyStage,
        'trimester': _userProfile!.pregnancyStage,
        'concerns': [],
        'birthPlanPreferences': _userProfile!.birthPreference != null ? [_userProfile!.birthPreference!] : [],
        'culturalPreferences': [],
        'traumaInformedPreferences': [],
        'learningStyle': 'visual',
        'chronicConditions': _userProfile!.chronicConditions,
        'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
      } : null;

      // Call Firebase Function to analyze manual text
      // Note: The function will handle redaction and analysis
      setState(() => _currentStep = '🔒 Securing your information...');
      
      final analysisResult = await _functionsService.analyzeVisitSummaryText(
        text: userText,
        appointmentDate: _selectedDate!.toIso8601String(),
        educationLevel: _userProfile?.educationLevel,
        userProfile: userProfileData,
        saveOriginalText: _saveOriginalText,
      );

      print('✅ Text analysis completed successfully');

      setState(() {
        _generatedSummary = analysisResult['summary'];
        _isLoading = false;
        _currentStep = null;
        // Clear text input to show success state
        if (!_saveOriginalText) {
          _manualTextController.clear();
        }
      });

      // Show success message
      final todosCount = (analysisResult['todos'] as List?)?.length ?? 0;
      final modulesCount = (analysisResult['learningModules'] as List?)?.length ?? 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Analysis complete! ${todosCount > 0 ? "📝 $todosCount todos added. " : ""}${modulesCount > 0 ? "📚 $modulesCount learning modules created." : ""}'
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = null;
      });
      
      if (mounted) {
        final errorMessage = e.toString();
        String userFriendlyMessage = errorMessage;
        
        final lowerMessage = errorMessage.toLowerCase();
        if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
          userFriendlyMessage = '🌐 Network connection error. Please check your internet connection and try again.';
        } else if (lowerMessage.contains('permission') || lowerMessage.contains('unauthorized')) {
          userFriendlyMessage = '🔒 Permission denied. Please ensure you are logged in and try again.';
        } else {
          userFriendlyMessage = '❌ Analysis failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _processManualText(),
            ),
          ),
        );
      }
      
      print('❌ Analysis error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Visit Summary'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Upload Your Visit Summary',
              style: AppTheme.responsiveTitleStyle(
                context,
                baseSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get an easy-to-understand summary of your appointment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Disclaimer banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, 
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This helps you understand your care. It doesn\'t replace a clinician. '
                      'For emergencies, call 911 or contact your provider immediately.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appointment Date Picker
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppTheme.brandPurple),
                title: const Text(
                  'Appointment Date',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                      : 'Tap to select date',
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Input Method Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How would you like to add your visit summary?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Upload PDF'),
                        icon: Icon(Icons.picture_as_pdf, size: 18),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Type Notes'),
                        icon: Icon(Icons.edit_note, size: 18),
                      ),
                    ],
                    selected: {_inputMethod},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _inputMethod = newSelection.first;
                        _selectedPDF = null;
                        _pdfFileName = null;
                        _manualTextController.clear();
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppTheme.brandPurple,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  if (_inputMethod == 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, 
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recommended for privacy. Your text won\'t be stored unless you choose to save it.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PDF Upload Section
            if (_inputMethod == 0 && _selectedPDF == null) ...[
              GestureDetector(
                onTap: _pickPDF,
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.brandPurple,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 80,
                        color: AppTheme.brandPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload Visit Summary PDF',
                        style: AppTheme.responsiveTitleStyle(
                          context,
                          baseSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to select PDF file from your device',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_inputMethod == 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.green, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pdfFileName ?? '',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedPDF = null;
                          _pdfFileName = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_inputMethod == 1) ...[
              // Manual Text Input Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type or paste your visit notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualTextController,
                      maxLines: 12,
                      decoration: InputDecoration(
                        hintText: 'Enter your visit summary, notes from your provider, test results, medications, or any other information from your appointment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Save my original text'),
                      subtitle: const Text(
                        'By default, only the AI summary is saved. Check this to also store your original notes.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _saveOriginalText,
                      onChanged: (value) {
                        setState(() {
                          _saveOriginalText = value ?? false;
                        });
                      },
                      activeColor: AppTheme.brandPurple,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Process Button (for both methods)
            if ((_inputMethod == 0 && _selectedPDF != null) || 
                (_inputMethod == 1 && _manualTextController.text.trim().isNotEmpty)) ...[
              ElevatedButton(
                onPressed: (_selectedDate != null && !_isLoading)
                    ? () => _inputMethod == 0 ? _processPDF() : _processManualText()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          if (_currentStep != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentStep!,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        'Upload Visit Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              
              // Show current step and progress below button if loading
              if (_isLoading && _currentStep != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentStep!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.brandPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadProgress > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppTheme.brandPurple.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Generated Summary Display
            if (_generatedSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your Visit Summary',
                            style: AppTheme.responsiveTitleStyle(
                              context,
                              baseSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Adjusted to ${_userProfile?.educationLevel ?? "6th grade"} reading level',
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    MarkdownBody(
                      data: _generatedSummary!,
                      styleSheet: MarkdownStyleSheet(
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPurple,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        p: const TextStyle(fontSize: 15, height: 1.6),
                        listBullet: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedSummary = null;
                    _selectedPDF = null;
                    _pdfFileName = null;
                    _selectedDate = null;
                  });
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Another File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brandPurple,
                  side: const BorderSide(color: AppTheme.brandPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

