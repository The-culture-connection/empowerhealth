import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/birth_plan.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
      '\u2611': '[x]', // ballot box with check
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
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HearthPushedHeader(
                backLabel: 'Birth Plans',
                title: 'Your birth preferences',
                subtitle:
                    'Download a copy for your care team and update anytime.',
                padding: EdgeInsets.only(top: 12),
              ),
              const SizedBox(height: 24),
              HearthFeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HearthIconChip(
                          Icons.favorite_border,
                          tone: HearthChipTone.surface,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Summary',
                          style: hearthFeatureTitleStyle(),
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
              SizedBox(
                width: double.infinity,
                child: HearthCard(
                  padding: const EdgeInsets.all(22),
                  child: SelectableText.rich(
                    _planText.trim().isNotEmpty
                        ? _planSpans(context, _planText.trimRight())
                        : const TextSpan(text: 'No plan content available.'),
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 15,
                      height: 23 / 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              HearthButton.primary(
                onPressed: _downloadPdf,
                loading: _isDownloading,
                icon: Icons.ios_share,
                label: 'Download PDF',
              ),
              const SizedBox(height: 12),
              if (birthPlan.id != null) ...[
                HearthButton.secondary(
                  onPressed: _editPlan,
                  icon: Icons.edit_outlined,
                  label: 'Edit plan',
                ),
                const SizedBox(height: 12),
              ],
              Center(
                child: HearthButton.text(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ComprehensiveBirthPlanScreen(),
                      ),
                    );
                  },
                  icon: Icons.add,
                  label: 'Create another plan',
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

  /// Gives the plain-text plan the same headings the PDF draws: the opening
  /// title in serif and the numbered sections in bold. The text is unchanged
  /// apart from the title's case.
  TextSpan _planSpans(BuildContext context, String text) {
    final sectionHeading = RegExp(r'^\d+\. ');
    final lines = text.split('\n');
    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final end = i < lines.length - 1 ? '\n' : '';
      final trimmed = line.trim();
      if (i == 0 && trimmed.toUpperCase() == 'BIRTH PLAN') {
        final title = trimmed[0] + trimmed.substring(1).toLowerCase();
        spans.add(TextSpan(
          text: '$title$end',
          style: Theme.of(context).textTheme.headlineMedium,
        ));
      } else if (sectionHeading.hasMatch(line)) {
        spans.add(TextSpan(
          text: '$line$end',
          style: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ));
      } else {
        spans.add(TextSpan(text: '$line$end'));
      }
    }
    return TextSpan(children: spans);
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
              style: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 21 / 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
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
