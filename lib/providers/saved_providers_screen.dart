import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'provider_profile_screen.dart';
import 'saved_providers_store.dart';

/// Providers the user bookmarked from a provider profile.
class SavedProvidersScreen extends StatefulWidget {
  const SavedProvidersScreen({super.key});

  @override
  State<SavedProvidersScreen> createState() => _SavedProvidersScreenState();
}

class _SavedProvidersScreenState extends State<SavedProvidersScreen> {
  final SavedProvidersStore _store = SavedProvidersStore();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<List<SavedProvider>>? _stream =
      _uid == null ? null : _store.watch(_uid);

  Future<void> _remove(SavedProvider saved) async {
    final uid = _uid;
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _store.remove(uid, saved.docId);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Removed from Saved providers'),
          action: saved.provider == null
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () => _store.save(
                    uid,
                    saved.provider!,
                    docId: saved.docId,
                  ),
                ),
        ),
      );
    } catch (e) {
      debugPrint('Remove saved provider failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text("We couldn't remove this provider. Please try again."),
        ),
      );
    }
  }

  void _open(SavedProvider saved) {
    final p = saved.provider;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => p != null
            ? ProviderProfileScreen(provider: p, providerId: p.id)
            : ProviderProfileScreen(providerId: saved.docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HearthPushedHeader(
              title: 'Saved providers',
              subtitle: 'Tap the bookmark on a provider profile to save it here.',
            ),
            Expanded(
              child: _stream == null
                  ? _message(
                      'Sign in to save providers',
                      'Saved providers are kept with your account.',
                    )
                  : StreamBuilder<List<SavedProvider>>(
                      stream: _stream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return _message(
                            'Could not load your saved providers',
                            'Check your internet connection and try again.',
                          );
                        }
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final items = snap.data!;
                        if (items.isEmpty) {
                          return _message(
                            'No saved providers yet',
                            'Open a provider from your search results and tap the bookmark at the top to save them here.',
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _card(items[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(SavedProvider saved) {
    final p = saved.provider;
    final textTheme = Theme.of(context).textTheme;
    final location = p != null && p.locations.isNotEmpty ? p.locations.first : null;
    return HearthCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      onTap: () => _open(saved),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.primaryDisplayName ?? 'Saved provider',
                  style: textTheme.titleLarge,
                ),
                if (p?.specialty != null) ...[
                  const SizedBox(height: 4),
                  Text(p!.specialty!, style: hearthCardBodyStyle),
                ],
                if (location != null) ...[
                  const SizedBox(height: 6),
                  Text(location.cityStateZipLine, style: hearthCaptionStyle),
                ],
                if (p != null) ...[
                  const SizedBox(height: 6),
                  Text(p.communityRatingText, style: hearthCaptionStyle),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from Saved providers',
            onPressed: () => _remove(saved),
            icon: const Icon(Icons.bookmark_remove_outlined,
                color: AppTheme.brandPurple),
          ),
        ],
      ),
    );
  }

  Widget _message(String title, String body) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Center(child: HearthIconChip(Icons.bookmark_border, size: 64, iconSize: 30)),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: textTheme.bodyLarge),
      ],
    );
  }
}
