import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/text_cleanup.dart';
import 'suggested_learning_list.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/research/research_firestore_service.dart';
import '../models/user_profile.dart';
import '../research/post_visit_summary_rating_modal.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

  /// Picked document as PDF bytes (photos are converted to PDF on pick).
  /// Kept in memory rather than a temp file so it works on web and mobile.
  Uint8List? _selectedPdfBytes;
  String? _uploadFileName; // storage-safe name ending in .pdf
  DateTime? _selectedDate;
  UserProfile? _userProfile;
  String? _generatedSummary;
  // From the latest result: lessons generated for this visit.
  String? _resultSummaryId;
  List<Map> _resultModules = const [];
  bool _isLoading = false;
  String? _currentStep; // Track current processing step
  double _uploadProgress = 0.0; // Track upload progress
  String _inputMethod = 'pdf'; // 'pdf' or 'text'
  /// Research `avs_upload_type` slug for the next successful AVS analysis (PDF vs gallery image).
  String _avsUploadResearchSlug = 'unknown';
  final TextEditingController _manualTextController = TextEditingController();
  bool _saveOriginalText = false; // Default: don't save raw text
  /// Anchors the generated summary so we can scroll it into view.
  final GlobalKey _summaryKey = GlobalKey();

  static const String _noSummaryMessage =
      'We couldn\'t open your summary. Please try again in a moment.';

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
          // Fill, radius and scrim come from the dialog theme.
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HearthIconChip(Icons.spa_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'How After-Visit Support works',
                          style: Theme.of(ctx).textTheme.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We simplify the language in paperwork or notes you choose to share. '
                    'We don’t diagnose or tell you what to do medically. Your care team does that.',
                    style: Theme.of(ctx).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: HearthButton.text(
                      label: 'Your privacy (plain language)',
                      onPressed: () {
                        Navigator.of(ctx).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AfterVisitPrivacyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  HearthButton.primary(
                    label: 'I understand',
                    onPressed: () async {
                      await prefs.setBool(_transparencyPrefsKey, true);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
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

  void _setResultLessons(Map<String, dynamic> result) {
    final id = result['summaryId'];
    _resultSummaryId = id is String && id.isNotEmpty ? id : null;
    final modules = result['learningModules'];
    _resultModules = modules is List ? modules.whereType<Map>().toList() : const [];
  }

  /// Tappable lessons for this visit (shown loading until each is ready).
  List<Widget> _buildSuggestedLearning() {
    if (_resultModules.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      _visitSummarySectionCard(
        label: 'Suggested Learning',
        child: SuggestedLearningList(
          key: ValueKey(_resultSummaryId),
          summaryId: _resultSummaryId,
          modules: _resultModules,
        ),
      ),
    ];
  }

  List<Widget> _buildVisitSummarySections(BuildContext context) {
    final chunks = _splitMarkdownByH2(_generatedSummary!);
    // The tappable list below replaces the plain-text topics section.
    final nonEmpty = chunks
        .where((c) => c.value.trim().isNotEmpty)
        .where((c) => _resultModules.isEmpty || !(c.key ?? '').toLowerCase().startsWith('suggested learning'))
        .toList();
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
    String body = '',
    Widget? child,
    bool showReadingLevel = false,
  }) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: hearthCaptionStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPurple,
            ),
          ),
          if (showReadingLevel) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.tintWarm,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.brandPurple),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adjusted toward ${_userProfile?.educationLevel ?? "6th grade"} reading level where possible.',
                        style: hearthCaptionStyle.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (child != null) child else
          MarkdownBody(
            data: fixDoublePeriods(body),
            styleSheet: MarkdownStyleSheet(
              h2: hearthCardTitleStyle,
              h3: hearthCardTitleStyle.copyWith(fontSize: 15),
              p: hearthCardBodyStyle,
              strong: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink),
              listBullet: hearthCardBodyStyle.copyWith(color: AppTheme.brandPurple),
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
  /// Returns the PDF bytes in memory so this works on web and mobile alike.
  Future<Uint8List> _imageBytesToPdfBytes(Uint8List bytes) async {
    final document = PdfDocument();
    try {
      final page = document.pages.add();
      final bitmap = PdfBitmap(bytes);
      final pageSize = page.getClientSize();
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );
      final List<int> out = await document.save();
      return Uint8List.fromList(out);
    } finally {
      document.dispose();
    }
  }

  /// Storage-safe file name ending in `.pdf` (we always upload a PDF).
  String _storageSafePdfName(String originalName) {
    var base = originalName;
    final dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    base = base.replaceAll(RegExp(r'[^\w\-]'), '_');
    if (base.isEmpty) base = 'visit_summary';
    return '$base.pdf';
  }

  /// Read the picked file's bytes. Web (and `withData: true`) gives bytes
  /// directly; on mobile we fall back to reading the cached file path.
  Future<Uint8List?> _readPickedBytes(PlatformFile pickedFile) async {
    if (pickedFile.bytes != null) return pickedFile.bytes;
    if (!kIsWeb && pickedFile.path != null) {
      final f = File(pickedFile.path!);
      if (await f.exists()) {
        return await f.readAsBytes();
      }
    }
    return null;
  }

  void _showPickError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppTheme.brandWhite,
          onPressed: () => _pickPDF(),
        ),
      ),
    );
  }

  Future<void> _pickPDF() async {
    // FileType.any on Android is more reliable (some devices/emulators reject
    // custom extension filters). Web and iOS use the extension filter.
    final useAnyType = !kIsWeb && Platform.isAndroid;

    FilePickerResult? result;
    try {
      try {
        result = await FilePicker.platform.pickFiles(
          type: useAnyType ? FileType.any : FileType.custom,
          allowedExtensions: useAnyType
              ? null
              : ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
          withData: true, // Load file data directly (required on web)
          allowMultiple: false,
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('File picker timed out'),
        );
      } catch (e) {
        if (e is TimeoutException) rethrow;
        debugPrint('File picker (custom type) failed, trying any type: $e');
        // Fallback: try picking any file
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
          allowMultiple: false,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('File picker timed out'),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('The file picker took too long to open. Please try again.'),
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
    } catch (e) {
      debugPrint('File picker error: $e');
      _showPickError('We couldn\'t open your files. Please try again.');
      return;
    }

    // Cancelled by the user — expected, no message.
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final fileName = pickedFile.name.toLowerCase();
    final extension = pickedFile.extension?.toLowerCase() ?? '';
    final isPdf = extension == 'pdf' || fileName.endsWith('.pdf');
    const imageExts = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
    final isImage = imageExts.contains(extension) ||
        imageExts.any((ext) => fileName.endsWith('.$ext'));

    if (!isPdf && !isImage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please choose a PDF or a photo (JPG, PNG, HEIC, WebP). Selected: ${pickedFile.name}',
            ),
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

    Uint8List? bytes;
    try {
      bytes = await _readPickedBytes(pickedFile);
    } catch (e) {
      debugPrint('Reading picked file failed: $e');
    }
    if (bytes == null || bytes.isEmpty) {
      _showPickError('We couldn\'t read that file. Please try choosing it again.');
      return;
    }

    Uint8List pdfBytes;
    if (isImage) {
      try {
        pdfBytes = await _imageBytesToPdfBytes(bytes);
      } catch (e) {
        debugPrint('Image to PDF conversion failed: $e');
        _showPickError(
          'We couldn\'t read that photo. Please try a JPG or PNG, or a PDF instead.',
        );
        return;
      }
    } else {
      pdfBytes = bytes;
    }

    if (!mounted) return;
    setState(() {
      _selectedPdfBytes = pdfBytes;
      _uploadFileName = _storageSafePdfName(pickedFile.name);
      _avsUploadResearchSlug = isImage ? 'image_gallery' : 'pdf';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_avsUploadResearchSlug == 'pdf' ? 'Your document is ready to upload.' : 'Your photo is ready to upload.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Display text for any successful analysis response, fresh or duplicate.
  /// Falls back to the saved summary doc when the response only has an id.
  /// Returns null when there is nothing usable to show.
  Future<String?> _summaryFromResult(Map<String, dynamic> result) async {
    final raw = result['summary'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    final summaryId = result['summaryId'];
    final userId = _auth.currentUser?.uid;
    if (summaryId is String && summaryId.isNotEmpty && userId != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('visit_summaries')
            .doc(summaryId)
            .get();
        final stored = doc.data()?['summary'];
        if (stored is String && stored.trim().isNotEmpty) return stored;
      } catch (e) {
        debugPrint('Could not load visit summary $summaryId: $e');
      }
    }
    return null;
  }

  /// Bring the generated summary into view once it has been laid out.
  void _scrollToSummary() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _summaryKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  /// Shown when the server returned an existing summary (duplicate: true).
  void _showDuplicateSummarySnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You already had a summary for this visit, so we opened it.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Plain-language message for upload/analysis failures (never a raw exception).
  String _friendlyErrorMessage(Object e, {required String fallback}) {
    if (e is VisitSummaryException) return e.message;
    final lower = e.toString().toLowerCase();
    if (lower.contains('unable to resolve host') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('unavailable') ||
        lower.contains('unreachable') ||
        lower.contains('no address associated') ||
        lower.contains('failed to fetch')) {
      return 'We couldn\'t connect. Check your internet connection and try again.';
    }
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('deadline')) {
      return 'This is taking longer than expected. Please try again.';
    }
    if (lower.contains('unauthenticated') ||
        lower.contains('not signed in') ||
        lower.contains('session expired')) {
      return 'Please sign in again, then try once more.';
    }
    if (lower.contains('permission') || lower.contains('unauthorized')) {
      return 'Something went wrong with your sign-in. Please sign in again and try once more.';
    }
    if (lower.contains('quota') || lower.contains('resource-exhausted')) {
      return 'We\'re getting a lot of requests right now. Please try again in a few minutes.';
    }
    return fallback;
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
    if (_selectedPdfBytes == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedDate == null
                ? 'Please choose your appointment date at the top first.'
                : 'Please choose a file to upload.',
          ),
        ),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add your visit summary.'),
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
      _currentStep = 'Getting your document ready…';
      _uploadProgress = 0.0;
    });

    try {
      print('📄 Starting PDF upload to Firebase Storage...');
      
      // PDF bytes were read (and photos converted) at pick time
      final pdfBytes = _selectedPdfBytes!;
      print('📄 PDF size: ${pdfBytes.length} bytes');

      // Create storage path: visit_summaries/{userId}/{timestamp}_{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = _uploadFileName ?? 'visit_summary.pdf';
      final storagePath = 'visit_summaries/$userId/${timestamp}_$fileName';
      
      // Create storage reference
      final storageRef = _storage.ref().child(storagePath);
      
      // Upload to Firebase Storage with progress tracking
      print('📤 Uploading file to Firebase Storage: $storagePath');
      setState(() => _currentStep = 'Uploading your document…');
      
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
        if (!mounted || snapshot.totalBytes <= 0) return;
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
          _currentStep = 'Uploading your document… ${(progress * 100).toStringAsFixed(0)}%';
        });
      }, onError: (_) {
        // Upload failures surface through `await uploadTask` below.
      });

      // Wait for upload to complete
      final uploadSnapshot = await uploadTask;
      final downloadUrl = await uploadSnapshot.ref.getDownloadURL();
      
      print('✅ File uploaded successfully');
      print('📥 Download URL: $downloadUrl');

      // Save metadata to Firestore
      setState(() => _currentStep = 'Almost there…');
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
      setState(() => _currentStep = 'Reading your visit summary. This can take up to a minute.');
      
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
              throw Exception('Please sign in before adding a visit summary.');
            }
          } else {
            throw Exception('Please sign in before adding a visit summary.');
          }
        }
      }
      
      if (currentUser == null) {
        throw Exception('Your sign-in expired. Please sign in again.');
      }
      
      // Force token refresh before calling function
      try {
        await currentUser.getIdToken(true);
        print('✅ Auth token refreshed');
      } catch (e) {
        print('⚠️ Token refresh warning: $e');
      }
      
      print('👤 Current user: ${currentUser.uid}');
      print('📅 Appointment date (calendar): ${visitAppointmentCalendarKey(_selectedDate!)}');

      // Call Firebase Function to analyze PDF
      final analysisResult = await _functionsService.analyzeVisitSummaryPDF(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        appointmentDate: visitAppointmentCalendarKey(_selectedDate!),
        educationLevel: _userProfile?.educationLevel,
        userProfile: userProfileData,
      );

      print('✅ PDF analysis completed successfully');

      final isDuplicate = analysisResult['duplicate'] == true;
      final summaryIdValue = analysisResult['summaryId'];
      final avsSummaryId = summaryIdValue is String ? summaryIdValue : null;

      // Update upload status
      try {
        await uploadDocRef.update({
          'status': 'analyzed',
          'summaryId': avsSummaryId,
          'analyzedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ Could not update upload status (non-critical): $e');
      }

      final summaryText = await _summaryFromResult(analysisResult);
      if (summaryText == null) {
        throw const VisitSummaryException(_noSummaryMessage);
      }
      if (!mounted) return;

      setState(() {
        _generatedSummary = summaryText;
        _setResultLessons(analysisResult);
        _isLoading = false;
        _currentStep = null;
        _uploadProgress = 0.0;
        // Clear selected file to show success state
        _selectedPdfBytes = null;
        _uploadFileName = null;
      });
      _scrollToSummary();

      if (isDuplicate) {
        // Nothing new was created, so no creation analytics or rating prompt.
        _showDuplicateSummarySnackBar();
        return;
      }

      // Track visit summary creation
      try {
        final analytics = AnalyticsService();
        if (avsSummaryId != null) {
          await analytics.logVisitSummaryCreated(
            summaryId: avsSummaryId,
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
              'Your summary is ready.${todosCount > 0 ? " We added $todosCount next ${todosCount == 1 ? "step" : "steps"}." : ""}${modulesCount > 0 ? " $modulesCount new ${modulesCount == 1 ? "lesson is" : "lessons are"} waiting in Learn." : ""}'
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (avsSummaryId != null && avsSummaryId.isNotEmpty) {
        await _maybePromptVisitSummaryMicroMeasure(avsSummaryId, 'visit_summary_avs');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = null;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        final lowerMessage = e.toString().toLowerCase();
        final userFriendlyMessage = lowerMessage.contains('cancel')
            ? 'Upload cancelled.'
            : _friendlyErrorMessage(
                e,
                fallback:
                    'We couldn\'t upload and simplify your file. Please try again in a moment.',
              );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            duration: const Duration(seconds: 6),
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
    if (_isLoading) return;
    if (_selectedDate == null || _manualTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedDate == null
                ? 'Please choose your appointment date at the top first.'
                : 'Please type or paste your visit notes first.',
          ),
        ),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to simplify your visit notes.'),
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
      _currentStep = 'Reading your notes. This can take up to a minute.';
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
      // We only need to handle the response for display. A duplicate
      // (same notes, same date) comes back in the same shape with duplicate: true.
      final isDuplicate = analysisResult['duplicate'] == true;
      final summary = await _summaryFromResult(analysisResult);
      if (summary == null) {
        throw const VisitSummaryException(_noSummaryMessage);
      }
      if (!mounted) return;

      setState(() {
        _generatedSummary = summary;
        _setResultLessons(analysisResult);
        _isLoading = false;
        _currentStep = null;
      });
      _scrollToSummary();

      if (isDuplicate) {
        // Nothing new was created, so no creation analytics or rating prompt.
        _showDuplicateSummarySnackBar();
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your summary is ready.'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      final textSummaryIdValue = analysisResult['summaryId'];
      final textSummaryId = textSummaryIdValue is String ? textSummaryIdValue : null;
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
      debugPrint('Visit notes analysis error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyErrorMessage(
              e,
              fallback:
                  'We couldn\'t simplify your notes right now. Please try again in a moment.',
            ),
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppTheme.brandWhite,
            onPressed: () => _processManualText(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSessionScope(
      feature: 'appointment-summarizing',
      entrySource: 'upload_visit_summary',
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HearthPushedHeader(
                          backLabel: 'My Visits',
                          title: 'After-Visit Support',
                          subtitle:
                              'Doctor visits can be overwhelming. We’re here to help you understand paperwork in plain language: after-visit summaries, discharge instructions, provider notes, and similar documents. This is literacy support, not a diagnosis.',
                          padding: EdgeInsets.only(top: 20, bottom: 4),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: HearthButton.text(
                            label: 'Your privacy (plain language)',
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const AfterVisitPrivacyScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        HearthFeatureCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const HearthIconChip(
                                Icons.shield_outlined,
                                tone: HearthChipTone.surface,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'We help simplify the documents you share',
                                      style: hearthCardTitleStyle,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'This tool makes medical language easier to understand. It does not provide medical advice, diagnoses, or replace your healthcare provider.',
                                      style: hearthCardBodyStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const HearthSectionHeading('Appointment date'),
                        const SizedBox(height: 14),
                        HearthCard(
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              const HearthIconChip(Icons.calendar_today_outlined),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? MaterialLocalizations.of(context)
                                          .formatFullDate(_selectedDate!)
                                      : 'Tap to select date',
                                  style: TextStyle(
                                    fontFamily: AppTheme.sansFamily,
                                    fontSize: 16,
                                    height: 22 / 16,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedDate != null
                                        ? AppTheme.ink
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MethodPill(
                                selected: _inputMethod == 'pdf',
                                icon: Icons.upload_outlined,
                                label: 'From file',
                                onTap: () =>
                                    setState(() => _inputMethod = 'pdf'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MethodPill(
                                selected: _inputMethod == 'text',
                                icon: Icons.text_fields,
                                label: 'Type notes',
                                onTap: () =>
                                    setState(() => _inputMethod = 'text'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_inputMethod == 'text')
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: HearthNote(
                              icon: Icons.lock_outline,
                              text:
                                  'Recommended for privacy: your text won\'t be stored unless you choose to save it.',
                            ),
                          ),

            // PDF Upload Section
            if (_inputMethod == 'pdf' && _selectedPdfBytes == null) ...[
              HearthCard(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  children: [
                    const HearthIconChip(
                      Icons.cloud_upload_outlined,
                      size: 80,
                      iconSize: 36,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'PDF or image file',
                      textAlign: TextAlign.center,
                      style: hearthCardTitleStyle.copyWith(fontSize: 17, height: 24 / 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a PDF or image (JPG, PNG, HEIC, WebP) from Files',
                      textAlign: TextAlign.center,
                      style: hearthCardBodyStyle,
                    ),
                    const SizedBox(height: 20),
                    HearthButton.primary(
                      icon: Icons.description_outlined,
                      label: 'Choose file',
                      expand: false,
                      onPressed: _pickPDF,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'After-visit summaries, discharge paperwork, and provider notes work well. Remove sensitive information you do not want analyzed.',
                  textAlign: TextAlign.center,
                  style: hearthCaptionStyle,
                ),
              ),
            ] else if (_inputMethod == 'pdf') ...[
              HearthCard(
                padding: const EdgeInsets.all(16),
                color: AppTheme.tintWarm,
                borderColor: AppTheme.brandPurple,
                borderWidth: 2,
                child: Row(
                  children: [
                    const HearthIconChip(
                      Icons.description_outlined,
                      tone: HearthChipTone.surface,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check, size: 18, color: AppTheme.brandPurple),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Ready to upload',
                                  style: hearthCardTitleStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _avsUploadResearchSlug == 'pdf' ? 'Your document' : 'Your photo',
                            style: hearthCardBodyStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HearthCircleButton(
                      icon: Icons.close,
                      onPressed: () {
                        setState(() {
                          _selectedPdfBytes = null;
                          _uploadFileName = null;
                          _avsUploadResearchSlug = 'unknown';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Process Button. Theme gives the purple stadium; the child keeps
              // the live step text while uploading.
              ElevatedButton(
                onPressed: !_isLoading
                    ? _processPDF
                    : null,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
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
                    : const Text('Upload Visit Summary'),
              ),
            ] else ...[
              HearthCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _manualTextController,
                      // Rebuild so the Simplify button reflects typed/pasted text.
                      onChanged: (_) => setState(() {}),
                      maxLines: 10,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        height: 22 / 15,
                        color: AppTheme.ink,
                      ),
                      // Inset fill because the field sits inside a card.
                      decoration: const InputDecoration(
                        hintText: 'Type or paste your visit notes here...',
                        fillColor: AppTheme.surfaceInset,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Save my original text',
                        style: hearthCardTitleStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'By default, only the summary is saved. Check this to also save your original notes.',
                        style: hearthCaptionStyle,
                      ),
                      value: _saveOriginalText,
                      onChanged: (value) =>
                          setState(() => _saveOriginalText = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final isReady = _selectedDate != null &&
                            _manualTextController.text.trim().isNotEmpty;
                        // Keep the filled style while loading so the white
                        // spinner/progress text stays readable.
                        final canRun = isReady || _isLoading;
                        return Material(
                          color: canRun ? AppTheme.brandPurple : AppTheme.borderWarm,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            // Stay tappable when not ready so the user is told what is missing
                            // (date or notes) instead of a silently dead button.
                            onTap: _isLoading ? null : _processManualText,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                        fontFamily: AppTheme.sansFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                    if (_selectedDate == null && !_isLoading) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Choose your appointment date above to continue.',
                        textAlign: TextAlign.center,
                        style: hearthCaptionStyle,
                      ),
                    ],
                  ],
                ),
              ),

              // Show current step and progress below button if loading
              if (_isLoading && _currentStep != null) ...[
                const SizedBox(height: 12),
                HearthCard(
                  padding: const EdgeInsets.all(14),
                  color: AppTheme.tintWarm,
                  borderColor: null,
                  radius: BorderRadius.circular(AppTheme.fieldRadius),
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
                                fontFamily: AppTheme.sansFamily,
                                fontSize: 14,
                                color: AppTheme.brandPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadProgress > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 6,
                            backgroundColor: AppTheme.borderWarm,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

                        const SizedBox(height: 20),
                        const HearthNote(
                          icon: Icons.info_outline,
                          title: 'We\'re making this easier to understand',
                          text:
                              'We\'ll explain your visit in everyday words, including any medical terms. Nothing is shared without your permission.',
                        ),
                        const SizedBox(height: 4),

            // Generated Summary Display — sectioned like NewUI
            if (_generatedSummary != null) ...[
              KeyedSubtree(
                key: _summaryKey,
                child: const AIDisclaimerBanner(
                  customMessage: 'This summary helps you understand your visit.',
                  customSubMessage: 'It is not medical advice and does not replace your provider.',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Below is a gentle breakdown of what you shared. If anything feels unclear, bring these notes to your next visit.',
                textAlign: TextAlign.center,
                style: hearthCaptionStyle,
              ),
              const SizedBox(height: 16),
              ..._buildVisitSummarySections(context),
              ..._buildSuggestedLearning(),
              const SizedBox(height: 12),
              Text(
                'Still have questions? Write them down and ask your care team. You’re not bothering anyone.',
                textAlign: TextAlign.center,
                style: hearthCaptionStyle,
              ),
              const SizedBox(height: 16),
              HearthButton.secondary(
                onPressed: () {
                  setState(() {
                    _generatedSummary = null;
                    _selectedPdfBytes = null;
                    _uploadFileName = null;
                    _selectedDate = null;
                    _avsUploadResearchSlug = 'unknown';
                  });
                },
                icon: Icons.add,
                label: 'Add another visit summary',
              ),
            ],
          ],
        ),
      ),
    ),
  ),
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
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Full-width version of the Hearth choice chip (tint + purple outline when
  /// selected), centred so the two pills read as a segmented choice.
  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTheme.brandPurple : AppTheme.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppTheme.tintWarm : AppTheme.surface,
        shape: StadiumBorder(
          side: selected
              ? const BorderSide(color: AppTheme.brandPurple, width: 2)
              : const BorderSide(color: AppTheme.borderWarm),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

