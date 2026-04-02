import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';

/// Full-screen visit detail matching NewUI [VisitDetail.tsx] — replaces modal dialog.
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({
    super.key,
    required this.summaryId,
    required this.data,
  });

  final String summaryId;
  final Map<String, dynamic> data;

  Map<String, dynamic>? get _summaryData =>
      data['summaryData'] is Map<String, dynamic>
          ? data['summaryData'] as Map<String, dynamic>
          : (data['summary'] is Map<String, dynamic>
              ? data['summary'] as Map<String, dynamic>
              : null);

  String _formatHeaderDate(dynamic appointmentDate) {
    if (appointmentDate == null) return 'Visit';
    if (appointmentDate is Timestamp) {
      return DateFormat('MMM d, yyyy').format(appointmentDate.toDate());
    }
    if (appointmentDate is String) {
      try {
        return DateFormat('MMM d, yyyy').format(DateTime.parse(appointmentDate));
      } catch (_) {
        return appointmentDate;
      }
    }
    return appointmentDate.toString();
  }

  List<String> _questionsList() {
    final sd = _summaryData;
    if (sd != null && sd['questionsToAsk'] is List) {
      return (sd['questionsToAsk'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final s = data['summary']?.toString();
    if (s == null) return [];
    return _sectionLines(s, '## Questions to Ask at Your Next Visit');
  }

  List<String> _notesList() {
    final sd = _summaryData;
    if (sd != null && sd['visitNotes'] is List) {
      return (sd['visitNotes'] as List)
          .map((e) => e?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    }
    final s = data['summary']?.toString();
    if (s == null) return [];
    return _sectionLines(s, '## Notes');
  }

  List<String> _sectionLines(String markdown, String heading) {
    final idx = markdown.indexOf(heading);
    if (idx < 0) return [];
    final rest = markdown.substring(idx + heading.length).trim();
    final next = RegExp(r'\n## ').firstMatch(rest);
    final block = next == null ? rest : rest.substring(0, next.start);
    return block.split('\n').map((l) => l.trim()).where((l) {
      if (l.isEmpty) return false;
      return RegExp(r'^\d+\.\s').hasMatch(l) ||
          RegExp(r'^[-*]\s').hasMatch(l);
    }).map((l) {
      return l
          .replaceFirst(RegExp(r'^\d+\.\s*'), '')
          .replaceFirst(RegExp(r'^[-*]\s*'), '');
    }).toList();
  }

  String? _actionsMarkdown() {
    final sd = _summaryData;
    if (sd != null) {
      final parts = <String>[];
      if (sd['nextSteps'] != null) {
        parts.add(sd['nextSteps'].toString());
      }
      if (sd['followUpInstructions'] != null) {
        parts.add(sd['followUpInstructions'].toString());
      }
      if (sd['empowermentTips'] is List) {
        for (final t in sd['empowermentTips'] as List) {
          if (t != null) parts.add(t.toString());
        }
      }
      if (parts.isNotEmpty) return parts.join('\n\n');
    }
    final s = data['summary']?.toString();
    if (s == null) return null;
    final match = RegExp(
      r'## Actions To Take\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    return match?.group(1)?.trim();
  }

  String _whatWasDiscussed() {
    final sd = _summaryData;
    final parts = <String>[];
    if (sd != null) {
      if (sd['howBabyIsDoing'] != null) {
        parts.add(sd['howBabyIsDoing'].toString());
      }
      if (sd['howYouAreDoing'] != null) {
        parts.add(sd['howYouAreDoing'].toString());
      }
    }
    if (parts.isNotEmpty) return parts.join('\n\n');
    final s = data['summary']?.toString();
    if (s == null) return '';
    final baby = RegExp(
      r'## How Your Baby Is Doing\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    final you = RegExp(
      r'## How You Are Doing\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    final b = baby?.group(1)?.trim() ?? '';
    final y = you?.group(1)?.trim() ?? '';
    if (b.isEmpty && y.isEmpty) return s.split('\n').take(8).join('\n');
    return [b, y].where((x) => x.isNotEmpty).join('\n\n');
  }

  Widget _newUiCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Gradient? gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppTheme.surfaceCard : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.4)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 24, y: 4),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDate = data['appointmentDate'];
    final readingLevel = data['readingLevel']?.toString() ?? '6th grade level';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F4),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: MediaQuery.sizeOf(context).width * 0.2,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A574).withOpacity(0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB899D4).withOpacity(0.12),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'My Visits',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.3,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF663399),
                          Color(0xFF7744AA),
                          Color(0xFF8855BB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPurple.withOpacity(0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.brandWhite.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.brandWhite.withOpacity(0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppTheme.brandWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatHeaderDate(appointmentDate),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF5F0F7),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Visit summary · $readingLevel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.brandWhite.withOpacity(0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _newUiCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Color(0xFFD4A574),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This summary helps you understand your visit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'It does not replace medical advice from your provider.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'WHAT WAS DISCUSSED',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandPurple.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _newUiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In simpler words',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandPurple.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _whatWasDiscussed().isEmpty
                              ? 'Open your full summary below if sections are still loading.'
                              : _whatWasDiscussed(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (_summaryData != null &&
                            _summaryData!['keyMedicalTerms'] is List &&
                            (_summaryData!['keyMedicalTerms'] as List)
                                .isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Divider(color: AppTheme.borderLight.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Key terms',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandPurple.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_summaryData!['keyMedicalTerms'] as List).map((t) {
                            if (t is! Map) return const SizedBox.shrink();
                            final term = t['term']?.toString() ?? '';
                            final exp = t['explanation']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$term: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: exp),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  if (_actionsMarkdown() != null &&
                      _actionsMarkdown()!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'ACTIONS TO TAKE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandPurple.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _newUiCard(
                      child: MarkdownBody(
                        data: _actionsMarkdown()!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textPrimary,
                          ),
                          listBullet: const TextStyle(
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_questionsList().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: AppTheme.brandGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'QUESTIONS TO ASK NEXT TIME',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandPurple.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF5EEE0),
                            AppTheme.surfaceCard,
                            const Color(0xFFEBE0D6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE8DFC8).withOpacity(0.5),
                        ),
                        boxShadow: AppTheme.shadowSoft(
                          opacity: 0.06,
                          blur: 18,
                          y: 3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _questionsList().map((q) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD4A574),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      fontWeight: FontWeight.w300,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (_notesList().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandPurple.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _newUiCard(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surfaceCard,
                          const Color(0xFFF5F0EB),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _notesList().map((n) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 20,
                                  color: AppTheme.brandGold.withOpacity(0.9),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    n,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      fontWeight: FontWeight.w300,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (data['learningModules'] != null &&
                      (data['learningModules'] as List).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'SUGGESTED LEARNING',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandPurple.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _newUiCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (data['learningModules'] as List).asMap().entries.map((e) {
                          final i = e.key + 1;
                          final m = e.value;
                          if (m is! Map) return const SizedBox.shrink();
                          final title = m['title']?.toString() ?? 'Topic';
                          final reason =
                              m['reason'] ?? m['description'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '$i. $title${reason.toString().isNotEmpty ? ' — $reason' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFAF7F3),
                          const Color(0xFFF0EAD8).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE8DFC8).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.brandGold,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reminder',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'This summary helps you understand your document. It does not replace medical advice from your healthcare provider. Always contact your provider with questions or concerns.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
