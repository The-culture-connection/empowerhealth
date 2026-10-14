import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/legal_docs_urls.dart';
import '../cors/ui_theme.dart';
import '../cors/main_navigation_scaffold.dart';
import '../design_system/hearth.dart';

class ConsentScreen extends StatefulWidget {
  final bool isFirstRun;
  final VoidCallback? onConsentAccepted;
  
  const ConsentScreen({
    super.key, 
    this.isFirstRun = true,
    this.onConsentAccepted,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedAIUse = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  const HearthIconChip(Icons.favorite_border, size: 72, iconSize: 30),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to EmpowerHealth',
                    style: textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy and trust matter to us',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Privacy Information
              _buildSection(
                icon: Icons.lock_outline,
                title: 'Your Data is Private',
                content: [
                  'We store your health information securely in your account',
                  'Only you can access your personal data',
                  'We use industry-standard encryption to protect your information',
                  'You can export or delete your data anytime from Settings',
                ],
              ),
              const SizedBox(height: 16),

              // AI Use Disclosure
              _buildSection(
                icon: Icons.auto_awesome_outlined,
                title: 'How We Use AI',
                content: [
                  'AI helps us create easy-to-understand summaries of your visits',
                  'AI generates personalized learning content based on your needs',
                  'AI provides educational support. This is not medical advice',
                  'Your raw documents are not stored unless you choose to save them',
                  'You can turn off AI features anytime in Settings',
                ],
              ),
              const SizedBox(height: 16),

              // Important Disclaimers
              HearthFeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.ink, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Important', style: textTheme.titleLarge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This app provides educational support and tools to help you understand your care. It does not replace professional medical advice, diagnosis, or treatment.',
                      style: hearthCardBodyStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you have a medical emergency, call 911 or contact your healthcare provider immediately.',
                      style: hearthCardBodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Consent Checkboxes
              _buildCheckbox(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value!),
                title: 'I accept the Terms of Service',
                subtitle: 'I understand and agree to the app\'s terms',
              ),
              const SizedBox(height: 12),
              _buildCheckbox(
                value: _acceptedPrivacy,
                onChanged: (value) => setState(() => _acceptedPrivacy = value!),
                title: 'I accept the Privacy Policy',
                subtitle: 'I understand how my data is collected and used',
              ),
              const SizedBox(height: 12),
              _buildCheckbox(
                value: _acceptedAIUse,
                onChanged: (value) => setState(() => _acceptedAIUse = value!),
                title: 'I consent to AI-powered features',
                subtitle: 'I understand AI is used for educational summaries and content',
              ),
              const SizedBox(height: 28),

              // Continue Button
              HearthButton.primary(
                label: 'Continue',
                loading: _isSaving,
                onPressed: (_acceptedTerms && _acceptedPrivacy && _acceptedAIUse && !_isSaving)
                    ? _saveConsent
                    : null,
              ),
              const SizedBox(height: 8),

              // Links
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    HearthButton.text(
                      onPressed: () {
                        _openDocsSection(LegalDocsFragments.terms);
                      },
                      label: 'Terms of Service',
                    ),
                    HearthButton.text(
                      onPressed: () {
                        _openDocsSection(LegalDocsFragments.privacy);
                      },
                      label: 'Privacy Policy',
                    ),
                    HearthButton.text(
                      onPressed: () {
                        _openDocsSection(LegalDocsFragments.eula);
                      },
                      label: 'EULA',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HearthIconChip(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppTheme.brandPurple, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item, style: hearthCardBodyStyle),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _openDocsSection(String fragment) async {
    if (!await launchLegalDocs(fragment)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open documentation')),
      );
    }
  }

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String title,
    required String subtitle,
  }) {
    return HearthCard(
      onTap: () => onChanged(!value),
      padding: const EdgeInsets.fromLTRB(6, 12, 16, 12),
      color: value ? AppTheme.tintWarm : AppTheme.surface,
      borderColor: value ? AppTheme.brandPurple : AppTheme.borderWarm,
      borderWidth: value ? 2 : 1,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: hearthCardTitleStyle.copyWith(
                    color: value ? AppTheme.brandPurple : AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: hearthCaptionStyle.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConsent() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(userId).set({
        'consents': {
          'termsAccepted': true,
          'privacyAccepted': true,
          'aiUseAccepted': _acceptedAIUse,
          'termsVersion': '1.0', // Update when terms change
          'privacyVersion': '1.0',
          'acceptedAt': FieldValue.serverTimestamp(),
        },
        'privacySettings': {
          'aiFeaturesEnabled': _acceptedAIUse,
          'researchDataSharing': true, // Default ON
        },
      }, SetOptions(merge: true));

      if (mounted) {
        if (widget.isFirstRun) {
          // If this is first run (after onboarding), navigate to main screen
          // The callback is only used when called from _AuthWrapper
          if (widget.onConsentAccepted != null) {
            widget.onConsentAccepted!();
          } else {
            // Navigate to main screen after consent
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigationScaffold(),
              ),
            );
          }
        } else {
          // If called from another screen, just pop back
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving consent: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
