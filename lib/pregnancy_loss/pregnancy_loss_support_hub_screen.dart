import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../models/user_profile.dart';
import 'pregnancy_loss_home_content.dart';

/// Full list of support paths from the primary home card.
class PregnancyLossSupportHubScreen extends StatelessWidget {
  const PregnancyLossSupportHubScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthPushedHeader(
                onBack: () => Navigator.pop(context),
                title: 'Support options',
                subtitle: 'One step at a time. Choose what feels right today.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: PregnancyLossHomeContent(
                  profile: profile,
                  showWelcome: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
