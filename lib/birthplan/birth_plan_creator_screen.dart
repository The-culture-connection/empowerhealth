import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/firebase_functions_service.dart';
import '../cors/ui_theme.dart';

class BirthPlanCreatorScreen extends StatefulWidget {
  const BirthPlanCreatorScreen({super.key});

  @override
  State<BirthPlanCreatorScreen> createState() => _BirthPlanCreatorScreenState();
}

class _BirthPlanCreatorScreenState extends State<BirthPlanCreatorScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _concernsController = TextEditingController();
  final TextEditingController _supportPeopleController = TextEditingController();

  final Map<String, dynamic> _preferences = {
    'laborEnvironment': 'Calm and quiet',
    'painManagement': 'Open to options',
    'deliveryPosition': 'No preference',
    'skinToSkin': true,
    'delayedCordClamping': true,
    'breastfeeding': true,
  };

  String? _generatedBirthPlan;
  String? _planId;
  bool _isLoading = false;

  @override
  void dispose() {
    _medicalHistoryController.dispose();
    _concernsController.dispose();
    _supportPeopleController.dispose();
    super.dispose();
  }

  Future<void> _generateBirthPlan() async {
    setState(() {
      _isLoading = true;
      _generatedBirthPlan = null;
    });

    try {
      final result = await _functionsService.generateBirthPlan(
        preferences: _preferences,
        medicalHistory: _medicalHistoryController.text.trim().isEmpty
            ? null
            : _medicalHistoryController.text.trim(),
        concerns: _concernsController.text.trim().isEmpty
            ? null
            : _concernsController.text.trim(),
        supportPeople: _supportPeopleController.text.trim().isEmpty
            ? null
            : _supportPeopleController.text.trim(),
      );

      setState(() {
        _generatedBirthPlan = result['birthPlan'];
        _planId = result['planId'];
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

  Future<void> _shareBirthPlan() async {
    if (_generatedBirthPlan == null) return;

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birth_plan.txt');
      await file.writeAsString(_generatedBirthPlan!);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Birth Plan',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportAsPdf() async {
    if (_generatedBirthPlan == null) return;

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'My Birth Plan',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _generatedBirthPlan!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birth_plan.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Birth Plan',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Birth plan exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Plan Creator'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
        actions: _generatedBirthPlan != null
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareBirthPlan,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _exportAsPdf,
                  tooltip: 'Export as PDF',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Create Your Birth Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your wishes with your healthcare team',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSection('Labor & Delivery Preferences', [
              _buildPreferenceDropdown(
                'Labor Environment',
                'laborEnvironment',
                ['Calm and quiet', 'Music playing', 'Lights dimmed', 'No preference'],
              ),
              _buildPreferenceDropdown(
                'Pain Management',
                'painManagement',
                ['Epidural', 'Natural', 'Open to options', 'Will decide during labor'],
              ),
              _buildPreferenceDropdown(
                'Delivery Position',
                'deliveryPosition',
                ['No preference', 'On back', 'Squatting', 'Side-lying', 'Whatever feels right'],
              ),
              _buildSwitch('Immediate Skin-to-Skin', 'skinToSkin'),
              _buildSwitch('Delayed Cord Clamping', 'delayedCordClamping'),
              _buildSwitch('Plan to Breastfeed', 'breastfeeding'),
            ]),

            const SizedBox(height: 24),

            // Medical History
            TextField(
              controller: _medicalHistoryController,
              decoration: const InputDecoration(
                labelText: 'Medical History (Optional)',
                hintText: 'Any conditions or previous pregnancies',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Concerns
            TextField(
              controller: _concernsController,
              decoration: const InputDecoration(
                labelText: 'Special Concerns or Requests',
                hintText: 'Anything else your team should know',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Support People
            TextField(
              controller: _supportPeopleController,
              decoration: const InputDecoration(
                labelText: 'Support People',
                hintText: 'Who will be with you? (partner, doula, family)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _generateBirthPlan,
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
                      'Generate Birth Plan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 24),

            // Generated Birth Plan
            if (_generatedBirthPlan != null) ...[
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
                        const Icon(Icons.favorite, color: AppTheme.brandPurple),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Your Birth Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: _shareBirthPlan,
                          color: AppTheme.brandPurple,
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          onPressed: _exportAsPdf,
                          color: AppTheme.brandPurple,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    MarkdownBody(
                      data: _generatedBirthPlan!,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandPurple,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildPreferenceDropdown(String label, String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _preferences[key],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _preferences[key] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: _preferences[key] as bool,
            onChanged: (value) {
              setState(() {
                _preferences[key] = value;
              });
            },
            activeColor: AppTheme.brandPurple,
          ),
        ],
      ),
    );
  }
}

