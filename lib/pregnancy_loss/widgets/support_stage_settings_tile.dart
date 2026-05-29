import 'package:flutter/material.dart';

import '../../cors/ui_theme.dart';
import '../../models/user_profile.dart';
import '../../support_stage/support_stage.dart';
import '../pregnancy_loss_navigation.dart';
import '../pregnancy_loss_service.dart';

/// Profile setting to change [UserProfile.currentSupportStage].
class SupportStageSettingsTile extends StatelessWidget {
  const SupportStageSettingsTile({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _showPicker(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update my current support stage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your app experience will update based on what feels most relevant now.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
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
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text(
            'Update your support experience?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Your app experience will update based on what feels most relevant now.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
              ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: AppTheme.textPrimary,
        ),
      ),
      onTap: () => Navigator.pop(ctx, value),
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
    return ListTile(
      leading: Icon(Icons.favorite_outline, color: AppTheme.brandPurple),
      title: Text(
        'Update my current support stage',
        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        _stageLabel(profile.currentSupportStage),
        style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w300),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: () => _showPicker(context),
    );
  }
}
