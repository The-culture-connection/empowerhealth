import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

class SupportNetworkStep extends StatelessWidget {
  const SupportNetworkStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your support network. This helps us identify resources you might need.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader('Do you have access to:'),
            const SizedBox(height: AppTheme.spacingL),

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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.brandPurple,
        fontFamily: 'Primary',
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.brandPurple : Colors.grey[300]!,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        value: value,
        activeColor: AppTheme.brandPurple,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
      ),
    );
  }
}






