// Care needs checklist rows: compact, but every row stays a 48px tap target
// and the long need labels lay out cleanly at phone width.
import 'package:empowerhealth/cors/ui_theme.dart';
import 'package:empowerhealth/qa/layout_auditor.dart';
import 'package:empowerhealth/research/needs_checklist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('needs checklist rows are compact, tappable and clean',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final selected = <String>['mental-health'];
    final toggled = <String>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: NeedsChecklistScreen(
            selectedNeedIds: selected,
            onToggleNeed: toggled.add,
            otherDetailController: controller,
            onBack: () {},
            onContinue: () async {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    for (final need in kCareNeedsChecklistItems) {
      final row = find.ancestor(
        of: find.text(need['label']!),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
    }

    await tester.ensureVisible(find.text(kCareNeedsChecklistItems.first['label']!));
    await tester.tap(find.text(kCareNeedsChecklistItems.first['label']!));
    expect(toggled, [kCareNeedsChecklistItems.first['id']]);

    final issues = qaRunAudit()
        .where((i) => const {'squeezed', 'mid-word', 'truncated', 'overflow'}
            .contains(i.kind))
        .map((i) => '${i.kind}: ${i.message}')
        .toList();
    expect(issues, isEmpty);
  });
}
