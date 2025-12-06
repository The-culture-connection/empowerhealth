import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedPDF = File(result.files.single.path!);
          _pdfFileName = result.files.single.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF selected: $_pdfFileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting PDF: $e')),
      );
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
    });

    try {
      // Extract text from PDF using syncfusion_flutter_pdf
      final pdfBytes = await _selectedPDF!.readAsBytes();
      final PdfDocument pdfDoc = PdfDocument(inputBytes: pdfBytes);
      
      String pdfText = '';
      final pageCount = pdfDoc.pages.count;
      
      // Extract text from all pages
      for (int i = 0; i < pageCount; i++) {
        final PdfPage page = pdfDoc.pages[i];
        final String pageText = PdfTextExtractor(pdfDoc).extractText(startPageIndex: i, endPageIndex: i);
        pdfText += pageText;
        if (i < pageCount - 1) {
          pdfText += '\n\n'; // Add spacing between pages
        }
      }
      
      pdfDoc.dispose();

      // Check if we extracted any text
      if (pdfText.trim().isEmpty) {
        throw Exception('Could not extract text from PDF. The PDF might be image-based or encrypted. Please try entering the text manually.');
      }

      // Call Firebase Function to summarize
      final result = await _functionsService.summarizeAfterVisitPDF(
        pdfText: pdfText,
        appointmentDate: _selectedDate!.toIso8601String(),
        educationLevel: _userProfile?.educationLevel,
      );

      setState(() {
        _generatedSummary = result['summary'];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit summary created successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analyze & Summarize Visit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
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

