import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/legal_docs_urls.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/firebase_functions_service.dart';
import 'blocked_users_screen.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  
  bool _aiFeaturesEnabled = true;
  bool _researchDataSharing = true; // Default to ON
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final privacySettings = doc.data()?['privacySettings'] ?? {};
        setState(() {
          _aiFeaturesEnabled = privacySettings['aiFeaturesEnabled'] ?? true; // Default ON
          _researchDataSharing = privacySettings['researchDataSharing'] ?? true; // Default ON
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'privacySettings': {
          'aiFeaturesEnabled': key == 'aiFeaturesEnabled' ? value : _aiFeaturesEnabled,
          'researchDataSharing': key == 'researchDataSharing' ? value : _researchDataSharing,
        },
      }, SetOptions(merge: true));

      setState(() {
        if (key == 'aiFeaturesEnabled') {
          _aiFeaturesEnabled = value;
        } else if (key == 'researchDataSharing') {
          _researchDataSharing = value;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isExporting = true);

    try {
      // Call Cloud Function to export data
      final callable = _functions.httpsCallable('exportUserData');
      final result = await callable.call({'userId': userId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your data export is being prepared. You\'ll receive it via email.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            // Destructive actions are ink, not red (THEME_SPEC).
            style: TextButton.styleFrom(foregroundColor: AppTheme.ink),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      // Call Cloud Function to delete account
      final callable = _functions.httpsCallable('deleteUserAccount');
      await callable.call();

      if (mounted) {
        // User will be logged out automatically
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
          ),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HearthPushedHeader(title: 'Privacy & Trust'),
            Expanded(
              child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  HearthFeatureCard(
                    tone: HearthTone.purple,
                    child: Row(
                      children: [
                        const HearthIconChip(Icons.lock_outline, tone: HearthChipTone.gold),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy Matters',
                                style: hearthFeatureTitleStyle(onPurple: true),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You control your data',
                                style: hearthCardBodyStyle.copyWith(
                                  color: AppTheme.onPurpleSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Privacy Settings
                  _buildSection(
                    title: 'Privacy Settings',
                    children: [
                      _buildToggle(
                        title: 'AI Features',
                        subtitle: 'Enable AI-powered summaries and content generation',
                        value: _aiFeaturesEnabled,
                        onChanged: (value) => _updatePrivacySetting('aiFeaturesEnabled', value),
                      ),
                      const Divider(height: 28),
                      _buildToggle(
                        title: 'Research Data Sharing',
                        subtitle: 'Help improve maternal health care (anonymized data only)',
                        value: _researchDataSharing,
                        onChanged: (value) => _updatePrivacySetting('researchDataSharing', value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Community Safety
                  _buildSection(
                    title: 'Community Safety',
                    children: [
                      _buildActionTile(
                        icon: Icons.block,
                        title: 'Blocked Users',
                        subtitle: 'Review and unblock people you\'ve blocked',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BlockedUsersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Management
                  _buildSection(
                    title: 'Your Data',
                    children: [
                      _buildActionTile(
                        icon: Icons.delete_outline,
                        title: 'Delete My Account',
                        subtitle: 'Permanently delete all your data',
                        onTap: _deleteAccount,
                        isLoading: _isDeleting,
                        // Destructive, so ink rather than purple; never red.
                        iconColor: AppTheme.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Information
                  _buildSection(
                    title: 'Information',
                    children: [
                      _buildInfoTile(
                        icon: Icons.info_outline,
                        title: 'What Data We Store',
                        content: [
                          'Your profile information (name, age, pregnancy stage)',
                          'Visit summaries and notes you create',
                          'Learning modules and tasks',
                          'Journal entries',
                          'Birth plan preferences',
                        ],
                      ),
                      const Divider(height: 28),
                      _buildInfoTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'How AI is Used',
                        content: [
                          'AI analyzes visit summaries to create easy-to-read summaries',
                          'AI generates personalized learning content',
                          'AI provides educational support, not medical advice',
                          'Raw documents are not stored unless you choose to save them',
                        ],
                      ),
                      const Divider(height: 28),
                      _buildInfoTile(
                        icon: Icons.people_outline,
                        title: 'Community Privacy',
                        content: [
                          'Community posts are visible to all authenticated users',
                          'Your profile information is not shared in posts',
                          'You can report inappropriate content',
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Support
                  _buildSection(
                    title: 'Support',
                    children: [
                      _buildActionTile(
                        icon: Icons.help_outline,
                        title: 'Privacy Policy',
                        subtitle: 'Read our full privacy policy',
                        onTap: () {
                          _openDocsSection(LegalDocsFragments.privacy);
                        },
                      ),
                      const Divider(height: 28),
                      _buildActionTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms of service',
                        onTap: () {
                          _openDocsSection(LegalDocsFragments.terms);
                        },
                      ),
                      const Divider(height: 28),
                      _buildActionTile(
                        icon: Icons.article_outlined,
                        title: 'EULA',
                        subtitle: 'Read the end-user license agreement',
                        onTap: () {
                          _openDocsSection(LegalDocsFragments.eula);
                        },
                      ),
                      const Divider(height: 28),
                      _buildActionTile(
                        icon: Icons.email_outlined,
                        title: 'Contact Support',
                        subtitle: 'Report a privacy concern or get help',
                        onTap: () {
                          // TODO: Open support email
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support email: privacy@empowerhealth.app')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HearthSectionHeading(title),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: hearthCardTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: hearthCaptionStyle),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Colours come from the Hearth switch theme.
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 46px tint circle; [iconColor] lets the delete row use ink.
  Widget _rowChip(IconData icon, {Color iconColor = AppTheme.brandPurple}) {
    return SizedBox(
      width: 46,
      height: 46,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.tintWarm, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.brandPurple,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Row(
          children: [
            _rowChip(icon, iconColor: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: hearthCardTitleStyle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: hearthCaptionStyle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
          ],
        ),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    // Title has no colour of its own so the tile can turn it purple when open.
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      minTileHeight: 46,
      shape: const Border(),
      collapsedShape: const Border(),
      textColor: AppTheme.brandPurple,
      collapsedTextColor: AppTheme.ink,
      iconColor: AppTheme.brandPurple,
      collapsedIconColor: AppTheme.textMuted,
      leading: _rowChip(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTheme.sansFamily,
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check, color: AppTheme.brandPurple, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: hearthCardBodyStyle,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ),
        ),
      ],
    );
  }
}
