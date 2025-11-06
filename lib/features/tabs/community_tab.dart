import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      children: [
        DS.section(title: 'Community', child: Column(children: const [
          ListTile(title: Text('How did you prep for GDM test?'), subtitle: Text('12 replies • last active 5m')),
          ListTile(title: Text('Birth plan templates')),
        ])),
      ],
    );
  }
}
