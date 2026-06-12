import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handles blocking abusive users for App Store Guideline 1.2.
///
/// Blocking does three things required by Apple:
///  1. Records the block under `users/{me}/blockedUsers/{them}` so the blocked
///     author's content is filtered out of the current user's feed instantly.
///  2. Writes a `moderation_reports` document, which **notifies the developer**
///     of the objectionable content (reviewed via the admin dashboard).
///  3. The UI uses [blockedUidsStream] to remove the content from the feed
///     immediately, without requiring a refresh.
class BlockService {
  BlockService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _blockedCol(String uid) =>
      _db.collection('users').doc(uid).collection('blockedUsers');

  /// Live set of UIDs the current user has blocked. Emits an empty set when
  /// signed out. UI filters feeds/threads against this for instant removal.
  Stream<Set<String>> blockedUidsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream<Set<String>>.value(<String>{});
    return _blockedCol(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  /// One-shot read of the current user's blocked UIDs.
  Future<Set<String>> getBlockedUids() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return <String>{};
    final snap = await _blockedCol(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Blocks [blockedUid] and reports the offending content to the developer.
  ///
  /// [contextType] is e.g. 'community_post' or 'community_reply'.
  /// [contextId] is the post id (so moderators can find the content).
  /// [contentSnapshot] is the offending text captured for review.
  Future<void> blockUser({
    required String blockedUid,
    String? blockedName,
    required String contextType,
    String? contextId,
    String? contentSnapshot,
    String? reason,
  }) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw StateError('Must be signed in to block a user.');
    }
    if (blockedUid == me) {
      throw ArgumentError('You cannot block yourself.');
    }

    // 1. Record the block for instant feed filtering. This is the critical
    // step — if it succeeds, the user is considered blocked.
    await _blockedCol(me).doc(blockedUid).set({
      'blockedUid': blockedUid,
      'blockedName': blockedName,
      'contextType': contextType,
      'contextId': contextId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Notify the developer / moderators of the objectionable content.
    // Best-effort: a failure here (e.g. transient) must not make the block
    // itself look like it failed — the content is already hidden from the user.
    try {
      await _db.collection('moderation_reports').add({
        'type': 'user_blocked',
        'reportedByUid': me,
        'blockedUid': blockedUid,
        'blockedName': blockedName,
        'contextType': contextType,
        'contextId': contextId,
        'contentSnapshot': contentSnapshot,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Block recorded, but moderation report failed: $e');
      }
    }
  }

  /// Unblocks a previously blocked user.
  Future<void> unblockUser(String blockedUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return;
    await _blockedCol(me).doc(blockedUid).delete();
  }
}
