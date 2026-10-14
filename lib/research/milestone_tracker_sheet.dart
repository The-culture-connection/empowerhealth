import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'milestone_check_in_screen.dart';

/// Bottom sheet: milestone journey checklist for research participants.
class MilestoneTrackerSheet extends StatelessWidget {
  const MilestoneTrackerSheet({
    super.key,
    required this.navigator,
    required this.summary,
    required this.studyId,
    required this.onRefresh,
  });

  /// Host navigator (e.g. home tab) — used so [push] works after the sheet [pop] disposes this subtree.
  final NavigatorState navigator;
  final Map<String, dynamic> summary;
  final String studyId;
  final Future<void> Function() onRefresh;

  int? get _eligible {
    final e = summary['eligible_milestone_type'];
    if (e is int) return e;
    if (e is num) return e.toInt();
    return null;
  }

  bool get _hasPending {
    final e = _eligible;
    if (e == null) return false;
    return summary['badge_dot'] == true;
  }

  List<Map<String, dynamic>> _steps() {
    final raw = summary['journey_steps'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    final eligible = _eligible;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: HearthSheetHandle()),
            const SizedBox(height: 20),
            Text(
              'Milestone check-ins',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Short research check-ins along your pregnancy or postpartum journey. '
              'Each row shows where you are and what is already completed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No milestone windows are listed yet. Complete your research onboarding and baseline '
                  'so we can match check-ins to your journey.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = steps[i];
                    final completed = s['completed'] == true;
                    final isCurrent = s['is_current'] == true;
                    final title = '${s['title'] ?? 'Check-in'}';
                    final subtitle = '${s['subtitle'] ?? ''}';
                    // The current window gets the selected outline; done rows a purple check.
                    return HearthCard(
                      padding: EdgeInsets.all(isCurrent ? 15 : 16),
                      borderColor: isCurrent ? AppTheme.brandPurple : AppTheme.borderWarm,
                      borderWidth: isCurrent ? 2 : 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                            color: completed ? AppTheme.brandPurple : AppTheme.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(title, style: hearthCardTitleStyle),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      const HearthTag('Current window'),
                                    ],
                                  ],
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(subtitle, style: hearthCaptionStyle),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  completed ? 'Completed' : 'Not completed yet',
                                  style: completed
                                      ? hearthCaptionStyle.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.brandPurple,
                                        )
                                      : hearthCaptionStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (_hasPending && eligible != null) ...[
              const SizedBox(height: 20),
              HearthButton.primary(
                label: 'Start check-in',
                onPressed: () async {
                  navigator.pop();
                  await navigator.push<bool>(
                    MaterialPageRoute(
                      builder: (_) => MilestoneCheckInScreen(
                        studyId: studyId,
                        milestoneType: eligible,
                        title: 'Milestone check-in',
                        subtitle: 'Three yes or no questions for the study team.',
                      ),
                    ),
                  );
                  await onRefresh();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
