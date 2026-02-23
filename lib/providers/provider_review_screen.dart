import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider_review.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
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
  
  int _rating = 0;
  bool _wouldRecommend = false;
  bool _isSubmitting = false;
  bool _isAdmin = false;
  bool _mamaApproved = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
        return;
      }

      // Check if user's email exists in ADMIN collection
      final adminQuery = await FirebaseFirestore.instance
          .collection('ADMIN')
          .where('email', isEqualTo: user!.email)
          .limit(1)
          .get();

      setState(() {
        _isAdmin = adminQuery.docs.isNotEmpty;
        _isCheckingAdmin = false;
      });
      
      print('✅ [ProviderReview] Admin check: ${user.email} is ${_isAdmin ? "admin" : "not admin"}');
    } catch (e) {
      print('⚠️ [ProviderReview] Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
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
        createdAt: DateTime.now(),
        isVerified: true, // Provider reviews are verified
      );

      // Save provider to Firestore if provided, then submit review
      String? firestoreProviderId;
      
      // If admin wants to mark as Mama Approved, ensure provider is saved
      if (_isAdmin && _mamaApproved && widget.provider != null) {
        firestoreProviderId = await _repository.saveProviderOnReview(
          widget.provider!,
          markMamaApproved: true,
        );
        print('✅ [ProviderReview] Provider saved with Firestore ID: $firestoreProviderId (Mama Approved)');
      } else if (widget.provider != null) {
        firestoreProviderId = await _repository.saveProviderOnReview(widget.provider!);
        print('✅ [ProviderReview] Provider saved with Firestore ID: $firestoreProviderId');
      }
      
      // Submit review
      await _repository.submitProviderReview(
        review,
        firestoreProviderId: firestoreProviderId,
      );
      print('✅ [ProviderReview] Review submitted with providerId: ${firestoreProviderId ?? review.providerId}');

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
      appBar: AppBar(
        title: const Text('Write a Review'),
        backgroundColor: AppTheme.brandPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F6F8)],
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
                      color: Colors.white,
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

                  // Review Text
                  const Text(
                    'Your Experience',
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
                      fillColor: Colors.white,
                    ),
                    // Review text is optional, no validation needed
                  ),
                  const SizedBox(height: 24),

                  // Would Recommend
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                  const SizedBox(height: 16),
                  
                  // Mama Approved (only for admin users)
                  if (_isAdmin && !_isCheckingAdmin)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFEF3F3), // rose-50
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFFECDD3)), // rose-200
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Color(0xFFE11D48), // rose-600
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mama Approved™',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFBE123C), // rose-700
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mark this provider as Mama Approved',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: _mamaApproved,
                            onChanged: (value) {
                              setState(() {
                                _mamaApproved = value ?? false;
                              });
                            },
                            activeColor: Color(0xFFE11D48), // rose-600
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
                      foregroundColor: Colors.white,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
