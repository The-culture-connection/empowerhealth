import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/feature_session_scope.dart';
import 'pregnancy_loss_constants.dart';
import 'pregnancy_loss_service.dart';

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
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HearthPushedHeader(
                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                        onBack: () => Navigator.pop(context),
                        title: 'What support would feel helpful right now?',
                        subtitle:
                            'Choose anything that feels supportive today. You can skip anything you do not want to answer.',
                      ),
                      const SizedBox(height: 16),
                      ...kPregnancyLossPreferenceOptions.map((opt) {
                        final selected = _selected.contains(opt.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HearthOptionRow(
                            label: opt.label,
                            selected: selected,
                            control: HearthControl.checkbox,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(opt.id);
                                } else {
                                  _selected.add(opt.id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                      if (showOther) ...[
                        const SizedBox(height: 8),
                        // Field look comes from the Hearth input theme.
                        TextField(
                          controller: _otherController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Optional: only what you want to share',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 22 / 15,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    HearthButton.primary(
                      label: 'Continue',
                      loading: _busy,
                      onPressed: _busy ? null : () => _saveAndFinish(skipped: false),
                    ),
                    const SizedBox(height: 4),
                    HearthButton.text(
                      label: 'Skip for now',
                      onPressed: _busy ? null : () => _saveAndFinish(skipped: true),
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
