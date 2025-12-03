import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/firebase_functions_service.dart';
import '../cors/ui_theme.dart';

class AppointmentChecklistScreen extends StatefulWidget {
  const AppointmentChecklistScreen({super.key});

  @override
  State<AppointmentChecklistScreen> createState() => _AppointmentChecklistScreenState();
}

class _AppointmentChecklistScreenState extends State<AppointmentChecklistScreen> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final TextEditingController _concernsController = TextEditingController();
  final TextEditingController _lastVisitController = TextEditingController();

  String _selectedAppointmentType = 'Regular Checkup';
  String _selectedTrimester = 'First';
  String? _generatedChecklist;
  bool _isLoading = false;

  final List<String> _appointmentTypes = [
    'Regular Checkup',
    'First Visit',
    'Ultrasound',
    'Glucose Test',
    'Group B Strep Test',
    'Non-Stress Test',
    'Other Specialist Visit',
  ];

  final List<String> _trimesters = ['First', 'Second', 'Third'];

  @override
  void dispose() {
    _concernsController.dispose();
    _lastVisitController.dispose();
    super.dispose();
  }

  Future<void> _generateChecklist() async {
    setState(() {
      _isLoading = true;
      _generatedChecklist = null;
    });

    try {
      final result = await _functionsService.generateAppointmentChecklist(
        appointmentType: _selectedAppointmentType,
        trimester: _selectedTrimester,
        concerns: _concernsController.text.trim().isEmpty ? null : _concernsController.text.trim(),
        lastVisit: _lastVisitController.text.trim().isEmpty ? null : _lastVisitController.text.trim(),
      );

      setState(() {
        _generatedChecklist = result['checklist'];
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
        title: const Text('Appointment Checklist'),
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
              'Prepare for Your Visit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get a personalized checklist to make the most of your appointment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Appointment Type
            _buildDropdown(
              label: 'Appointment Type',
              value: _selectedAppointmentType,
              items: _appointmentTypes,
              onChanged: (value) => setState(() => _selectedAppointmentType = value!),
            ),
            const SizedBox(height: 16),

            // Trimester
            _buildDropdown(
              label: 'Trimester',
              value: _selectedTrimester,
              items: _trimesters,
              onChanged: (value) => setState(() => _selectedTrimester = value!),
            ),
            const SizedBox(height: 16),

            // Concerns
            TextField(
              controller: _concernsController,
              decoration: const InputDecoration(
                labelText: 'Your Concerns or Questions',
                hintText: 'e.g., Back pain, baby movements',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Last Visit Notes
            TextField(
              controller: _lastVisitController,
              decoration: const InputDecoration(
                labelText: 'Notes from Last Visit (Optional)',
                hintText: 'What happened last time?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _generateChecklist,
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
                      'Generate Checklist',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 24),

            // Generated Checklist
            if (_generatedChecklist != null) ...[
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
                        const Icon(Icons.checklist, color: AppTheme.brandPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Personalized Checklist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    MarkdownBody(
                      data: _generatedChecklist!,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

