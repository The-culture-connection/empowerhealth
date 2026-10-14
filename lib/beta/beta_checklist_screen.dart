import 'dart:async';

import 'package:flutter/material.dart';

import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import 'beta_checklist_service.dart';

/// What beta testers should try, with today's 10-minute goal.
class BetaChecklistScreen extends StatefulWidget {
  const BetaChecklistScreen({super.key});

  @override
  State<BetaChecklistScreen> createState() => _BetaChecklistScreenState();
}

class _BetaChecklistScreenState extends State<BetaChecklistScreen> {
  final BetaChecklistService _service = BetaChecklistService.instance;

  @override
  void initState() {
    super.initState();
    // Pick up progress made on another device since the app started.
    unawaited(_service.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) {
            final items = _service.items;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const HearthPushedHeader(
                  title: 'Beta checklist',
                  subtitle:
                      'Thanks for testing EmpowerHealth Watch. Try each feature and come back every day.',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HearthStepProgress(
                        step: _service.completedCount,
                        total: _service.totalItems,
                        label:
                            '${_service.completedCount} of ${_service.totalItems} features tried',
                      ),
                      const SizedBox(height: 20),
                      _DailyGoalCard(
                        minutes: _service.todayMinutes,
                        goalMet: _service.todayGoalMet,
                        daysGoalMet: _service.daysGoalMet,
                      ),
                      const SizedBox(height: 28),
                      const HearthSectionHeading('Features to try'),
                      const SizedBox(height: 14),
                      for (final entry in items) ...[
                        _ChecklistRow(item: entry.item, done: entry.done),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.minutes,
    required this.goalMet,
    required this.daysGoalMet,
  });

  final int minutes;
  final bool goalMet;
  final int daysGoalMet;

  @override
  Widget build(BuildContext context) {
    const goalMinutes = kBetaDailyGoalSeconds ~/ 60;
    final shown = minutes > goalMinutes ? goalMinutes : minutes;
    return HearthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckCircle(done: goalMet),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Use the app for 10 minutes today',
                  style: hearthCardTitleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          HearthStepProgress(
            step: shown,
            total: goalMinutes,
            label: '$shown of $goalMinutes minutes today',
          ),
          const SizedBox(height: 12),
          Text(
            'Days you hit 10 minutes: $daysGoalMet',
            style: hearthCardBodyStyle,
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.done});

  final BetaChecklistItem item;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: () => item.open(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CheckCircle(done: done),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: hearthCardTitleStyle),
                const SizedBox(height: 2),
                Text(item.subtitle, style: hearthCaptionStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppTheme.brandPurple,
          ),
        ],
      ),
    );
  }
}

/// 22px check: filled purple when done, outlined when not.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: done ? 'Done' : 'Not done yet',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: done ? AppTheme.brandPurple : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? AppTheme.brandPurple : AppTheme.textMuted,
            width: 2,
          ),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: AppTheme.onPurple)
            : null,
      ),
    );
  }
}
