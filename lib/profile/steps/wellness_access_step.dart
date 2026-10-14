import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/profile_creation_provider.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';

class WellnessAccessStep extends StatelessWidget {
  const WellnessAccessStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileCreationProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Understanding your access to resources helps us connect you with the right support.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            _buildSectionHeader(context, 'Do you have access to:'),
            const SizedBox(height: 14),

            _buildYesNoTile(
              context: context,
              title: 'Reliable Transportation',
              subtitle: 'Access to a car, public transit, or other reliable transportation',
              value: provider.hasTransportation,
              onChanged: (value) {
                provider.updateWellnessAccess(hasTransportation: value);
                if (value == false) {
                  _showReferralDialog(context, 'Transportation');
                }
              },
            ),

            _buildYesNoTile(
              context: context,
              title: 'Stable Housing',
              subtitle: 'Safe and stable place to live',
              value: provider.hasStableHousing,
              onChanged: (value) {
                provider.updateWellnessAccess(hasStableHousing: value);
                if (value == false) {
                  _showReferralDialog(context, 'Housing');
                }
              },
            ),

            _buildYesNoTile(
              context: context,
              title: 'Adequate Food',
              subtitle: 'Regular access to nutritious food',
              value: provider.hasAccessToFood,
              onChanged: (value) {
                provider.updateWellnessAccess(hasAccessToFood: value);
                if (value == false) {
                  _showReferralDialog(context, 'Food Access');
                }
              },
            ),

            _buildYesNoTile(
              context: context,
              title: 'Mental Health Support',
              subtitle: 'Access to counseling, therapy, or mental health services',
              value: provider.hasMentalHealthSupport,
              onChanged: (value) {
                provider.updateWellnessAccess(hasMentalHealthSupport: value);
                if (value == false) {
                  _showReferralDialog(context, 'Mental Health Support');
                }
              },
            ),

            const SizedBox(height: AppTheme.spacingM),
            _buildSectionHeader(context, 'Additional Support:'),
            const SizedBox(height: 14),

            _buildYesNoTile(
              context: context,
              title: 'WIC Enrollment',
              subtitle: 'Women, Infants, and Children nutrition program',
              value: provider.enrolledInWIC,
              onChanged: (value) {
                provider.updateWellnessAccess(enrolledInWIC: value);
                if (value == false) {
                  _showReferralDialog(context, 'WIC Enrollment');
                }
              },
            ),

            _buildYesNoTile(
              context: context,
              title: 'Childcare Needs',
              subtitle: 'Need help finding or accessing childcare',
              value: provider.needsChildcare,
              onChanged: (value) {
                provider.updateWellnessAccess(needsChildcare: value);
                if (value == false) {
                  _showReferralDialog(context, 'Childcare');
                }
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

  Widget _buildYesNoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return HearthCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: hearthCardTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: hearthCaptionStyle),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: 'Yes',
                  selected: value,
                  onPressed: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(
                  label: 'No',
                  selected: !value,
                  onPressed: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Yes and No share the selected-chip look; "No" is an answer, not an error.
  Widget _buildAnswerButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          backgroundColor: selected ? AppTheme.tintWarm : AppTheme.ground,
          foregroundColor: selected ? AppTheme.brandPurple : AppTheme.textSecondary,
          side: BorderSide(
            color: selected ? AppTheme.brandPurple : AppTheme.borderWarm,
            width: selected ? 2 : 1,
          ),
          textStyle: TextStyle(
            fontFamily: AppTheme.sansFamily,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  void _showReferralDialog(BuildContext context, String resourceType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Wider dialog + smaller title so long words like "Transportation?"
        // don't get split (leaving the "?" alone on its own line) at large
        // text sizes on small phones.
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          'Need Help with $resourceType?',
        ),
        content: Text(
          'We can help connect you with resources for $resourceType. Would you like us to provide referrals?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse('https://211.org/about-us/your-local-211');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open 211.org. Please visit https://211.org/about-us/your-local-211'),
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, Get Referrals'),
          ),
        ],
      ),
    );
  }
}






