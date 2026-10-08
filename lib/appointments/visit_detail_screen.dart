import 'package:flutter/material.dart';
import '../utils/text_cleanup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'visit_summary_preview.dart';
import 'suggested_learning_list.dart';

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

  /// Markdown blob for regex fallbacks — handles `summary` stored as a Map (legacy / bad writes).
  String? _summaryMarkdownString() {
    final raw = data['summary'];
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      if (t.startsWith('{') &&
          (t.contains('howBabyIsDoing') || t.contains('questionsToAsk'))) {
        return null;
      }
      return t;
    }
    if (raw is Map<String, dynamic>) {
      return formatSummaryFromMap(raw);
    }
    if (raw is Map) {
      return formatSummaryFromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

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
    final s = _summaryMarkdownString();
    if (s == null) return [];
    final fromNew = _sectionLines(s, '## Questions to Ask');
    if (fromNew.isNotEmpty) return fromNew;
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
    final s = _summaryMarkdownString();
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
      if (sd['importantNextSteps'] != null) {
        parts.add(sd['importantNextSteps'].toString());
      }
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
    final s = _summaryMarkdownString();
    if (s == null) return null;
    final important = RegExp(
      r'## Important Next Steps\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    if (important != null) return important.group(1)?.trim();
    final match = RegExp(
      r'## Actions To Take\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    return match?.group(1)?.trim();
  }

  List<Map<String, String>> _medicationsList() {
    final sd = _summaryData;
    if (sd == null || sd['medications'] is! List) return [];
    final out = <Map<String, String>>[];
    for (final m in sd['medications'] as List) {
      if (m is! Map) continue;
      final name = m['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      out.add({
        'name': name,
        'detail': [
          if (m['purpose'] != null) m['purpose'].toString(),
          if (m['instructions'] != null) m['instructions'].toString(),
        ].map(_asSentence).where((e) => e.isNotEmpty).join(' '),
      });
    }
    return out;
  }

  /// Trims and ends with exactly one period, so joined parts never read "..".
  static String _asSentence(String text) {
    final t = text.trim().replaceAll(RegExp(r'[.\s]+$'), '');
    if (t.isEmpty) return '';
    return RegExp(r'[!?]$').hasMatch(t) ? t : '$t.';
  }

  String _whatWasDiscussed() {
    final sd = _summaryData;
    if (sd != null && sd['whatThisMeans'] != null) {
      final w = sd['whatThisMeans'].toString().trim();
      if (w.isNotEmpty) return w;
    }
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
    final s = _summaryMarkdownString();
    if (s == null || s.isEmpty) return '';
    final wtm = RegExp(
      r'## What This Means\n(.*?)(?=\n## |$)',
      dotAll: true,
    ).firstMatch(s);
    final wtmText = wtm?.group(1)?.trim();
    if (wtmText != null && wtmText.isNotEmpty) return wtmText;
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

  Widget _card({
    required Widget child,
    Color color = AppTheme.surface,
    Color? borderColor = AppTheme.borderWarm,
  }) {
    return SizedBox(
      width: double.infinity,
      child: HearthCard(
        padding: const EdgeInsets.all(20),
        color: color,
        borderColor: borderColor,
        child: child,
      ),
    );
  }

  /// Serif section heading with the 14px gap the mockup puts under it.
  List<Widget> _section(Widget heading) => [
        const SizedBox(height: 24),
        heading,
        const SizedBox(height: 14),
      ];

  @override
  Widget build(BuildContext context) {
    final appointmentDate = data['appointmentDate'];
    final readingLevel = data['readingLevel']?.toString() ?? '6th grade level';
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HearthPushedHeader(
                    backLabel: 'My Visits',
                    onBack: () => Navigator.pop(context),
                    actions: [
                      HearthTextAction(
                        icon: Icons.delete_outline,
                        label: 'Delete this summary',
                        onPressed: () =>
                            confirmDeleteVisitSummary(context, summaryId: summaryId),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // The date card is this screen's title, so it is the one purple card.
                  SizedBox(
                    width: double.infinity,
                    child: HearthFeatureCard(
                      tone: HearthTone.purple,
                      child: Row(
                        children: [
                          const HearthIconChip(
                            Icons.description_outlined,
                            tone: HearthChipTone.gold,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatHeaderDate(appointmentDate),
                                  style: text.displaySmall
                                      ?.copyWith(color: AppTheme.onPurple),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Visit summary · $readingLevel',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.sansFamily,
                                    fontSize: 14,
                                    height: 20 / 14,
                                    color: AppTheme.onPurpleSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Single-line disclaimer (replaces the large "About this summary" card).
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.info_outline,
                            size: 15, color: AppTheme.textMuted),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Plain-language summary. It doesn\'t replace medical advice from your provider.',
                          style: hearthCaptionStyle,
                        ),
                      ),
                    ],
                  ),
                  ..._section(const HearthSectionHeading('What was discussed')),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What this means', style: _cardLabelStyle),
                        const SizedBox(height: 10),
                        Text(
                          _whatWasDiscussed().isEmpty
                              ? 'Open your full summary below if sections are still loading.'
                              : _whatWasDiscussed(),
                          style: _bodyInkStyle,
                        ),
                        if (_summaryData != null &&
                            _summaryData!['keyMedicalTerms'] is List &&
                            (_summaryData!['keyMedicalTerms'] as List)
                                .isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Divider(height: 1, color: AppTheme.borderWarm),
                          const SizedBox(height: 14),
                          const Text('Key terms', style: _cardLabelStyle),
                          const SizedBox(height: 8),
                          ...(_summaryData!['keyMedicalTerms'] as List).map((t) {
                            if (t is! Map) return const SizedBox.shrink();
                            final term = t['term']?.toString() ?? '';
                            final exp = t['explanation']?.toString() ?? '';
                            return ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              minTileHeight: 44,
                              shape: const Border(),
                              collapsedShape: const Border(),
                              textColor: AppTheme.brandPurple,
                              collapsedTextColor: AppTheme.ink,
                              iconColor: AppTheme.brandPurple,
                              collapsedIconColor: AppTheme.textSecondary,
                              expandedAlignment: Alignment.centerLeft,
                              childrenPadding: const EdgeInsets.only(
                                bottom: 8,
                                left: 4,
                                right: 4,
                              ),
                              // No colour here so the tile's open/closed colours apply.
                              title: Text(
                                term,
                                style: const TextStyle(
                                  fontFamily: AppTheme.sansFamily,
                                  fontSize: 15,
                                  height: 22 / 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              children: [
                                Text(exp, style: hearthCardBodyStyle),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  if (_actionsMarkdown() != null &&
                      _actionsMarkdown()!.trim().isNotEmpty) ...[
                    ..._section(const HearthSectionHeading('Important next steps')),
                    _card(
                      child: MarkdownBody(
                        data: fixDoublePeriods(_actionsMarkdown()!),
                        styleSheet: MarkdownStyleSheet(
                          p: _bodyInkStyle,
                          listBullet: const TextStyle(
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_medicationsList().isNotEmpty) ...[
                    ..._section(const HearthSectionHeading('Medications mentioned')),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _medicationsList().map((med) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med['name']!, style: hearthCardTitleStyle),
                                if (med['detail']!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(med['detail']!, style: hearthCardBodyStyle),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (_questionsList().isNotEmpty) ...[
                    ..._section(
                      Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: AppTheme.brandPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Questions to ask next time',
                              style: text.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _card(
                      color: AppTheme.tintWarm,
                      borderColor: null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _questionsList().map((q) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Dot(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q,
                                    style: hearthCardBodyStyle.copyWith(
                                      color: AppTheme.ink,
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
                    ..._section(const HearthSectionHeading('Notes')),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _notesList().map((n) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppTheme.brandPurple,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(n, style: hearthCardBodyStyle),
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
                    ..._section(const HearthSectionHeading('Suggested learning')),
                    _card(
                      child: SuggestedLearningList(
                        summaryId: summaryId,
                        modules: (data['learningModules'] as List)
                            .whereType<Map>()
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Educational reminder collapsed into an expandable section.
                  SizedBox(
                    width: double.infinity,
                    child: HearthCard(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        minTileHeight: 52,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        iconColor: AppTheme.textSecondary,
                        collapsedIconColor: AppTheme.textSecondary,
                        childrenPadding: const EdgeInsets.only(bottom: 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppTheme.brandPurple,
                          size: 22,
                        ),
                        title: const Text(
                          'Reminder',
                          style: TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        children: const [
                          Text(
                            'This summary helps you understand your document. It does not replace medical advice from your healthcare provider. Always contact your provider with questions or concerns.',
                            style: hearthCaptionStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// Small purple label inside a card ("What this means", "Key terms").
const TextStyle _cardLabelStyle = TextStyle(
  fontFamily: AppTheme.sansFamily,
  fontSize: 13,
  height: 18 / 13,
  fontWeight: FontWeight.w700,
  color: AppTheme.brandPurple,
);

/// Summary prose: 15/22 ink, a little larger than other card body text.
const TextStyle _bodyInkStyle = TextStyle(
  fontFamily: AppTheme.sansFamily,
  fontSize: 15,
  height: 22 / 15,
  color: AppTheme.ink,
);

/// 6px purple bullet, nudged down to sit on the first line of 14/21 text.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: SizedBox(
        width: 6,
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.brandPurple,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Deletes the user's visit summary, matching `file_uploads` rows (and Storage objects),
/// and generated `learning_tasks` that reference this summary.
Future<void> confirmDeleteVisitSummary(
  BuildContext context, {
  required String summaryId,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final ok = await showHearthDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete this summary?'),
      content: const Text(
        'This removes the plain-language summary and your uploaded file record from your account. '
        'To-dos created from this visit are removed when possible; you can archive any that remain from Learning.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        // Destructive actions are an ink outline, never a filled or red button.
        HearthButton.destructive(
          expand: false,
          onPressed: () => Navigator.pop(ctx, true),
          label: 'Delete',
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    final fs = FirebaseFirestore.instance;

    final uploads = await fs
        .collection('users')
        .doc(uid)
        .collection('file_uploads')
        .where('summaryId', isEqualTo: summaryId)
        .get();

    for (final doc in uploads.docs) {
      final path = doc.data()['storagePath'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(path).delete();
        } catch (_) {}
      }
      await doc.reference.delete();
    }

    final tasksSnap = await fs
        .collection('learning_tasks')
        .where('userId', isEqualTo: uid)
        .get();
    for (final d in tasksSnap.docs) {
      final m = d.data();
      if (m['visitSummaryId'] == summaryId) {
        await d.reference.delete();
      }
    }

    await fs
        .collection('users')
        .doc(uid)
        .collection('visit_summaries')
        .doc(summaryId)
        .delete();

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary deleted'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete: $e'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    }
  }
}
