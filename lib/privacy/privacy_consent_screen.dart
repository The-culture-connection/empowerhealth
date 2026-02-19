import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';
import '../cors/main_navigation_scaffold.dart';

/// First-run consent screen shown after signup and accessible from Settings
/// Requires explicit acceptance of Terms, Privacy Policy, and AI Use disclosure
class PrivacyConsentScreen extends StatefulWidget {
  final bool isFirstRun;
  const PrivacyConsentScreen({super.key, this.isFirstRun = true});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedAIUse = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    if (!widget.isFirstRun)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstRun 
                                ? 'Welcome to EmpowerHealth' 
                                : 'Privacy & Trust',
                            style: AppTheme.responsiveTitleStyle(
                              context,
                              baseSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your privacy and trust matter to us',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Warm introduction
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.brandPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppTheme.brandPurple,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'We\'re here to support your health journey with care and respect for your privacy.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Data Use Information
                _buildSection(
                  'What We Store',
                  Icons.folder_outlined,
                  [
                    'Your profile information (name, due date, health preferences)',
                    'Visit summaries and appointment notes you choose to save',
                    'Learning modules and tasks personalized for you',
                    'Journal entries and birth plan preferences',
                    'Community posts (if you choose to participate)',
                  ],
                ),
                const SizedBox(height: 24),

                // AI Use Information
                _buildSection(
                  'How AI Helps You',
                  Icons.psychology_outlined,
                  [
                    'AI analyzes your visit summaries to create easy-to-understand explanations',
                    'AI generates personalized learning modules based on your profile',
                    'AI assistant answers questions about pregnancy and your rights',
                    'All AI features are educational support—not medical advice',
                    'You can disable AI features anytime in Settings',
                  ],
                ),
                const SizedBox(height: 24),

                // Data Control
                _buildSection(
                  'Your Control',
                  Icons.settings_outlined,
                  [
                    'Download your data anytime (Settings → Privacy Center)',
                    'Delete your account and all data (Settings → Privacy Center)',
                    'Opt out of research data sharing (off by default)',
                    'Choose whether to save original documents or just summaries',
                  ],
                ),
                const SizedBox(height: 24),

                // Emergency Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, 
                          color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Important',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This app provides educational support and is not a substitute for medical care. '
                              'For emergencies, call 911 or contact your healthcare provider immediately.',
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Consent Checkboxes
                _buildConsentCheckbox(
                  'I accept the Terms of Service',
                  _acceptedTerms,
                  (value) => setState(() => _acceptedTerms = value ?? false),
                  onTapLink: () {
                    // TODO: Link to Terms of Service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms of Service link will be added'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildConsentCheckbox(
                  'I accept the Privacy Policy',
                  _acceptedPrivacy,
                  (value) => setState(() => _acceptedPrivacy = value ?? false),
                  onTapLink: () {
                    // TODO: Link to Privacy Policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy link will be added'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildConsentCheckbox(
                  'I understand how AI is used and that it provides educational support, not medical advice',
                  _acceptedAIUse,
                  (value) => setState(() => _acceptedAIUse = value ?? false),
                ),
                const SizedBox(height: 32),

                // Continue Button
                ElevatedButton(
                  onPressed: (_acceptedTerms && _acceptedPrivacy && _acceptedAIUse && !_isSaving)
                      ? _saveConsent
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isFirstRun ? 'Continue' : 'Save Preferences',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.brandPurple, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConsentCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged, {
    VoidCallback? onTapLink,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.brandPurple,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: label),
                    if (onTapLink != null)
                      TextSpan(
                        text: ' (view)',
                        style: TextStyle(
                          color: AppTheme.brandPurple,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onTapLink,
                      ),
                  ],
                ),
              ),
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
          'privacyVersion': '1.0', // Update when privacy policy changes
          'acceptedAt': FieldValue.serverTimestamp(),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        'privacySettings': {
          'aiFeaturesEnabled': _acceptedAIUse,
          'researchDataSharing': false, // Default: opt-out
          'saveOriginalDocuments': false, // Default: privacy-minimizing
        },
      }, SetOptions(merge: true));

      if (mounted) {
        if (widget.isFirstRun) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScaffold()),
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy preferences saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving consent: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
