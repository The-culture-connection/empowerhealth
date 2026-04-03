import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/provider_report.dart';
import '../services/provider_repository.dart';

Future<void> showProviderReportSheet(
  BuildContext context, {
  required String providerId,
  required String providerName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.submitProviderReport(
        providerId: widget.providerId,
        providerName: widget.providerName,
        userId: uid,
        reasonCategory: _reason,
        details: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks — our team will review this listing.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Report this listing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If something looks inaccurate or harmful, tell us. This is not for medical emergencies.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.providerName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...ProviderReportReason.options.map((e) {
              return RadioListTile<String>(
                title: Text(
                  e.value,
                  style: const TextStyle(fontSize: 14),
                ),
                value: e.key,
                groupValue: _reason,
                onChanged: _submitting
                    ? null
                    : (v) {
                        if (v != null) setState(() => _reason = v);
                      },
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.brandPurple,
              );
            }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'What should we know?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surfaceInput,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: AppTheme.brandWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.brandWhite,
                      ),
                    )
                  : const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
