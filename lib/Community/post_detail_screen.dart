import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../cors/ui_theme.dart';
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
  bool _isSubmittingReply = false;
  DateTime? _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _trackPostView();
  }

  @override
  void dispose() {
    _trackPostExit();
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
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reply'),
          backgroundColor: AppTheme.brandGold,
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

      // Get user profile for author name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();
      final authorName = userData?['username'] ?? 'Anonymous';

      // Use Timestamp.now() instead of FieldValue.serverTimestamp() for array elements
      final replyData = {
        'userId': userId,
        'authorName': authorName,
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
            content: Text('✅ Reply posted!'),
            backgroundColor: AppTheme.brandTurquoise,
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

  Future<void> _reportPost(String postId, String postTitle) async {
    final reasonController = TextEditingController();
    final selectedReason = ValueNotifier<String>('');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this post?'),
              const SizedBox(height: 12),
              ...['Inappropriate content', 'Spam', 'Harassment', 'Other'].map(
                (reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason.value,
                  onChanged: (value) {
                    setState(() {
                      selectedReason.value = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedReason.value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a reason'),
                    backgroundColor: AppTheme.brandGold,
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
                      'userId': userId,
                      'reason': selectedReason.value,
                      'details': reasonController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ Report submitted. Thank you for helping keep our community safe.',
                      ),
                      backgroundColor: AppTheme.brandTurquoise,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: AppTheme.brandWhite,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(
        context,
        title: 'Discussion',
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              return IconButton(
                icon: Icon(Icons.flag_outlined, color: AppTheme.textMuted),
                onPressed: () => _reportPost(widget.postId, title),
                tooltip: 'Report post',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? '';
          final content = data['content'] ?? '';
          final authorName = data['authorName'] ?? 'Anonymous';
          final category = data['category'] ?? 'General';
          final likes = List<String>.from(data['likes'] ?? []);
          final replies = List<Map<String, dynamic>>.from(
            data['replies'] ?? [],
          );
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final isLiked = userId != null && likes.contains(userId);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                      // Post Card - matching NewUI style
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderLight.withOpacity(0.6)),
                          boxShadow: AppTheme.shadowSoft(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (createdAt != null)
                                  Text(
                                    _formatDate(createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Content
                            Text(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Author and Like Row
                            Row(
                              children: [
                                // Author Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF663399),
                                        Color(0xFFCBBEC9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      authorName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.brandWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Author Name
                                Expanded(
                                  child: Text(
                                    authorName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Like Button
                                InkWell(
                                  onTap: () =>
                                      _toggleLike(widget.postId, likes),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? AppTheme.brandGold.withOpacity(0.14)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isLiked
                                            ? AppTheme.brandGold.withOpacity(0.45)
                                            : Colors.grey.shade200,
                                      ),
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
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${likes.length}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isLiked
                                                ? AppTheme.brandTerracotta
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Replies Section Header
                      Row(
                        children: [
                          const Text(
                            'Replies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF663399).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${replies.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF663399),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Replies List
                      if (replies.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No replies yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to reply!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...replies.map((reply) {
                          final replyAuthor =
                              reply['authorName'] ?? 'Anonymous';
                          final replyContent = reply['content'] ?? '';
                          final replyCreatedAt =
                              (reply['createdAt'] as Timestamp?)?.toDate();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderLight.withOpacity(0.6)),
                              boxShadow: AppTheme.shadowSoft(opacity: 0.05, blur: 12, y: 2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Reply Author Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF663399),
                                        Color(0xFFCBBEC9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      replyAuthor[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.brandWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (replyCreatedAt != null)
                                            Text(
                                              _formatDate(replyCreatedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        replyContent,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              // Reply Input - matching NewUI style
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandPurple.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
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
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: AppTheme.surfaceInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFF663399),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.keyboard_hide,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () => FocusScope.of(context).unfocus(),
                              tooltip: 'Dismiss keyboard',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryActionGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.shadowSoft(opacity: 0.14, blur: 14, y: 3),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmittingReply
                                ? null
                                : () => _submitReply(widget.postId),
                            borderRadius: BorderRadius.circular(24),
                            child: Center(
                              child: _isSubmittingReply
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.brandWhite,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: AppTheme.brandWhite,
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
      ),
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
