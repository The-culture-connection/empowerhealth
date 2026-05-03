import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../models/user_profile.dart';
import '../services/research/research_firestore_service.dart';
import '../services/research/research_milestone_service.dart';
import 'milestone_check_in_screen.dart';

/// Lightweight prompt: calls [scheduleMilestonePrompt], then offers navigation to [MilestoneCheckInScreen].
class MilestonePromptModal {
  MilestonePromptModal._();

  /// Shows a dialog when the server reports `should_prompt` for this participant.
  static Future<void> showIfEligible(BuildContext context, UserProfile profile) async {
    if (!profile.isResearchParticipant) return;
    final sid = await ResearchFirestoreService.instance.ensureStudyId(profile);
    if (sid == null || !context.mounted) return;

    Map<String, dynamic> schedule;
    try {
      schedule = await ResearchMilestoneService.instance.scheduleMilestonePrompt(studyId: sid);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    if (schedule['should_prompt'] != true) return;
    final mt = schedule['milestone_type'];
    final int? milestoneType =
        mt is int ? mt : mt is num ? mt.toInt() : int.tryParse('$mt');
    if (milestoneType == null) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text('Time for a quick check-in', style: TextStyle(color: AppTheme.textPrimary)),
          content: Text(
            'We have a few short questions about your care journey right now. '
            'Your answers help the study team see how support is landing over time.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Not now', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MilestoneCheckInScreen(
                      studyId: sid,
                      milestoneType: milestoneType,
                      title: 'Milestone check-in',
                      subtitle: 'Three yes or no questions — there are no wrong answers.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: AppTheme.brandWhite,
              ),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
}
