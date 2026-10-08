import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../design_system/hearth.dart';
import '../models/provider_report.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/provider_repository.dart';

Future<void> showProviderReportSheet(
  BuildContext context, {
  required String providerId,
  required String providerName,
}) async {
  // The Hearth sheet supplies the ground fill, handle, padding and keyboard inset.
  await showHearthSheet<void>(
    context: context,
    builder: (ctx) {
      return _ProviderReportSheetBody(
        providerId: providerId,
        providerName: providerName,
      );
    },
  );
}

class _ProviderReportSheetBody extends StatefulWidget {
  const _ProviderReportSheetBody({
    required this.providerId,
    required this.providerName,
  });

  final String providerId;
  final String providerName;

  @override
  State<_ProviderReportSheetBody> createState() =>
      _ProviderReportSheetBodyState();
}

class _ProviderReportSheetBodyState extends State<_ProviderReportSheetBody> {
  final _detailsController = TextEditingController();
  final _repository = ProviderRepository();
  String _reason = ProviderReportReason.inaccurateInfo;
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to submit a report'),
          ),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final detailsText = _detailsController.text.trim();
      await _repository.submitProviderReport(
        providerId: widget.providerId,
        providerName: widget.providerName,
        userId: uid,
        reasonCategory: _reason,
        details: detailsText.isEmpty ? null : detailsText,
      );
      try {
        final profile = await DatabaseService().getUserProfile(uid);
        await AnalyticsService().logProviderListingReportSubmitted(
          providerId: widget.providerId,
          reasonCategory: _reason,
          reasonCategoryLabel:
              ProviderReportReason.labels[_reason] ?? _reason,
          hasDetails: detailsText.isNotEmpty,
          userProfile: profile,
        );
      } catch (_) {}
      if (mounted) Navigator.of(context).pop();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Thank you. We received your report and will review it.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send report: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Report this listing', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'If something looks inaccurate or harmful, tell us. This is not for medical emergencies.',
            style: hearthCardBodyStyle,
          ),
          const SizedBox(height: 16),
          Text(widget.providerName, style: hearthCardTitleStyle),
          const SizedBox(height: 16),
          Text('Reason', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          ...ProviderReportReason.options.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HearthOptionRow(
                label: e.value,
                selected: _reason == e.key,
                onTap: _submitting
                    ? null
                    : () => setState(() => _reason = e.key),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextFormField(
            controller: _detailsController,
            maxLines: 4,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              hintText: 'What should we know?',
            ),
          ),
          const SizedBox(height: 20),
          HearthButton.primary(
            label: 'Submit report',
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}
