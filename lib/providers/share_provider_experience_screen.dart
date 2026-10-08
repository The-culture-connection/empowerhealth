import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../models/provider.dart';
import '../services/provider_repository.dart';
import '../widgets/mama_approved_community_badge.dart';
import 'add_provider_screen.dart';
import 'provider_quick_search_screen.dart';
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
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HearthPushedHeader(title: 'Share Provider Experience'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help Another Mama Choose Care\u00A0',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find the provider, hospital, doula, or birth team you saw and '
                    'share your experience. Your feedback helps other mothers find '
                    'care where they feel heard, respected, and supported, and '
                    'helps providers earn Mama Approved™.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                    decoration: const InputDecoration(
                      hintText: 'Search by provider or practice name',
                      prefixIcon: Icon(Icons.search, color: AppTheme.brandPurple),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HearthButton.primary(
                    onPressed: _isSearching ? null : _runSearch,
                    icon: Icons.search,
                    label: 'Find provider',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
      return _buildNoResults();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ProviderResultCard(
        provider: _results[i],
        onTap: () => _openReview(_results[i]),
      ),
    );
  }

  /// Shown when the name search finds nothing. Gives real next steps instead of
  /// dead-ending: search the full directory (universal — no type required) or
  /// add the provider so it can be reviewed.
  Widget _buildNoResults() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HearthIconChip(Icons.search_off, size: 64, iconSize: 30),
            const SizedBox(height: 16),
            const Text(
              "We couldn't find that provider yet",
              textAlign: TextAlign.center,
              style: hearthCardTitleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different spelling, search the full directory, or add them '
              'so you (and other mamas) can share reviews.',
              textAlign: TextAlign.center,
              style: hearthCardBodyStyle,
            ),
            const SizedBox(height: 20),
            HearthButton.primary(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProviderQuickSearchScreen(),
                ),
              ),
              icon: Icons.search,
              label: 'Search the full directory',
            ),
            const SizedBox(height: 10),
            HearthButton.secondary(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddProviderScreen(),
                ),
              ),
              icon: Icons.person_add_alt_1_outlined,
              label: 'Add a provider',
            ),
          ],
        ),
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
          style: hearthCardBodyStyle.copyWith(color: AppTheme.textMuted),
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

    return HearthCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.primaryDisplayName,
                  style: hearthCardTitleStyle,
                ),
                // Badge on its own line so long names never squeeze it.
                if (provider.showsMamaApprovedBadge) ...[
                  const SizedBox(height: 6),
                  const MamaApprovedCommunityBadge(compact: true),
                ],
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: hearthCaptionStyle.copyWith(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
