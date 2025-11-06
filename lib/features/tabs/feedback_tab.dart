import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class FeedbackTab extends StatelessWidget {
  const FeedbackTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      children: [
        DS.section(
          title: 'Request feedback',
          child: Column(
            children: [
              const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Describe what you want input on…')),
              const SizedBox(height: AppTheme.spacingM),
              DS.cta('Send to doula / provider', icon: Icons.send, onPressed: () { /* TODO */ }),
            ],
          ),
        ),
        DS.gapL,
        DS.section(
          title: 'Received',
          child: Column(children: const [
            ListTile(title: Text('Doula A • 2h ago'), subtitle: Text('Consider asking about Tdap…')),
            ListTile(title: Text('Provider B • Yesterday'), subtitle: Text('All labs look good. Next step: glucose screen.')),
          ]),
        ),
      ],
    );
  }
}
