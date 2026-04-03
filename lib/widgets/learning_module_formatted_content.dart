import 'package:flutter/material.dart';

import '../cors/ui_theme.dart' show AppTheme;
import '../learning/notes_dialog.dart';

/// Renders AI learning module text: sections, inline **bold**, bullets, and notes UX.
///
/// When [selectionControls] is null, long-press selection shows a snackbar + [NotesDialog].
/// When non-null (e.g. custom toolbar), that path handles "add note" instead.
class LearningModuleFormattedContent extends StatelessWidget {
  const LearningModuleFormattedContent({
    super.key,
    required this.content,
    required this.moduleTitle,
    this.selectionControls,
  });

  final String content;
  final String moduleTitle;
  final TextSelectionControls? selectionControls;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
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

  static List<InlineSpan> _spans(String input) {
    final spans = <InlineSpan>[];
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

  @override
  Widget build(BuildContext context) {
    final spans = _spans(text);
    final plain = _plain(text);

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
              final selectedText = plain.substring(a, b).trim();
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
