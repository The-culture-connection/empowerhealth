import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/guest_guard.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

  /// When true the post is stored with authorName 'Anonymous' and
  /// isAnonymous: true; the real name never reaches the post document.
  /// userId is still stored so the owner can delete it and moderators can act.
  bool _postAnonymously = false;

  static const String anonymousAuthorName = 'Anonymous';

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
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content for your post'),
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

      // Anonymous posts never read or store the profile name.
      final String authorName;
      if (_postAnonymously) {
        authorName = anonymousAuthorName;
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        authorName = _displayNameFrom(userDoc.data());
      }

      final postData = <String, dynamic>{
        'userId': userId,
        'authorName': authorName,
        'isAnonymous': _postAnonymously,
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
            content: Text('Post created successfully!'),
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
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HearthPushedHeader(title: 'Create Post'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // One-line privacy reminder (replaces the large trust card).
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.lock_outline,
                              size: 18, color: AppTheme.textSecondary),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Community posts are public. Please avoid sharing private health details.',
                            style: hearthCardBodyStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title Field — moved up so users can start writing immediately.
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Add a title',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Content Field
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: widget.contentPlaceholder ?? 'Write your post',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.keyboard_hide,
                              color: AppTheme.textMuted, size: 20),
                          onPressed: () => FocusScope.of(context).unfocus(),
                          tooltip: 'Dismiss keyboard',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Selection — compact chips, below the writing fields.
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        return HearthChoiceChip(
                          label: category,
                          selected: _selectedCategory == category,
                          onSelected: () =>
                              setState(() => _selectedCategory = category),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Anonymous option, directly above the Post button.
                    HearthCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      // Plain Material switch: the adaptive one renders a
                      // Cupertino switch on iOS that ignores the Hearth theme.
                      child: SwitchListTile(
                        value: _postAnonymously,
                        onChanged: _isSubmitting
                            ? null
                            : (v) => setState(() => _postAnonymously = v),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: const Text(
                          'Post anonymously',
                          style: hearthCardTitleStyle,
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            "Others will see “Anonymous” instead of your name.",
                            style: hearthCaptionStyle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Attribution summary so the user knows exactly how the post
                    // will appear before publishing.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            _postAnonymously
                                ? Icons.visibility_off_outlined
                                : Icons.person_outline,
                            size: 18,
                            color: AppTheme.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _postAnonymously
                                ? 'Posting as Anonymous in “$_selectedCategory”. You can still delete it later.'
                                : _authorName == null
                                ? 'Your post will show your profile display name in “$_selectedCategory”.'
                                : 'Posting publicly as $_authorName in “$_selectedCategory”.',
                            style: hearthCaptionStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    HearthButton.primary(
                      label: 'Post',
                      onPressed: _submitPost,
                      loading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
