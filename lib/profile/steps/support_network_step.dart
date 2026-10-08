import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class SupportNetworkStep extends StatelessWidget {
  const SupportNetworkStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about your support network. This helps us identify resources you might need.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader(context, 'Do you have access to:'),
            const SizedBox(height: 14),

            _buildCheckboxTile(
              title: 'Doula',
              subtitle: 'A trained professional who provides support during pregnancy and childbirth',
              value: provider.hasDoula,
              onChanged: (value) {
                provider.updateSupportNetwork(hasDoula: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Partner or Spouse',
              subtitle: 'Someone who provides emotional and physical support',
              value: provider.hasPartner,
              onChanged: (value) {
                provider.updateSupportNetwork(hasPartner: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Support Person',
              subtitle: 'Family member, friend, or other support person',
              value: provider.hasSupportPerson,
              onChanged: (value) {
                provider.updateSupportNetwork(hasSupportPerson: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Primary OB/GYN or Midwife',
              subtitle: 'A healthcare provider for pregnancy and birth care',
              value: provider.hasPrimaryProvider,
              onChanged: (value) {
                provider.updateSupportNetwork(hasPrimaryProvider: value);
              },
            ),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: HearthOptionRow(
        label: title,
        subtitle: subtitle,
        selected: value,
        control: HearthControl.checkbox,
        onTap: () => onChanged(!value),
      ),
    );
  }
}
