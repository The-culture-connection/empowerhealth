import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/guest_guard.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../utils/content_filter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    this.communityStage,
    this.categories,
    this.contentPlaceholder,
  });

  final String? communityStage;
  final List<String>? categories;
  final String? contentPlaceholder;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late String _selectedCategory;
  bool _isSubmitting = false;

  List<String> get _categories =>
      widget.categories ??
      const ['Questions', 'Birth Stories', 'Support', 'Resources'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _loadAuthorName();
  }

  /// Name shown on the post. Resolved up front so the user sees exactly how
  /// the post will be attributed before publishing.
  String? _authorName;

  static String _displayNameFrom(Map<String, dynamic>? userData) {
    for (final key in const ['username', 'name']) {
      final v = userData?[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return 'Anonymous';
  }

  Future<void> _loadAuthorName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) setState(() => _authorName = _displayNameFrom(doc.data()));
    } catch (_) {
      // Non-blocking: the name is resolved again on submit.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!await requireAccount(context, action: 'post in the community')) return;
    if (!mounted) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your post'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content for your post'),
          backgroundColor: AppTheme.brandGold,
        ),
      );
      return;
    }

    // Objectionable-content filter (Guideline 1.2)
    final filterError = ContentFilter.check(
      '${_titleController.text}\n${_contentController.text}',
    );
    if (filterError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filterError),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile for username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();
      final authorName = _displayNameFrom(userData);

      final postData = <String, dynamic>{
        'userId': userId,
        'authorName': authorName,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'likes': [],
        'replies': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.communityStage != null) {
        postData['communityStage'] = widget.communityStage;
      }
      await FirebaseFirestore.instance.collection('community_posts').add(postData);

      // Track community post creation
      try {
        final analytics = AnalyticsService();
        final databaseService = DatabaseService();
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logCommunityPostCreated(
          topicCategory: _selectedCategory,
          userProfile: userProfile,
        );
      } catch (e) {
        print('Error tracking community post creation: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post created successfully!'),
            backgroundColor: AppTheme.brandTurquoise,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: ${e.toString()}'),
            backgroundColor: AppTheme.brandPurple,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Create Post'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundWarm, AppTheme.surfaceCard],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One-line privacy reminder (replaces the large trust card).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Community posts are public. Please avoid sharing private health details.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title Field — moved up so users can start writing immediately.
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Add a title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF663399),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceInput,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
                const SizedBox(height: 12),

                // Content Field
                TextField(
                  controller: _contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: widget.contentPlaceholder ?? 'Write your post',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF663399),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceInput,
                    contentPadding: const EdgeInsets.all(18),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.keyboard_hide,
                          color: Colors.grey[400], size: 20),
                      onPressed: () => FocusScope.of(context).unfocus(),
                      tooltip: 'Dismiss keyboard',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Selection — compact chips, below the writing fields.
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = category),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Attribution summary so the user knows how the post will
                // appear before publishing (there is no anonymous mode; posts
                // always show the profile display name).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _authorName == null
                            ? 'Your post will show your profile display name in “$_selectedCategory”.'
                            : 'Posting publicly as $_authorName in “$_selectedCategory”.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppTheme.brandWhite),
                            ),
                          )
                        : const Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
