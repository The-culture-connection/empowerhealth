import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';
import '../../core/constants.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('Advocacy for Every Prenatal Visit', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Record, summarize, and share — so mothers, doulas, and providers align with confidence.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              DS.cta('Get Started', icon: Icons.login, onPressed: () => Navigator.pushNamed(context, Routes.login)),
              DS.gapM,
              DS.secondary('Create an account', onPressed: () => Navigator.pushNamed(context, Routes.signup)),
              const SizedBox(height: AppTheme.spacingL),
              Text('By continuing you agree to our Terms & Privacy.', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
