import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class RecorderTab extends StatelessWidget {
  const RecorderTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 72),
            const SizedBox(height: AppTheme.spacingL),
            Text('Record your visit', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingM),
            const Text('Tap below to start a secure, on-device recording. You control what\'s shared.'),
            const SizedBox(height: AppTheme.spacingL),
            DS.cta('Start recording', icon: Icons.fiber_manual_record, onPressed: () {
              // TODO: trigger recording flow
            }),
          ],
        ),
      ),
    );
  }
}
