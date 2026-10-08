// Hearth components at phone width with the longest strings they carry: no
// squeezed, broken, truncated or overflowing text (design/hearth/THEME_SPEC.md §4).
import 'package:empowerhealth/cors/ui_theme.dart';
import 'package:empowerhealth/design_system/hearth.dart';
import 'package:empowerhealth/qa/layout_auditor.dart';
import 'package:empowerhealth/widgets/mama_approved_community_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font renders every glyph as a square one font-size wide, so these
// widths are harsher than the real Figtree and Young Serif.
Future<void> _pump(WidgetTester tester, Widget child, {Widget? bottom}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
      bottomNavigationBar: bottom,
    ),
  ));
}

void _expectClean() {
  final issues = qaRunAudit()
      .where((i) => const {'squeezed', 'mid-word', 'truncated', 'overflow'}.contains(i.kind))
      .map((i) => '${i.kind}: ${i.message}')
      .toList();
  expect(issues, isEmpty);
}

void main() {
  testWidgets('pushed header with a long back label and title', (tester) async {
    await _pump(
      tester,
      HearthPushedHeader(
        padding: EdgeInsets.zero,
        backLabel: 'My Visits',
        title: 'My Visits & What It Means',
        onBack: () {},
        actions: [HearthTextAction(label: 'Delete', icon: Icons.delete_outline, onPressed: () {})],
      ),
    );
    expect(tester.takeException(), isNull);
    _expectClean();
  });

  testWidgets('row card with a provider name and Mama Approved badge', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthRowCard(
            icon: Icons.location_on_outlined,
            title: 'Danielle Whitfield, CNM',
            subtitle: 'Midwife',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const MamaApprovedCommunityBadge(),
          const SizedBox(height: 12),
          const MamaApprovedCommunityBadge(compact: true, showInfoAffordance: true),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    _expectClean();
  });

  testWidgets('option row with a long label', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          HearthOptionRow(
            label: 'I felt my concerns were dismissed or not taken seriously by my provider',
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          HearthOptionRow(
            label: 'Something else',
            selected: false,
            control: HearthControl.checkbox,
            onTap: () {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    _expectClean();
  });

  testWidgets('bottom nav shows all five labels and marks the active tab', (tester) async {
    await _pump(
      tester,
      const SizedBox.shrink(),
      bottom: HearthBottomNav(
        index: 3,
        onTap: (_) {},
        items: const [
          HearthNavItem(icon: Icons.home_outlined, label: 'Home'),
          HearthNavItem(icon: Icons.menu_book_outlined, label: 'Learn'),
          HearthNavItem(icon: Icons.favorite_border, label: 'Journal'),
          HearthNavItem(icon: Icons.chat_bubble_outline, label: 'Community'),
          HearthNavItem(icon: Icons.person_outline, label: 'You'),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    for (final label in ['Home', 'Learn', 'Journal', 'Community', 'You']) {
      expect(find.text(label), findsOneWidget);
    }
    final active = tester.widget<Text>(find.text('Community'));
    expect(active.style?.color, AppTheme.brandPurple);
    expect(active.style?.fontWeight, FontWeight.w700);
    _expectClean();
  });

  testWidgets('notes, chips, tags, buttons and stars lay out cleanly', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthNote(
            tone: HearthNoteTone.lavender,
            title: 'This tool helps you understand your care.',
            text: 'It does not replace your provider.',
          ),
          const SizedBox(height: 12),
          const HearthStepProgress(step: 2, total: 5, label: 'Step 2 of 5'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            HearthChoiceChip(label: 'All', selected: true, primary: true, onSelected: () {}),
            HearthChoiceChip(label: 'Birth Stories', selected: false, onSelected: () {}),
          ]),
          const SizedBox(height: 12),
          const HearthTag('Accepting new patients'),
          const SizedBox(height: 12),
          HearthStarRating(value: 3, onChanged: (_) {}),
          const SizedBox(height: 12),
          HearthButton.primary(label: 'Save', onPressed: () {}),
          const SizedBox(height: 12),
          HearthButton.destructive(label: 'Delete', onPressed: () {}),
          const SizedBox(height: 12),
          HearthButton.text(label: 'See options', chevron: true, onPressed: () {}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
    _expectClean();
  });
}
