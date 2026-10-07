import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/provider.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/provider_repository.dart';
import '../widgets/mama_approved_community_badge.dart';
import 'provider_profile_screen.dart';

/// Full list of directory providers that earn the community Mama Approved™ badge
/// (3+ reviews, average ≥ 4★ — see [Provider.showsMamaApprovedBadge]).
class MamaApprovedProvidersScreen extends StatefulWidget {
  const MamaApprovedProvidersScreen({super.key});

  @override
  State<MamaApprovedProvidersScreen> createState() =>
      _MamaApprovedProvidersScreenState();
}

class _MamaApprovedProvidersScreenState
    extends State<MamaApprovedProvidersScreen> {
  final ProviderRepository _repository = ProviderRepository();
  List<Provider> _providers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _trackScreen();
  }

  Future<void> _trackScreen() async {
    try {
      final analytics = AnalyticsService();
      final databaseService = DatabaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProfile = await databaseService.getUserProfile(userId);
        await analytics.logScreenView(
          screenName: 'mama_approved_providers_list',
          feature: 'provider-search',
          userProfile: userProfile,
        );
      }
    } catch (e) {
      print('Error tracking mama approved list screen: $e');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repository.fetchMamaApprovedCommunityBadgeProviders();
      if (mounted) {
        setState(() {
          _providers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppTheme.newUiAppBar(
        context,
        title: 'Mama Approved™ providers',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Could not load the list.',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your internet connection, then pull down to try again.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try again'),
                        ),
                      ),
                    ],
                  )
                : _providers.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            'No Mama Approved™ providers yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${Provider.mamaApprovedCriteriaText} Share your own provider experience to help other moms.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w300,
                              height: 1.35,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        // Index 0 is a one-sentence explainer of the badge.
                        itemCount: _providers.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Text(
                              Provider.mamaApprovedCriteriaText,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w300,
                                height: 1.35,
                              ),
                            );
                          }
                          final p = _providers[index - 1];
                          final location = p.locations.isNotEmpty
                              ? p.locations.first
                              : null;
                          final locationText = location != null
                              ? '${location.city}, ${location.state}'
                              : 'Location not available';
                          return Material(
                            color: AppTheme.surfaceCard,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => ProviderProfileScreen(
                                      provider: p,
                                      providerId: p.id,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name gets the full card width; the
                                    // badge sits on its own line below so it
                                    // never squeezes the name at large text.
                                    Text(
                                      p.primaryDisplayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const MamaApprovedCommunityBadge(
                                      compact: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p.specialty ?? 'Provider',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      locationText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    if (p.rating != null ||
                                        (p.reviewCount ?? 0) > 0) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${p.rating != null ? '${Provider.formatAverageRating(p.rating!)} ★ · ' : ''}${p.reviewCount ?? 0} reviews',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
