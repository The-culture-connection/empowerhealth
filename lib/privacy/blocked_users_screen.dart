import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query();
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HearthPushedHeader(title: 'Blocked Users'),
            Expanded(child: _buildBody(query)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Query<Map<String, dynamic>>? query) {
    return query == null
          ? Center(
              child: Text(
                'Sign in to manage blocked users',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
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
                          const Icon(Icons.block,
                              size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            "You haven't blocked anyone",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you block someone, their posts and replies are '
                            'hidden from you. You can unblock them here anytime.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // One card holding every row, split by warm dividers.
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    HearthCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          for (var index = 0; index < docs.length; index++) ...[
                            if (index > 0) const Divider(height: 1),
                            _buildRow(docs[index]),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
  }

  Widget _buildRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final blockedUid = doc.id;
    final name = (data['blockedName'] as String?) ?? 'This user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          HearthAvatar(name.isNotEmpty ? name[0].toUpperCase() : '?'),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hearthCardTitleStyle,
            ),
          ),
          const SizedBox(width: 14),
          // Compact purple outline per the mockup; unblocking is not destructive.
          OutlinedButton(
            onPressed: () => _unblock(blockedUid, name),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
