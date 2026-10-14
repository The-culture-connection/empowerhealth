import 'package:flutter/material.dart';

import '../support_stage/support_stage_scope.dart';
import 'pregnancy_loss_home_content.dart';

/// Home tab for the pregnancy-loss app shell only.
class PregnancyLossHomeScreen extends StatelessWidget {
  const PregnancyLossHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = SupportStageScope.profileOf(context);
    if (profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
          child: PregnancyLossHomeContent(profile: profile),
        ),
      ),
    );
  }
}
