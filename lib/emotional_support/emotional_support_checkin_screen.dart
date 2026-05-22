import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../widgets/feature_session_scope.dart';
import 'emotional_support_constants.dart';
import 'emotional_support_emergency_hub_screen.dart';
import '../pregnancy_loss/pregnancy_loss_navigation.dart';
import '../pregnancy_loss/pregnancy_loss_service.dart';
import 'emotional_support_service.dart';

/// Full-screen emotional support check-in (selection step).
class EmotionalSupportCheckInScreen extends StatefulWidget {
  const EmotionalSupportCheckInScreen({super.key});

  @override
  State<EmotionalSupportCheckInScreen> createState() =>
      _EmotionalSupportCheckInScreenState();
}

class _EmotionalSupportCheckInScreenState
    extends State<EmotionalSupportCheckInScreen> {
  final Set<String> _selected = {};
  final TextEditingController _otherController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _trackOpened();
  }

  Future<void> _trackOpened() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    UserProfile? profile;
    if (uid != null) {
      profile = await DatabaseService().getUserProfile(uid);
    }
    await EmotionalSupportService.instance.logOpened(profile: profile);
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
        EmotionalSupportService.instance.logOptionSelected(optionId: id);
      }
    });
  }

  Future<void> _onContinue() async {
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserProfile? profile;
      if (uid != null) {
        profile = await DatabaseService().getUserProfile(uid);
      }

      final selectedIds = _selected.toList();
      final somethingElse = _selected.contains(EmotionalSupportOptionId.somethingElse)
          ? _otherController.text
          : null;

      if (_selected.contains(EmotionalSupportOptionId.pregnancyLoss)) {
        if (!mounted) return;
        final entered = await enterPregnancyLossAndShowHome(
          context,
          selectedOptionIds: selectedIds,
          somethingElseText: somethingElse,
        );
        if (entered) {
          // After navigation — avoid getIdToken(true) before pop (was flashing login).
          unawaited(
            EmotionalSupportService.instance.logPregnancyLossFlowStarted(
              profile: profile,
            ),
          );
          unawaited(
            EmotionalSupportService.instance.logCompleted(
              optionIds: selectedIds,
              profile: profile,
            ),
          );
          unawaited(PregnancyLossService.instance.logFlowStarted());
        }
        return;
      }

      await EmotionalSupportService.instance.saveCheckIn(
        selectedOptionIds: selectedIds,
        somethingElseText: somethingElse,
      );
      await EmotionalSupportService.instance.logCompleted(
        optionIds: selectedIds,
        profile: profile,
      );

      if (!mounted) return;

      if (_selected.isEmpty) {
        Navigator.pop(context);
        return;
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => EmotionalSupportEmergencyHubScreen(
            selectedOptionIds: Set<String>.from(_selected),
            somethingElseText: _otherController.text.trim().isEmpty
                ? null
                : _otherController.text.trim(),
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSkip() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final showOther =
        _selected.contains(EmotionalSupportOptionId.somethingElse);

    return FeatureSessionScope(
      feature: 'emotional-support',
      entrySource: 'checkin_selection',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWarm,
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
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderLight.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: AppTheme.brandPurple.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Private check-in',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'How have things been feeling lately?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You can choose anything that feels true today. This is a private check-in to help us show support that fits what you need right now.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...kEmotionalSupportCheckInOptions.map((opt) {
                        final selected = _selected.contains(opt.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggle(opt.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: selected
                                      ? const LinearGradient(
                                          colors: [
                                            AppTheme.brandPurple,
                                            Color(0xFF7744AA),
                                          ],
                                        )
                                      : null,
                                  color: selected
                                      ? null
                                      : AppTheme.surfaceCard,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.transparent
                                        : AppTheme.borderLight
                                            .withValues(alpha: 0.45),
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.brandPurple
                                                .withValues(alpha: 0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : AppTheme.shadowSoft(
                                          opacity: 0.06,
                                          blur: 16,
                                          y: 4,
                                        ),
                                ),
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    fontWeight: FontWeight.w300,
                                    color: selected
                                        ? AppTheme.brandWhite
                                        : AppTheme.textPrimary,
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
                            hintText: 'Optional — share in your own words',
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w300,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.borderLight.withValues(alpha: 0.5),
                              ),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _onSkip,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Skip'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _onContinue,
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
                      ],
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
