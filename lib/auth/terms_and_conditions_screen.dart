import 'package:flutter/material.dart';
import '../app_router.dart';
import '../constants/legal_docs_urls.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({
    super.key,
    this.onAccept,
    this.acceptLabel = 'Accept',
  });

  /// Custom action for the Accept button. When null (default sign-up flow),
  /// accepting routes to the sign-up screen. The guest-entry flow passes a
  /// handler that signs in anonymously and enters the app.
  final Future<void> Function(BuildContext context)? onAccept;

  /// Label for the primary (accept) button.
  final String acceptLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            // Back shows only when there is a route to return to, as the
            // app bar's implied leading did.
            child: HearthPushedHeader(
              title: 'Terms & Conditions',
              showBack: Navigator.of(context).canPop(),
              backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EmpowerHealth Watch: Terms and Conditions & End User License Agreement',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${DateTime.now().year}',
                    style: hearthCaptionStyle,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSection(
                    '1. Purpose of the App',
                    'EmpowerHealth Watch is a health literacy, self-advocacy, and maternal health resource designed to help users:\n\n'
                    '• Understand prenatal, birth, and postpartum care\n'
                    '• Build birth plans\n'
                    '• Track experiences\n'
                    '• Receive educational modules\n'
                    '• Access community-driven insights and reviews\n\n'
                    'The App does not provide medical care or medical advice.\n\n'
                    'For all health decisions, please consult a licensed healthcare provider.',
                  ),
                  
                  _buildSection(
                    '2. Eligibility',
                    'You must be at least 18 years old to use this App.',
                  ),
                  
                  _buildSection(
                    '3. User Responsibilities',
                    'By using the App, you agree to:\n\n'
                    '• Provide accurate information when creating an account\n'
                    '• Use the App only for lawful purposes\n'
                    '• Not share your login credentials\n'
                    '• Not upload harmful, abusive, or illegal content\n'
                    '• Not misuse community review features',
                  ),
                  
                  _buildSection(
                    '4. License Grant (EULA)',
                    'We grant you a limited, non-exclusive, non-transferable, revocable license to use EmpowerHealth Watch for personal, non-commercial purposes.\n\n'
                    'You may not:\n\n'
                    '• Copy, distribute, or modify the App\n'
                    '• Reverse engineer or attempt to access source code\n'
                    '• Use the App for commercial purposes\n'
                    '• Attempt unauthorized access to servers, data, or systems\n\n'
                    'All rights not expressly granted to you remain with The Empowerment Foundation.',
                  ),
                  
                  _buildSection(
                    '5. Intellectual Property',
                    'All content in the App (including logos, graphics, text, audio, designs, health modules, and software) is owned by The Empowerment Foundation and protected by copyright and trademark law.',
                  ),
                  
                  _buildSection(
                    '6. Community Reviews & User-Generated Content',
                    'You may submit reviews and feedback about healthcare experiences. By doing so, you grant us a non-exclusive, royalty-free license to display, store, and use this content for research, reporting, and product improvement in anonymized or aggregated form.\n\n'
                    'We reserve the right to remove content that is:\n\n'
                    '• False or misleading\n'
                    '• Abusive, discriminatory, or harmful\n'
                    '• Violates privacy or confidentiality\n'
                    '• Violates these Terms',
                  ),
                  
                  _buildSection(
                    '7. Health Disclaimer',
                    'The App provides educational content only.\n\n'
                    'It does not:\n\n'
                    '• Diagnose medical conditions\n'
                    '• Provide medical advice\n'
                    '• Replace professional medical judgment\n\n'
                    'If you are experiencing an emergency, call 911 or your local emergency number.',
                  ),
                  
                  _buildSection(
                    '8. AI Features',
                    'Some features (transcription, summaries, learning modules) may be generated using artificial intelligence.\n\n'
                    '• AI output is for informational purposes only.\n'
                    '• It should not be considered clinical guidance.\n'
                    '• Users are responsible for verifying information with a clinician.',
                  ),
                  
                  _buildSection(
                    '9. Privacy & Data Security',
                    'Your use of the App is also governed by our Privacy Policy, which explains:\n\n'
                    '• What data we collect\n'
                    '• How we use it\n'
                    '• Your rights regarding your data\n\n'
                    'The App is designed to follow HIPAA-aligned best practices but is not a replacement for a healthcare provider\'s clinical systems.',
                  ),
                  
                  _buildSection(
                    '10. Payment & Subscriptions (If Applicable)',
                    'Some future features may require subscription payments.\n\n'
                    'If implemented, you will be notified of:\n\n'
                    '• Pricing\n'
                    '• Renewal terms\n'
                    '• Cancellation policies',
                  ),
                  
                  _buildSection(
                    '11. Termination',
                    'We may suspend or terminate your access to the App if you:\n\n'
                    '• Violate these Terms\n'
                    '• Misuse the App\n'
                    '• Engage in harmful conduct toward the community\n\n'
                    'You may delete your account at any time through the App or by contacting support.',
                  ),
                  
                  _buildSection(
                    '12. Limitation of Liability',
                    'To the fullest extent permitted by law, The Empowerment Foundation is not liable for:\n\n'
                    '• Errors or omissions in educational content\n'
                    '• User decisions based on non-medical information\n'
                    '• Issues arising from inaccurate user data\n'
                    '• Loss of data\n'
                    '• App interruptions or technical failures',
                  ),
                  
                  _buildSection(
                    '13. Indemnification',
                    'You agree to indemnify and hold harmless The Empowerment Foundation, its staff, and partners from claims arising from:\n\n'
                    '• Your misuse of the App\n'
                    '• Violation of this Agreement\n'
                    '• Content you submit',
                  ),
                  
                  _buildSection(
                    '14. Governing Law',
                    'These Terms are governed by the laws of the State of Ohio, without regard to conflict of law principles.',
                  ),
                  
                  _buildSection(
                    '15. Changes to This Agreement',
                    'We may update this Agreement at any time. Continued use of the App constitutes acceptance of the updated Terms.',
                  ),
                  
                  _buildSection(
                    '16. Contact Us',
                    'For questions about this Agreement, contact:\n\n'
                    'The Empowerment Foundation\n'
                    'Email: drcorinntaylor@drcorinn.com\n'
                    'Website: https://www.drcorinn.com',
                  ),
                  
                  const Divider(color: AppTheme.borderWarm, height: 1, thickness: 1),
                  const SizedBox(height: 20),
                  Text(
                    'You can review the full Privacy Policy and additional legal documentation anytime on our website.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openDocsSection(context, LegalDocsFragments.privacy),
                        child: const Text('Privacy Policy'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openDocsSection(context, LegalDocsFragments.terms),
                        child: const Text('Terms of Service'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openDocsSection(context, LegalDocsFragments.eula),
                        child: const Text('EULA'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Accept/Decline buttons outside scroll view
          // A top border, not a shadow, separates the action bar (Hearth has
          // no drop shadows).
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.borderWarm)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: HearthButton.secondary(
                      label: 'Decline',
                      onPressed: () {
                        // Decline - go back to auth screen
                        Navigator.of(context).pushReplacementNamed(Routes.auth);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: HearthButton.primary(
                      label: acceptLabel,
                      onPressed: () async {
                        if (onAccept != null) {
                          await onAccept!(context);
                        } else {
                          // Accept - go to sign up screen
                          Navigator.of(context)
                              .pushReplacementNamed(Routes.signup);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 17,
              height: 24 / 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 15,
              height: 22 / 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocsSection(BuildContext context, String fragment) async {
    if (!await launchLegalDocs(fragment)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open documentation')),
      );
    }
  }
}



