import 'package:flutter/material.dart';

import '../constants/medical_sources.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';

/// "Sources & References" card shown beneath health/medical content.
///
/// Satisfies App Store Guideline 1.4.1 by giving users easy-to-find citations
/// (tappable links) to the trusted organizations the information is based on.
///
/// Pass [topic] (e.g. the module title) to surface topic-specific sources in
/// addition to the always-shown defaults.
class MedicalCitationsSection extends StatelessWidget {
  final String? topic;

  const MedicalCitationsSection({super.key, this.topic});

  Future<void> _open(BuildContext context, MedicalSource source) async {
    final ok = await launchMedicalSource(source);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${source.url}'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = MedicalSources.forTopic(topic);

    return SizedBox(
      width: double.infinity,
      child: HearthCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 20, color: AppTheme.brandPurple),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Sources & References',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This educational content is based on guidance from the following '
            'trusted health organizations. Tap to read the source.',
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 13,
              height: 19 / 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...sources.map((s) => _SourceLink(
                source: s,
                onTap: () => _open(context, s),
              )),
        ],
      ),
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  final MedicalSource source;
  final VoidCallback onTap;

  const _SourceLink({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        // Keeps each link a comfortable tap target.
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.open_in_new,
                  size: 16, color: AppTheme.brandPurple),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandPurple,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.brandPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.organization,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 12,
                      height: 17 / 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
