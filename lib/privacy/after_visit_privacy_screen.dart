import 'package:flutter/material.dart';
import '../constants/legal_docs_urls.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// Plain-language privacy explainer for After-Visit Support (uploads & summaries).
class AfterVisitPrivacyScreen extends StatelessWidget {
  const AfterVisitPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const HearthPushedHeader(title: 'Your privacy'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HearthSectionHeading('How we handle what you share'),
                  const SizedBox(height: 12),
                  Text(
                    'After-Visit Support is here to turn paperwork or notes into easier words. '
                    'It is not for diagnosis or treatment decisions. Your care team does that.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  _bulletsCard(
                    title: 'What we store',
                    lines: [
                      'When you upload a file, we keep it in your secure account storage so the app can read it and build a summary.',
                      'We save the plain-language summary in your account so you can open it again from My Visits.',
                      'If you type notes instead of uploading, we only keep what you explicitly choose to save.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bulletsCard(
                    title: 'How we protect it',
                    lines: [
                      'Your content is tied to your login. Other users cannot see it.',
                      'We use industry-standard security on our servers (encryption in transit and at rest where supported).',
                      'Our team uses this information to run the feature, not to sell your data.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bulletsCard(
                    title: 'Your control',
                    lines: [
                      'You can delete a visit summary (and its linked upload record) from the visit detail screen whenever you want.',
                      'Deleting removes that summary and file metadata from your account; some backups may take a short time to clear.',
                      'You can turn off AI features in settings if you prefer not to use this tool.',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const HearthNote(
                    icon: Icons.info_outline,
                    padding: EdgeInsets.all(18),
                    text:
                        'Questions? Use Privacy & data in settings or contact support through the channel your team uses for the app.',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      HearthButton.text(
                        label: 'Privacy Policy',
                        onPressed: () =>
                            _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.privacy),
                      ),
                      HearthButton.text(
                        label: 'Terms of Service',
                        onPressed: () =>
                            _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.terms),
                      ),
                      HearthButton.text(
                        label: 'EULA',
                        onPressed: () =>
                            _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.eula),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulletsCard({required String title, required List<String> lines}) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: hearthCardTitleStyle.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(line, style: hearthCardBodyStyle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchLegalDocForPrivacyScreen(BuildContext context, String fragment) async {
  if (!await launchLegalDocs(fragment)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open documentation')),
    );
  }
}
