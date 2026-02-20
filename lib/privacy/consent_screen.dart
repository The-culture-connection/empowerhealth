import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cors/ui_theme.dart';
import '../cors/main_navigation_scaffold.dart';

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
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF663399), Color(0xFF8855BB)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to EmpowerHealth',
                        style: AppTheme.responsiveTitleStyle(
                          context,
                          baseSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your privacy and trust matter to us',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

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
                const SizedBox(height: 24),

                // AI Use Disclosure
                _buildSection(
                  icon: Icons.psychology_outlined,
                  title: 'How We Use AI',
                  content: [
                    'AI helps us create easy-to-understand summaries of your visits',
                    'AI generates personalized learning content based on your needs',
                    'AI provides educational support—this is not medical advice',
                    'Your raw documents are not stored unless you choose to save them',
                    'You can turn off AI features anytime in Settings',
                  ],
                ),
                const SizedBox(height: 24),

                // Important Disclaimers
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, 
                            color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Important',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This app provides educational support and tools to help you understand your care. It does not replace professional medical advice, diagnosis, or treatment.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'If you have a medical emergency, call 911 or contact your healthcare provider immediately.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Consent Checkboxes
                _buildCheckbox(
                  value: _acceptedTerms,
                  onChanged: (value) => setState(() => _acceptedTerms = value!),
                  title: 'I accept the Terms of Service',
                  subtitle: 'I understand and agree to the app\'s terms',
                ),
                const SizedBox(height: 16),
                _buildCheckbox(
                  value: _acceptedPrivacy,
                  onChanged: (value) => setState(() => _acceptedPrivacy = value!),
                  title: 'I accept the Privacy Policy',
                  subtitle: 'I understand how my data is collected and used',
                ),
                const SizedBox(height: 16),
                _buildCheckbox(
                  value: _acceptedAIUse,
                  onChanged: (value) => setState(() => _acceptedAIUse = value!),
                  title: 'I consent to AI-powered features',
                  subtitle: 'I understand AI is used for educational summaries and content',
                ),
                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_acceptedTerms && _acceptedPrivacy && _acceptedAIUse && !_isSaving)
                        ? _saveConsent
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Links
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Open Terms of Service URL
                        },
                        child: const Text('Terms of Service'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Open Privacy Policy URL
                        },
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
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

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? AppTheme.brandPurple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppTheme.brandPurple : Colors.grey.shade300,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.brandPurple,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value ? AppTheme.brandPurple : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            backgroundColor: Colors.red,
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
