import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';

class WellnessAccessStep extends StatelessWidget {
  const WellnessAccessStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Understanding your access to resources helps us connect you with the right support.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader('Do you have access to:'),
            const SizedBox(height: AppTheme.spacingL),

            _buildCheckboxTile(
              title: 'Reliable Transportation',
              subtitle: 'Access to a car, public transit, or other reliable transportation',
              value: provider.hasTransportation,
              onChanged: (value) {
                provider.updateWellnessAccess(hasTransportation: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Stable Housing',
              subtitle: 'Safe and stable place to live',
              value: provider.hasStableHousing,
              onChanged: (value) {
                provider.updateWellnessAccess(hasStableHousing: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Adequate Food',
              subtitle: 'Regular access to nutritious food',
              value: provider.hasAccessToFood,
              onChanged: (value) {
                provider.updateWellnessAccess(hasAccessToFood: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Mental Health Support',
              subtitle: 'Access to counseling, therapy, or mental health services',
              value: provider.hasMentalHealthSupport,
              onChanged: (value) {
                provider.updateWellnessAccess(hasMentalHealthSupport: value);
              },
            ),

            const SizedBox(height: AppTheme.spacingL),
            _buildSectionHeader('Additional Support:'),
            const SizedBox(height: AppTheme.spacingL),

            _buildCheckboxTile(
              title: 'WIC Enrollment',
              subtitle: 'Women, Infants, and Children nutrition program',
              value: provider.enrolledInWIC,
              onChanged: (value) {
                provider.updateWellnessAccess(enrolledInWIC: value);
              },
            ),

            _buildCheckboxTile(
              title: 'Childcare Needs',
              subtitle: 'Need help finding or accessing childcare',
              value: provider.needsChildcare,
              onChanged: (value) {
                provider.updateWellnessAccess(needsChildcare: value);
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
          color: value ? AppTheme.brandTurquoise : Colors.grey[300]!,
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
        activeColor: AppTheme.brandTurquoise,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
      ),
    );
  }
}


