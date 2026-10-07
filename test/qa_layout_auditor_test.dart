import 'package:empowerhealth/qa/layout_auditor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font renders every glyph as a 14px square, so widths are exact.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
    );

void main() {
  testWidgets('flags a name squeezed beside a fixed-width button', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 375,
      child: Row(children: [
        SizedBox(width: 355, child: Text('Edit Profile')),
        Expanded(child: Text('Corinne')),
      ]),
    )));
    final issues = qaRunAudit();
    expect(issues.map((i) => i.kind), contains('squeezed'));
    expect(issues.firstWhere((i) => i.kind == 'squeezed').severity, 'P0');
  });

  testWidgets('flags a word broken across lines', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 80,
      child: Text('Summaries here'),
    )));
    final issue = qaRunAudit().firstWhere((i) => i.kind == 'mid-word');
    expect(issue.message, contains('Summa'));
  });

  testWidgets('flags truncated text', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 120,
      child: Text(
        'Search providers by ZIP, city, and plan',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    )));
    expect(qaRunAudit().map((i) => i.kind), contains('truncated'));
  });

  testWidgets('flags a Row that overflows', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 200,
      child: Row(children: [SizedBox(width: 150, height: 10), SizedBox(width: 150, height: 10)]),
    )));
    tester.takeException(); // Flutter's own overflow assertion.
    final issue = qaRunAudit().firstWhere((i) => i.kind == 'overflow');
    expect(issue.message, contains('overflows by 100.0px'));
  });

  testWidgets('inspector finds the text under a tap inside a scrolling list', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          const SizedBox(height: 100),
          InkWell(onTap: () {}, child: const Padding(padding: EdgeInsets.all(16), child: Text('My Visits'))),
        ]),
      ),
    ));
    final root = tester.renderObject<RenderBox>(find.byType(MaterialApp));
    final info = qaInspectAt(root, tester.getCenter(find.text('My Visits')));
    expect(info?['type'], 'RenderParagraph');
    expect(info?['text'], 'My Visits');
  });

  testWidgets('reports nothing for text that wraps at word boundaries', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 375,
      child: Text('Understand your care, prepare questions, and find support.'),
    )));
    expect(qaRunAudit(), isEmpty);
  });
}
