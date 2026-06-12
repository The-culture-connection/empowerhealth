import 'package:flutter/material.dart';

import '../constants/medical_sources.dart';
import '../cors/ui_theme.dart';

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 16, y: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 20, color: AppTheme.brandPurple),
              const SizedBox(width: 8),
              Text(
                'Sources & References',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This educational content is based on guidance from the following '
            'trusted health organizations. Tap to read the source.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.open_in_new,
                size: 16, color: AppTheme.brandPurple.withOpacity(0.8)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandPurple,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.brandPurple.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.organization,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
