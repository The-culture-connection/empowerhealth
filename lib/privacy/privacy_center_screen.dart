import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_functions/firebase_functions.dart';
import '../cors/ui_theme.dart';
import 'privacy_consent_screen.dart';

/// Privacy Center - Settings section for data management and privacy controls
class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _aiFeaturesEnabled = true;
  bool _researchDataSharing = false;
  bool _saveOriginalDocuments = false;
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
          _aiFeaturesEnabled = privacySettings['aiFeaturesEnabled'] ?? true;
          _researchDataSharing = privacySettings['researchDataSharing'] ?? false;
          _saveOriginalDocuments = privacySettings['saveOriginalDocuments'] ?? false;
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

  Future<void> _updateSetting(String key, bool value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'privacySettings': {
          key: value,
        },
      }, SetOptions(merge: true));

      setState(() {
        switch (key) {
          case 'aiFeaturesEnabled':
            _aiFeaturesEnabled = value;
            break;
          case 'researchDataSharing':
            _researchDataSharing = value;
            break;
          case 'saveOriginalDocuments':
            _saveOriginalDocuments = value;
            break;
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Your Data'),
        content: const Text(
          'This will generate a downloadable file with all your data. '
          'This may take a few moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isExporting = true);

    try {
      final callable = _functions.httpsCallable('exportUserData');
      final result = await callable.call({'userId': userId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.data['success'] == true
                  ? 'Data export started. You will receive a download link via email.'
                  : 'Export failed. Please try again.',
            ),
            backgroundColor: result.data['success'] == true
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Account'),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Second confirmation
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance to cancel. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    setState(() => _isDeleting = true);

    try {
      final callable = _functions.httpsCallable('deleteUserAccount');
      final result = await callable.call();

      if (mounted) {
        if (result.data['success'] == true) {
          // User will be signed out automatically
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deletion failed. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Privacy & Trust'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F8)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Your Privacy Center',
                      style: AppTheme.responsiveTitleStyle(
                        context,
                        baseSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Control your data and privacy settings',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Privacy Settings
                    _buildSection(
                      'Privacy Settings',
                      Icons.privacy_tip_outlined,
                      [
                        _buildToggleTile(
                          'AI Features',
                          'Enable AI-powered features like visit summary analysis and learning modules',
                          _aiFeaturesEnabled,
                          (value) => _updateSetting('aiFeaturesEnabled', value),
                        ),
                        const Divider(),
                        _buildToggleTile(
                          'Research Data Sharing',
                          'Allow anonymized data to be used for research (opt-in)',
                          _researchDataSharing,
                          (value) => _updateSetting('researchDataSharing', value),
                        ),
                        const Divider(),
                        _buildToggleTile(
                          'Save Original Documents',
                          'Store original PDFs and text (recommended: off for privacy)',
                          _saveOriginalDocuments,
                          (value) => _updateSetting('saveOriginalDocuments', value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Data Management
                    _buildSection(
                      'Data Management',
                      Icons.folder_managed_outlined,
                      [
                        ListTile(
                          leading: const Icon(Icons.download_outlined,
                              color: AppTheme.brandPurple),
                          title: const Text('Download My Data'),
                          subtitle: const Text(
                            'Export all your data as a JSON file',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: _isExporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isExporting ? null : _exportData,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.description_outlined,
                              color: AppTheme.brandPurple),
                          title: const Text('View Privacy Policy'),
                          subtitle: const Text(
                            'Read our privacy policy',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Link to Privacy Policy
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy Policy link will be added'),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.description_outlined,
                              color: AppTheme.brandPurple),
                          title: const Text('View Terms of Service'),
                          subtitle: const Text(
                            'Read our terms of service',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Link to Terms
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terms of Service link will be added'),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info_outline,
                              color: AppTheme.brandPurple),
                          title: const Text('Review Privacy Consent'),
                          subtitle: const Text(
                            'Update your privacy preferences',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyConsentScreen(
                                  isFirstRun: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Community Privacy Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Community Posts',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Posts in the Community section are visible to all authenticated users. '
                                  'Please do not share sensitive health information in public posts.',
                                  style: TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Support & Contact
                    _buildSection(
                      'Support',
                      Icons.support_outlined,
                      [
                        ListTile(
                          leading: const Icon(Icons.email_outlined,
                              color: AppTheme.brandPurple),
                          title: const Text('Contact Support'),
                          subtitle: const Text(
                            'Get help with privacy questions',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Open support email
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Support contact will be added'),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.flag_outlined,
                              color: AppTheme.brandPurple),
                          title: const Text('Report a Concern'),
                          subtitle: const Text(
                            'Report privacy or security issues',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Open report form
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report form will be added'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Delete Account
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.red, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Permanently delete your account and all associated data. '
                            'This action cannot be undone.',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isDeleting ? null : _deleteAccount,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    )
                                  : const Text('Delete My Account'),
                            ),
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.brandPurple,
    );
  }
}
