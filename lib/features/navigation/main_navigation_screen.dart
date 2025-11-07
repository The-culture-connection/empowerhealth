import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DashboardScreen(),
    );
  }
}
