import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  File? _selectedPDF;
  String? _pdfFileName;
  DateTime? _selectedDate;
  UserProfile? _userProfile;
  String? _generatedSummary;
  bool _isLoading = false;
  String? _currentStep; // Track current processing step

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true, // Load file data directly - more reliable on Android
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            print('⏱️ File picker timed out after 60 seconds');
            throw TimeoutException('File picker timed out. Please try again.');
          },
        );
        print('📄 File picker completed (first attempt)');
      } catch (e) {
        if (e is TimeoutException) {
          print('⏱️ Timeout: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File picker timed out. Please try again.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
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
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('⏱️ File picker fallback timed out');
              throw TimeoutException('File picker timed out. Please try again.');
            },
          );
          print('📄 File picker completed (fallback attempt)');
        } catch (e2) {
          if (e2 is TimeoutException) {
            print('⏱️ Fallback timeout: $e2');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File picker timed out. Please try again.'),
                  backgroundColor: Colors.orange,
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
        
        // Check if it's a PDF
        final isPdf = pickedFile.extension?.toLowerCase() == 'pdf' || 
                      pickedFile.name.toLowerCase().endsWith('.pdf');
        
        if (!isPdf) {
          print('❌ Selected file is not a PDF');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a PDF file.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
        const SnackBar(content: Text('Please select both date and PDF')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedSummary = null;
      _currentStep = 'Preparing...';
    });

    try {
      print('📄 Starting PDF processing...');
      setState(() => _currentStep = 'Reading PDF file...');
      
      // Extract text from PDF using syncfusion_flutter_pdf
      print('📄 Reading PDF file...');
      final pdfBytes = await _selectedPDF!.readAsBytes();
      print('📄 PDF size: ${pdfBytes.length} bytes');
      
      print('📄 Extracting text from PDF...');
      setState(() => _currentStep = 'Extracting text from PDF...');
      final PdfDocument pdfDoc = PdfDocument(inputBytes: pdfBytes);
      
      String pdfText = '';
      final pageCount = pdfDoc.pages.count;
      print('📄 PDF has $pageCount pages');
      
      // Extract text from all pages
      for (int i = 0; i < pageCount; i++) {
        final PdfPage page = pdfDoc.pages[i];
        final String pageText = PdfTextExtractor(pdfDoc).extractText(startPageIndex: i, endPageIndex: i);
        pdfText += pageText;
        if (i < pageCount - 1) {
          pdfText += '\n\n'; // Add spacing between pages
        }
        print('📄 Extracted text from page ${i + 1}/${pageCount}');
      }
      
      pdfDoc.dispose();
      print('📄 Extracted text length: ${pdfText.length} characters');

      // Check if we extracted any text
      if (pdfText.trim().isEmpty) {
        throw Exception('Could not extract text from PDF. The PDF might be image-based or encrypted. Please try entering the text manually.');
      }

      // Prepare user profile data for context
      print('📄 Preparing user profile data...');
      setState(() => _currentStep = 'Preparing data...');
      final userProfileData = _userProfile != null ? {
        'pregnancyStage': _userProfile!.pregnancyStage,
        'trimester': _userProfile!.pregnancyStage,
        'concerns': [], // Can be expanded to capture user concerns
        'birthPlanPreferences': _userProfile!.birthPreference != null ? [_userProfile!.birthPreference!] : [],
        'culturalPreferences': [],
        'traumaInformedPreferences': [],
        'learningStyle': 'visual', // Default, can be added to profile
        'chronicConditions': _userProfile!.chronicConditions,
        'healthLiteracyGoals': _userProfile!.healthLiteracyGoals,
      } : null;

      // Call Firebase Function to summarize
      print('📄 Calling Firebase Function to summarize...');
      setState(() => _currentStep = 'Analyzing with AI... This may take a minute.');
      final result = await _functionsService.summarizeAfterVisitPDF(
        pdfText: pdfText,
        appointmentDate: _selectedDate!.toIso8601String(),
        educationLevel: _userProfile?.educationLevel,
        userProfile: userProfileData,
      );
      print('✅ Firebase Function completed successfully');

      setState(() {
        _generatedSummary = result['summary'];
        _isLoading = false;
        _currentStep = null;
      });

      // Show success message with counts
      final todosCount = (result['todos'] as List?)?.length ?? 0;
      final modulesCount = (result['learningModules'] as List?)?.length ?? 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visit summary created! ${todosCount > 0 ? "$todosCount todos added. " : ""}${modulesCount > 0 ? "$modulesCount learning modules created." : ""}'
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = null;
      });
      
      if (mounted) {
        // Check for network connectivity errors
        final errorMessage = e.toString().toLowerCase();
        String userFriendlyMessage;
        
        if (errorMessage.contains('unable to resolve host') || 
            errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('unavailable') ||
            errorMessage.contains('no address associated')) {
          userFriendlyMessage = 'Network connection error. Please check your internet connection and try again.';
        } else if (errorMessage.contains('permission') || errorMessage.contains('unauthorized')) {
          userFriendlyMessage = 'Permission denied. Please ensure you are logged in and try again.';
        } else if (errorMessage.contains('timeout')) {
          userFriendlyMessage = 'Request timed out. Please check your connection and try again.';
        } else {
          userFriendlyMessage = 'Error processing PDF: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _processPDF(),
            ),
          ),
        );
      }
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

            // PDF Upload Section
            if (_selectedPDF == null) ...[
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
            ] else ...[
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

              // Process Button
              ElevatedButton(
                onPressed: (_selectedDate != null && !_isLoading)
                    ? _processPDF
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
                        'Analyze & Summarize Visit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              
              // Show current step below button if loading
              if (_isLoading && _currentStep != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
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
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
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

