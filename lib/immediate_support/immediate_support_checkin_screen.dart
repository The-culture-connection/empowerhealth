import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
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
        backgroundColor: const Color(0xFFF7F4FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.chevron_left, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We\'re here with you 💜',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You do not have to explain everything.\nChoose what kind of support would help right now.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ...kImmediateSupportOptions.map((opt) {
                        final selected = _selected.contains(opt.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggle(opt.id),
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
                        onPressed: () => _continue(skipped: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: AppTheme.brandWhite,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _continue(skipped: true),
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
