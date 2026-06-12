import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../services/block_service.dart';

/// Lets users review and unblock people they have blocked (Guideline 1.2).
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();

  Query<Map<String, dynamic>>? _query() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blockedUsers')
        .orderBy('createdAt', descending: true);
  }

  Future<void> _unblock(String blockedUid, String name) async {
    await _blockService.unblockUser(blockedUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblocked $name'),
          backgroundColor: AppTheme.brandTurquoise,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query();
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Blocked Users'),
      body: query == null
          ? const Center(child: Text('Sign in to manage blocked users'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block,
                              size: 56, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            "You haven't blocked anyone",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you block someone, their posts and replies are '
                            'hidden from you. You can unblock them here anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final blockedUid = docs[index].id;
                    final name = (data['blockedName'] as String?) ?? 'This user';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.brandPurple.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: AppTheme.brandPurple),
                        ),
                      ),
                      title: Text(name),
                      trailing: OutlinedButton(
                        onPressed: () => _unblock(blockedUid, name),
                        child: const Text('Unblock'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
