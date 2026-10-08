import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../models/user_profile.dart';
import '../../support_stage/support_stage.dart';
import '../pregnancy_loss_navigation.dart';
import '../pregnancy_loss_service.dart';

/// Profile setting to change [UserProfile.currentSupportStage].
class SupportStageSettingsTile extends StatelessWidget {
  const SupportStageSettingsTile({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _showPicker(BuildContext context) async {
    final choice = await showHearthSheet<String>(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update my current support stage',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your app experience will update based on what feels most relevant now.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _option(ctx, SupportStage.pregnant, 'I am currently pregnant'),
              _option(ctx, SupportStage.postpartum, 'I recently had my baby'),
              _option(
                ctx,
                SupportStage.pregnancyLoss,
                'I experienced a pregnancy loss',
              ),
              _option(
                ctx,
                SupportStage.preferNotToAnswer,
                'I prefer not to answer',
              ),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;
    if (choice == profile.currentSupportStage) return;

    if (choice == SupportStage.pregnancyLoss &&
        profile.currentSupportStage != SupportStage.pregnancyLoss) {
      await startPregnancyLossFlowFromProfile(context);
      return;
    }

    if (profile.isInPregnancyLossMode &&
        choice != SupportStage.pregnancyLoss) {
      final confirm = await showHearthDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update your support experience?'),
          content: const Text(
            'Your app experience will update based on what feels most relevant now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
    }

    await PregnancyLossService.instance.updateSupportStage(choice);
    if (!context.mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your support experience was updated.')),
      );
    }
  }

  Widget _option(BuildContext ctx, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HearthCard(
        radius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onTap: () => Navigator.pop(ctx, value),
        child: Text(
          label,
          style: Theme.of(ctx)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.ink),
        ),
      ),
    );
  }

  String _stageLabel(String? stage) {
    switch (stage) {
      case SupportStage.pregnant:
        return 'Currently pregnant';
      case SupportStage.postpartum:
        return 'Recently had baby';
      case SupportStage.pregnancyLoss:
        return 'After pregnancy loss';
      case SupportStage.preferNotToAnswer:
        return 'Prefer not to answer';
      default:
        return 'Not set';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      color: AppTheme.ground,
      radius: BorderRadius.circular(AppTheme.fieldRadius),
      padding: const EdgeInsets.all(12),
      onTap: () => _showPicker(context),
      child: Row(
        children: [
          const HearthIconChip(Icons.favorite_outline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update my current support stage',
                  style: hearthCardTitleStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  _stageLabel(profile.currentSupportStage),
                  style: hearthCaptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
