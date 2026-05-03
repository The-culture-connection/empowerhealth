import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/research/research_firestore_service.dart';
import '../models/user_profile.dart';
import '../research/post_visit_summary_rating_modal.dart';
import '../cors/ui_theme.dart';
import '../widgets/ai_disclaimer_banner.dart';
import '../widgets/feature_session_scope.dart';
import '../privacy/after_visit_privacy_screen.dart';
import 'visit_date_utils.dart';

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
  String _inputMethod = 'pdf'; // 'pdf' or 'text'
  /// Research `avs_upload_type` slug for the next successful AVS analysis (PDF vs gallery image).
  String _avsUploadResearchSlug = 'unknown';
  final TextEditingController _manualTextController = TextEditingController();
  bool _saveOriginalText = false; // Default: don't save raw text

  @override
  void initState() {
    super.initState();
    _trackScreenView();
    _loadUserProfile();
    _checkConsentAndShowPrivacyScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowAfterVisitTransparency();
    });
  }

  static const _transparencyPrefsKey = 'after_visit_transparency_v1';

  Future<void> _maybeShowAfterVisitTransparency() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_transparencyPrefsKey) == true) return;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
                boxShadow: AppTheme.shadowMedium(opacity: 0.12, blur: 32, y: 10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.spa_outlined, color: Color(0xFFD4A574), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'How After-Visit Support works',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We simplify the language in paperwork or notes you choose to share. '
                    'We don’t diagnose or tell you what to do medically — your care team does that.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AfterVisitPrivacyScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Your privacy (plain language)',
                      style: TextStyle(
                        color: AppTheme.brandPurple,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await prefs.setBool(_transparencyPrefsKey, true);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('I understand'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Transparency dialog: $e');
    }
  }

  Future<void> _trackScreenView() async {
    try {
      final analytics = AnalyticsService();
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'upload_visit_summary',
          feature: 'appointment-summarizing',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking visit summary screen view: $e');
    }
  }

  Future<void> _checkConsentAndShowPrivacyScreen() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final hasConsent = await _databaseService.userHasConsent(userId);
    if (!hasConsent && mounted) {
      // Show consent screen (not first run, so it will pop back)
      final result = await Navigator.of(context).pushNamed('/consent');
      // If user accepted, refresh the screen state if needed
      if (result == true && mounted) {
        // User has now given consent, continue with the screen
      }
    }
  }

  void _showAIDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('AI Features Disabled'),
        content: const Text(
          'AI features are disabled. Go to settings to enable this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to main tab view
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/privacy-center');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  /// Split AI markdown on `## ` headings so we can show NewUI-style section cards.
  List<MapEntry<String?, String>> _splitMarkdownByH2(String md) {
    final lines = md.split('\n');
    final chunks = <MapEntry<String?, String>>[];
    String? currentTitle;
    final buf = StringBuffer();
    void flush() {
      final text = buf.toString().trim();
      buf.clear();
      if (text.isEmpty && currentTitle == null) return;
      chunks.add(MapEntry(currentTitle, text));
      currentTitle = null;
    }

    for (final line in lines) {
      if (line.startsWith('## ')) {
        flush();
        currentTitle = line.substring(3).trim();
      } else {
        buf.writeln(line);
      }
    }
    flush();
    if (chunks.isEmpty && md.trim().isNotEmpty) {
      return [MapEntry(null, md.trim())];
    }
    return chunks;
  }

  /// Use the real `##` heading from the model output. (Older code used fixed
  /// labels by index, so every block after the third became "Questions You May Want to Ask".)
  String _cardLabelForSummaryChunk(
    MapEntry<String?, String> chunk,
    int index,
    int total,
  ) {
    final fromMd = chunk.key?.trim();
    if (fromMd != null && fromMd.isNotEmpty) {
      return fromMd;
    }
    if (total <= 1) return 'In simpler words';
    if (index == 0) return 'In simpler words';
    return 'More from your visit';
  }

  List<Widget> _buildVisitSummarySections(BuildContext context) {
    final chunks = _splitMarkdownByH2(_generatedSummary!);
    final nonEmpty = chunks.where((c) => c.value.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return [];

    final out = <Widget>[];
    for (var i = 0; i < nonEmpty.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 16));
      out.add(
        _visitSummarySectionCard(
          label: _cardLabelForSummaryChunk(nonEmpty[i], i, nonEmpty.length),
          body: nonEmpty[i].value.trim(),
          showReadingLevel: i == 0,
        ),
      );
    }
    return out;
  }

  Widget _visitSummarySectionCard({
    required String label,
    required String body,
    bool showReadingLevel = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.07, blur: 20, y: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPurple.withOpacity(0.88),
            ),
          ),
          if (showReadingLevel) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.brandPurple.withOpacity(0.85)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adjusted toward ${_userProfile?.educationLevel ?? "6th grade"} reading level where possible.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          MarkdownBody(
            data: body,
            styleSheet: MarkdownStyleSheet(
              h2: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              p: const TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w300),
              listBullet: TextStyle(fontSize: 15, color: AppTheme.brandPurple.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _manualTextController.dispose();
    super.dispose();
  }

  Future<void> _maybePromptVisitSummaryMicroMeasure(String contentId, String contentType) async {
    final p = _userProfile;
    if (p == null || !p.isResearchParticipant || !mounted) return;
    final sid = await ResearchFirestoreService.instance.ensureStudyId(p);
    if (!mounted || sid == null) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PostVisitSummaryRatingModal(
        studyId: sid,
        contentId: contentId,
        contentType: contentType,
      ),
    );
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

  /// One page, image scaled to fill the page (visit paperwork photos).
  Future<File> _imageBytesToTempPdf(Uint8List bytes, String baseName) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final bitmap = PdfBitmap(bytes);
    final pageSize = page.getClientSize();
    page.graphics.drawImage(
      bitmap,
      Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );
    final List<int> out = await document.save();
    document.dispose();
    final dir = await getTemporaryDirectory();
    final safe = baseName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    final file = File(
      '${dir.path}/visit_img_${DateTime.now().millisecondsSinceEpoch}_$safe.pdf',
    );
    await file.writeAsBytes(out);
    return file;
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
          allowedExtensions: Platform.isAndroid
              ? null
              : ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
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
                  textColor: AppTheme.brandWhite,
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
                    textColor: AppTheme.brandWhite,
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
        final isImage = [
              'jpg',
              'jpeg',
              'png',
              'heic',
              'webp',
            ].contains(extension) ||
            fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.heic') ||
            fileName.endsWith('.webp');

        if (!isPdf && !isImage) {
          print('❌ Unsupported file: $fileName (extension: $extension)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please choose a PDF or a photo (JPG, PNG, HEIC, WebP). Selected: ${pickedFile.name}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: AppTheme.brandWhite,
                  onPressed: () => _pickPDF(),
                ),
              ),
            );
          }
          return;
        }

        late final File finalFile;
        String displayName = pickedFile.name;

        if (isImage) {
          Uint8List? imageBytes = pickedFile.bytes;
          if (imageBytes == null && pickedFile.path != null) {
            final f = File(pickedFile.path!);
            if (await f.exists()) {
              imageBytes = await f.readAsBytes();
            }
          }
          if (imageBytes == null) {
            throw Exception(
              'Could not read image data. Please try selecting the file again.',
            );
          }
          finalFile = await _imageBytesToTempPdf(imageBytes, pickedFile.name);
          displayName = '${pickedFile.name} (as PDF)';
        } else {
          // PDF — prefer bytes (more reliable on Android)
          if (pickedFile.bytes != null) {
            print('📄 Saving file from bytes...');
            final tempDir = await getTemporaryDirectory();
            final tempFile = File(
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}',
            );
            await tempFile.writeAsBytes(pickedFile.bytes!);
            finalFile = tempFile;
            print('📄 Temp file created: ${tempFile.path}');
          } else if (pickedFile.path != null) {
            print('📄 Using file path: ${pickedFile.path}');
            final file = File(pickedFile.path!);

            if (await file.exists()) {
              finalFile = file;
              print('📄 File exists and verified');
            } else {
              print('❌ File does not exist at path: ${pickedFile.path}');
              throw Exception('Selected file does not exist. Please try again.');
            }
          } else {
            print('❌ Both file path and bytes are null!');
            throw Exception(
              'Could not access file data. Please try selecting the file again.',
            );
          }
        }

        setState(() {
          _selectedPDF = finalFile;
          _pdfFileName = displayName;
          _avsUploadResearchSlug = isImage ? 'image_gallery' : 'pdf';
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
              textColor: AppTheme.brandWhite,
              onPressed: () => _pickPDF(),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _checkAIFeaturesBeforeProcessing() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    
    final aiEnabled = await _databaseService.areAIFeaturesEnabled(userId);
    if (!aiEnabled) {
      _showAIDisabledDialog();
      return false;
    }
    return true;
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

    // Check if AI features are enabled - this will show dialog and return false if disabled
    final canProceed = await _checkAIFeaturesBeforeProcessing();
    if (!canProceed) {
      return; // Dialog already shown, stop processing
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
            'appointmentDate': visitAppointmentCalendarKey(_selectedDate!),
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
        'appointmentDate': visitAppointmentFirestoreTimestamp(_selectedDate!),
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
      print(
        '📅 Appointment date (calendar): ${visitAppointmentCalendarKey(_selectedDate!)}',
      );

      // Call Firebase Function to analyze PDF
      final analysisResult = await _functionsService.analyzeVisitSummaryPDF(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        appointmentDate: visitAppointmentCalendarKey(_selectedDate!),
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

      // Track visit summary creation
      try {
        final analytics = AnalyticsService();
        final summaryId = analysisResult['summaryId'] as String?;
        if (summaryId != null) {
          await analytics.logVisitSummaryCreated(
            summaryId: summaryId,
            timeToComplete: DateTime.now().difference(_selectedDate ?? DateTime.now()).inSeconds,
            userProfile: _userProfile,
            avsUploadType: _avsUploadResearchSlug,
          );
        }
      } catch (e) {
        print('Error tracking visit summary creation: $e');
      }

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

      final avsSummaryId = analysisResult['summaryId'] as String?;
      if (avsSummaryId != null && avsSummaryId.isNotEmpty) {
        await _maybePromptVisitSummaryMicroMeasure(avsSummaryId, 'visit_summary_avs');
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
              textColor: AppTheme.brandWhite,
              onPressed: () => _processPDF(),
            ),
          ),
        );
      }
      
      print('❌ Upload error: $e');
    }
  }

  Future<void> _processManualText() async {
    if (_selectedDate == null || _manualTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Please select date and enter visit notes'),
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

    // Check if AI features are enabled - this will show dialog and return false if disabled
    final canProceed = await _checkAIFeaturesBeforeProcessing();
    if (!canProceed) {
      return; // Dialog already shown, stop processing
    }

    setState(() {
      _isLoading = true;
      _generatedSummary = null;
      _currentStep = '🤖 Analyzing visit notes...';
    });

    try {
      final visitText = _manualTextController.text.trim();
      
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

      // Call Firebase Function to analyze text (with redaction)
      // The function already saves to Firestore, so we don't need to save again
      final analysisResult = await _functionsService.analyzeVisitSummaryText(
        visitText: visitText,
        appointmentDate: visitAppointmentCalendarKey(_selectedDate!),
        educationLevel: _userProfile?.educationLevel,
        userProfile: userProfileData,
        saveOriginalText: _saveOriginalText,
      );

      // Note: The Cloud Function already saves the summary to Firestore
      // We only need to handle the response for display

      setState(() {
        _generatedSummary = analysisResult['summary'];
        _isLoading = false;
        _currentStep = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis complete!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }

      final textSummaryId = analysisResult['summaryId'] as String?;
      if (textSummaryId != null && textSummaryId.isNotEmpty) {
        try {
          await AnalyticsService().logVisitSummaryCreated(
            summaryId: textSummaryId,
            userProfile: _userProfile,
            avsUploadType: 'notes_typed',
          );
        } catch (e) {
          print('Error tracking visit summary creation (text): $e');
        }
        await _maybePromptVisitSummaryMicroMeasure(textSummaryId, 'visit_summary_avs');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'appointment-summarizing',
      entrySource: 'upload_visit_summary',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        body: Stack(
          children: [
            Positioned(
              top: -60,
              right: MediaQuery.sizeOf(context).width * 0.2,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD4A574).withOpacity(0.22),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.sizeOf(context).height * 0.15,
              left: -60,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB899D4).withOpacity(0.16),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chevron_left,
                                  size: 22,
                                  color: AppTheme.textMuted,
                                ),
                                Text(
                                  'My Visits',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.3,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'After-Visit Support',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: -0.32,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Doctor visits can be overwhelming. We’re here to help you understand paperwork in plain language — after-visit summaries, discharge instructions, provider notes, and similar documents. This is literacy support, not a diagnosis.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const AfterVisitPrivacyScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Your privacy (plain language)',
                              style: TextStyle(
                                color: AppTheme.brandPurple,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF5EEE0),
                                Color(0xFFFAF8F4),
                                Color(0xFFEBE0D6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.borderLight.withOpacity(0.4),
                            ),
                            boxShadow: AppTheme.shadowSoft(
                              opacity: 0.08,
                              blur: 20,
                              y: 4,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF5EEE0),
                                      Color(0xFFEBE0D6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFD4A574),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'We help simplify the documents you share',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.05,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This tool makes medical language easier to understand. It does not provide medical advice, diagnoses, or replace your healthcare provider.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'APPOINTMENT DATE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandPurple.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.borderLight.withOpacity(0.45),
                                ),
                                boxShadow: AppTheme.shadowSoft(
                                  opacity: 0.06,
                                  blur: 16,
                                  y: 3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.brandPurple.withOpacity(0.12),
                                          AppTheme.brandPurple.withOpacity(0.06),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppTheme.brandPurple.withOpacity(0.9),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _selectedDate != null
                                          ? MaterialLocalizations.of(context)
                                              .formatFullDate(_selectedDate!)
                                          : 'Tap to select date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                        color: _selectedDate != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textLight,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: AppTheme.textLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _MethodPill(
                                selected: _inputMethod == 'pdf',
                                icon: Icons.upload_file_rounded,
                                label: 'From file',
                                useGoldWhenSelected: true,
                                onTap: () =>
                                    setState(() => _inputMethod = 'pdf'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MethodPill(
                                selected: _inputMethod == 'text',
                                icon: Icons.text_fields_rounded,
                                label: 'Type notes',
                                useGoldWhenSelected: false,
                                onTap: () =>
                                    setState(() => _inputMethod = 'text'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_inputMethod == 'text')
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFBBDDF0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: Colors.blue.shade800,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Recommended for privacy: your text won\'t be stored unless you choose to save it.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

            // PDF Upload Section
            if (_inputMethod == 'pdf' && _selectedPDF == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.borderLight.withOpacity(0.55),
                    width: 2,
                  ),
                  boxShadow: AppTheme.shadowSoft(
                    opacity: 0.06,
                    blur: 20,
                    y: 4,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB899D4), Color(0xFF9D7AB8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB899D4).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        size: 40,
                        color: AppTheme.brandWhite,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PDF or image file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.05,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a PDF or image (JPG, PNG, HEIC, WebP) from Files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GradientActionButton(
                          icon: Icons.description_outlined,
                          label: 'Choose file',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF663399),
                              Color(0xFF7744AA),
                              Color(0xFF8855BB),
                            ],
                          ),
                          onPressed: _pickPDF,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'After-visit summaries, discharge paperwork, and provider notes work well. Remove sensitive information you do not want analyzed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ),
            ] else if (_inputMethod == 'pdf') ...[
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
                          _avsUploadResearchSlug = 'unknown';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Process Button
              ElevatedButton(
                onPressed: (_selectedDate != null && !_isLoading)
                    ? _processPDF
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: AppTheme.brandWhite,
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandWhite),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600                      ),
                    ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.borderLight.withOpacity(0.45),
                  ),
                  boxShadow: AppTheme.shadowSoft(
                    opacity: 0.06,
                    blur: 20,
                    y: 4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _manualTextController,
                      maxLines: 10,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w300,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type or paste your visit notes here...',
                        hintStyle: TextStyle(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w300,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppTheme.borderLight.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppTheme.borderLight.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppTheme.brandPurple.withOpacity(0.45),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Save my original text',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'By default, only the summary is saved. Check this to also save your original notes.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _saveOriginalText,
                      onChanged: (value) =>
                          setState(() => _saveOriginalText = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final canRun = _selectedDate != null &&
                            _manualTextController.text.trim().isNotEmpty &&
                            !_isLoading;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canRun ? _processManualText : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: canRun
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF663399),
                                          Color(0xFF7744AA),
                                          Color(0xFF8855BB),
                                        ],
                                      )
                                    : null,
                                color: canRun
                                    ? null
                                    : AppTheme.borderLight.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppTheme.brandWhite,
                                            ),
                                          ),
                                        ),
                                        if (_currentStep != null) ...[
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              _currentStep!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.brandWhite,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : Text(
                                      'Simplify this visit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: canRun
                                            ? AppTheme.brandWhite
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFAF7F3),
                                Color(0xFFF5F0EB),
                                Color(0xFFF0EAD8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.borderLight.withOpacity(0.35),
                            ),
                            boxShadow: AppTheme.shadowSoft(
                              opacity: 0.06,
                              blur: 14,
                              y: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 22,
                                color: const Color(0xFFD4A574),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'We\'re making this easier to understand',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.05,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'We\'ll turn your visit summary into plain-language explanations. Medical terms will be simplified. Nothing is shared without your permission.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.45,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

            // Generated Summary Display — sectioned like NewUI
            if (_generatedSummary != null) ...[
              const AIDisclaimerBanner(
                customMessage: 'This summary helps you understand your visit.',
                customSubMessage: 'It is not medical advice and does not replace your provider.',
              ),
              const SizedBox(height: 12),
              Text(
                'Below is a gentle breakdown of what you shared. If anything feels unclear, bring these notes to your next visit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildVisitSummarySections(context),
              const SizedBox(height: 12),
              Text(
                'Still have questions? Write them down and ask your care team — you’re not bothering anyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w300,
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
                    _avsUploadResearchSlug = 'unknown';
                  });
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add another visit summary'),
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
    ),
  ),
),
            ],
          ),
        ),
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.useGoldWhenSelected,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final bool useGoldWhenSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Gradient? selectedGradient = selected
        ? LinearGradient(
            colors: useGoldWhenSelected
                ? const [Color(0xFFD4A574), Color(0xFFE0B589)]
                : const [
                    Color(0xFF663399),
                    Color(0xFF7744AA),
                    Color(0xFF8855BB),
                  ],
          )
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selectedGradient,
            color: selected ? null : AppTheme.surfaceCard,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppTheme.borderLight.withOpacity(0.5),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (useGoldWhenSelected
                              ? const Color(0xFFD4A574)
                              : const Color(0xFF663399))
                          .withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppTheme.brandWhite : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: selected ? AppTheme.brandWhite : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF663399).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.brandWhite),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.brandWhite,
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

