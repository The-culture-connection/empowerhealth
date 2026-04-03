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
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit review: Provider ID is missing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Note: reviewText is optional, so we don't need to validate it

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
        print(
          '✅ [ProviderReview] Provider saved with Firestore ID: $firestoreProviderId',
        );
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
            content: Text('✅ Thank you for your review!'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(context, title: 'Write a Review'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.surfaceCard, AppTheme.backgroundWarm],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Provider Name
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.brandPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.providerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating
                  const Text(
                    'Overall Rating *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 48,
                            color: index < _rating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'How was your visit?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These help other parents beyond stars alone.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _feltHeard,
                          onChanged: (v) =>
                              setState(() => _feltHeard = v ?? false),
                          activeColor: AppTheme.brandPurple,
                          title: const Text(
                            'I felt heard',
                            style: TextStyle(fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: _feltRespected,
                          onChanged: (v) =>
                              setState(() => _feltRespected = v ?? false),
                          activeColor: AppTheme.brandPurple,
                          title: const Text(
                            'I felt respected',
                            style: TextStyle(fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: _explainedClearly,
                          onChanged: (v) =>
                              setState(() => _explainedClearly = v ?? false),
                          activeColor: AppTheme.brandPurple,
                          title: const Text(
                            'Things were explained clearly',
                            style: TextStyle(fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'About you (optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Helps others find perspectives like theirs. You can skip any section.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Race / ethnicity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReviewerSelfReportTags.raceEthnicity.map((label) {
                      final sel = _raceEthnicity.contains(label);
                      return FilterChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _raceEthnicity.add(label);
                          } else {
                            _raceEthnicity.remove(label);
                          }
                        }),
                        selectedColor:
                            AppTheme.brandPurple.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.brandPurple,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReviewerSelfReportTags.languages.map((label) {
                      final sel = _reviewLanguages.contains(label);
                      return FilterChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _reviewLanguages.add(label);
                          } else {
                            _reviewLanguages.remove(label);
                          }
                        }),
                        selectedColor:
                            AppTheme.brandPurple.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.brandPurple,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cultural / community tags',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReviewerSelfReportTags.culturalTags.map((label) {
                      final sel = _culturalTags.contains(label);
                      return FilterChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _culturalTags.add(label);
                          } else {
                            _culturalTags.remove(label);
                          }
                        }),
                        selectedColor:
                            AppTheme.brandPurple.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.brandPurple,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'What did they do especially well?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatWentWellController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Optional — e.g. listened without rushing…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceInput,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Review Text
                  const Text(
                    'Anything else about your experience?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reviewController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this provider...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceInput,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Would Recommend
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _wouldRecommend,
                          onChanged: (value) {
                            setState(() {
                              _wouldRecommend = value ?? false;
                            });
                          },
                          activeColor: AppTheme.brandPurple,
                        ),
                        const Expanded(
                          child: Text(
                            'I would recommend this provider',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: AppTheme.brandWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandWhite),
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
