import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/birth_plan.dart';
import '../cors/ui_theme.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../widgets/module_quick_feedback.dart';
import 'birth_plan_file_saver.dart';
import 'birth_plan_formatter.dart';
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
  late BirthPlan _plan;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.birthPlan;
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

  /// Always rebuilt from the saved fields so the on-screen and downloaded plan
  /// include everything recorded (older plans stored a shorter text snapshot).
  String get _planText {
    final text = BirthPlanFormatter().format(_plan);
    if (text.trim().isNotEmpty) return text;
    return _plan.formattedPlan ?? '';
  }

  /// The built-in PDF fonts only cover Latin-1, so swap common typographic
  /// characters for plain equivalents and drop anything else (e.g. emoji)
  /// rather than printing empty boxes.
  String _pdfSafe(String input) {
    const replacements = {
      '—': '-', // em dash
      '–': '-', // en dash
      '‘': "'",
      '’': "'",
      '“': '"',
      '”': '"',
      '…': '...',
      '•': '-',
      '☑': '[x]',
      '☐': '[ ]',
    };
    final out = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final mapped = replacements[ch];
      if (mapped != null) {
        out.write(mapped);
      } else if (rune <= 0xFF) {
        out.write(ch);
      }
    }
    return out.toString();
  }

  /// Splits [text] at word boundaries into pieces of at most [maxChars].
  List<String> _chunkForPdf(String text, {int maxChars = 600}) {
    if (text.length <= maxChars) return [text];
    final chunks = <String>[];
    var current = StringBuffer();
    for (final word in text.split(' ')) {
      if (current.isNotEmpty && current.length + word.length + 1 > maxChars) {
        chunks.add(current.toString());
        current = StringBuffer();
      }
      // A single enormous "word" (e.g. a pasted URL) is hard-split.
      var remaining = word;
      while (remaining.length > maxChars) {
        chunks.add(remaining.substring(0, maxChars));
        remaining = remaining.substring(maxChars);
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(remaining);
    }
    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks;
  }

  Future<Uint8List> _buildPdfBytes() async {
    final pdf = pw.Document(title: 'Birth Plan', author: _plan.fullName);
    final lines = _planText.split('\n');
    // The formatter starts with its own "BIRTH PLAN" heading; the PDF draws a
    // styled title instead.
    if (lines.isNotEmpty && lines.first.trim().toUpperCase() == 'BIRTH PLAN') {
      lines.removeAt(0);
    }
    final sectionHeading = RegExp(r'^\d+\. ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Text(
            'BIRTH PLAN',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          for (final raw in lines)
            if (raw.trim().isEmpty)
              pw.SizedBox(height: 8)
            else if (sectionHeading.hasMatch(raw)) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                _pdfSafe(raw),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
            ] else
              // A single pw.Text can't break across pages, so very long
              // answers are split into smaller blocks that MultiPage can flow.
              for (final chunk in _chunkForPdf(_pdfSafe(raw)))
                pw.Text(
                  chunk,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _buildPdfBytes();
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await saveBirthPlanPdf(bytes, 'birth_plan_$stamp.pdf');
      await _logExported(kIsWeb ? 'pdf_download' : 'pdf_share');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Your birth plan PDF is downloading.'
                : 'Your birth plan PDF is ready to save or send.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Birth plan PDF download failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Sorry, we couldn\'t download your birth plan. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _editPlan() async {
    final updated = await Navigator.push<BirthPlan>(
      context,
      MaterialPageRoute(
        builder: (context) => ComprehensiveBirthPlanScreen(editingPlan: _plan),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _plan = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your birth plan was updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthPlan = _plan;
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
                'Download a copy for your care team and update anytime.',
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
                  _planText.trim().isNotEmpty
                      ? _planText.trimRight()
                      : 'No plan content available.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadPdf,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.brandWhite,
                          ),
                        )
                      : const Icon(Icons.download_outlined, size: 20),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: AppTheme.brandWhite,
                    disabledBackgroundColor: purple.withValues(alpha: 0.7),
                    disabledForegroundColor: AppTheme.brandWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (birthPlan.id != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _editPlan,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: const BorderSide(color: purple),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
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
                  style: TextButton.styleFrom(
                    foregroundColor: purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // "How do you feel now?" feedback after birth planning.
              ModuleQuickFeedback.howDoYouFeel(
                feature: 'birth-planning',
                moduleTitle: 'Birth Plan',
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
