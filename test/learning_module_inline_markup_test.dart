import 'package:empowerhealth/widgets/learning_module_formatted_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Lessons from the AI use **bold**, *italic* and "* " bullets; none of the
// asterisks should reach the screen.
Future<String> _renderedText(WidgetTester tester, String content) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LearningModuleFormattedContent(content: content, moduleTitle: 'Test'),
      ),
    ),
  ));
  final texts = tester.widgetList<SelectableText>(find.byType(SelectableText));
  return texts.map((t) => t.textSpan?.toPlainText() ?? t.data ?? '').join('\n');
}

void main() {
  testWidgets('italic quotes render without asterisks', (tester) async {
    final text = await _renderedText(tester, 'Phrases you can use\n\n- *“Please explain that in simpler words.”*\n- *“What are my other options?”*');
    expect(text, contains('“Please explain that in simpler words.”'));
    expect(text, isNot(contains('*')));
  });

  testWidgets('"* " bullets and **bold** render without asterisks', (tester) async {
    final text = await _renderedText(tester, 'Know this\n\n* **Bring** a list of questions\n* Ask for an interpreter');
    expect(text, contains('Bring a list of questions'));
    expect(text, contains('Ask for an interpreter'));
    expect(text, isNot(contains('*')));
  });

  testWidgets('a lone asterisk in ordinary text is kept', (tester) async {
    final text = await _renderedText(tester, 'Notes\n\nTake 2 * 3 tablets as directed');
    expect(text, contains('2 * 3'));
  });
}
