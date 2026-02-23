import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../models/provider_review.dart';
import '../services/provider_repository.dart';
import '../cors/ui_theme.dart';
import 'provider_review_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String? providerId;
  final Provider? provider; // Allow passing provider directly

  const ProviderProfileScreen({
    super.key,
    this.providerId,
    this.provider,
  }) : assert(providerId != null || provider != null, 'Either providerId or provider must be provided');

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ProviderRepository _repository = ProviderRepository();
  Provider? _provider;
  List<ProviderReview> _reviews = [];
  bool _isLoading = true;
  bool _isSaved = false;
  bool _showMamaApprovedInfo = false;
  bool _showTagInfo = false;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      // Provider passed directly - no need to load
      setState(() {
        _provider = widget.provider;
        _isLoading = false;
      });
      // Always try to load reviews, even if provider doesn't have Firestore ID
      // (might have NPI or composite ID)
      _loadReviews();
    } else if (widget.providerId != null && widget.providerId!.isNotEmpty) {
      // Load from Firestore
      _loadProvider();
      _loadReviews();
    } else {
      // Invalid state
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProvider() async {
    if (widget.providerId == null || widget.providerId!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final provider = await _repository.getProvider(widget.providerId!);
      setState(() {
        _provider = provider;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    // Use the same logic as review submission to get providerId
    String? reviewProviderId = _provider?.id;
    if (reviewProviderId == null || reviewProviderId.isEmpty) {
      // Try NPI
      if (_provider?.npi != null && _provider!.npi!.isNotEmpty) {
        reviewProviderId = 'npi_${_provider!.npi}';
      } else if (widget.providerId != null && widget.providerId!.isNotEmpty) {
        reviewProviderId = widget.providerId;
      } else if (_provider?.locations.isNotEmpty == true) {
        // Create composite ID from name + location
        final loc = _provider!.locations.first;
        final namePart = _provider!.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
        reviewProviderId = 'api_${namePart}_${loc.city}_${loc.zip}';
      } else if (_provider?.name.isNotEmpty == true) {
        // Last resort: use name only (sanitized)
        final namePart = _provider!.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
        reviewProviderId = 'name_$namePart';
      }
    }
    
    if (reviewProviderId == null || reviewProviderId.isEmpty) {
      print('⚠️ [ProviderProfile] Cannot load reviews: No provider ID available');
      print('⚠️ [ProviderProfile] Provider name: ${_provider?.name}, NPI: ${_provider?.npi}, Locations: ${_provider?.locations.length}');
      return;
    }
    
    print('🔍 [ProviderProfile] Using providerId for reviews: $reviewProviderId');
    
    try {
      print('🔍 [ProviderProfile] Loading reviews for providerId: $reviewProviderId');
      final reviews = await _repository.getProviderReviews(reviewProviderId);
      print('✅ [ProviderProfile] Loaded ${reviews.length} reviews');
      
      // Calculate average rating from reviews
      double? averageRating;
      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
        averageRating = totalRating / reviews.length;
      }
      
      setState(() {
        _reviews = reviews;
        // Update provider rating if we have reviews
        if (averageRating != null && _provider != null) {
          _provider = _provider!.copyWith(
            rating: averageRating,
            reviewCount: reviews.length,
          );
        }
      });
    } catch (e, stackTrace) {
      print('❌ [ProviderProfile] Error loading reviews: $e');
      print('❌ [ProviderProfile] Stack trace: $stackTrace');
      // Still set empty list so UI doesn't show loading forever
      setState(() {
        _reviews = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider Not Found')),
        body: const Center(child: Text('Provider not found')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F6F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Back to results',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? AppTheme.brandPurple : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSaved = !_isSaved;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProviderHeader(),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      _buildContactInfo(),
                      const SizedBox(height: 16),
                      _buildIdentityTags(),
                      const SizedBox(height: 16),
                      _buildAbout(),
                      const SizedBox(height: 16),
                      _buildReviews(),
                      const SizedBox(height: 16),
                      _buildCommunityNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF663399), Color(0xFF8855BB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _provider!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_provider!.specialty != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _provider!.specialty!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_provider!.mamaApproved)
                InkWell(
                  onTap: () {
                    setState(() {
                      _showMamaApprovedInfo = !_showMamaApprovedInfo;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text(
                          'Mama Approved™',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_showMamaApprovedInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mama Approved™ is a community experience-based trust indicator, not a medical certification.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This provider has received consistently positive reviews from mothers in our community, with high ratings for feeling heard, respected, and supported.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                _provider!.rating != null && _provider!.rating! > 0
                    ? _provider!.rating!.toStringAsFixed(1)
                    : _reviews.isNotEmpty
                        ? (_reviews.fold<double>(0.0, (sum, r) => sum + r.rating) / _reviews.length).toStringAsFixed(1)
                        : 'N/A',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_reviews.length} reviews)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _provider!.phone != null
                ? () async {
                    final uri = Uri.parse('tel:${_provider!.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                : null,
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    final location = _provider!.locations.isNotEmpty ? _provider!.locations.first : null;
    return _buildSection(
      title: 'Contact & Location',
      child: Column(
        children: [
          if (location != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_provider!.practiceName != null)
                        Text(
                          _provider!.practiceName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        location.fullAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (location.distance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${location.distance!.toStringAsFixed(1)} miles away',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],
          if (_provider!.phone != null) ...[
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('tel:${_provider!.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    _provider!.phone!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],
          if (_provider!.email != null) ...[
            Row(
              children: [
                Icon(Icons.email, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('mailto:${_provider!.email}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    _provider!.email!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],
          if (_provider!.website != null) ...[
            Row(
              children: [
                Icon(Icons.language, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(_provider!.website!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    _provider!.website!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentityTags() {
    if (_provider!.identityTags.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: 'Identity & Cultural Tags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Identity & Cultural Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showTagInfo = !_showTagInfo;
                      });
                    },
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to add tag
                },
                child: const Text(
                  '+ Add tag',
                  style: TextStyle(color: Color(0xFF663399)),
                ),
              ),
            ],
          ),
          if (_showTagInfo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About identity tags:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These help mothers find culturally concordant care. Tags show their source and verification status for transparency. Community members can add tags, which are then reviewed by our team.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ..._provider!.identityTags.map((tag) {
            MaterialColor statusColor;
            IconData statusIcon;
            switch (tag.verificationStatus) {
              case 'verified':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                break;
              case 'pending':
                statusColor = Colors.amber;
                statusIcon = Icons.access_time;
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.help_outline;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor.shade700),
                          const SizedBox(width: 8),
                          Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: statusColor.shade700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag.verificationStatus,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${tag.source}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement report
            },
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('Report incorrect info'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return _buildSection(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_provider!.specialties.isNotEmpty) ...[
            const Text(
              'Specialties',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _provider!.specialties.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildReviews() {
    // Use actual review count from loaded reviews
    final reviewCount = _reviews.length;
    return _buildSection(
      title: 'Patient Experiences ($reviewCount)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_reviews.isNotEmpty) ...[
            ..._reviews.take(3).toList().map((review) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  review.userName ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (review.isVerified) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Text(
                                      'Verified Patient',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    size: 14,
                                    color: index < review.rating
                                        ? Colors.amber
                                        : Colors.grey[300],
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  review.createdAt.toString().split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (review.wouldRecommend)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '✓ Would recommend',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (review.reviewText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        review.reviewText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else
            const Text(
              'No reviews yet. Be the first to review!',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Help Other Mothers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your experience matters. Share your story to help other mothers make informed decisions about their care.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  // Use NPI if available, otherwise use Firestore ID, otherwise use name+location as composite ID
                  String? reviewProviderId = _provider!.id;
                  if (reviewProviderId == null || reviewProviderId.isEmpty) {
                    // Try NPI
                    if (_provider!.npi != null && _provider!.npi!.isNotEmpty) {
                      reviewProviderId = 'npi_${_provider!.npi}';
                    } else if (widget.providerId != null && widget.providerId!.isNotEmpty) {
                      reviewProviderId = widget.providerId;
                    } else if (_provider!.locations.isNotEmpty) {
                      // Create composite ID from name + location
                      final loc = _provider!.locations.first;
                      reviewProviderId = 'api_${_provider!.name}_${loc.city}_${loc.zip}'.replaceAll(' ', '_').toLowerCase();
                    }
                  }
                  
                  if (reviewProviderId == null || reviewProviderId.isEmpty) {
                    // Try to create a composite ID as last resort
                    if (_provider?.name.isNotEmpty == true) {
                      final namePart = _provider!.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
                      if (_provider?.locations.isNotEmpty == true) {
                        final loc = _provider!.locations.first;
                        reviewProviderId = 'api_${namePart}_${loc.city}_${loc.zip}';
                      } else {
                        reviewProviderId = 'name_$namePart';
                      }
                    }
                    
                    if (reviewProviderId == null || reviewProviderId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot submit review: Provider identifier is missing'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                  }
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderReviewScreen(
                        providerId: reviewProviderId!,
                        providerName: _provider!.name,
                        provider: _provider, // Pass provider data to save
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    // Reload reviews after submission using the same providerId logic
                    await _loadReviews();
                    // Update review count in provider
                    if (_provider != null) {
                      setState(() {
                        _provider = Provider(
                          id: _provider!.id,
                          name: _provider!.name,
                          specialty: _provider!.specialty,
                          practiceName: _provider!.practiceName,
                          npi: _provider!.npi,
                          locations: _provider!.locations,
                          providerTypes: _provider!.providerTypes,
                          specialties: _provider!.specialties,
                          phone: _provider!.phone,
                          email: _provider!.email,
                          website: _provider!.website,
                          acceptingNewPatients: _provider!.acceptingNewPatients,
                          acceptsPregnantWomen: _provider!.acceptsPregnantWomen,
                          acceptsNewborns: _provider!.acceptsNewborns,
                          telehealth: _provider!.telehealth,
                          rating: _provider!.rating,
                          reviewCount: _reviews.length, // Update with actual count
                          mamaApproved: _provider!.mamaApproved,
                          mamaApprovedCount: _provider!.mamaApprovedCount,
                          identityTags: _provider!.identityTags,
                          createdAt: _provider!.createdAt,
                          updatedAt: _provider!.updatedAt,
                          source: _provider!.source,
                        );
                      });
                    }
                  }
                },
                child: const Text(
                  'Write a review →',
                  style: TextStyle(color: Color(0xFF663399)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
