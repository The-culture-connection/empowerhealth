import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../widgets/mama_approved_community_badge.dart';
import 'provider_review_screen.dart';

/// Entry point in the Community → Reviews → Mama Approved™ flow.
///
/// A mother searches for a provider she has seen, then leaves a review. Those
/// reviews feed the provider's trust score and Mama Approved™ qualification.
class ShareProviderExperienceScreen extends StatefulWidget {
  const ShareProviderExperienceScreen({super.key});

  @override
  State<ShareProviderExperienceScreen> createState() =>
      _ShareProviderExperienceScreenState();
}

class _ShareProviderExperienceScreenState
    extends State<ShareProviderExperienceScreen> {
  final ProviderRepository _repository = ProviderRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Provider> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final results = await _repository.searchProvidersByName(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _openReview(Provider provider) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderReviewScreen(
          providerId: provider.id ?? provider.npi ?? provider.name,
          providerName: provider.primaryDisplayName,
          provider: provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Share Provider Experience'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help Another Mama Choose Care 💜',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find the provider, hospital, doula, or birth team you saw and '
                    'share your experience. Your feedback helps other mothers find '
                    'care where they feel heard, respected, and supported — and '
                    'helps providers earn Mama Approved™.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search by provider or practice name',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSearching ? null : _runSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: AppTheme.brandWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Find provider'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return _hint('Search for the provider you saw to share your experience.');
    }
    if (_results.isEmpty) {
      return _hint(
        'No providers found. Try a different spelling, or search providers '
        'from the home screen first.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ProviderResultCard(
        provider: _results[i],
        onTap: () => _openReview(_results[i]),
      ),
    );
  }

  Widget _hint(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w300,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ProviderResultCard extends StatelessWidget {
  const _ProviderResultCard({required this.provider, required this.onTap});

  final Provider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location =
        provider.locations.isNotEmpty ? provider.locations.first : null;
    final subtitle = [
      provider.specialty,
      if (location != null) '${location.city}, ${location.state}',
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' • ');

    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.primaryDisplayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (provider.showsMamaApprovedBadge) ...[
                          const SizedBox(width: 8),
                          const MamaApprovedCommunityBadge(compact: true),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
