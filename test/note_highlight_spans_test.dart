import 'package:empowerhealth/learning/module_notes.dart';
import 'package:empowerhealth/learning/notes_dialog.dart';
import 'package:empowerhealth/widgets/learning_module_formatted_content.dart';
import 'package:empowerhealth/widgets/note_highlight_spans.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = TextStyle(fontSize: 16);
const _bold = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

String _textOf(List<InlineSpan> spans) =>
    TextSpan(children: spans).toPlainText();

void main() {
  group('locateHighlight', () {
    test('finds an exact match', () {
      expect(locateHighlight('Labor is a process.', 'a process'), (9, 18));
    });

    test('tolerates whitespace differences', () {
      const text = 'move through the\nbirth   canal. It often';
      final match = locateHighlight(text, ' through the birth canal. ');
      expect(match, isNotNull);
      expect(text.substring(match!.$1, match.$2), 'through the\nbirth   canal.');
    });

    test('returns null when the text is not there', () {
      expect(locateHighlight('Labor is a process.', 'contractions'), isNull);
    });
  });

  group('findNoteHighlightRanges', () {
    test('skips missing and too-short highlights, merges overlaps', () {
      const text = 'one two three four five';
      final ranges = findNoteHighlightRanges<String>(
        text,
        ['two three', 'three four', 'x', 'nowhere', 'five'],
        (s) => s,
      );
      expect(ranges.length, 2);
      expect(text.substring(ranges[0].start, ranges[0].end), 'two three four');
      expect(ranges[0].items, ['two three', 'three four']);
      expect(text.substring(ranges[1].start, ranges[1].end), 'five');
    });
  });

  group('applyNoteHighlights', () {
    test('splits across span boundaries and adds an emblem after each range',
        () {
      final spans = [
        const TextSpan(text: 'Early ', style: _base),
        const TextSpan(text: 'labor', style: _bold),
        const TextSpan(text: ': mild cramps.', style: _base),
      ];
      const text = 'Early labor: mild cramps.';
      final ranges = findNoteHighlightRanges<String>(
        text,
        ['ly labor: mild', 'cramps'],
        (s) => s,
      );
      final out = applyNoteHighlights<String>(
        spans,
        ranges,
        highlightStyle: (s) =>
            (s ?? const TextStyle()).copyWith(backgroundColor: Colors.yellow),
        emblemBuilder: (_) => const WidgetSpan(child: SizedBox(width: 4)),
      );

      // Text is preserved; each range gets one placeholder after it.
      final placeholder =
          String.fromCharCode(PlaceholderSpan.placeholderCodeUnit);
      expect(
        _textOf(out),
        'Early labor: mild$placeholder cramps$placeholder.',
      );

      final highlighted = out
          .whereType<TextSpan>()
          .where((s) => s.style?.backgroundColor == Colors.yellow)
          .map((s) => s.text)
          .toList();
      expect(highlighted, ['ly ', 'labor', ': mild', 'cramps']);

      // Bold styling is kept inside the highlight.
      final boldHighlight = out.whereType<TextSpan>().firstWhere(
            (s) => s.text == 'labor',
          );
      expect(boldHighlight.style?.fontWeight, FontWeight.w600);
      expect(out.whereType<WidgetSpan>().length, 2);
    });

    test('returns the spans unchanged when there are no ranges', () {
      final spans = [const TextSpan(text: 'Hello', style: _base)];
      final out = applyNoteHighlights<String>(
        spans,
        const [],
        highlightStyle: (s) => s ?? const TextStyle(),
        emblemBuilder: (_) => const WidgetSpan(child: SizedBox()),
      );
      expect(_textOf(out), 'Hello');
      expect(out.length, 1);
    });
  });

  group('LearningModuleFormattedContent notes', () {
    const note = ModuleNote(
      id: 'n1',
      content: 'Ask about early labor',
      highlightedText: 'opening the cervix',
    );

    final emblem = find.descendant(
      of: find.byType(SelectableText),
      matching: find.byIcon(Icons.sticky_note_2_rounded),
    );

    Future<void> pumpContent(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
              textScaler: TextScaler.linear(1.3),
              boldText: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LearningModuleFormattedContent(
                  content: '## What this is\n'
                      "Labor is your body's process of opening the cervix "
                      'and helping your baby move through the birth canal.',
                  moduleTitle: 'Labor & delivery basics',
                  notes: const [note],
                  onAddNote: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('tapping the emblem opens the note', (tester) async {
      await pumpContent(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Your notes on this lesson'), findsOneWidget);

      await tester.tap(emblem);
      await tester.pumpAndSettle();
      expect(find.text('Your note'), findsOneWidget);
      expect(find.text('Ask about early labor'), findsNWidgets(2));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clicking the emblem with a mouse opens the note',
        (tester) async {
      await pumpContent(tester);
      await tester.tap(
        emblem,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.text('Your note'), findsOneWidget);
    });
  });

  testWidgets('NotesDialog footer fits one line at 375px, 1.3x, bold',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(375, 667),
            textScaler: TextScaler.linear(1.3),
            boldText: true,
          ),
          child: Scaffold(
            body: NotesDialog(
              moduleTitle: 'Labor & delivery basics',
              preFilledText: 'move through the birth canal.',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final save = find.text('Save');
    expect(save, findsOneWidget);
    final saveSize = tester.getSize(save);
    final cancelSize = tester.getSize(find.text('Cancel'));
    // Single line: both labels are one text line tall.
    expect(saveSize.height, cancelSize.height);
    expect(saveSize.height, lessThan(40));
  });
}
