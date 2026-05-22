import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/user_profile.dart';
import 'pregnancy_loss_constants.dart';
import 'pregnancy_loss_home_content.dart';

/// Full list of support paths from the primary home card.
class PregnancyLossSupportHubScreen extends StatelessWidget {
  const PregnancyLossSupportHubScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Support options',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One step at a time — choose what feels right today.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              PregnancyLossHomeContent(
                profile: profile.copyWith(
                  pregnancyLossSupportPreferences: const [
                    PregnancyLossPreferenceId.emotionalGrief,
                    PregnancyLossPreferenceId.understanding,
                    PregnancyLossPreferenceId.bodyCare,
                    PregnancyLossPreferenceId.providerTalk,
                    PregnancyLossPreferenceId.futureReady,
                    PregnancyLossPreferenceId.practical,
                  ],
                ),
                showWelcome: false,
                showPrimaryCard: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
