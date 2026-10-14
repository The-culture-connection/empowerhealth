import 'package:empower_health_ui/main.dart';
import 'package:empower_health_ui/theme/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home greeting renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(EmpowerHealthApp(themeController: ThemeController(prefs)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Mama 🤍'), findsOneWidget);
  });
}
