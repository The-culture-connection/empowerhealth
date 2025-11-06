import 'package:flutter/material.dart';
import '../../design_system/widgets.dart';
import '../../design_system/theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back,", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingS),
          Text("Here's your prenatal visit timeline and next actions.", style: Theme.of(context).textTheme.bodyLarge),
          DS.gapL,
          DS.section(
            title: 'Upcoming visit',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('OB appointment • Tue 10:30 AM')
              ],
            ),
          ),
          DS.gapL,
          DS.section(
            title: 'Recent summaries',
            child: Column(
              children: const [
                ListTile(title: Text('Visit 10/31 • 3 min summary'), subtitle: Text('Fundal height 28cm, GDM screen ordered…')),
                ListTile(title: Text('Visit 10/15 • 2 min summary'), subtitle: Text('BP 118/72, fetal HR 140, next labs…')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
