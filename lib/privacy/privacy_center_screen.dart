import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../cors/ui_theme.dart';
import '../services/firebase_functions_service.dart';

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
            content: Text('✅ Your data export is being prepared. You\'ll receive it via email.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: Colors.red,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF663399), Color(0xFF8855BB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.white, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy Matters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'You control your data',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
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
                      const Divider(),
                      _buildToggle(
                        title: 'Research Data Sharing',
                        subtitle: 'Help improve maternal health care (anonymized data only)',
                        value: _researchDataSharing,
                        onChanged: (value) => _updatePrivacySetting('researchDataSharing', value),
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
                        color: Colors.red,
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
                      const Divider(),
                      _buildInfoTile(
                        icon: Icons.psychology_outlined,
                        title: 'How AI is Used',
                        content: [
                          'AI analyzes visit summaries to create easy-to-read summaries',
                          'AI generates personalized learning content',
                          'AI provides educational support—not medical advice',
                          'Raw documents are not stored unless you choose to save them',
                        ],
                      ),
                      const Divider(),
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
                          // TODO: Open privacy policy URL
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy Policy link coming soon')),
                          );
                        },
                        color: Colors.blue,
                      ),
                      const Divider(),
                      _buildActionTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms of service',
                        onTap: () {
                          // TODO: Open terms URL
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terms of Service link coming soon')),
                          );
                        },
                        color: Colors.blue,
                      ),
                      const Divider(),
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
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.brandPurple,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.brandPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 13, height: 1.4),
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
