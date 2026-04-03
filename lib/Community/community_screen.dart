import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'seed_mock_posts.dart';
import '../widgets/community_survey_banner.dart';
import '../widgets/trust_cue_banner.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  bool _hasSeeded = false;
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _trackScreenView();
    _seedMockPostsIfNeeded();
  }

  Future<void> _trackScreenView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await _databaseService.getUserProfile(userId);
        await _analytics.logScreenView(
          screenName: 'community',
          feature: 'community',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking community screen view: $e');
    }
  }

  Future<void> _seedMockPostsIfNeeded() async {
    if (_hasSeeded) return;
    
    try {
      // Check if posts exist
      final snapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        await seedMockPosts();
        setState(() => _hasSeeded = true);
      }
    } catch (e) {
      // Silently fail - don't block the UI
      debugPrint('Error seeding mock posts: $e');
    }
  }

  List<Widget> _headerSlivers(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        sliver: SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'EmpowerHealth Watch',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('New post'),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEBE4F3),
                  Color(0xFFE0D5EB),
                  Color(0xFFE8DFE8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppTheme.shadowSoft(opacity: 0.1, blur: 24, y: 6),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.gradientBeigeStart,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          Icon(Icons.favorite, color: AppTheme.textMuted, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You\'re among friends',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share stories, ask questions, and support each other.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: TrustCueBanner(
            message:
                'Your posts use your display name. Share only what you are comfortable with others reading.',
            subMessage:
                'Moderators may remove content that breaks community guidelines. This is not medical advice.',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () => setState(() => _selectedCategory = 'All'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Questions',
                  isSelected: _selectedCategory == 'Questions',
                  onTap: () =>
                      setState(() => _selectedCategory = 'Questions'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Birth Stories',
                  isSelected: _selectedCategory == 'Birth Stories',
                  onTap: () =>
                      setState(() => _selectedCategory = 'Birth Stories'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Support',
                  isSelected: _selectedCategory == 'Support',
                  onTap: () => setState(() => _selectedCategory = 'Support'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Resources',
                  isSelected: _selectedCategory == 'Resources',
                  onTap: () =>
                      setState(() => _selectedCategory = 'Resources'),
                ),
              ],
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      const SliverToBoxAdapter(child: CommunitySurveyBanner()),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ];
  }

  Future<void> _confirmDeletePostFromFeed(String postId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: Text(
          title.isEmpty
              ? 'This removes your post and all replies. This cannot be undone.'
              : '“$title” will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: AppTheme.brandWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(postId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted'),
            backgroundColor: AppTheme.brandTurquoise,
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

  Widget _postCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final authorName = data['authorName'] ?? 'Anonymous';
    final replies =
        List<Map<String, dynamic>>.from(data['replies'] ?? []);
    final category = data['category'] ?? 'General';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final likes = List<String>.from(data['likes'] ?? []);
    final postUserId = data['userId'] as String?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnPost =
        postUserId != null && currentUid != null && postUserId == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: doc.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.gradientBeigeStart,
                    AppTheme.gradientBeigeEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  authorName.isNotEmpty
                      ? authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.brandWhite,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLighter.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLightest,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.message,
                            size: 14,
                            color: AppTheme.textBarelyVisible,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${replies.length} replies',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLightest,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppTheme.textBarelyVisible,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${likes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLightest,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLightest,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
                    ],
                  ),
                ),
              ),
            ),
            if (isOwnPost)
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppTheme.textMuted),
                tooltip: 'Delete post',
                onPressed: () => _confirmDeletePostFromFeed(doc.id, '$title'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _feedSlivers(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 64, color: AppTheme.textBarelyVisible),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to start a discussion!',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final posts = snapshot.data!.docs.where((doc) {
      if (_selectedCategory == 'All') return true;
      final data = doc.data() as Map<String, dynamic>;
      return data['category'] == _selectedCategory;
    }).toList();

    if (posts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No posts in this category yet',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _postCard(context, posts[index] as QueryDocumentSnapshot),
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return CustomScrollView(
                slivers: [
                  ..._headerSlivers(context),
                  ..._feedSlivers(snapshot),
                ],
              );
            },
          ),
        ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.encouragementGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandGold.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
            child: const Icon(Icons.edit, color: AppTheme.textPrimary, size: 24),
          ),
        ),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.brandGold.withOpacity(0.42),
                    AppTheme.gradientGoldEnd.withOpacity(0.28),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandGold.withOpacity(0.5)
                : AppTheme.borderLighter.withOpacity(0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandGold.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.shadowSoft(opacity: 0.05, blur: 12, y: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
