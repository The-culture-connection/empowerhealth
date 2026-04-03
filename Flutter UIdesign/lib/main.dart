import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeController = ThemeController(prefs);
  runApp(EmpowerHealthApp(themeController: themeController));
}

class EmpowerHealthApp extends StatefulWidget {
  const EmpowerHealthApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<EmpowerHealthApp> createState() => _EmpowerHealthAppState();
}

class _EmpowerHealthAppState extends State<EmpowerHealthApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: widget.themeController,
      child: ListenableBuilder(
        listenable: widget.themeController,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'EmpowerHealth',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: widget.themeController.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
