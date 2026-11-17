import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Firestore: `users/{uid}/visit_questions` (covered by the owner wildcard rule).
const String kVisitQuestionsCollection = 'visit_questions';

/// General starters, offered when there are no questions from a visit summary.
const List<String> kStarterVisitQuestions = [
  'Is what I am feeling normal at this stage?',
  'What warning signs mean I should call you or go to the hospital?',
  'What tests or vaccines are coming up, and why do I need them?',
  'Can you explain that again in simpler words?',
];

CollectionReference<Map<String, dynamic>>? _questionsRef() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(kVisitQuestionsCollection);
}

/// Saves [questions] to the user's list, skipping ones already there.
/// Returns how many were added.
Future<int> saveVisitQuestions(
  List<String> questions, {
  String source = 'user',
  String? summaryId,
}) async {
  final ref = _questionsRef();
  if (ref == null) return 0;
  final existing = await ref.get();
  final have = existing.docs
      .map((d) => (d.data()['text'] as String? ?? '').trim().toLowerCase())
      .toSet();
  var added = 0;
  for (final raw in questions) {
    final text = raw.trim();
    if (text.isEmpty || !have.add(text.toLowerCase())) continue;
    await ref.add({
      'text': text,
      'asked': false,
      'source': source,
      if (summaryId != null) 'summaryId': summaryId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    added++;
  }
  return added;
}

/// Opens the question list from anywhere.
Future<void> openVisitQuestions(BuildContext context) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => const VisitQuestionsScreen()),
  );
}

/// Pulls "questions to ask" from the newest visit summary, if any.
Future<List<String>> _latestSummaryQuestions() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const [];
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('visit_summaries')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return const [];
    final data = snap.docs.first.data();
    for (final key in ['summaryData', 'summary']) {
      final sd = data[key];
      if (sd is Map && sd['questionsToAsk'] is List) {
        return (sd['questionsToAsk'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
  } catch (e) {
    debugPrint('Visit questions: could not read latest summary: $e');
  }
  return const [];
}

/// Appointment preparation: write, save and check off questions for the next visit.
class VisitQuestionsScreen extends StatefulWidget {
  const VisitQuestionsScreen({super.key});

  @override
  State<VisitQuestionsScreen> createState() => _VisitQuestionsScreenState();
}

class _VisitQuestionsScreenState extends State<VisitQuestionsScreen> {
  final TextEditingController _controller = TextEditingController();
  late final Future<List<String>> _summaryQuestions = _latestSummaryQuestions();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addTyped() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final added = await saveVisitQuestions([text]);
      _controller.clear();
      _snack(added > 0
          ? 'Question saved to your list'
          : 'That question is already on your list');
    } catch (e) {
      debugPrint('Visit question save failed: $e');
      _snack("We couldn't save your question right now. Please try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSuggestion(String text, String source) async {
    try {
      final added = await saveVisitQuestions([text], source: source);
      _snack(added > 0
          ? 'Question saved to your list'
          : 'That question is already on your list');
    } catch (e) {
      debugPrint('Visit question save failed: $e');
      _snack("We couldn't save your question right now. Please try again.");
    }
  }

  Future<void> _setAsked(DocumentReference ref, bool asked) async {
    try {
      await ref.update({'asked': asked});
    } catch (e) {
      debugPrint('Visit question update failed: $e');
      _snack("We couldn't update that question. Please try again.");
    }
  }

  Future<void> _delete(DocumentReference ref) async {
    try {
      await ref.delete();
      _snack('Question removed');
    } catch (e) {
      debugPrint('Visit question delete failed: $e');
      _snack("We couldn't remove that question. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _questionsRef();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: ref == null
            ? Column(
                children: [
                  const HearthPushedHeader(title: 'My visit questions'),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sign in to save questions for your visits.',
                        style: text.bodyLarge,
                      ),
                    ),
                  ),
                ],
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ref.orderBy('createdAt', descending: false).snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  final open = docs.where((d) => d.data()['asked'] != true).toList();
                  final asked = docs.where((d) => d.data()['asked'] == true).toList();
                  final saved = docs
                      .map((d) => (d.data()['text'] as String? ?? '')
                          .trim()
                          .toLowerCase())
                      .toSet();

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const HearthPushedHeader(
                        title: 'My visit questions',
                        subtitle:
                            'Saved to your account. Open this list at your visit.',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 300,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addTyped(),
                              decoration: const InputDecoration(
                                labelText: 'Add a question',
                                hintText: 'e.g. Why do I need this test?',
                              ),
                            ),
                            HearthButton.primary(
                              label: 'Save question',
                              icon: Icons.add,
                              loading: _saving,
                              onPressed: _addTyped,
                            ),
                            const SizedBox(height: 24),
                            HearthSectionHeading(
                              open.isEmpty && asked.isEmpty
                                  ? 'Your list'
                                  : 'To ask (${open.length})',
                            ),
                            const SizedBox(height: 10),
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData)
                              const Center(child: CircularProgressIndicator())
                            else if (open.isEmpty)
                              Text(
                                asked.isEmpty
                                    ? 'No questions yet. Type one above or add a suggestion below.'
                                    : 'You have asked every question on your list.',
                                style: hearthCardBodyStyle,
                              )
                            else
                              ...open.map(
                                (d) => _QuestionRow(
                                  text: d.data()['text'] as String? ?? '',
                                  asked: false,
                                  onToggle: (v) => _setAsked(d.reference, v),
                                  onDelete: () => _delete(d.reference),
                                ),
                              ),
                            if (asked.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              HearthSectionHeading('Asked (${asked.length})'),
                              const SizedBox(height: 10),
                              ...asked.map(
                                (d) => _QuestionRow(
                                  text: d.data()['text'] as String? ?? '',
                                  asked: true,
                                  onToggle: (v) => _setAsked(d.reference, v),
                                  onDelete: () => _delete(d.reference),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FutureBuilder<List<String>>(
                              future: _summaryQuestions,
                              builder: (context, snap) {
                                final fromSummary = snap.data ?? const [];
                                final source = fromSummary.isEmpty
                                    ? 'starter'
                                    : 'visit_summary';
                                final ideas = (fromSummary.isEmpty
                                        ? kStarterVisitQuestions
                                        : fromSummary)
                                    .where((q) =>
                                        !saved.contains(q.trim().toLowerCase()))
                                    .toList();
                                if (ideas.isEmpty) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    HearthSectionHeading(
                                      fromSummary.isEmpty
                                          ? 'Ideas to get started'
                                          : 'From your latest visit summary',
                                    ),
                                    const SizedBox(height: 10),
                                    ...ideas.map(
                                      (q) => _SuggestionRow(
                                        text: q,
                                        onAdd: () => _addSuggestion(q, source),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.text,
    required this.asked,
    required this.onToggle,
    required this.onDelete,
  });

  final String text;
  final bool asked;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HearthCard(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        onTap: () => onToggle(!asked),
        child: Row(
          children: [
            Checkbox(
              value: asked,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: AppTheme.brandPurple,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  text,
                  style: hearthCardBodyStyle.copyWith(
                    color: asked ? AppTheme.textMuted : AppTheme.ink,
                    decoration: asked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppTheme.textMuted,
              tooltip: 'Remove question',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.text, required this.onAdd});

  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HearthCard(
        color: AppTheme.tintWarm,
        borderColor: null,
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        onTap: onAdd,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  text,
                  style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: AppTheme.brandPurple,
              tooltip: 'Add to my list',
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
