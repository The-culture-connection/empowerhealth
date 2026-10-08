import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../auth/guest_guard.dart';
import '../cors/main_navigation_scope.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

  /// Height of the category chip row at the current text scale (chip
  /// padding plus one 20px line), never below the 44px touch target, so the
  /// horizontal ListView is never too short under large Dynamic Type.
  double _chipRowHeight(BuildContext context) {
    final chip = MediaQuery.textScalerOf(context).scale(15) * 20 / 15 + 20;
    return chip < 44 ? 44 : chip;
  }

  List<Widget> _headerSlivers(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return [
      SliverToBoxAdapter(
        // Title row: the title gets all remaining width and never breaks
        // mid-word ("Communit" / "y") under Bold Text + large Dynamic Type;
        // the compact New post button keeps its intrinsic size. The loss
        // space stays calm: no decorative circle.
        child: HearthTabHeader(
          warmCircle: !_isPregnancyLossSpace,
          titleWidget: _isPregnancyLossSpace
              ? Text(
                  'Pregnancy Loss Support Space',
                  style: textTheme.displaySmall,
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Community',
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.displayLarge,
                  ),
                ),
          subtitle: _isPregnancyLossSpace
              ? 'A gentle space for support, reflection, and connection at your own pace.'
              : 'EmpowerHealth Watch',
          trailing: ElevatedButton.icon(
            onPressed: _openCreatePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGold,
              foregroundColor: AppTheme.ink,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('New post', maxLines: 1, softWrap: false),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      // Deliberate horizontally scrollable tab row: a real horizontal
      // ListView (viewport) so chips scroll instead of running off the
      // screen, full-bleed so the chip cut off at the right edge shows
      // there are more tabs.
      SliverToBoxAdapter(
        child: SizedBox(
          height: _chipRowHeight(context),
          child: HorizontalDragScroll(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Center(
                child: HearthChoiceChip(
                  label: _categories[i],
                  primary: true,
                  selected: _selectedCategory == _categories[i],
                  onSelected: () =>
                      setState(() => _selectedCategory = _categories[i]),
                ),
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      if (!_isPregnancyLossSpace) ...[
        const SliverToBoxAdapter(child: CommunitySurveyBanner()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ] else ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Center(
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
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text(
                  'Browse general community (optional)',
                  textAlign: TextAlign.center,
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        sliver: SliverToBoxAdapter(
          child: HearthCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.favorite_border,
                      size: 20, color: AppTheme.brandPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPregnancyLossSpace
                            ? 'Share only what feels comfortable'
                            : "You're among friends",
                        style: const TextStyle(
                          fontFamily: AppTheme.sansFamily,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPregnancyLossSpace
                            ? 'A supportive space. Please avoid giving medical advice. Moderators may remove content that breaks community guidelines.'
                            : 'Share stories, ask questions, and support each other. Your posts show your display name unless you choose to post anonymously. Moderators may remove content that breaks community guidelines. Not medical advice.',
                        style: hearthCaptionStyle,
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
          .doc(postId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete post: $e')),
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

    // The card is not tappable as a whole: the delete button sits beside
    // the tappable area so it never opens the post.
    return HearthCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
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
                padding: EdgeInsets.fromLTRB(16, 16, isOwnPost ? 0 : 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HearthAvatar(
                      authorName.isNotEmpty
                          ? authorName[0].toUpperCase()
                          : '?',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HearthTag(category),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: hearthCardTitleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Metadata: textMuted (~6:1 on surface) and Wrap with
                          // roomier spacing so items flow to new lines instead
                          // of crowding under large Dynamic Type.
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isOwnPost ? '$authorName (you)' : authorName,
                                style: hearthCaptionStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${replies.length} replies',
                                    style: hearthCaptionStyle,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_border,
                                    size: 14,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${likes.length}',
                                    style: hearthCaptionStyle,
                                  ),
                                ],
                              ),
                              if (createdAt != null)
                                Text(
                                  _formatDate(createdAt),
                                  style: hearthCaptionStyle,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 6, 0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppTheme.textMuted),
                tooltip: 'Delete your post',
                constraints:
                    const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => _confirmDeletePostFromFeed(doc.id, '$title'),
              ),
            ),
        ],
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
                  const HearthIconChip(Icons.forum_outlined),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to start a discussion!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
