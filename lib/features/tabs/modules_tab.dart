import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class ModulesTab extends StatelessWidget {
  const ModulesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      children: [
        DS.section(title: 'Education modules', child: Column(children: const [
          ListTile(title: Text('Birth plan basics'), subtitle: Text('Preferences, interventions, contingencies')),
          ListTile(title: Text('Warning signs')),
          ListTile(title: Text('Postpartum planning')),
        ])),
      ],
    );
  }
}
