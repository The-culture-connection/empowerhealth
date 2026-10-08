import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'notes_dialog.dart';

/// A journal note the user took on a lesson (users/{uid}/notes, written by
/// [NotesDialog]).
class ModuleNote {
  const ModuleNote({
    required this.id,
    required this.content,
    this.tag,
    this.highlightedText,
    this.moduleId,
    this.moduleTitle,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String content;
  final String? tag;
  final String? highlightedText;
  final String? moduleId;
  final String? moduleTitle;

  /// Null while a just-saved note's server timestamp is pending.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ModuleNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    String? str(String key) {
      final v = data[key];
      if (v == null) return null;
      final s = v.toString();
      return s.trim().isEmpty ? null : s;
    }

    DateTime? date(String key) {
      final v = data[key];
      return v is Timestamp ? v.toDate() : null;
    }

    return ModuleNote(
      id: doc.id,
      content: (data['content'] ?? '').toString(),
      tag: str('tag'),
      highlightedText: str('highlightedText'),
      moduleId: str('moduleId'),
      moduleTitle: str('moduleTitle'),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
    );
  }
}

/// Live list of the signed-in user's notes on one lesson, oldest first.
///
/// Uses two single-field equality queries (no composite index needed):
/// `moduleId == moduleId` and, for older notes saved without an id,
/// `moduleTitle == moduleTitle`. Results are merged client-side; a
/// title match that belongs to a different module id is dropped.
Stream<List<ModuleNote>> watchModuleNotes({
  String? moduleId,
  required String moduleTitle,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final id = moduleId?.trim() ?? '';
  final title = moduleTitle.trim();
  if (uid == null) return Stream.value(const <ModuleNote>[]);

  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('notes');
  final queries = <Query<Map<String, dynamic>>>[
    if (id.isNotEmpty) col.where('moduleId', isEqualTo: id),
    if (title.isNotEmpty) col.where('moduleTitle', isEqualTo: title),
  ];
  if (queries.isEmpty) return Stream.value(const <ModuleNote>[]);

  final latest = List<List<ModuleNote>?>.filled(queries.length, null);
  final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  late final StreamController<List<ModuleNote>> controller;

  void emit() {
    final byId = <String, ModuleNote>{};
    for (final list in latest) {
      if (list == null) continue;
      for (final note in list) {
        final noteId = note.moduleId ?? '';
        if (id.isNotEmpty && noteId.isNotEmpty && noteId != id) continue;
        byId[note.id] = note;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        // Pending (null) timestamps are the newest notes.
        final ad = a.createdAt, bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    if (!controller.isClosed) controller.add(merged);
  }

  controller = StreamController<List<ModuleNote>>(
    onListen: () {
      for (var i = 0; i < queries.length; i++) {
        subs.add(
          queries[i].snapshots().listen(
            (snap) {
              // "Save" bookmarks (savedLesson) aren't notes on the text.
              latest[i] = snap.docs
                  .where((d) => d.data()['savedLesson'] != true)
                  .map(ModuleNote.fromDoc)
                  .toList();
              emit();
            },
            onError: (Object e) {
              debugPrint('Error loading lesson notes: $e');
              latest[i] = const <ModuleNote>[];
              emit();
            },
          ),
        );
      }
    },
    onCancel: () async {
      for (final sub in subs) {
        await sub.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

String _formatNoteDate(ModuleNote note) {
  final created = note.createdAt;
  if (created == null) return 'Saved just now';
  final fmt = DateFormat('MMM d, y');
  final updated = note.updatedAt;
  final edited =
      updated != null && updated.difference(created).inSeconds.abs() > 5;
  return edited
      ? 'Saved ${fmt.format(created)} (edited ${fmt.format(updated)})'
      : 'Saved ${fmt.format(created)}';
}

/// Shows the given lesson note(s) with their highlighted passage, date and
/// tag, plus Edit and Delete actions.
Future<void> showModuleNotesDialog(
  BuildContext context, {
  required List<ModuleNote> notes,
  required String moduleTitle,
  String? moduleId,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ModuleNotesViewDialog(
      notes: notes,
      moduleTitle: moduleTitle,
      moduleId: moduleId,
    ),
  );
}

class _ModuleNotesViewDialog extends StatelessWidget {
  const _ModuleNotesViewDialog({
    required this.notes,
    required this.moduleTitle,
    this.moduleId,
  });

  final List<ModuleNote> notes;
  final String moduleTitle;
  final String? moduleId;

  Future<void> _edit(BuildContext context, ModuleNote note) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await showDialog<void>(
      context: navigator.context,
      builder: (_) => NotesDialog(
        noteId: note.id,
        initialContent: note.content,
        initialTag: note.tag,
        preFilledText: note.highlightedText,
        moduleTitle: note.moduleTitle ?? moduleTitle,
        moduleId: note.moduleId ?? moduleId,
      ),
    );
  }

  Future<void> _delete(BuildContext context, ModuleNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This removes it from your journal.'),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: HearthButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(c).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              // Destructive actions use the ink outline, not red.
              Expanded(
                child: HearthButton.destructive(
                  label: 'Delete',
                  onPressed: () => Navigator.of(c).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(note.id)
          .delete();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not delete note: $e'),
        ),
      );
    }
  }

  Widget _noteCard(BuildContext context, ModuleNote note) {
    final highlight = note.highlightedText?.trim();
    return HearthCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlight != null && highlight.isNotEmpty) ...[
              NoteHighlightQuote(text: highlight, maxLines: 4),
              const SizedBox(height: 10),
            ],
            Text(
              note.content,
              style: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 15,
                height: 22 / 15,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                _formatNoteDate(note),
                if (note.tag != null) note.tag!,
              ].join(' · '),
              style: hearthCaptionStyle,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              children: [
                HearthTextAction(
                  onPressed: () => _edit(context, note),
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppTheme.brandPurple,
                ),
                // Quiet ink action; destructive is never red.
                HearthTextAction(
                  onPressed: () => _delete(context, note),
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppTheme.ink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 22, color: AppTheme.brandPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notes.length == 1 ? 'Your note' : 'Your notes',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  HearthCircleButton(
                    icon: Icons.close,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final note in notes) _noteCard(context, note),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
