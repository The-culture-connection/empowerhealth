import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

class NotesDialog extends StatefulWidget {
  final String? preFilledText; // For highlighted text
  final String? moduleTitle;
  final String? moduleId;

  /// Pre-selected journal category. When the note is saved from a known
  /// section (Know Your Rights, Questions to Ask, etc.) the category is set
  /// automatically so the user doesn't have to organize it manually.
  final String? initialTag;

  /// When set, the dialog edits this existing note in users/{uid}/notes
  /// instead of adding a new one.
  final String? noteId;

  /// Existing note text to pre-fill when editing ([noteId] set).
  final String? initialContent;

  const NotesDialog({
    super.key,
    this.preFilledText, // This will be the highlighted text
    this.moduleTitle,
    this.moduleId,
    this.initialTag,
    this.noteId,
    this.initialContent,
  });

  bool get isEditing => noteId != null;

  /// Journal categories. The richer set lets saved content be auto-organized
  /// by the section it came from (see [categoryForSection]).
  static const List<String> journalCategories = [
    'Questions for My Provider',
    'Birth Preferences',
    'Labor & Delivery Questions',
    'Rights & Self-Advocacy',
    'Health Information I Want to Remember',
    'Emotional Reflection',
    'Track a symptom',
  ];

  /// Maps the section a note was saved from to its default journal category.
  /// Returns null when the section is unknown (user picks manually).
  static String? categoryForSection(String? section) {
    switch (section) {
      case 'know_your_rights':
      case 'rights':
        return 'Rights & Self-Advocacy';
      case 'questions_to_ask':
      case 'questions':
        return 'Questions for My Provider';
      case 'birth_preferences':
      case 'birth_plan':
        return 'Birth Preferences';
      case 'labor_delivery':
      case 'labor_and_delivery':
        return 'Labor & Delivery Questions';
      case 'health_made_simple':
      case 'learning':
      case 'learning_module':
        return 'Health Information I Want to Remember';
      case 'emotional_support':
      case 'emotional':
        return 'Emotional Reflection';
      default:
        return null;
    }
  }

  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedTag;
  bool _isSaving = false;

  List<String> get _tags => NotesDialog.journalCategories;

  @override
  void initState() {
    super.initState();
    // Auto-categorize when opened from a known section.
    if (widget.initialTag != null &&
        NotesDialog.journalCategories.contains(widget.initialTag)) {
      _selectedTag = widget.initialTag;
    }
    if (widget.initialContent != null) {
      _notesController.text = widget.initialContent!;
    }
    // Don't pre-fill notes with highlighted text - show it separately
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some notes before saving'),
        ),
      );
      return;
    }

    if (_selectedTag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tag for your note'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final notes = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes');

      if (widget.isEditing) {
        await notes.doc(widget.noteId).update({
          'content': _notesController.text.trim(),
          'tag': _selectedTag,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      await notes.add({
        'content': _notesController.text.trim(),
        'tag': _selectedTag,
        'moduleTitle': widget.moduleTitle,
        'moduleId': widget.moduleId,
        'highlightedText': widget.preFilledText != null ? widget.preFilledText : null,
        'isFromModule': widget.moduleTitle != null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved to journal!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // The note dialog sits on the lighter surface so its fields read as inset.
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.borderWarm),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Icon(Icons.note_add_outlined, size: 22, color: AppTheme.brandPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Edit Note'
                          : widget.preFilledText != null
                              ? 'Add Note from Highlight'
                              : 'Add Note',
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  HearthCircleButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module title if available
                    if (widget.moduleTitle != null) ...[
                      DecoratedBox(
                        decoration: const ShapeDecoration(
                          color: AppTheme.tintWarm,
                          shape: StadiumBorder(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.brandPurple),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'From: ${widget.moduleTitle}',
                                  style: textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Highlighted text if available
                    if (widget.preFilledText != null && widget.preFilledText!.trim().isNotEmpty) ...[
                      NoteHighlightQuote(
                        label: 'Highlighted Text:',
                        text: widget.preFilledText!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Notes text field
                    Text('Your Notes', style: textTheme.labelMedium?.copyWith(color: AppTheme.ink)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        fillColor: AppTheme.surfaceInset,
                        hintText: widget.preFilledText != null
                            ? 'Add your thoughts about the highlighted text...'
                            : 'Write your notes here...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.keyboard_hide,
                              color: AppTheme.textMuted, size: 20),
                          onPressed: () => FocusScope.of(context).unfocus(),
                          tooltip: 'Dismiss keyboard',
                        ),
                      ),
                      maxLines: 8,
                      minLines: 4,
                    ),
                    const SizedBox(height: 16),
                    // Tag selection
                    const Text('Tag this note:', style: hearthCardTitleStyle),
                    const SizedBox(height: 6),
                    ..._tags.map((tag) {
                      final selected = _selectedTag == tag;
                      return RadioListTile<String>(
                        title: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppTheme.ink : AppTheme.textSecondary,
                          ),
                        ),
                        value: tag,
                        groupValue: _selectedTag,
                        onChanged: (value) {
                          setState(() => _selectedTag = value);
                        },
                        activeColor: AppTheme.brandPurple,
                        selected: selected,
                        tileColor: Colors.transparent,
                        selectedTileColor: AppTheme.tintWarm,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selected ? AppTheme.brandPurple : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Footer buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: HearthButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HearthButton.primary(
                      label: 'Save',
                      loading: _isSaving,
                      onPressed: _saveNote,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A saved passage: inset fill with a gold rule on the left, as in the note
/// dialog and the lesson-notes viewer.
class NoteHighlightQuote extends StatelessWidget {
  const NoteHighlightQuote({
    super.key,
    required this.text,
    this.label,
    this.maxLines,
  });

  final String text;
  final String? label;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderWarm),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 4, child: ColoredBox(color: AppTheme.brandGold)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.format_quote, size: 16, color: AppTheme.brandPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label!,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      text,
                      maxLines: maxLines,
                      overflow: maxLines == null ? null : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 13,
                        height: 19 / 13,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.ink,
                      ),
                    ),
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

