import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../widgets/feature_session_scope.dart';
import 'immediate_support_constants.dart';
import 'immediate_support_hub_screen.dart';
import 'immediate_support_service.dart';

/// Universal trauma-informed support check-in — no reproductive-event disclosure.
class ImmediateSupportCheckInScreen extends StatefulWidget {
  const ImmediateSupportCheckInScreen({
    super.key,
    this.entrySource = 'checkin',
  });

  final String entrySource;

  @override
  State<ImmediateSupportCheckInScreen> createState() =>
      _ImmediateSupportCheckInScreenState();
}

class _ImmediateSupportCheckInScreenState
    extends State<ImmediateSupportCheckInScreen> {
  final Set<String> _selected = {};
  final TextEditingController _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ImmediateSupportService.instance.logOpened(
      entrySource: widget.entrySource,
    );
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _continue({required bool skipped}) async {
    final count = _selected.length;
    await ImmediateSupportService.instance.logCompleted(
      selectionCount: count,
      skipped: skipped,
    );

    if (!mounted) return;

    final somethingElse = _selected.contains(ImmediateSupportOptionId.somethingElse)
        ? _otherController.text.trim()
        : null;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ImmediateSupportHubScreen(
          selectedOptionIds: Set<String>.from(_selected),
          somethingElseText:
              somethingElse != null && somethingElse.isNotEmpty
                  ? somethingElse
                  : null,
        ),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final showOther =
        _selected.contains(ImmediateSupportOptionId.somethingElse);

    return FeatureSessionScope(
      feature: 'immediate-support',
      entrySource: widget.entrySource,
      child: Scaffold(
        backgroundColor: AppTheme.ground,
        body: SafeArea(
          child: Column(
            children: [
              HearthPushedHeader(
                onBack: () => Navigator.pop(context),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We\'re here with you',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You do not have to explain everything.\nChoose what kind of support would help right now.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ...kImmediateSupportOptions.map((opt) {
                        final selected = _selected.contains(opt.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HearthOptionRow(
                            label: opt.label,
                            selected: selected,
                            control: HearthControl.checkbox,
                            onTap: () => _toggle(opt.id),
                          ),
                        );
                      }),
                      if (showOther) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _otherController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Optional: only what you want to share',
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
                      onPressed: () => _continue(skipped: false),
                    ),
                    const SizedBox(height: 4),
                    HearthButton.text(
                      label: 'Skip for now',
                      onPressed: () => _continue(skipped: true),
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
