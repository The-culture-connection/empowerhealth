import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider.dart';
import '../models/provider_review.dart';
import '../services/provider_repository.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
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

    print('🔍 [ProviderProfile] Loading reviews for provider: ${_provider!.name}');

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
      return const Scaffold(
        backgroundColor: AppTheme.ground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return const Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HearthPushedHeader(title: 'Provider Not Found'),
              Expanded(child: Center(child: Text('Provider not found'))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HearthPushedHeader(
                backLabel: 'Back to results',
                onBack: () => Navigator.pop(context, _reviewSubmitted),
                actions: [
                    HearthCircleButton(
                      icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      iconColor: _isSaved
                          ? AppTheme.brandPurple
                          : AppTheme.textMuted,
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProviderHeader(),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                      if (_provider != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.center,
                          // Reporting is a quiet action: ink-muted, never red.
                          child: TextButton.icon(
                            onPressed: () {
                              showProviderReportSheet(
                                context,
                                providerId: _reportProviderId(),
                                providerName: _provider!.primaryDisplayName,
                              );
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: AppTheme.textMuted,
                            ),
                            icon: const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                            label: const Text(
                              'Report inaccurate or harmful info',
                              style: hearthCaptionStyle,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildContactInfo(),
                      const SizedBox(height: 16),
                      _buildIdentityTags(),
                      const SizedBox(height: 16),
                      _buildAbout(),
                      const SizedBox(height: 16),
                      _buildReviews(),
                      const SizedBox(height: 16),
                      _buildCommunityNote(),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildProviderHeader() {
    const onPurpleBody = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 15,
      height: 22 / 15,
      color: AppTheme.onPurpleSecondary,
    );
    return HearthFeatureCard(
      tone: HearthTone.purple,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name gets the full card width; the Mama Approved™ badge sits on
          // its own line below so it never squeezes the name at large text.
          Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _provider!.primaryDisplayName,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.onPurple,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (_provider!.specialty != null)
                      Text(
                        _provider!.specialty!,
                        style: onPurpleBody,
                      ),
                    if (_provider!.healthCoverageLabel != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.health_and_safety_outlined,
                              size: 18,
                              color: AppTheme.onPurpleSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Accepted health: ${_provider!.healthCoverageLabel}',
                              style: onPurpleBody,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_provider!.showsMamaApprovedBadge) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showMamaApprovedInfo = !_showMamaApprovedInfo;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: const Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: MamaApprovedCommunityBadge(
                              onDarkBackground: true,
                              showInfoAffordance: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
          ),
          if (_showMamaApprovedInfo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.onPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Provider.mamaApprovedCriteriaText} It reflects community reviews only, not a hospital, insurer, or medical board.',
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      height: 21 / 14,
                      color: AppTheme.onPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.brandGold, size: 22),
              const SizedBox(width: 6),
              Text(
                _provider!.rating != null && _provider!.rating! > 0
                    ? Provider.formatAverageRating(_provider!.rating!)
                    : _publishedReviews.isNotEmpty
                    ? Provider.formatAverageRating(
                        _publishedReviews.fold<double>(
                              0.0, (sum, r) => sum + r.rating) /
                            _publishedReviews.length,
                      )
                    : 'N/A',
                style: const TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onPurple,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '(${_publishedReviews.length} review${_publishedReviews.length == 1 ? '' : 's'})',
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppTheme.onPurpleSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return HearthButton.primary(
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
                icon: Icons.phone_outlined,
                label: 'Call Now',
    );
  }

  /// Contact link row: 52px tall with a warm rule above it, like the mockup.
  Widget _contactLinkRow({
    required IconData icon,
    required Widget label,
    required VoidCallback onTap,
    required bool ruleAbove,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: ruleAbove
            ? const Border(top: BorderSide(color: AppTheme.borderWarm))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brandPurple, size: 20),
              const SizedBox(width: 12),
              Expanded(child: label),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _contactLinkStyle = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.brandPurple,
  );

  Widget _buildContactInfo() {
    final location = _provider!.locations.isNotEmpty
        ? _provider!.locations.first
        : null;
    final hasLinks = _provider!.phone != null ||
        _provider!.email != null ||
        _provider!.website != null;
    return _buildSection(
      title: 'Contact & Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (location != null) ...[
            Padding(
              padding: EdgeInsets.only(bottom: hasLinks ? 16 : 0),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.brandPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_provider!.practiceName != null)
                        Text(
                          _provider!.practiceName!,
                          style: const TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      const SizedBox(height: 4),
                      ...location.addressLines.map(
                        (line) => Text(line, style: hearthCardBodyStyle),
                      ),
                      if (location.distance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${location.distance!.toStringAsFixed(1)} mi from search',
                          style: hearthCaptionStyle.copyWith(
                            color: AppTheme.brandPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            ),
          ],
          if (_provider!.phone != null) ...[
            _contactLinkRow(
                  icon: Icons.phone_outlined,
                  ruleAbove: location != null,
                  label: Text(
                    _provider!.phoneDisplay ?? _provider!.phone!,
                    style: _contactLinkStyle,
                  ),
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
            ),
          ],
          if (_provider!.email != null) ...[
            _contactLinkRow(
                  icon: Icons.mail_outline,
                  ruleAbove: location != null || _provider!.phone != null,
                  label: Text(
                    _provider!.email!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: _contactLinkStyle,
                  ),
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
            ),
          ],
          if (_provider!.website != null) ...[
            _contactLinkRow(
                  icon: Icons.language,
                  ruleAbove: location != null ||
                      _provider!.phone != null ||
                      _provider!.email != null,
                  label: Text(
                    _provider!.website!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: _contactLinkStyle,
                  ),
                  onTap: () async {
                    final uri = Uri.parse(_provider!.website!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
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
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppTheme.tintWarm,
          shape: StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  tag.name,
                  style: _tagTextStyle,
                  softWrap: true,
                ),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: AppTheme.brandPurple),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Same text as HearthTag, so verified identity tags match the plain ones.
  static const TextStyle _tagTextStyle = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textSecondary,
  );

  static const TextStyle _subheadingStyle = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );

  static const TextStyle _reviewLabelStyle = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textMuted,
  );

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
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('About these tags', style: hearthCaptionStyle),
                      SizedBox(width: 6),
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
          ),
          if (_showTagInfo) ...[
            const SizedBox(height: 8),
            const HearthNote(
              title: 'About identity tags',
              text:
                  'These help you find culturally concordant care. Tags may come from the community or from visit experiences; verified tags show a checkmark.',
            ),
          ],
          const SizedBox(height: 12),
          for (final cat in categories) ...[
            Text(
              _identityCategoryTitle(cat),
              style: _subheadingStyle,
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
            const Text('Specialties', style: _subheadingStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _provider!.specialties.map((specialty) {
                return HearthTag(specialty);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _experienceReviewChip(String label) {
    return HearthTag(label);
  }

  /// Community trust indicators from the experience questions — the same
  /// trust indicators shown alongside (not part of) the Mama Approved™ rule.
  Widget _buildExperienceTrustSummary() {
    final reviews = _publishedReviews;
    if (reviews.isEmpty) return const SizedBox.shrink();
    final count = reviews.length;
    int pct(bool Function(ProviderReview) test) =>
        ((reviews.where(test).length / count) * 100).round();
    final feltHeard = pct((r) => r.feltHeard);
    final feltRespected = pct((r) => r.feltRespected);
    final explained = pct((r) => r.explainedClearly);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.tintWarm,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What mothers said',
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPurple,
            ),
          ),
          const SizedBox(height: 12),
          _trustRow(Icons.hearing, '$feltHeard% felt heard'),
          const SizedBox(height: 10),
          _trustRow(Icons.volunteer_activism_outlined,
              '$feltRespected% felt respected'),
          const SizedBox(height: 10),
          _trustRow(Icons.chat_bubble_outline_rounded,
              '$explained% said things were explained clearly'),
        ],
      ),
    );
  }

  Widget _trustRow(IconData icon, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: AppTheme.brandPurple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: hearthCardBodyStyle.copyWith(color: AppTheme.ink),
          ),
        ),
      ],
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
          if (_publishedReviews.isNotEmpty) _buildExperienceTrustSummary(),
          if (_publishedReviews.isNotEmpty) ...[
            ..._publishedReviews.take(3).map((review) {
              return HearthCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                color: AppTheme.ground,
                radius: BorderRadius.circular(18),
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
                          style: const TextStyle(
                            fontFamily: AppTheme.sansFamily,
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        if (review.wouldRecommend)
                          const HearthTag('✓ Would recommend'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        HearthStarRating(value: review.rating, size: 16),
                        Text(
                          review.createdAt.toString().split(' ')[0],
                          style: hearthCaptionStyle,
                        ),
                      ],
                    ),
                    if (review.feltHeard ||
                        review.feltRespected ||
                        review.explainedClearly) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'How was your visit?',
                        style: _reviewLabelStyle,
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
                        style: _reviewLabelStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.whatWentWell!.trim(),
                        style: hearthCardBodyStyle,
                      ),
                    ],
                    if (review.reviewerRaceEthnicity.isNotEmpty ||
                        review.reviewerLanguages.isNotEmpty ||
                        review.reviewerCulturalTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      if (review.reviewerRaceEthnicity.isNotEmpty) ...[
                        Text(
                          'Race / ethnicity',
                          style: _reviewLabelStyle,
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
                          style: _reviewLabelStyle,
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
                          style: _reviewLabelStyle,
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
                        style: hearthCaptionStyle,
                      ),
                    ],
                    if (review.experienceFields != null &&
                        review.experienceFields!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Additional notes',
                        style: _reviewLabelStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.experienceFields!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: hearthCardBodyStyle,
                      ),
                    ],
                    if (review.updatedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Updated ${review.updatedAt!.toLocal().toString().split('.').first}',
                        style: hearthCaptionStyle.copyWith(fontSize: 12),
                      ),
                    ],
                    if (review.reviewText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        review.reviewText!,
                        style: hearthCardBodyStyle,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else
            const Text(
              'No reviews yet. Be the first to review!',
              style: hearthCardBodyStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityNote() {
    return HearthFeatureCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HearthIconChip(Icons.favorite_border, tone: HearthChipTone.surface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help Other Mothers',
                  style: hearthFeatureTitleStyle(),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your experience matters. Share your story to help other mothers make informed decisions about their care.',
                  style: hearthCardBodyStyle,
                ),
                const SizedBox(height: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppTheme.brandPurple,
                  ),
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
                      print('✅ [ProviderProfile] Review submitted, result: $result');

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
                        print('✅ [ProviderProfile] Updated provider with Firestore ID from review: $returnedProviderId');
                      }

                      // Wait a moment for Firestore to index the new review
                      await Future.delayed(const Duration(milliseconds: 1000));

                      // Reload reviews immediately using the Firestore ID
                      final reviewIdToUse =
                          _provider?.id ??
                          returnedProviderId ??
                          reviewProviderId;
                      print('🔄 [ProviderProfile] Reloading reviews with providerId: $reviewIdToUse');
                      await _loadReviews();
                      print('✅ [ProviderProfile] Reviews reloaded: ${_reviews.length} reviews');

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
                          print('🔄 [ProviderProfile] Reloading provider from Firestore with ID: $providerIdToReload');
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
                            print('✅ [ProviderProfile] Provider updated: rating=${_provider!.rating}, reviewCount=${_provider!.reviewCount}');
                          }
                        } catch (e) {
                          print('⚠️ [ProviderProfile] Could not reload provider: $e');
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
                        print('✅ [ProviderProfile] Provider updated (no Firestore ID): rating=${_provider!.rating}, reviewCount=${_provider!.reviewCount}');
                      }
                    }
                  },
                  child: const Text(
                    'Write a review →',
                    style: TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandPurple,
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
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthSectionHeading(title),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
