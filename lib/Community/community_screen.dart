import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../cors/ui_theme.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'seed_mock_posts.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  bool _hasSeeded = false;

  @override
  void initState() {
    super.initState();
    _seedMockPostsIfNeeded();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWarm,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (matching NewUI)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with others on the same journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Safety Note (matching NewUI)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEBE4F3), // #ebe4f3
                        Color(0xFFE0D5EB), // #e0d5eb
                        Color(0xFFE8DFE8), // #e8dfe8
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle background pattern
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
                                  color: Colors.white,
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
                      // Content
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.favorite, color: AppTheme.textMuted, size: 20),
                          ),
                          const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'A safe space',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Share your experiences, ask questions, and support others. All discussions are moderated to keep this space respectful and supportive.',
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
              const SizedBox(height: 24),

              // Categories (matching NewUI)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        onTap: () => setState(() => _selectedCategory = 'Questions'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Birth Stories',
                        isSelected: _selectedCategory == 'Birth Stories',
                        onTap: () => setState(() => _selectedCategory = 'Birth Stories'),
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
                        onTap: () => setState(() => _selectedCategory = 'Resources'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Discussions Section (matching NewUI)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent discussions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreatePostScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'New post',
                        style: TextStyle(
                          color: AppTheme.textLightest,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Discussions List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
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
                      );
                    }

                    final posts = snapshot.data!.docs.where((doc) {
                      if (_selectedCategory == 'All') return true;
                      final data = doc.data() as Map<String, dynamic>;
                      return data['category'] == _selectedCategory;
                    }).toList();

                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          'No posts in this category yet',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final doc = posts[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? '';
                        final authorName = data['authorName'] ?? 'Anonymous';
                        final replies = List<Map<String, dynamic>>.from(
                            data['replies'] ?? []);
                        final category = data['category'] ?? 'General';
                        final createdAt =
                            (data['createdAt'] as Timestamp?)?.toDate();
                        final likes = List<String>.from(data['likes'] ?? []);

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  postId: doc.id,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppTheme.borderLighter.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
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
                                      authorName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            authorName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textLightest,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: AppTheme.textBarelyVisible,
                                            ),
                                          ),
                                          Icon(Icons.message,
                                              size: 14,
                                              color: AppTheme.textBarelyVisible),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${replies.length} replies',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textLightest,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: AppTheme.textBarelyVisible,
                                            ),
                                          ),
                                          Icon(Icons.favorite,
                                              size: 14,
                                              color: AppTheme.textBarelyVisible),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${likes.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textLightest,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          if (createdAt != null) ...[
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                color: AppTheme.textBarelyVisible,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textLightest,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.gradientPurpleStart, AppTheme.gradientPurpleEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPurple.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
            child: const Icon(Icons.edit, color: Colors.white, size: 24),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.gradientBeigeStart, AppTheme.textLightest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.borderLighter.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w300,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
