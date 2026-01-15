import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

            const SizedBox(height: AppTheme.spacingL),
            _buildSectionHeader('Additional Support:'),
            const SizedBox(height: AppTheme.spacingL),

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

  Widget _buildYesNoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingS,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingS),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: value ? AppTheme.brandTurquoise : Colors.white,
                      foregroundColor: value ? Colors.white : AppTheme.brandTurquoise,
                      side: BorderSide(
                        color: value ? AppTheme.brandTurquoise : Colors.grey[300]!,
                        width: value ? 2 : 1,
                      ),
                    ),
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged(false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !value ? Colors.red.withOpacity(0.1) : Colors.white,
                      foregroundColor: !value ? Colors.red : Colors.grey[600]!,
                      side: BorderSide(
                        color: !value ? Colors.red : Colors.grey[300]!,
                        width: !value ? 2 : 1,
                      ),
                    ),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog(BuildContext context, String resourceType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Need Help with $resourceType?'),
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
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
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






