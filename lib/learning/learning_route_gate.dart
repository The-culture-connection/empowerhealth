import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Home/Learning Modules/learning_modules_screen_v2.dart';
import '../models/user_profile.dart';
import '../pregnancy_loss/pregnancy_loss_learning_screen.dart';
import '../services/database_service.dart';
import '../support_stage/support_stage.dart';

/// Routes to pregnancy-loss guides or standard learning based on profile.
class LearningRouteGate extends StatefulWidget {
  const LearningRouteGate({super.key});

  @override
  State<LearningRouteGate> createState() => _LearningRouteGateState();
}

class _LearningRouteGateState extends State<LearningRouteGate> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final profile = await DatabaseService().getUserProfile(uid);
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile?.isInPregnancyLossMode == true) {
      return const PregnancyLossLearningScreen();
    }
    return const LearningModulesScreenV2();
  }
}
