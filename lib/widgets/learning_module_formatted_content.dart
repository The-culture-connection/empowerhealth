import 'package:flutter/material.dart';

import '../cors/ui_theme.dart' show AppTheme;
import '../learning/module_notes.dart';
import '../learning/notes_dialog.dart';
import 'note_highlight_spans.dart';

/// Renders AI learning module text: sections, inline **bold**, bullets, and notes UX.
///
/// When [onAddNote] is set, the selection context menu (long-press on mobile)
/// gets an "Add note" action, and [onSelectionTextChanged] reports the current
/// selection so the host screen can offer its own "Add note" button (needed on
/// web, where the browser's context menu replaces Flutter's).
///
/// Otherwise, when [selectionControls] is null, long-press selection shows a
/// snackbar + [NotesDialog].
///
/// [notes] are the user's saved notes on this lesson: each note's
/// highlighted passage is shaded in the paragraph that contains it, followed
/// by a tappable note emblem, and every note is listed under "Your notes on
/// this lesson" at the end.
class LearningModuleFormattedContent extends StatelessWidget {
  const LearningModuleFormattedContent({
    super.key,
    required this.content,
    required this.moduleTitle,
    this.moduleId,
    this.selectionControls,
    this.onAddNote,
    this.onSelectionTextChanged,
    this.notes = const <ModuleNote>[],
  });

  final String content;
  final String moduleTitle;
  final String? moduleId;
  final TextSelectionControls? selectionControls;

  /// The user's notes on this lesson (see [watchModuleNotes]).
  final List<ModuleNote> notes;

  /// Called with the selected text when the user picks "Add note" from the
  /// selection context menu.
  final ValueChanged<String>? onAddNote;

  /// Called with the selected text whenever the user changes a selection
  /// (empty string when the selection collapses).
  final ValueChanged<String>? onSelectionTextChanged;

  @override
  Widget build(BuildContext context) {
    final cleaned = content.replaceAll('\$1', '\n\n---\n\n');
    final lines = cleaned.split('\n');
    final widgets = <Widget>[];
    var i = 0;

    while (i < lines.length) {
      final raw = lines[i];
      final t = raw.trim();
      if (t.isEmpty) {
        i++;
        continue;
      }
      if (t == '---' || (t.startsWith('---') && t.length <= 5)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.borderLight.withOpacity(0.8),
            ),
          ),
        );
        i++;
        continue;
      }
      if (t.startsWith('## ')) {
        final title = t.substring(3).trim();
        final chunk = _collectBodyUntilNextSection(lines, i + 1);
        i = chunk.$2;
        final tier = RegExp(r'^\d+\.').hasMatch(title)
            ? _SectionStyleTier.card
            : _SectionStyleTier.h2;
        widgets.add(
          _EngagingModuleSection(
            title: title,
            body: chunk.$1,
            moduleTitle: moduleTitle,
            styleTier: tier,
            selectionControls: selectionControls,
          ),
        );
        continue;
      }
      if (t.startsWith('### ')) {
        final title = t.substring(4).trim();
        final chunk = _collectBodyUntilNextSection(lines, i + 1);
        i = chunk.$2;
        widgets.add(
          _EngagingModuleSection(
            title: title,
            body: chunk.$1,
            moduleTitle: moduleTitle,
            styleTier: _SectionStyleTier.h3,
            selectionControls: selectionControls,
          ),
        );
        continue;
      }
      if (_isBoldWrappedSectionLine(t)) {
        final title = _stripOuterBold(t);
        final chunk = _collectBodyUntilNextSection(lines, i + 1);
        i = chunk.$2;
        widgets.add(
          _EngagingModuleSection(
            title: title,
            body: chunk.$1,
            moduleTitle: moduleTitle,
            styleTier: _SectionStyleTier.card,
            selectionControls: selectionControls,
          ),
        );
        continue;
      }
      if (t.startsWith('• ') || t.startsWith('- ')) {
        widgets.add(
          _BulletLine(
            text: raw.startsWith('• ') || raw.startsWith('- ')
                ? raw.substring(2).trim()
                : t.substring(2).trim(),
            moduleTitle: moduleTitle,
            selectionControls: selectionControls,
          ),
        );
        i++;
        continue;
      }
      final chunk = _collectBodyUntilNextSection(lines, i);
      i = chunk.$2;
      if (chunk.$1.trim().isNotEmpty) {
        widgets.add(
          _EngagingModuleSection(
            title: 'Overview',
            body: chunk.$1,
            moduleTitle: moduleTitle,
            styleTier: _SectionStyleTier.intro,
            selectionControls: selectionControls,
          ),
        );
      }
    }

    if (notes.isNotEmpty) {
      widgets.add(
        _LessonNotesList(
          notes: notes,
          moduleTitle: moduleTitle,
          moduleId: moduleId,
        ),
      );
    }

    return _ModuleNotesScope(
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      notes: notes,
      onAddNote: onAddNote,
      onSelectionTextChanged: onSelectionTextChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}

/// Passes the note callbacks (and the user's saved notes) down to every
/// selectable paragraph without threading them through each section widget.
class _ModuleNotesScope extends InheritedWidget {
  const _ModuleNotesScope({
    required this.moduleId,
    required this.moduleTitle,
    required this.notes,
    required this.onAddNote,
    required this.onSelectionTextChanged,
    required super.child,
  });

  final String? moduleId;
  final String moduleTitle;
  final List<ModuleNote> notes;
  final ValueChanged<String>? onAddNote;
  final ValueChanged<String>? onSelectionTextChanged;

  static _ModuleNotesScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ModuleNotesScope>();

  @override
  bool updateShouldNotify(_ModuleNotesScope oldWidget) =>
      moduleId != oldWidget.moduleId ||
      moduleTitle != oldWidget.moduleTitle ||
      notes != oldWidget.notes ||
      onAddNote != oldWidget.onAddNote ||
      onSelectionTextChanged != oldWidget.onSelectionTextChanged;
}

/// Soft highlight behind text the user has taken a note on.
TextStyle _noteHighlightStyle(TextStyle? base) =>
    (base ?? const TextStyle()).copyWith(
      backgroundColor: AppTheme.brandGold.withOpacity(0.32),
    );

/// Small tappable note icon shown right after a highlighted passage. Works
/// with a mouse click on web and a tap on mobile.
class _NoteEmblem extends StatelessWidget {
  const _NoteEmblem({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count == 1 ? 'View your note' : 'View your $count notes',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppTheme.brandPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                size: 14,
                color: AppTheme.brandWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Your notes on this lesson": every saved note, including ones whose
/// highlighted text couldn't be located in the lesson (or that have none).
class _LessonNotesList extends StatelessWidget {
  const _LessonNotesList({
    required this.notes,
    required this.moduleTitle,
    this.moduleId,
  });

  final List<ModuleNote> notes;
  final String moduleTitle;
  final String? moduleId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_rounded,
                size: 18,
                color: AppTheme.brandPurple,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Your notes on this lesson',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppTheme.brandWhite,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showModuleNotesDialog(
                    context,
                    notes: [note],
                    moduleTitle: moduleTitle,
                    moduleId: moduleId,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note.highlightedText != null) ...[
                                Text(
                                  '"${note.highlightedText!.trim()}"',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

bool _isBoldWrappedSectionLine(String t) {
  final s = t.trim();
  return s.startsWith('**') && s.endsWith('**') && s.length > 4;
}

String _stripOuterBold(String t) {
  final s = t.trim();
  if (_isBoldWrappedSectionLine(s)) {
    return s.substring(2, s.length - 2).trim();
  }
  return s;
}

(String, int) _collectBodyUntilNextSection(List<String> lines, int start) {
  final buf = StringBuffer();
  var i = start;
  while (i < lines.length) {
    final t = lines[i].trim();
    if (t.isEmpty) {
      buf.writeln();
      i++;
      continue;
    }
    if (t.startsWith('## ') || t.startsWith('### ')) break;
    if (_isBoldWrappedSectionLine(t)) break;
    if (t == '---' || (t.startsWith('---') && t.length <= 5)) break;
    buf.writeln(lines[i]);
    i++;
  }
  return (buf.toString().trimRight(), i);
}

enum _SectionStyleTier { intro, h2, h3, card }

class _EngagingModuleSection extends StatelessWidget {
  const _EngagingModuleSection({
    required this.title,
    required this.body,
    required this.moduleTitle,
    required this.styleTier,
    this.selectionControls,
  });

  final String title;
  final String body;
  final String moduleTitle;
  final _SectionStyleTier styleTier;
  final TextSelectionControls? selectionControls;

  static final _numberedTitle = RegExp(r'^(\d+)\.\s*(.+)$');

  IconData _iconForTitle(String titleLower) {
    if (titleLower.contains('what this is')) return Icons.menu_book_rounded;
    if (titleLower.contains('why it matters')) return Icons.favorite_rounded;
    if (titleLower.contains('what to expect')) return Icons.visibility_rounded;
    if (titleLower.contains('what you can ask')) return Icons.chat_bubble_outline_rounded;
    if (titleLower.contains('risk') || titleLower.contains('option')) {
      return Icons.shield_outlined;
    }
    if (titleLower.contains('when to seek')) return Icons.health_and_safety_outlined;
    if (titleLower.contains('key point')) return Icons.star_rounded;
    if (titleLower.contains('right')) return Icons.volunteer_activism_outlined;
    if (titleLower.contains('insurance')) return Icons.description_outlined;
    if (titleLower.contains('empowerment')) return Icons.auto_awesome_rounded;
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final titleLower = title.toLowerCase();
    final icon = _iconForTitle(titleLower);
    final numbered = _numberedTitle.firstMatch(title);

    if (styleTier == _SectionStyleTier.intro) {
      if (body.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _ModuleBodyBlocks(
          body: body,
          moduleTitle: moduleTitle,
          selectionControls: selectionControls,
        ),
      );
    }

    if (styleTier == _SectionStyleTier.h2) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandPurple,
                height: 1.25,
              ),
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _ModuleBodyBlocks(
                body: body,
                moduleTitle: moduleTitle,
                selectionControls: selectionControls,
              ),
            ],
          ],
        ),
      );
    }
    if (styleTier == _SectionStyleTier.h3) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ModuleBodyBlocks(
                body: body,
                moduleTitle: moduleTitle,
                selectionControls: selectionControls,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderLight.withOpacity(0.55)),
          boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 16, y: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEDE7F3).withOpacity(0.55),
                    AppTheme.surfaceCard,
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppTheme.brandPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numbered != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandGold.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  numbered.group(1)!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  numbered.group(2)!.trim(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (body.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: _ModuleBodyBlocks(
                  body: body,
                  moduleTitle: moduleTitle,
                  selectionControls: selectionControls,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleBodyBlocks extends StatelessWidget {
  const _ModuleBodyBlocks({
    required this.body,
    required this.moduleTitle,
    this.selectionControls,
  });

  final String body;
  final String moduleTitle;
  final TextSelectionControls? selectionControls;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final buf = StringBuffer();

    void flushParagraph() {
      final s = buf.toString().trim();
      if (s.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RichSelectableParagraph(
            text: s,
            moduleTitle: moduleTitle,
            selectionControls: selectionControls,
          ),
        ),
      );
      buf.clear();
    }

    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) {
        flushParagraph();
        continue;
      }
      if (t.startsWith('• ') || t.startsWith('- ')) {
        flushParagraph();
        widgets.add(
          _BulletLine(
            text: line.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim(),
            moduleTitle: moduleTitle,
            selectionControls: selectionControls,
          ),
        );
      } else {
        if (buf.isNotEmpty) buf.writeln();
        buf.write(line);
      }
    }
    flushParagraph();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _RichSelectableParagraph extends StatelessWidget {
  const _RichSelectableParagraph({
    required this.text,
    required this.moduleTitle,
    this.selectionControls,
  });

  final String text;
  final String moduleTitle;
  final TextSelectionControls? selectionControls;

  static const _base = TextStyle(
    fontSize: 16,
    height: 1.55,
    color: AppTheme.textSecondary,
    fontWeight: FontWeight.w300,
  );

  static List<TextSpan> _spans(String input) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;
    for (final m in re.allMatches(input)) {
      if (m.start > start) {
        spans.add(TextSpan(text: input.substring(start, m.start), style: _base));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: _base.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      );
      start = m.end;
    }
    if (start < input.length) {
      spans.add(TextSpan(text: input.substring(start), style: _base));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: input, style: _base));
    }
    return spans;
  }

  static String _plain(String input) =>
      input.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);

  /// Inline note emblems are WidgetSpans, which occupy one placeholder
  /// character in the selectable text; strip them from selected text.
  static String _withoutPlaceholders(String s) =>
      s.replaceAll(String.fromCharCode(PlaceholderSpan.placeholderCodeUnit), '');

  /// The paragraph's spans with the user's noted passages highlighted and
  /// followed by a tappable note emblem.
  List<InlineSpan> _spansWithNotes(BuildContext context, _ModuleNotesScope? scope) {
    final spans = _spans(text);
    if (scope == null || scope.notes.isEmpty) return spans;
    final ranges = findNoteHighlightRanges<ModuleNote>(
      _plain(text),
      scope.notes,
      (note) => note.highlightedText,
    );
    if (ranges.isEmpty) return spans;
    return applyNoteHighlights<ModuleNote>(
      spans,
      ranges,
      highlightStyle: _noteHighlightStyle,
      emblemBuilder: (range) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _NoteEmblem(
          count: range.items.length,
          onTap: () => showModuleNotesDialog(
            context,
            notes: range.items,
            moduleTitle: scope.moduleTitle,
            moduleId: scope.moduleId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _ModuleNotesScope.of(context);
    final spans = _spansWithNotes(context, notes);
    // Selection offsets count each emblem as one placeholder character.
    final plain = TextSpan(children: spans).toPlainText();
    final onAddNote = notes?.onAddNote;

    if (onAddNote != null) {
      return SelectableText.rich(
        TextSpan(children: spans),
        onSelectionChanged: (selection, cause) {
          // Only user-driven changes (long-press, drag, double-tap, tap to
          // clear) are reported.
          if (cause == null) return;
          var selected = '';
          if (selection.isValid && !selection.isCollapsed) {
            final a = selection.start.clamp(0, plain.length);
            final b = selection.end.clamp(0, plain.length);
            if (a < b) {
              selected = _withoutPlaceholders(plain.substring(a, b)).trim();
            }
          }
          notes?.onSelectionTextChanged?.call(selected);
        },
        contextMenuBuilder: (context, editableTextState) {
          final value = editableTextState.textEditingValue;
          final selected = value.selection.isValid
              ? _withoutPlaceholders(value.selection.textInside(value.text))
                  .trim()
              : '';
          final items = <ContextMenuButtonItem>[
            if (selected.isNotEmpty)
              ContextMenuButtonItem(
                label: 'Add note',
                onPressed: () {
                  editableTextState.hideToolbar();
                  onAddNote(selected);
                },
              ),
            ...editableTextState.contextMenuButtonItems,
          ];
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: items,
          );
        },
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      selectionControls: selectionControls,
      onSelectionChanged: selectionControls != null
          ? null
          : (selection, cause) {
              if (!selection.isValid || selection.isCollapsed) return;
              if (cause != SelectionChangedCause.longPress) return;
              final a = selection.start.clamp(0, plain.length);
              final b = selection.end.clamp(0, plain.length);
              if (a >= b) return;
              final selectedText =
                  _withoutPlaceholders(plain.substring(a, b)).trim();
              if (selectedText.length <= 3) return;
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selected: ${selectedText.length > 40 ? "${selectedText.substring(0, 40)}..." : selectedText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          showDialog(
                            context: context,
                            builder: (context) => NotesDialog(
                              preFilledText: selectedText,
                              moduleTitle: moduleTitle,
                              moduleId: notes?.moduleId,
                            ),
                          );
                        },
                        child: const Text(
                          'Add Note',
                          style: TextStyle(color: AppTheme.brandWhite),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppTheme.brandPurple,
                ),
              );
            },
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({
    required this.text,
    required this.moduleTitle,
    this.selectionControls,
  });

  final String text;
  final String moduleTitle;
  final TextSelectionControls? selectionControls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppTheme.brandGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RichSelectableParagraph(
              text: text,
              moduleTitle: moduleTitle,
              selectionControls: selectionControls,
            ),
          ),
        ],
      ),
    );
  }
}
