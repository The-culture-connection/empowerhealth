import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import 'pregnancy_loss_navigation.dart';

/// Legacy route — redirects to [enterPregnancyLossAndShowHome].
@Deprecated('Use enterPregnancyLossAndShowHome from emotional support check-in.')
class PregnancyLossTransitionScreen extends StatefulWidget {
  const PregnancyLossTransitionScreen({super.key});

  @override
  State<PregnancyLossTransitionScreen> createState() =>
      _PregnancyLossTransitionScreenState();
}

class _PregnancyLossTransitionScreenState
    extends State<PregnancyLossTransitionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    await enterPregnancyLossAndShowHome(
      context,
      selectedOptionIds: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F4FA),
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.brandPurple),
        ),
      ),
    );
  }
}
