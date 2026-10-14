import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider_review.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../constants/reviewer_self_report_tags.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../auth/guest_guard.dart';
import '../utils/content_filter.dart';

class ProviderReviewScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final Provider? provider; // Optional provider data to save

  const ProviderReviewScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.provider,
  });

  @override
  State<ProviderReviewScreen> createState() => _ProviderReviewScreenState();
}

class _ProviderReviewScreenState extends State<ProviderReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final ProviderRepository _repository = ProviderRepository();
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  
  int _rating = 0;
  bool _wouldRecommend = false;
  bool _feltHeard = false;
  bool _feltRespected = false;
  bool _explainedClearly = false;
  final _whatWentWellController = TextEditingController();
  bool _isSubmitting = false;
  final List<String> _raceEthnicity = [];
  final List<String> _reviewLanguages = [];
  final List<String> _culturalTags = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _whatWentWellController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!await requireAccount(context, action: 'review providers')) return;
    if (!mounted) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
        ),
      );
      return;
    }

    if (widget.providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit review: Provider ID is missing'),
        ),
      );
      return;
    }

    // Note: reviewText is optional, so we don't need to validate it

    // Objectionable-content filter (Guideline 1.2)
    final filterError = ContentFilter.check(
      '${_reviewController.text}\n${_whatWentWellController.text}',
    );
    if (filterError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filterError),
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
      final userName = userData?['username'] ?? 'Anonymous';

      final review = ProviderReview(
        providerId: widget.providerId,
        userId: userId,
        userName: userName,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        wouldRecommend: _wouldRecommend,
        feltHeard: _feltHeard,
        feltRespected: _feltRespected,
        explainedClearly: _explainedClearly,
        whatWentWell: _whatWentWellController.text.trim().isEmpty
            ? null
            : _whatWentWellController.text.trim(),
        reviewerRaceEthnicity: List<String>.from(_raceEthnicity),
        reviewerLanguages: List<String>.from(_reviewLanguages),
        reviewerCulturalTags: List<String>.from(_culturalTags),
        createdAt: DateTime.now(),
        isVerified: false,
      );

      // Save provider to Firestore if provided, then submit review
      String? firestoreProviderId;
      if (widget.provider != null) {
        firestoreProviderId =
            await _repository.saveProviderOnReview(widget.provider!);
        print('✅ [ProviderReview] Provider saved with Firestore ID: $firestoreProviderId');
      }
      
      // Submit review
      await _repository.submitProviderReview(
        review,
        firestoreProviderId: firestoreProviderId,
      );
      print('✅ [ProviderReview] Review submitted with providerId: ${firestoreProviderId ?? review.providerId}');

      try {
        final profile = await _databaseService.getUserProfile(userId);
        final well = _whatWentWellController.text.trim();
        await _analytics.logProviderReviewSubmitted(
          providerId: firestoreProviderId ?? review.providerId,
          rating: _rating,
          feltHeard: _feltHeard,
          feltRespected: _feltRespected,
          explainedClearly: _explainedClearly,
          hasWhatWentWell: well.isNotEmpty,
          reviewTextLength: _reviewController.text.trim().length,
          userProfile: profile,
        );
      } catch (e) {
        print('⚠️ [ProviderReview] Analytics: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            duration: Duration(seconds: 2),
          ),
        );
        // Return the Firestore provider ID so the calling screen can use it immediately
        Navigator.pop(context, firestoreProviderId ?? review.providerId);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HearthPushedHeader(title: 'Write a Review'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Provider Name
                      HearthCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppTheme.brandPurple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.providerName,
                                style: hearthCardTitleStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      const HearthSectionHeading('Overall Rating *'),
                      const SizedBox(height: 12),
                      Center(
                        child: HearthStarRating(
                          value: _rating,
                          onChanged: (star) => setState(() => _rating = star),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const HearthSectionHeading('How was your visit?'),
                      const SizedBox(height: 4),
                      Text(
                        'These help other parents beyond stars alone.',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      HearthCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                            _visitCheck(
                              'I felt heard',
                              _feltHeard,
                              (v) => setState(() => _feltHeard = v ?? false),
                            ),
                            _visitCheck(
                              'I felt respected',
                              _feltRespected,
                              (v) => setState(() => _feltRespected = v ?? false),
                            ),
                            _visitCheck(
                              'Things were explained clearly',
                              _explainedClearly,
                              (v) => setState(() => _explainedClearly = v ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const HearthSectionHeading('About you (optional)'),
                      const SizedBox(height: 4),
                      Text(
                        'Helps others find perspectives like theirs. You can skip any section.',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _tagGroupLabel('Race / ethnicity'),
                      const SizedBox(height: 8),
                      _tagWrap(ReviewerSelfReportTags.raceEthnicity, _raceEthnicity),
                      const SizedBox(height: 16),
                      _tagGroupLabel('Language'),
                      const SizedBox(height: 8),
                      _tagWrap(ReviewerSelfReportTags.languages, _reviewLanguages),
                      const SizedBox(height: 16),
                      _tagGroupLabel('Cultural / community tags'),
                      const SizedBox(height: 8),
                      _tagWrap(ReviewerSelfReportTags.culturalTags, _culturalTags),
                      const SizedBox(height: 24),

                      const HearthSectionHeading('What did they do especially well?'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatWentWellController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Optional. For example: listened without rushing…',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Review Text
                      const HearthSectionHeading('Anything else about your experience?'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reviewController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Share your experience with this provider...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Would Recommend
                      HearthCard(
                        color: _wouldRecommend ? AppTheme.tintWarm : AppTheme.surface,
                        borderColor:
                            _wouldRecommend ? AppTheme.brandPurple : AppTheme.borderWarm,
                        borderWidth: _wouldRecommend ? 2 : 1,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _wouldRecommend,
                              onChanged: (value) {
                                setState(() {
                                  _wouldRecommend = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'I would recommend this provider',
                                style: hearthCardBodyStyle.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      HearthButton.primary(
                        label: 'Submit Review',
                        onPressed: _isSubmitting ? null : _submitReview,
                        loading: _isSubmitting,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _visitCheck(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: hearthCardBodyStyle.copyWith(fontSize: 15, color: AppTheme.ink),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _tagGroupLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
    );
  }

  Widget _tagWrap(List<String> labels, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final sel = selected.contains(label);
        return HearthChoiceChip(
          label: label,
          selected: sel,
          icon: sel ? Icons.check : null,
          onSelected: () => setState(() {
            if (!sel) {
              selected.add(label);
            } else {
              selected.remove(label);
            }
          }),
        );
      }).toList(),
    );
  }
}
