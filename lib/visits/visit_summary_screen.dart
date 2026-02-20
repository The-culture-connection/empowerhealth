import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../services/firebase_functions_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import '../widgets/ai_disclaimer_banner.dart';

class VisitSummaryScreen extends StatefulWidget {
  const VisitSummaryScreen({super.key});

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  File? _selectedPDF;
  String? _pdfFileName;
  DateTime? _selectedDate;
  UserProfile? _userProfile;
  
  final TextEditingController _visitNotesController = TextEditingController();
  final TextEditingController _diagnosesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _providerInstructionsController = TextEditingController();
  final TextEditingController _emotionalNotesController = TextEditingController();

  String? _generatedSummary;
  bool _isLoading = false;
  bool _showEmotionalAnalysis = false;
  Map<String, dynamic>? _emotionalAnalysis;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkConsentAndShowPrivacyScreen();
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

  Future<void> _loadUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final profile = await _databaseService.getUserProfile(userId);
      setState(() {
        _userProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _visitNotesController.dispose();
    _diagnosesController.dispose();
    _medicationsController.dispose();
    _providerInstructionsController.dispose();
    _emotionalNotesController.dispose();
    super.dispose();
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

  Future<void> _generateSummary() async {
    String visitText = _visitNotesController.text.trim();
    
    // Extract text from PDF if one is selected
    if (_selectedPDF != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final pdfBytes = await _selectedPDF!.readAsBytes();
        final PdfDocument pdfDoc = PdfDocument(inputBytes: pdfBytes);
        
        String pdfText = '';
        final pageCount = pdfDoc.pages.count;
        
        // Extract text from all pages
        for (int i = 0; i < pageCount; i++) {
          final String pageText = PdfTextExtractor(pdfDoc).extractText(startPageIndex: i, endPageIndex: i);
          pdfText += pageText;
          if (i < pageCount - 1) {
            pdfText += '\n\n'; // Add spacing between pages
          }
        }
        
        pdfDoc.dispose();
        
        if (pdfText.trim().isNotEmpty) {
          visitText = pdfText;
          // Optionally populate the text field with extracted text
          _visitNotesController.text = visitText;
        } else {
          throw Exception('Could not extract text from PDF. The PDF might be image-based or encrypted.');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error extracting PDF text: ${e.toString()}. Please enter text manually.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }
    
    if (visitText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter visit notes or upload PDF')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedSummary = null;
      _emotionalAnalysis = null;
    });

    try {
      // Generate summary
      final result = await _functionsService.summarizeVisitNotes(
        visitNotes: visitText,
        providerInstructions: _providerInstructionsController.text.trim().isEmpty
            ? null
            : _providerInstructionsController.text.trim(),
        medications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        diagnoses: _diagnosesController.text.trim().isEmpty
            ? null
            : _diagnosesController.text.trim(),
        emotionalFlags: _emotionalNotesController.text.trim().isEmpty
            ? null
            : _emotionalNotesController.text.trim(),
      );

      // Save to user's profile under visit_summaries subcollection
      final userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('visit_summaries')
          .add({
        'appointmentDate': _selectedDate,
        'originalNotes': visitText,
        'summary': result['summary'],
        'diagnoses': _diagnosesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'providerInstructions': _providerInstructionsController.text.trim(),
        'emotionalFlags': _emotionalNotesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Analyze emotional content if enabled
      if (_showEmotionalAnalysis) {
        final emotionalResult = await _functionsService.analyzeEmotionalContent(
          visitNotes: _visitNotesController.text.trim(),
        );
        setState(() {
          _emotionalAnalysis = emotionalResult['analysis'];
        });
      }

      setState(() {
        _generatedSummary = result['summary'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Visit Summary'),
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
              'Upload Visit Summary',
              style: AppTheme.responsiveTitleStyle(
                context,
                baseSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your visit summary PDF and get an easy-to-understand explanation',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Appointment Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
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
            const Divider(),
            const SizedBox(height: 16),

            // PDF Upload Section
            if (_selectedPDF == null) ...[
              GestureDetector(
                onTap: _pickPDF,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.brandPurple,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: AppTheme.brandPurple,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Upload Visit Summary PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select PDF file',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            _pdfFileName ?? '',
                            style: const TextStyle(fontSize: 12),
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

              // Generate Summary Button
              ElevatedButton(
                onPressed: (_selectedDate != null && !_isLoading) 
                    ? _generateSummary 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        'Analyze & Summarize',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],

            const SizedBox(height: 24),

            // Manual Text Entry Alternative
            ExpansionTile(
              title: const Text(
                'Or Enter Text Manually',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _visitNotesController,
              decoration: const InputDecoration(
                labelText: 'What happened during your visit? *',
                hintText: 'Doctor said... tests done... measurements taken...',
                border: OutlineInputBorder(),
                helperText: 'Copy and paste from your visit summary or describe in your own words',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Diagnoses
            TextField(
              controller: _diagnosesController,
              decoration: const InputDecoration(
                labelText: 'Any diagnoses or conditions mentioned?',
                hintText: 'e.g., Gestational diabetes, anemia',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Medications
            TextField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'Medications prescribed or discussed',
                hintText: 'e.g., Prenatal vitamins, iron supplements',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Provider Instructions
            TextField(
              controller: _providerInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions from your provider',
                hintText: 'What did they tell you to do?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Emotional Notes
            TextField(
              controller: _emotionalNotesController,
              decoration: const InputDecoration(
                labelText: 'How did you feel during the visit?',
                hintText: 'Confused, worried, reassured, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Emotional Analysis Toggle
            Row(
              children: [
                Checkbox(
                  value: _showEmotionalAnalysis,
                  onChanged: (value) {
                    setState(() {
                      _showEmotionalAnalysis = value ?? false;
                    });
                  },
                  activeColor: AppTheme.brandPurple,
                ),
                const Expanded(
                  child: Text(
                    'Analyze emotional moments and highlight areas of confusion',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _generateSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      'Generate Simple Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
              ],
            ),
            const SizedBox(height: 24),

            // Emotional Analysis Results
            if (_emotionalAnalysis != null) ...[
              _buildEmotionalAnalysisCard(),
              const SizedBox(height: 16),
            ],

            // Generated Summary
            if (_generatedSummary != null) ...[
              // AI Disclaimer Banner
              const AIDisclaimerBanner(
                customMessage: 'This summary helps you understand your visit.',
                customSubMessage: 'It does not replace medical advice from your provider.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_information, color: AppTheme.brandPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Visit Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Written at 6th grade reading level',
                              style: TextStyle(fontSize: 12, color: Colors.green),
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

              // View Past Summaries
              _buildPastSummariesButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Emotional Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_emotionalAnalysis!['emotionalFlags'] != null &&
              (_emotionalAnalysis!['emotionalFlags'] as List).isNotEmpty) ...[
            const Text(
              '💭 Emotional Moments:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...(_emotionalAnalysis!['emotionalFlags'] as List).map((flag) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $flag'),
              );
            }),
            const SizedBox(height: 12),
          ],
          if (_emotionalAnalysis!['confusionPoints'] != null &&
              (_emotionalAnalysis!['confusionPoints'] as List).isNotEmpty) ...[
            const Text(
              '❓ Points of Confusion:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...(_emotionalAnalysis!['confusionPoints'] as List).map((point) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $point'),
              );
            }),
            const SizedBox(height: 12),
          ],
          if (_emotionalAnalysis!['recommendations'] != null &&
              (_emotionalAnalysis!['recommendations'] as List).isNotEmpty) ...[
            const Text(
              '💡 Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...(_emotionalAnalysis!['recommendations'] as List).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $rec'),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPastSummariesButton() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PastSummariesScreen(),
          ),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text('View Past Visit Summaries'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brandPurple,
        side: const BorderSide(color: AppTheme.brandPurple),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// Screen to view past summaries
class PastSummariesScreen extends StatelessWidget {
  const PastSummariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Visit Summaries'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visit_summaries')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No past summaries yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.medical_information, color: AppTheme.brandPurple),
                  title: Text(
                    timestamp != null
                        ? 'Visit on ${_formatDate(timestamp.toDate())}'
                        : 'Visit Summary',
                  ),
                  subtitle: Text(
                    data['summary']?.toString().substring(0, 100) ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showSummaryDialog(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showSummaryDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visit Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Disclaimer Banner
              const AIDisclaimerBanner(
                customMessage: 'This summary helps you understand your visit.',
                customSubMessage: 'It does not replace medical advice from your provider.',
              ),
              const SizedBox(height: 16),
              MarkdownBody(
            data: data['summary'] ?? '',
            styleSheet: MarkdownStyleSheet(
              h2: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
              p: const TextStyle(fontSize: 14, height: 1.5),
            ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

