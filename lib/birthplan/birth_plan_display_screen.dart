import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/birth_plan.dart';
import '../cors/ui_theme.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import 'comprehensive_birth_plan_screen.dart';

class BirthPlanDisplayScreen extends StatefulWidget {
  final BirthPlan birthPlan;

  const BirthPlanDisplayScreen({super.key, required this.birthPlan});

  @override
  State<BirthPlanDisplayScreen> createState() => _BirthPlanDisplayScreenState();
}

class _BirthPlanDisplayScreenState extends State<BirthPlanDisplayScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackViewed());
  }

  Future<void> _trackViewed() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final profile = await _databaseService.getUserProfile(uid);
      await _analytics.logBirthPlanViewed(
        planId: widget.birthPlan.id,
        userProfile: profile,
      );
    } catch (_) {}
  }

  Future<void> _logExported(String exportType) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final profile = await _databaseService.getUserProfile(uid);
      await _analytics.logBirthPlanExported(
        exportType: exportType,
        planId: widget.birthPlan.id,
        userProfile: profile,
      );
    } catch (_) {}
  }

  Future<void> _exportAsPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final formattedText = widget.birthPlan.formattedPlan ?? '';

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
      await _logExported('pdf_share');

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
      final formattedText = widget.birthPlan.formattedPlan ?? '';
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birth_plan_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(formattedText);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Birth Plan',
      );
      await _logExported('text_share');
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
    final birthPlan = widget.birthPlan;
    const purple = Color(0xFF663399);
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, size: 20, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Birth Plans',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your birth preferences',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share with your care team and update anytime.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF5EEE0),
                      AppTheme.backgroundWarm,
                      const Color(0xFFEBE0D6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8E0F0).withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Color(0xFFD4A574),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (birthPlan.fullName.isNotEmpty)
                      _buildInfoRow('Name', birthPlan.fullName),
                    if (birthPlan.dueDate != null)
                      _buildInfoRow('Due date', _formatDate(birthPlan.dueDate!)),
                    if (birthPlan.supportPersonName != null)
                      _buildInfoRow(
                        'Birth partner',
                        '${birthPlan.supportPersonName}${birthPlan.supportPersonRelationship != null ? ' (${birthPlan.supportPersonRelationship})' : ''}',
                      ),
                    if (birthPlan.allergies.isNotEmpty)
                      _buildInfoRow(
                        'Allergies',
                        birthPlan.allergies.join(', '),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8E0F0).withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SelectableText(
                  birthPlan.formattedPlan ?? 'No plan content available.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportAsPdf(context),
                      icon: const Icon(Icons.download_outlined, size: 20),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(
                          color: const Color(0xFFE8E0F0).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareAsText(context),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: const Text('Share with team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: AppTheme.brandWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
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
                        builder: (context) =>
                            const ComprehensiveBirthPlanScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create another plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: const BorderSide(color: purple),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
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
