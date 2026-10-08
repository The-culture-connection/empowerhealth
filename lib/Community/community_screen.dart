import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../auth/guest_guard.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/drag_scroll_behavior.dart';
import '../services/analytics_service.dart';
import '../services/block_service.dart';
import '../services/database_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'seed_mock_posts.dart';
import '../widgets/community_survey_banner.dart';
import '../support_stage/support_stage.dart';
import '../pregnancy_loss/pregnancy_loss_constants.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    this.communityStageFilter,
  });

  /// When set to [CommunityStage.pregnancyLoss], only loss-space posts are shown.
  final String? communityStageFilter;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  bool _hasSeeded = false;
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  final BlockService _blockService = BlockService();
  Set<String> _blockedUids = <String>{};
  StreamSubscription<Set<String>>? _blockedSub;

  /// Created once so rebuilds (category taps, block-list updates, tab
  /// switches) never resubscribe. A stream created inside build() made the
  /// StreamBuilder drop back to ConnectionState.waiting on every rebuild,
  /// which flashed the spinner and made the posts flicker.
  late final Stream<QuerySnapshot> _postsStream = FirebaseFirestore.instance
      .collection('community_posts')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _trackScreenView();
    _seedMockPostsIfNeeded();
    _blockedSub = _blockService.blockedUidsStream().listen((blocked) {
      if (mounted) setState(() => _blockedUids = blocked);
    });
  }

  @override
  void dispose() {
    _blockedSub?.cancel();
    super.dispose();
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
        if (mounted) setState(() => _hasSeeded = true);
      }
    } catch (e) {
      // Silently fail - don't block the UI
      debugPrint('Error seeding mock posts: $e');
    }
  }

  bool get _isPregnancyLossSpace =>
      widget.communityStageFilter == CommunityStage.pregnancyLoss;

  List<String> get _categories => _isPregnancyLossSpace
      ? kPregnancyLossCommunityCategories
      : const ['All', 'Questions', 'Birth Stories', 'Support', 'Resources'];

  List<Widget> _headerSlivers(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        sliver: SliverToBoxAdapter(
          // Title row: the title gets all remaining width and never breaks
          // mid-word ("Communit" / "y") under Bold Text + large Dynamic Type;
          // the compact New post button keeps its intrinsic size.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _isPregnancyLossSpace
                        ? Text(
                            'Pregnancy Loss Support Space',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Community',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _openCreatePost,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('New post', maxLines: 1, softWrap: false),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isPregnancyLossSpace
                    ? 'A gentle space for support, reflection, and connection at your own pace.'
                    : 'EmpowerHealth Watch',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      // Deliberate horizontally scrollable tab row: a real horizontal
      // ListView (viewport) so chips scroll instead of running off the
      // screen, full-bleed so they are never clipped mid-label at the 24px
      // gutter, with a right-edge fade as the "more tabs" affordance.
      SliverToBoxAdapter(
        child: SizedBox(
          height: _CategoryChip.heightFor(context) + 12,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.86, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: HorizontalDragScroll(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 4, 48, 8),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Center(
                  child: _CategoryChip(
                    label: _categories[i],
                    isSelected: _selectedCategory == _categories[i],
                    onTap: () =>
                        setState(() => _selectedCategory = _categories[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      if (!_isPregnancyLossSpace) ...[
        const SliverToBoxAdapter(child: CommunitySurveyBanner()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ] else ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CommunityScreen(
                      communityStageFilter: CommunityStage.general,
                    ),
                  ),
                );
              },
              child: Text(
                'Browse general community (optional)',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ),
      ],
    ];
  }

  /// Minimized community guidelines / welcome note, moved to the bottom so the
  /// category tabs, review CTA, and posts are reachable without scrolling far.
  List<Widget> _footerSlivers(BuildContext context) {
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight.withOpacity(0.7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite, size: 18, color: AppTheme.brandPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPregnancyLossSpace
                            ? 'Share only what feels comfortable'
                            : "You're among friends",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPregnancyLossSpace
                            ? 'A supportive space. Please avoid giving medical advice. Moderators may remove content that breaks community guidelines.'
                            : 'Share stories, ask questions, and support each other. Your posts show your display name unless you choose to post anonymously. Moderators may remove content that breaks community guidelines. Not medical advice.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _openCreatePost() async {
    if (!await requireAccount(context, action: 'post in the community')) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          communityStage: _isPregnancyLossSpace
              ? CommunityStage.pregnancyLoss
              : CommunityStage.general,
          categories: _isPregnancyLossSpace
              ? kPregnancyLossCommunityCategories
                  .where((c) => c != 'All')
                  .toList()
              : null,
          contentPlaceholder: _isPregnancyLossSpace
              ? 'Share only what feels comfortable…'
              : null,
        ),
      ),
    );
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
    // Anonymous posts always render as "Anonymous", whatever authorName holds.
    final String authorName = data['isAnonymous'] == true
        ? 'Anonymous'
        : (data['authorName'] as String?) ?? 'Anonymous';
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
                            color: AppTheme.textMuted,
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
                  // Metadata: textMuted (~6:1 on surfaceCard) and Wrap with
                  // roomier spacing so items flow to new lines instead of
                  // crowding under large Dynamic Type.
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isOwnPost ? '$authorName (you)' : authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w400,
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
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${replies.length} replies',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
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
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${likes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
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
                            color: AppTheme.textMuted,
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
                tooltip: 'Delete your post',
                onPressed: () => _confirmDeletePostFromFeed(doc.id, '$title'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _feedSlivers(AsyncSnapshot<QuerySnapshot> snapshot) {
    // Spinner only before the very first snapshot; afterwards the current
    // posts stay on screen while Firestore delivers updates.
    if (!snapshot.hasData && !snapshot.hasError) {
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
      final data = doc.data() as Map<String, dynamic>;
      // Instant feed removal of blocked authors' posts (Guideline 1.2).
      if (_blockedUids.contains(data['userId'])) return false;
      final stage = data['communityStage'] as String?;
      if (_isPregnancyLossSpace) {
        if (stage != CommunityStage.pregnancyLoss) return false;
      } else if (stage == CommunityStage.pregnancyLoss) {
        return false;
      }
      if (_selectedCategory == 'All') return true;
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _postCard(context, posts[index]),
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final embeddedInMainNav = MainNavigationScope.maybeOf(context) != null;

    final feed = SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: _postsStream,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              ..._headerSlivers(context),
              ..._feedSlivers(snapshot),
              ..._footerSlivers(context),
            ],
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor:
          embeddedInMainNav ? Colors.transparent : AppTheme.backgroundWarm,
      body: embeddedInMainNav
          ? feed
          : Stack(
              fit: StackFit.expand,
              children: [
                const AmbientBackground(),
                feed,
              ],
            ),
      // No floating create button: the header "New post" button is the only
      // create action, so it isn't duplicated over the feed.
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

  static const double _fontSize = 14;
  static const double _lineHeight = 1.4;

  /// Chip height at the current text scale (vertical padding + border + one
  /// line of text, plus a little slack), so the horizontal ListView that
  /// hosts the chips is never too short under large Dynamic Type.
  static double heightFor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_fontSize) * _lineHeight +
      10 * 2 +
      2 +
      4;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: FontWeight.w400,
            fontSize: _fontSize,
            height: _lineHeight,
          ),
        ),
      ),
    );
  }
}
