import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../Journal/journal_learning_note_opener.dart';

/// Suggested lessons from one visit summary, each opening its lesson.
///
/// While a lesson is still being saved or written it shows "Getting your
/// lesson ready…" with a spinner. It stays tappable: a tap while loading is
/// remembered and the lesson opens as soon as it's ready.
class SuggestedLearningList extends StatefulWidget {
  const SuggestedLearningList({
    super.key,
    required this.summaryId,
    required this.modules,
  });

  /// The visit summary the lessons were generated from (`visitSummaryId`).
  final String? summaryId;

  /// The summary's `learningModules` entries (title, reason/description).
  final List<Map> modules;

  @override
  State<SuggestedLearningList> createState() => _SuggestedLearningListState();
}

class _SuggestedLearningListState extends State<SuggestedLearningList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _lessons;
  String? _opening;
  String? _openWhenReady;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final summaryId = widget.summaryId;
    if (uid != null && summaryId != null && summaryId.isNotEmpty) {
      // Equality filters only, so no composite index is needed.
      _lessons = FirebaseFirestore.instance
          .collection('learning_tasks')
          .where('userId', isEqualTo: uid)
          .where('visitSummaryId', isEqualTo: summaryId)
          .snapshots();
    }
  }

  static String _key(String s) => s.trim().toLowerCase();

  static bool _hasContent(Object? content) {
    if (content == null) return false;
    if (content is String) return content.trim().isNotEmpty;
    if (content is Map) return content.isNotEmpty;
    if (content is List) return content.isNotEmpty;
    return true;
  }

  Future<void> _open(String? id, String title) async {
    setState(() {
      _opening = _key(title);
      _openWhenReady = null;
    });
    try {
      await openLearningNoteModule(context, moduleId: id, moduleTitle: title);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  void _queueOpen(String title) {
    setState(() => _openWhenReady = _key(title));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We\'ll open it as soon as it\'s ready.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _lessons,
      builder: (context, snapshot) {
        final byTitle = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        for (final doc in snapshot.data?.docs ?? const []) {
          if (doc.data()['moduleType'] != 'visit_based') continue;
          byTitle[_key((doc.data()['title'] ?? '').toString())] = doc;
        }
        final loaded = snapshot.hasData || snapshot.hasError || _lessons == null;

        // A lesson tapped while loading opens once it's ready.
        final pending = _openWhenReady;
        if (pending != null) {
          final doc = byTitle[pending];
          if (doc != null && _hasContent(doc.data()['content'])) {
            final title = (doc.data()['title'] ?? '').toString();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _openWhenReady == pending) _open(doc.id, title);
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.modules.length; i++)
              _row(i + 1, widget.modules[i], byTitle, loaded),
          ],
        );
      },
    );
  }

  Widget _row(
    int number,
    Map m,
    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> byTitle,
    bool loaded,
  ) {
    final title = m['title']?.toString() ?? 'Topic';
    final reason = (m['reason'] ?? m['description'] ?? '').toString();
    final doc = byTitle[_key(title)];
    final ready = doc != null && _hasContent(doc.data()['content']);
    // Not found once loaded: older summaries may have no saved lesson; the
    // opener then finds it by title or falls back to the Learn tab.
    final waiting = !loaded || (doc != null && !ready);
    final busy = _opening == _key(title);
    final queued = _openWhenReady == _key(title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : () => waiting ? _queueOpen(title) : _open(doc?.id, title),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. $title',
                      style: hearthCardBodyStyle.copyWith(
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w700,
                        color: waiting ? AppTheme.textMuted : AppTheme.brandPurple,
                      ),
                    ),
                    if (reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(reason, style: hearthCardBodyStyle),
                      ),
                    if (waiting)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          queued ? 'Opening as soon as it\'s ready…' : 'Getting your lesson ready…',
                          style: hearthCaptionStyle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: waiting || busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brandPurple,
                        ),
                      )
                    : const Icon(Icons.chevron_right, size: 20, color: AppTheme.brandPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
