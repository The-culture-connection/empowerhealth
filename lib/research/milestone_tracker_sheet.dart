import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Milestone check-ins',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Short research check-ins along your pregnancy or postpartum journey. '
              'Each row shows where you are and what is already completed.',
              style: TextStyle(fontSize: 14, height: 1.45, color: AppTheme.textMuted, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 20),
            if (steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No milestone windows are listed yet. Complete your research onboarding and baseline '
                  'so we can match check-ins to your journey.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.45),
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
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.brandPurple.withValues(alpha: 0.35)
                              : AppTheme.borderLight.withValues(alpha: 0.5),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            completed ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: completed ? const Color(0xFF23C0C2) : AppTheme.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandPurple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Current window',
                                          style: TextStyle(fontSize: 11, color: AppTheme.brandPurple, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                  ],
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.35),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  completed ? 'Completed' : 'Not completed yet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: completed ? const Color(0xFF23C0C2) : AppTheme.textMuted,
                                    fontWeight: FontWeight.w400,
                                  ),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: AppTheme.brandWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start check-in'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
