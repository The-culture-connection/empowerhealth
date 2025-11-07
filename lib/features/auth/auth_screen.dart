import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../design_system/background.dart';
import '../../design_system/theme.dart';
import '../../design_system/widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('EmpowerHealth'),
        centerTitle: false,
      ),
      body: DSBackground(
        imagePath: 'assets/images/bg1.png',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXXL,
                vertical: AppTheme.spacingXL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DS.logo(size: 96),
                  const SizedBox(height: AppTheme.spacingXL),
                  Text(
                    'Welcome to EmpowerHealth',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkForeground
                              : AppTheme.lightForeground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Your prenatal journey, organized and supported every step of the way.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkForeground.withOpacity(0.85)
                              : AppTheme.lightForeground.withOpacity(0.75),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  DS.cta(
                    'Sign In',
                    icon: Icons.login,
                    onPressed: () => Navigator.pushNamed(context, Routes.login),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  DS.secondary(
                    'Create Account',
                    icon: Icons.person_add_alt_1,
                    onPressed: () => Navigator.pushNamed(context, Routes.signup),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
