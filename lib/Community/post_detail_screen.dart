import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../auth/guest_guard.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/firebase_functions_service.dart';
import '../services/block_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../utils/content_filter.dart';
import '../widgets/trust_cue_banner.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final BlockService _blockService = BlockService();
  bool _isSubmittingReply = false;
  bool _isDeletingReply = false;
  DateTime? _openedAt;
  Set<String> _blockedUids = <String>{};
  StreamSubscription<Set<String>>? _blockedSub;

  // Created once (not in build) so setState (reply sending, block updates)
  // never resubscribes and flashes the loading spinner.
  late final Stream<DocumentSnapshot> _postStream = _postRef().snapshots();
  late final Stream<DocumentSnapshot> _postActionsStream =
      _postRef().snapshots();

  DocumentReference<Map<String, dynamic>> _postRef() => FirebaseFirestore
      .instance
      .collection('community_posts')
      .doc(widget.postId);

  /// Display name for a post, honoring the anonymous flag.
  static String _postAuthorLabel(Map<String, dynamic> data) =>
      data['isAnonymous'] == true
          ? 'Anonymous'
          : (data['authorName'] as String?) ?? 'Anonymous';

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _trackPostView();
    _blockedSub = _blockService.blockedUidsStream().listen((blocked) {
      if (mounted) setState(() => _blockedUids = blocked);
    });
  }

  @override
  void dispose() {
    _trackPostExit();
    _blockedSub?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _trackPostView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final userProfile = await _databaseService.getUserProfile(userId);
      await _analytics.logCommunityPostViewed(
        threadId: widget.postId,
        userProfile: userProfile,
      );
      await _analytics.logScreenView(
        screenName: 'community_post_detail',
        feature: 'community',
        userProfile: userProfile,
      );
    } catch (e) {
      print('Error tracking post view: $e');
    }
  }

  Future<void> _trackPostExit() async {
    try {
      if (_openedAt == null) return;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final seconds = DateTime.now().difference(_openedAt!).inSeconds;
      final userProfile = await _databaseService.getUserProfile(userId);
      await _analytics.logFeatureTimeSpent(
        feature: 'community',
        timeSpentSeconds: seconds,
        sourceId: widget.postId,
        userProfile: userProfile,
      );
    } catch (e) {
      print('Error tracking post detail exit: $e');
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    if (!await requireAccount(context, action: 'like posts')) return;
    if (!mounted) return;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final likes = List<String>.from(currentLikes);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(postId)
          .update({'likes': likes});

      // Track "like" only when transitioning to liked.
      if (likes.contains(userId)) {
        try {
          UserProfile? userProfile;
          try {
            userProfile = await _databaseService.getUserProfile(userId);
          } catch (_) {
            userProfile = null;
          }
          await _analytics.logCommunityPostLiked(
            threadId: postId,
            userProfile: userProfile,
          );
        } catch (e) {
          print('Error tracking post liked: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    }
  }

  Future<void> _submitReply(String postId) async {
    if (!await requireAccount(context, action: 'reply in the community')) return;
    if (!mounted) return;

    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reply'),
        ),
      );
      return;
    }

    // Objectionable-content filter (Guideline 1.2)
    final filterError = ContentFilter.check(_replyController.text);
    if (filterError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filterError),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }

    setState(() => _isSubmittingReply = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // An anonymous poster replying in their own thread stays anonymous, so
      // their name is never tied to the post through the replies list.
      final postSnap = await _postRef().get();
      final postData = postSnap.data();
      final replyAnonymously = postData?['isAnonymous'] == true &&
          postData?['userId'] == userId;

      final String authorName;
      if (replyAnonymously) {
        authorName = 'Anonymous';
      } else {
        // Get user profile for author name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userDoc.data();
        authorName = (userData?['username'] as String?) ?? 'Anonymous';
      }

      final replyId = FirebaseFirestore.instance.collection('community_posts').doc().id;
      // Use Timestamp.now() instead of FieldValue.serverTimestamp() for array elements
      final replyData = {
        'replyId': replyId,
        'userId': userId,
        'authorName': authorName,
        if (replyAnonymously) 'isAnonymous': true,
        'content': _replyController.text.trim(),
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(postId)
          .update({
            'replies': FieldValue.arrayUnion([replyData]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      try {
        UserProfile? userProfile;
        try {
          userProfile = await _databaseService.getUserProfile(userId);
        } catch (_) {
          userProfile = null;
        }
        await _analytics.logCommunityPostReplied(
          threadId: postId,
          replyLength: _replyController.text.trim().length,
          userProfile: userProfile,
        );
      } catch (e) {
        print('Error tracking post replied: $e');
      }

      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting reply: ${e.toString()}'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReply = false);
      }
    }
  }

  Future<void> _reportPost(
    String postId,
    String postTitle, {
    String? reportedUserId,
    String? reportedUserName,
  }) async {
    final reasonController = TextEditingController();
    final selectedReason = ValueNotifier<String>('');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Scrolls so the reason rows and details field fit above the keyboard.
        scrollable: true,
        title: const Text('Report Post'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this post?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ...['Inappropriate content', 'Spam', 'Harassment', 'Other'].map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HearthOptionRow(
                    label: reason,
                    selected: selectedReason.value == reason,
                    onTap: () {
                      setState(() {
                        selectedReason.value = reason;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          HearthButton.secondary(
            label: 'Cancel',
            expand: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          HearthButton.primary(
            label: 'Submit Report',
            expand: false,
            onPressed: () async {
              if (selectedReason.value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a reason'),
                  ),
                );
                return;
              }

              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) return;

                await FirebaseFirestore.instance
                    .collection('post_reports')
                    .add({
                      'postId': postId,
                      'postTitle': postTitle,
                      'reportedUserId': reportedUserId,
                      'reportedUserName': reportedUserName,
                      'userId': userId,
                      'reason': selectedReason.value,
                      'details': reasonController.text.trim(),
                      'status': 'open',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Thank you for helping keep our community safe.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error submitting report: ${e.toString()}'),
                      backgroundColor: AppTheme.brandPurple,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportReply(Map<String, dynamic> reply) async {
    final selectedReason = ValueNotifier<String>('');
    final detailsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Scrolls so the reason rows and details field fit above the keyboard.
        scrollable: true,
        title: const Text('Report Reply'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this reply?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ...['Inappropriate content', 'Spam', 'Harassment', 'Other'].map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HearthOptionRow(
                    label: reason,
                    selected: selectedReason.value == reason,
                    onTap: () =>
                        setState(() => selectedReason.value = reason),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          HearthButton.secondary(
            label: 'Cancel',
            expand: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          HearthButton.primary(
            label: 'Submit Report',
            expand: false,
            onPressed: () async {
              if (selectedReason.value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a reason'),
                  ),
                );
                return;
              }
              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) return;
                await FirebaseFirestore.instance.collection('reply_reports').add({
                  'postId': widget.postId,
                  'replyId': reply['replyId'],
                  'reportedUserId': reply['userId'],
                  'reportedUserName': reply['authorName'],
                  'content': reply['content'],
                  'userId': userId,
                  'reason': selectedReason.value,
                  'details': detailsController.text.trim(),
                  'status': 'open',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Thank you for helping keep our community safe.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error submitting report: ${e.toString()}'),
                      backgroundColor: AppTheme.brandPurple,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Blocks an abusive author: records the block, notifies the developer, and
  /// removes their content from this user's feed instantly (Guideline 1.2).
  Future<void> _confirmAndBlockUser({
    required String blockedUid,
    required String blockedName,
    required String contextType,
    String? contentSnapshot,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to block a user'),
        ),
      );
      return;
    }
    if (blockedUid == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot block yourself'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $blockedName?'),
        content: const Text(
          "You won't see posts or replies from this person anymore, and our "
          'team will be notified to review their content. You can unblock them '
          'later from your privacy settings.',
        ),
        actions: [
          HearthButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          HearthButton.destructive(
            label: 'Block',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _blockService.blockUser(
        blockedUid: blockedUid,
        blockedName: blockedName,
        contextType: contextType,
        contextId: widget.postId,
        contentSnapshot: contentSnapshot,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked. Their content has been hidden.'),
          ),
        );
        // If we blocked the post author, the whole thread is now hidden — leave.
        if (contextType == 'community_post') {
          Navigator.of(context).maybePop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not block user: $e'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeletePost(String postTitle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: Text(
          postTitle.isEmpty
              ? 'This removes your post and all replies for everyone in the community. This cannot be undone.'
              : '“$postTitle” will be removed for everyone, including all replies. This cannot be undone.',
        ),
        actions: [
          HearthButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          HearthButton.destructive(
            label: 'Delete',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .delete();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete post: $e'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteReply(
    Map<String, dynamic> reply,
    String postAuthorId, {
    required bool isOwnReply,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this reply?'),
        content: Text(
          isOwnReply
              ? 'This removes your reply for everyone. This cannot be undone.'
              : 'This removes the reply from your thread for everyone. This cannot be undone.',
        ),
        actions: [
          HearthButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          HearthButton.destructive(
            label: 'Delete',
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isDeletingReply = true);
    try {
      final rid = reply['replyId'] as String?;
      final content = reply['content'] as String? ?? '';
      final ts = reply['createdAt'] as Timestamp?;
      await _functionsService.deleteCommunityReply(
        postId: widget.postId,
        replyId: rid,
        legacyContent: rid == null ? content : null,
        legacyCreatedAtSeconds: rid == null && ts != null ? ts.seconds : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete reply: $e'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingReply = false);
      }
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
            _buildHeader(),
            Expanded(child: _buildThread()),
          ],
        ),
      ),
    );
  }

  /// Pushed header; moderation actions follow the live post document.
  Widget _buildHeader() {
    return HearthPushedHeader(
      title: 'Discussion',
      actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _postActionsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final postAuthorId = data['userId'] as String?;
              final postAuthorName = data['isAnonymous'] == true
                  ? 'this user'
                  : data['authorName'] as String? ?? 'this user';
              final postContent = data['content'] as String? ?? '';
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final isPostOwner =
                  postAuthorId != null && uid != null && postAuthorId == uid;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPostOwner) ...[
                    HearthCircleButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete post',
                      onPressed: () => _confirmAndDeletePost('$title'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  HearthCircleButton(
                    icon: Icons.flag_outlined,
                    onPressed: () => _reportPost(
                      widget.postId,
                      '$title',
                      reportedUserId: postAuthorId,
                      reportedUserName: postAuthorName,
                    ),
                    tooltip: 'Report post',
                  ),
                  if (!isPostOwner && postAuthorId != null) ...[
                    const SizedBox(width: 8),
                    HearthCircleButton(
                      icon: Icons.block,
                      tooltip: 'Block user',
                      onPressed: () => _confirmAndBlockUser(
                        blockedUid: postAuthorId,
                        blockedName: postAuthorName,
                        contextType: 'community_post',
                        contentSnapshot: '$title\n$postContent',
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildThread() {
    return StreamBuilder<DocumentSnapshot>(
        stream: _postStream,
        builder: (context, snapshot) {
          // Spinner only until the first snapshot arrives.
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? '';
          final content = data['content'] ?? '';
          final category = data['category'] ?? 'General';
          final likes = List<String>.from(data['likes'] ?? []);
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final postOwnerId = data['userId'] as String?;
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final authorName = _postAuthorLabel(data);
          final isOwnPost = postOwnerId != null && postOwnerId == userId;
          final isLiked = userId != null && likes.contains(userId);

          // Instant feed removal: a blocked author's whole thread is hidden.
          if (postOwnerId != null && _blockedUids.contains(postOwnerId)) {
            return _BlockedContentPlaceholder(
              onBack: () => Navigator.of(context).maybePop(),
            );
          }

          // Hide replies from blocked authors instantly (Guideline 1.2).
          final replies = List<Map<String, dynamic>>.from(
            data['replies'] ?? [],
          ).where((r) => !_blockedUids.contains(r['userId'])).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TrustCueBanner(
                        message:
                            'Community posts are visible to members. Only share what you are comfortable with others reading.',
                        subMessage:
                            'Not a substitute for medical care or crisis support.',
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      const SizedBox(height: 16),
                      // Post card
                      HearthCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            Row(
                              children: [
                                Flexible(child: HearthTag('$category')),
                                const Spacer(),
                                if (createdAt != null)
                                  Text(
                                    _formatDate(createdAt),
                                    style: hearthCaptionStyle,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Title
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            // Content
                            Text(
                              content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            // Author and Like Row
                            Row(
                              children: [
                                HearthAvatar(
                                  authorName.isNotEmpty
                                      ? authorName[0].toUpperCase()
                                      : '?',
                                ),
                                const SizedBox(width: 12),
                                // Author Name
                                Expanded(
                                  child: Text(
                                    isOwnPost
                                        ? '$authorName (you)'
                                        : authorName,
                                    style: hearthCardBodyStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                ),
                                // Like Button
                                Material(
                                  color: isLiked
                                      ? AppTheme.tintWarm
                                      : AppTheme.surface,
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: isLiked
                                          ? AppTheme.brandGold
                                          : AppTheme.borderWarm,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () =>
                                        _toggleLike(widget.postId, likes),
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(minHeight: 44),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 18,
                                              color: isLiked
                                                  ? AppTheme.brandTerracotta
                                                  : AppTheme.ink,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${likes.length}',
                                              style: hearthCardBodyStyle
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Replies Section Header
                      Row(
                        children: [
                          Text(
                            'Replies',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(width: 10),
                          HearthTag(
                            '${replies.length}',
                            tone: HearthTagTone.tintPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Replies List
                      if (replies.isEmpty)
                        HearthCard(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: Column(
                              children: [
                                const HearthIconChip(Icons.message_outlined),
                                const SizedBox(height: 12),
                                const Text(
                                  'No replies yet',
                                  style: hearthCardTitleStyle,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Be the first to reply!',
                                  style: hearthCaptionStyle,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...replies.map((reply) {
                          final String replyAuthor = reply['isAnonymous'] == true
                              ? 'Anonymous'
                              : (reply['authorName'] as String?) ??
                                  'Anonymous';
                          final replyContent = reply['content'] ?? '';
                          final replyUserId = reply['userId'] as String?;
                          final replyCreatedAt =
                              (reply['createdAt'] as Timestamp?)?.toDate();
                          final canDeleteReply = userId != null &&
                              (replyUserId == userId ||
                                  (postOwnerId != null &&
                                      postOwnerId == userId));
                          return HearthCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Reply Author Avatar
                                HearthAvatar(
                                  replyAuthor.isNotEmpty
                                      ? replyAuthor[0].toUpperCase()
                                      : '?',
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                // Reply Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            replyAuthor,
                                            style: hearthCardBodyStyle.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.ink,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (replyCreatedAt != null)
                                            Text(
                                              _formatDate(replyCreatedAt),
                                              style: hearthCaptionStyle,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        replyContent,
                                        style: hearthCardBodyStyle.copyWith(
                                          fontSize: 15,
                                          height: 22 / 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final isOwnReply = replyUserId == userId;
                                  final canBlockOrReport =
                                      replyUserId != null && !isOwnReply;
                                  if (!canDeleteReply && !canBlockOrReport) {
                                    return const SizedBox.shrink();
                                  }
                                  return PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert,
                                        size: 20, color: AppTheme.textSecondary),
                                    tooltip: 'More',
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'delete':
                                          if (!_isDeletingReply) {
                                            _confirmAndDeleteReply(
                                              reply,
                                              postOwnerId ?? '',
                                              isOwnReply: isOwnReply,
                                            );
                                          }
                                          break;
                                        case 'report':
                                          _reportReply(reply);
                                          break;
                                        case 'block':
                                          _confirmAndBlockUser(
                                            blockedUid: replyUserId!,
                                            blockedName: replyAuthor,
                                            contextType: 'community_reply',
                                            contentSnapshot: replyContent,
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (canDeleteReply)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete reply'),
                                        ),
                                      if (canBlockOrReport)
                                        const PopupMenuItem(
                                          value: 'report',
                                          child: Text('Report reply'),
                                        ),
                                      if (canBlockOrReport)
                                        const PopupMenuItem(
                                          value: 'block',
                                          child: Text('Block user'),
                                        ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              // Reply input bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderWarm, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.keyboard_hide,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => FocusScope.of(context).unfocus(),
                              tooltip: 'Dismiss keyboard',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Material(
                          color: AppTheme.brandPurple,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _isSubmittingReply
                                ? null
                                : () => _submitReply(widget.postId),
                            child: Center(
                              child: _isSubmittingReply
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.onPurple,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_outlined,
                                      color: AppTheme.onPurple,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

/// Shown in place of a thread when its author has been blocked.
class _BlockedContentPlaceholder extends StatelessWidget {
  final VoidCallback onBack;

  const _BlockedContentPlaceholder({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HearthIconChip(Icons.block, size: 56, iconSize: 26),
            const SizedBox(height: 16),
            Text(
              'Content hidden',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You blocked this user, so their posts and replies are no longer '
              'shown to you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            HearthButton.primary(
              label: 'Go back',
              expand: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
