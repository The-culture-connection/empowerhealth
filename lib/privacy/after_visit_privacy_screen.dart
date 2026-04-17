import 'package:flutter/material.dart';
import '../constants/legal_docs_urls.dart';
import '../cors/ui_theme.dart';

/// Plain-language privacy explainer for After-Visit Support (uploads & summaries).
class AfterVisitPrivacyScreen extends StatelessWidget {
  const AfterVisitPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Your privacy'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'How we handle what you share',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'After-Visit Support is here to turn paperwork or notes into easier words. '
              'It is not for diagnosis or treatment decisions — your care team does that.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),
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
                'Our team uses this information to run the feature — not to sell your data.',
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
              ),
              child: Text(
                'Questions? Use Privacy & data in settings or contact support through the channel your team uses for the app.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () =>
                      _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.privacy),
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () =>
                      _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.terms),
                  child: const Text('Terms of Service'),
                ),
                TextButton(
                  onPressed: () =>
                      _launchLegalDocForPrivacyScreen(context, LegalDocsFragments.eula),
                  child: const Text('EULA'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulletsCard({required String title, required List<String> lines}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPurple.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textSecondary,
                      ),
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
}

Future<void> _launchLegalDocForPrivacyScreen(BuildContext context, String fragment) async {
  if (!await launchLegalDocs(fragment)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open documentation')),
    );
  }
}
