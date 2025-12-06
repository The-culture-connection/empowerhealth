import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/birth_plan.dart';
import '../cors/ui_theme.dart';
import 'comprehensive_birth_plan_screen.dart';

class BirthPlanDisplayScreen extends StatelessWidget {
  final BirthPlan birthPlan;

  const BirthPlanDisplayScreen({super.key, required this.birthPlan});

  Future<void> _exportAsPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final formattedText = birthPlan.formattedPlan ?? '';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BIRTH PLAN',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  formattedText,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birth_plan_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Birth Plan',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Birth plan exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareAsText(BuildContext context) async {
    try {
      final formattedText = birthPlan.formattedPlan ?? '';
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birth_plan_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(formattedText);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Birth Plan',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Birth Plan'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAsText(context),
            tooltip: 'Share as Text',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportAsPdf(context),
            tooltip: 'Export as PDF',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComprehensiveBirthPlanScreen(),
                ),
              );
            },
            tooltip: 'Create Another Birth Plan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppTheme.brandPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Birth Plan',
                        style: AppTheme.responsiveTitleStyle(
                          context,
                          baseSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (birthPlan.fullName.isNotEmpty)
                    _buildInfoRow('Name', birthPlan.fullName),
                  if (birthPlan.dueDate != null)
                    _buildInfoRow('Due Date', _formatDate(birthPlan.dueDate!)),
                  if (birthPlan.supportPersonName != null)
                    _buildInfoRow(
                      'Support Person',
                      '${birthPlan.supportPersonName}${birthPlan.supportPersonRelationship != null ? ' (${birthPlan.supportPersonRelationship})' : ''}',
                    ),
                  if (birthPlan.allergies.isNotEmpty)
                    _buildInfoRow('Allergies', birthPlan.allergies.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Formatted Plan
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Text(
                birthPlan.formattedPlan ?? 'No plan content available',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareAsText(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share as Text'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      side: const BorderSide(color: AppTheme.brandPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportAsPdf(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComprehensiveBirthPlanScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Another Birth Plan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brandPurple,
                  side: const BorderSide(color: AppTheme.brandPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.brandPurple,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

