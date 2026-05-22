import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_constants.dart';
import 'pregnancy_loss_service.dart';
import 'pregnancy_loss_theme.dart';

class PregnancyLossPreferencesScreen extends StatefulWidget {
  const PregnancyLossPreferencesScreen({super.key});

  @override
  State<PregnancyLossPreferencesScreen> createState() =>
      _PregnancyLossPreferencesScreenState();
}

class _PregnancyLossPreferencesScreenState
    extends State<PregnancyLossPreferencesScreen> {
  final Set<String> _selected = {};
  final TextEditingController _otherController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish({required bool skipped}) async {
    setState(() => _busy = true);
    try {
      await PregnancyLossService.instance.saveSupportPreferences(
        preferenceIds: _selected.toList(),
        somethingElseText: _selected.contains(PregnancyLossPreferenceId.somethingElse)
            ? _otherController.text
            : null,
      );
      await PregnancyLossService.instance.logSupportPreferencesSaved(
        preferenceIds: _selected.toList(),
        skipped: skipped,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOther =
        _selected.contains(PregnancyLossPreferenceId.somethingElse);

    return FeatureSessionScope(
      feature: 'pregnancy-loss',
      entrySource: 'preferences',
      child: Scaffold(
        backgroundColor: PregnancyLossTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What support would feel helpful right now?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose anything that feels supportive today. You can skip anything you do not want to answer.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ...kPregnancyLossPreferenceOptions.map((opt) {
                        final selected = _selected.contains(opt.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selected.remove(opt.id);
                                  } else {
                                    _selected.add(opt.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEBE4F3)
                                      : AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.brandPurple
                                            .withValues(alpha: 0.35)
                                        : AppTheme.borderLight
                                            .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    height: 1.4,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (showOther) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otherController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: 'Optional — only what you want to share',
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : () => _saveAndFinish(skipped: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: AppTheme.brandWhite,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.brandWhite,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _saveAndFinish(skipped: true),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
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
