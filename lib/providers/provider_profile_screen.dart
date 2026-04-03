import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider.dart';
import '../models/provider_review.dart';
import '../services/provider_repository.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../widgets/mama_approved_community_badge.dart';
import 'provider_report_sheet.dart';
import 'provider_review_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String? providerId;
  final Provider? provider; // Allow passing provider directly

  const ProviderProfileScreen({super.key, this.providerId, this.provider})
    : assert(
        providerId != null || provider != null,
        'Either providerId or provider must be provided',
      );

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ProviderRepository _repository = ProviderRepository();
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  Provider? _provider;
  List<ProviderReview> _reviews = [];
  bool _isLoading = true;

  /// Shown on profile; moderated reviews can be hidden via [ProviderReview.status].
  List<ProviderReview> get _publishedReviews =>
      _reviews.where((r) => r.status == 'published').toList();
  bool _isSaved = false;
  bool _showMamaApprovedInfo = false;
  bool _showTagInfo = false;
  bool _reviewSubmitted = false; // Track if a review was submitted
  DateTime? _screenOpenedAt;
  /// Shown when profile cannot load (e.g. [directoryHidden] or missing doc).
  String? _profileUnavailableMessage;

  @override
  void initState() {
    super.initState();
    _screenOpenedAt = DateTime.now();
    if (widget.provider != null) {
      _isLoading = true;
      Future.microtask(() => _resolveProviderForProfile(widget.provider!));
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

  /// Reconcile search/navigation payload with Firestore so hidden listings disappear.
  Future<void> _resolveProviderForProfile(Provider initial) async {
    try {
      final resolved =
          await _repository.resolveDirectoryListingForProfile(initial);
      if (!mounted) return;
      if (resolved == null) {
        setState(() {
          _provider = null;
          _isLoading = false;
          _profileUnavailableMessage =
              'This provider is no longer listed in the directory.';
        });
        return;
      }
      setState(() {
        _provider = resolved;
        _isLoading = false;
        _profileUnavailableMessage = null;
      });
      _trackProviderProfileView();
      _trackScreenView();
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _provider = initial;
        _isLoading = false;
        _profileUnavailableMessage = null;
      });
      _trackProviderProfileView();
      _trackScreenView();
      _loadReviews();
    }
  }

  Future<void> _trackProviderScreenExit() async {
    if (_screenOpenedAt == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final seconds = DateTime.now().difference(_screenOpenedAt!).inSeconds;
    try {
      final userProfile = await _databaseService.getUserProfile(userId);
      await _analytics.logFeatureTimeSpent(
        feature: 'provider-search',
        timeSpentSeconds: seconds,
        sourceId: _provider?.id,
        userProfile: userProfile,
      );
    } catch (e) {
      print('Error tracking provider profile time spent: $e');
    }
  }

  @override
  void dispose() {
    _trackProviderScreenExit();
    super.dispose();
  }

  Future<void> _trackProviderProfileView() async {
    if (_provider == null) return;
    try {
      final analytics = AnalyticsService();
      final databaseService = DatabaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logProviderProfileViewed(
          providerId: _provider!.id ?? 'unknown',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking provider profile view: $e');
    }
  }

  Future<void> _trackScreenView() async {
    try {
      final analytics = AnalyticsService();
      final databaseService = DatabaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'provider_profile',
          feature: 'provider-search',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking provider profile screen view: $e');
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
        _profileUnavailableMessage = provider == null
            ? 'This provider is no longer listed in the directory.'
            : null;
      });
      if (provider != null) {
        _trackProviderProfileView();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _reportProviderId() {
    if (_provider == null) return 'unknown';
    final id = _provider!.id;
    if (id != null && id.isNotEmpty) return id;
    final npi = _provider!.npi;
    if (npi != null && npi.isNotEmpty) return 'npi_$npi';
    final pid = widget.providerId;
    if (pid != null && pid.isNotEmpty) return pid;
    return 'unknown';
  }

  Future<void> _loadReviews() async {
    if (_provider == null) {
      print('⚠️ [ProviderProfile] Cannot load reviews: Provider is null');
      return;
    }

    print(
      '🔍 [ProviderProfile] Loading reviews for provider: ${_provider!.name}',
    );

    try {
      // Use the repository method to enrich provider with reviews
      // This will find the provider in Firestore first, then fetch reviews using the correct ID
      final enrichedProvider = await _repository.enrichProviderWithReviews(
        _provider!,
      );

      // Get reviews separately to display them
      String? reviewProviderId = enrichedProvider.id ?? _provider!.id;
      if (reviewProviderId == null || reviewProviderId.isEmpty) {
        // Fallback: construct ID
        if (_provider!.npi != null && _provider!.npi!.isNotEmpty) {
          reviewProviderId = 'npi_${_provider!.npi}';
        } else if (_provider!.locations.isNotEmpty) {
          final loc = _provider!.locations.first;
          final namePart = _provider!.name
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
              .toLowerCase();
          reviewProviderId = 'api_${namePart}_${loc.city}_${loc.zip}';
        } else if (_provider!.name.isNotEmpty) {
          final namePart = _provider!.name
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
              .toLowerCase();
          reviewProviderId = 'name_$namePart';
        }
      }

      List<ProviderReview> reviews = [];
      if (reviewProviderId != null && reviewProviderId.isNotEmpty) {
        reviews = await _repository.getProviderReviews(reviewProviderId);
      }

      print('✅ [ProviderProfile] Loaded ${reviews.length} reviews');

      setState(() {
        _reviews = reviews;
        // Update provider with enriched data (Firestore ID, rating, review count)
        _provider = enrichedProvider;
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
        backgroundColor: AppTheme.backgroundWarm,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
        appBar: AppTheme.newUiAppBar(context, title: 'Provider Not Found'),
        body: const Center(child: Text('Provider not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.surfaceCard, AppTheme.backgroundWarm],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (matching NewUI)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context, _reviewSubmitted),
                    ),
                    Expanded(
                      child: Text(
                        'Back to results',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved
                            ? AppTheme.brandPurple
                            : AppTheme.textBarelyVisible,
                      ),
                      onPressed: () async {
                        final becameSaved = !_isSaved;
                        setState(() {
                          _isSaved = becameSaved;
                        });
                        if (becameSaved && _provider != null) {
                          try {
                            final userId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (userId != null) {
                              final userProfile = await _databaseService
                                  .getUserProfile(userId);
                              await _analytics.logProviderSelectedSuccess(
                                providerId: _provider!.id ?? 'unknown',
                                selectionMethod: 'bookmark',
                                userProfile: userProfile,
                              );
                            }
                          } catch (e) {
                            print(
                              'Error tracking provider selected success: $e',
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Content (matching NewUI)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ), // px-5 py-5
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProviderHeader(),
                      const SizedBox(height: 16), // mb-4
                      _buildQuickActions(),
                      if (_provider != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () {
                              showProviderReportSheet(
                                context,
                                providerId: _reportProviderId(),
                                providerName: _provider!.primaryDisplayName,
                              );
                            },
                            icon: Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                            label: Text(
                              'Report inaccurate or harmful info',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16), // mb-4
                      _buildContactInfo(),
                      const SizedBox(height: 16), // mb-4
                      _buildIdentityTags(),
                      const SizedBox(height: 16), // mb-4
                      _buildAbout(),
                      const SizedBox(height: 16), // mb-4
                      _buildReviews(),
                      const SizedBox(height: 16), // mb-4
                      _buildCommunityNote(),
                      const SizedBox(height: 100), // Space for bottom nav
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
      margin: const EdgeInsets.only(bottom: 16), // mb-4
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF663399), Color(0xFF8855BB)],
        ),
        borderRadius: BorderRadius.circular(24), // rounded-3xl
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
                      _provider!.primaryDisplayName,
                      style: const TextStyle(
                        fontSize: 24, // text-2xl
                        fontWeight: FontWeight.w400, // font-normal
                        color: AppTheme.brandWhite,
                      ),
                    ),
                    const SizedBox(height: 4), // mb-1
                    if (_provider!.specialty != null)
                      Text(
                        _provider!.specialty!,
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: AppTheme.brandWhite.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    if (_provider!.healthCoverageLabel != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            size: 18,
                            color: AppTheme.brandWhite.withOpacity(0.88),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Accepted health: ${_provider!.healthCoverageLabel}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.brandWhite.withOpacity(0.9),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_provider!.showsMamaApprovedBadge)
                InkWell(
                  onTap: () {
                    setState(() {
                      _showMamaApprovedInfo = !_showMamaApprovedInfo;
                    });
                  },
                  child: const MamaApprovedCommunityBadge(
                    onDarkBackground: true,
                    showInfoAffordance: true,
                  ),
                ),
            ],
          ),
          if (_showMamaApprovedInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandWhite.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.brandWhite.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This label appears when at least three parents rated this provider and the average is 4 stars or higher. It comes from community reviews only — not from a hospital, insurer, or medical board.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppTheme.brandWhite.withOpacity(0.92),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.brandWhite, size: 20),
              const SizedBox(width: 4),
              Text(
                _provider!.rating != null && _provider!.rating! > 0
                    ? _provider!.rating!.toStringAsFixed(1)
                    : _publishedReviews.isNotEmpty
                    ? (_publishedReviews.fold<double>(
                            0.0, (sum, r) => sum + r.rating) /
                          _publishedReviews.length)
                          .toStringAsFixed(1)
                    : 'N/A',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brandWhite,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_publishedReviews.length} reviews)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.brandWhite.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // mb-4
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF663399), Color(0xFF8855BB)],
                ),
                borderRadius: BorderRadius.circular(24), // rounded-2xl
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF663399).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _provider!.phone != null
                    ? () async {
                        // Track provider contact click
                        try {
                          final analytics = AnalyticsService();
                          final databaseService = DatabaseService();
                          final userId = FirebaseAuth.instance.currentUser?.uid;
                          if (userId != null) {
                            final userProfile = await databaseService
                                .getUserProfile(userId);
                            await analytics.logProviderContactClicked(
                              providerId: _provider!.id ?? 'unknown',
                              contactMethod: 'phone',
                              userProfile: userProfile,
                            );
                          }
                        } catch (e) {
                          print('Error tracking provider contact: $e');
                        }

                        final uri = Uri.parse('tel:${_provider!.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    : null,
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Call Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppTheme.brandWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final location = _provider!.locations.isNotEmpty
        ? _provider!.locations.first
        : null;
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      ...location.addressLines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                      if (location.distance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${location.distance!.toStringAsFixed(1)} mi from search',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.brandPurple,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              color: AppTheme.borderLight,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
          ],
          if (_provider!.phone != null) ...[
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    // Track provider contact click
                    try {
                      final analytics = AnalyticsService();
                      final databaseService = DatabaseService();
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        final userProfile = await databaseService
                            .getUserProfile(userId);
                        await analytics.logProviderContactClicked(
                          providerId: _provider!.id ?? 'unknown',
                          contactMethod: 'phone',
                          userProfile: userProfile,
                        );
                      }
                    } catch (e) {
                      print('Error tracking provider contact: $e');
                    }

                    final uri = Uri.parse('tel:${_provider!.phone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    _provider!.phone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.brandPurple,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              color: AppTheme.borderLight,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
          ],
          if (_provider!.email != null) ...[
            Row(
              children: [
                Icon(Icons.email, color: AppTheme.brandPurple, size: 20),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    // Track provider contact click
                    try {
                      final analytics = AnalyticsService();
                      final databaseService = DatabaseService();
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        final userProfile = await databaseService
                            .getUserProfile(userId);
                        await analytics.logProviderContactClicked(
                          providerId: _provider!.id ?? 'unknown',
                          contactMethod: 'email',
                          userProfile: userProfile,
                        );
                      }
                    } catch (e) {
                      print('Error tracking provider contact: $e');
                    }

                    final uri = Uri.parse('mailto:${_provider!.email}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    _provider!.email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.brandPurple,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 1,
              color: AppTheme.borderLight,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
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
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    _provider!.website!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.brandPurple,
                      fontWeight: FontWeight.w300,
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

  String _identityCategoryTitle(String category) {
    final c = category.toLowerCase().trim();
    switch (c) {
      case 'visit':
        return 'Visit experience';
      case 'race':
        return 'Race / ethnicity';
      case 'language':
        return 'Language';
      case 'cultural':
        return 'Cultural';
      case 'specialty':
        return 'Specialty';
      case 'certification':
        return 'Certification';
      default:
        if (c.isEmpty) return 'Other tags';
        return '${c[0].toUpperCase()}${c.substring(1)}';
    }
  }

  int _identityCategoryOrder(String category) {
    const order = [
      'visit',
      'race',
      'language',
      'cultural',
      'specialty',
      'certification',
    ];
    final c = category.toLowerCase().trim();
    final i = order.indexOf(c);
    return i >= 0 ? i : 50;
  }

  Widget _buildIdentityTagChip(IdentityTag tag) {
    final verified = tag.verificationStatus == 'verified';
    final screenW = MediaQuery.sizeOf(context).width;
    final maxTagW = (screenW - 80).clamp(160.0, screenW);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTagW),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.brandPurple,
                  fontWeight: FontWeight.w300,
                ),
                softWrap: true,
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 14, color: AppTheme.brandPurple),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityTags() {
    if (_provider!.identityTags.isEmpty) return const SizedBox.shrink();

    final byCategory = <String, List<IdentityTag>>{};
    for (final tag in _provider!.identityTags) {
      final key = tag.category.trim().isEmpty ? 'other' : tag.category.trim();
      byCategory.putIfAbsent(key, () => []).add(tag);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) {
        final oa = _identityCategoryOrder(a);
        final ob = _identityCategoryOrder(b);
        if (oa != ob) return oa.compareTo(ob);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return _buildSection(
      title: 'Identity & Cultural Tags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showTagInfo = !_showTagInfo;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'About these tags',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.brandPurple,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showTagInfo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About identity tags',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These help you find culturally concordant care. Tags may come from the community or from visit experiences; verified tags show a checkmark.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final cat in categories) ...[
            Text(
              _identityCategoryTitle(cat),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: byCategory[cat]!
                  .map((tag) => _buildIdentityTagChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
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
            Text(
              'Specialties',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
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
                      fontWeight: FontWeight.w300,
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

  Widget _experienceReviewChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1BEE7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.brandPurple,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildReviews() {
    // Use actual review count from loaded reviews
    final reviewCount = _publishedReviews.length;
    return _buildSection(
      title: 'Patient Experiences ($reviewCount)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_publishedReviews.isNotEmpty) ...[
            ..._publishedReviews.take(3).map((review) {
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          review.userName ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
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
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    if (review.feltHeard ||
                        review.feltRespected ||
                        review.explainedClearly) ...[
                      const SizedBox(height: 10),
                      Text(
                        'How was your visit?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (review.feltHeard)
                            _experienceReviewChip('Felt heard'),
                          if (review.feltRespected)
                            _experienceReviewChip('Felt respected'),
                          if (review.explainedClearly)
                            _experienceReviewChip('Explained clearly'),
                        ],
                      ),
                    ],
                    if (review.whatWentWell != null &&
                        review.whatWentWell!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'What went well',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.whatWentWell!.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (review.reviewerRaceEthnicity.isNotEmpty ||
                        review.reviewerLanguages.isNotEmpty ||
                        review.reviewerCulturalTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      if (review.reviewerRaceEthnicity.isNotEmpty) ...[
                        Text(
                          'Race / ethnicity',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: review.reviewerRaceEthnicity
                              .map((t) => _experienceReviewChip(t))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (review.reviewerLanguages.isNotEmpty) ...[
                        Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: review.reviewerLanguages
                              .map((t) => _experienceReviewChip(t))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (review.reviewerCulturalTags.isNotEmpty) ...[
                        Text(
                          'Cultural tags',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: review.reviewerCulturalTags
                              .map((t) => _experienceReviewChip(t))
                              .toList(),
                        ),
                      ],
                    ],
                    if (review.helpfulCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${review.helpfulCount} found this helpful',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                    if (review.experienceFields != null &&
                        review.experienceFields!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Additional notes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.experienceFields!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (review.updatedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Updated ${review.updatedAt!.toLocal().toString().split('.').first}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                    if (review.reviewText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        review.reviewText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else
            Text(
              'No reviews yet. Be the first to review!',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityNote() {
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // from-blue-50
            Color(0xFFF3E5F5), // to-purple-50
          ],
        ),
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, // w-10
            height: 40, // h-10
            decoration: BoxDecoration(
              color: AppTheme.brandPurple,
              borderRadius: BorderRadius.circular(16), // rounded-2xl
            ),
            child: const Icon(Icons.favorite, color: AppTheme.brandWhite, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help Other Mothers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8), // mb-2
                Text(
                  'Your experience matters. Share your story to help other mothers make informed decisions about their care.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12), // mb-3
                TextButton(
                  onPressed: () async {
                    // Use NPI if available, otherwise use Firestore ID, otherwise use name+location as composite ID
                    String? reviewProviderId = _provider!.id;
                    if (reviewProviderId == null || reviewProviderId.isEmpty) {
                      // Try NPI
                      if (_provider!.npi != null &&
                          _provider!.npi!.isNotEmpty) {
                        reviewProviderId = 'npi_${_provider!.npi}';
                      } else if (widget.providerId != null &&
                          widget.providerId!.isNotEmpty) {
                        reviewProviderId = widget.providerId;
                      } else if (_provider!.locations.isNotEmpty) {
                        // Create composite ID from name + location
                        final loc = _provider!.locations.first;
                        reviewProviderId =
                            'api_${_provider!.name}_${loc.city}_${loc.zip}'
                                .replaceAll(' ', '_')
                                .toLowerCase();
                      }
                    }

                    if (reviewProviderId == null || reviewProviderId.isEmpty) {
                      // Try to create a composite ID as last resort
                      if (_provider?.name.isNotEmpty == true) {
                        final namePart = _provider!.name
                            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
                            .toLowerCase();
                        if (_provider?.locations.isNotEmpty == true) {
                          final loc = _provider!.locations.first;
                          reviewProviderId =
                              'api_${namePart}_${loc.city}_${loc.zip}';
                        } else {
                          reviewProviderId = 'name_$namePart';
                        }
                      }

                      if (reviewProviderId == null ||
                          reviewProviderId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot submit review: Provider identifier is missing',
                            ),
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
                    if (result != null && mounted) {
                      // Mark that a review was submitted
                      _reviewSubmitted = true;
                      print(
                        '✅ [ProviderProfile] Review submitted, result: $result',
                      );

                      // Result is the Firestore provider ID (or original providerId if no Firestore ID)
                      final returnedProviderId = result is String
                          ? result
                          : null;

                      // Immediately update provider ID if we got a Firestore ID back
                      if (returnedProviderId != null &&
                          _provider != null &&
                          (returnedProviderId != _provider!.id) &&
                          !returnedProviderId.startsWith('api_') &&
                          !returnedProviderId.startsWith('name_') &&
                          !returnedProviderId.startsWith('npi_')) {
                        setState(() {
                          _provider = _provider!.copyWith(
                            id: returnedProviderId,
                          );
                        });
                        print(
                          '✅ [ProviderProfile] Updated provider with Firestore ID from review: $returnedProviderId',
                        );
                      }

                      // Wait a moment for Firestore to index the new review
                      await Future.delayed(const Duration(milliseconds: 1000));

                      // Reload reviews immediately using the Firestore ID
                      final reviewIdToUse =
                          _provider?.id ??
                          returnedProviderId ??
                          reviewProviderId;
                      print(
                        '🔄 [ProviderProfile] Reloading reviews with providerId: $reviewIdToUse',
                      );
                      await _loadReviews();
                      print(
                        '✅ [ProviderProfile] Reviews reloaded: ${_reviews.length} reviews',
                      );

                      // Also reload provider to get updated review count from Firestore
                      // Use the Firestore ID if available (either from returnedProviderId or _provider.id)
                      final providerIdToReload =
                          returnedProviderId ?? _provider?.id;
                      if (providerIdToReload != null &&
                          providerIdToReload.isNotEmpty &&
                          !providerIdToReload.startsWith('api_') &&
                          !providerIdToReload.startsWith('name_') &&
                          !providerIdToReload.startsWith('npi_')) {
                        try {
                          print(
                            '🔄 [ProviderProfile] Reloading provider from Firestore with ID: $providerIdToReload',
                          );
                          final updatedProvider = await _repository.getProvider(
                            providerIdToReload,
                          );
                          if (updatedProvider != null && mounted) {
                            setState(() {
                              _provider = updatedProvider.copyWith(
                                rating: _publishedReviews.isNotEmpty
                                    ? _publishedReviews.fold<double>(
                                            0.0,
                                            (sum, r) => sum + r.rating,
                                          ) /
                                          _publishedReviews.length
                                    : updatedProvider.rating,
                                reviewCount: _publishedReviews.length,
                              );
                            });
                            print(
                              '✅ [ProviderProfile] Provider updated: rating=${_provider!.rating}, reviewCount=${_provider!.reviewCount}',
                            );
                          }
                        } catch (e) {
                          print(
                            '⚠️ [ProviderProfile] Could not reload provider: $e',
                          );
                          // Still update with current review count
                          if (_provider != null && mounted) {
                            setState(() {
                              _provider = _provider!.copyWith(
                                reviewCount: _reviews.length,
                                rating: _reviews.isNotEmpty
                                    ? _reviews.fold<double>(
                                            0.0,
                                            (sum, r) => sum + r.rating,
                                          ) /
                                          _reviews.length
                                    : null,
                              );
                            });
                          }
                        }
                      } else if (_provider != null && mounted) {
                        // Update with current review count even if no Firestore ID
                        setState(() {
                          _provider = _provider!.copyWith(
                            reviewCount: _publishedReviews.length,
                            rating: _publishedReviews.isNotEmpty
                                ? _publishedReviews.fold<double>(
                                        0.0,
                                        (sum, r) => sum + r.rating,
                                      ) /
                                      _publishedReviews.length
                                : null,
                          );
                        });
                        print(
                          '✅ [ProviderProfile] Provider updated (no Firestore ID): rating=${_provider!.rating}, reviewCount=${_provider!.reviewCount}',
                        );
                      }
                    }
                  },
                  child: Text(
                    'Write a review →',
                    style: TextStyle(
                      color: AppTheme.brandPurple,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // mb-4
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        border: Border.all(color: AppTheme.borderLight),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16), // mb-4
          child,
        ],
      ),
    );
  }
}
