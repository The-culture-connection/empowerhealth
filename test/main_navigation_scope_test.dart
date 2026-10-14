// A tapped notification opens its screen above the Home tab, and Back returns
// to the tabs rather than to whatever was open before.
import 'package:empowerhealth/cors/main_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int index = 3;

  @override
  Widget build(BuildContext context) {
    return MainNavigationScope(
      selectTab: (i) => setState(() => index = i),
      child: Scaffold(body: Text('tab $index')),
    );
  }
}

Widget _app() => MaterialApp(
      home: const _Tabs(),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('route ${settings.name}')),
      ),
    );

void main() {
  testWidgets('openOverTab closes other screens, selects Home and pushes on top', (tester) async {
    await tester.pumpWidget(_app());
    expect(MainNavigationScope.isTabScaffoldMounted, isTrue);

    // Something else is open above the tabs (e.g. a provider profile).
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/other');
    await tester.pumpAndSettle();
    expect(find.text('route /other'), findsOneWidget);

    expect(MainNavigationScope.openOverTab(MainNavigationScope.tabHome, '/beta-checklist'), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('route /beta-checklist'), findsOneWidget);

    // Back lands on the tabs, now on Home; the other screen is gone.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('tab 0'), findsOneWidget);
    expect(find.text('route /other'), findsNothing);
  });

  testWidgets('openOverTab returns false when no tabs are on screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('sign in')));
    expect(MainNavigationScope.isTabScaffoldMounted, isFalse);
    expect(MainNavigationScope.openOverTab(MainNavigationScope.tabHome, '/x'), isFalse);
  });
}
