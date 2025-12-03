import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_functions_service.dart';
import '../cors/ui_theme.dart';

class VisitSummaryScreen extends StatefulWidget {
  const VisitSummaryScreen({super.key});

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
  void dispose() {
    _visitNotesController.dispose();
    _diagnosesController.dispose();
    _medicationsController.dispose();
    _providerInstructionsController.dispose();
    _emotionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_visitNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your visit notes')),
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
        visitNotes: _visitNotesController.text.trim(),
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
        title: const Text('Visit Summary Tool'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Understand Your Visit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get a simple explanation of your appointment in easy-to-understand language',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Visit Notes
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
            const SizedBox(height: 24),

            // Emotional Analysis Results
            if (_emotionalAnalysis != null) ...[
              _buildEmotionalAnalysisCard(),
              const SizedBox(height: 16),
            ],

            // Generated Summary
            if (_generatedSummary != null) ...[
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
          child: MarkdownBody(
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

