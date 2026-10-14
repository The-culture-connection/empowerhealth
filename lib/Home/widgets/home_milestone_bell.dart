import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../models/user_profile.dart';
import '../../research/milestone_tracker_sheet.dart';
import '../../services/research/research_firestore_service.dart';
import '../../services/research/research_milestone_service.dart';

/// Bell on the home header: opens milestone tracker; purple dot when [badge_dot] from the server.
///
/// The bell stays visible for research participants even if the tracker call fails (wrong region,
/// missing `studyId`, etc.) so the user can open a help sheet and retry.
class HomeMilestoneBell extends StatefulWidget {
  const HomeMilestoneBell({super.key, required this.profile});

  final UserProfile? profile;

  @override
  State<HomeMilestoneBell> createState() => _HomeMilestoneBellState();
}

class _HomeMilestoneBellState extends State<HomeMilestoneBell> {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  String? _studyId;
  String? _helpMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(HomeMilestoneBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile?.userId != widget.profile?.userId ||
        oldWidget.profile?.isResearchParticipant != widget.profile?.isResearchParticipant) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final p = widget.profile;
    if (p == null || !p.isResearchParticipant) {
      if (mounted) {
        setState(() {
          _loading = false;
          _summary = null;
          _studyId = null;
          _helpMessage = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _helpMessage = null;
      });
    }
    try {
      final sid = await ResearchFirestoreService.instance.ensureStudyId(p);
      final data = await ResearchMilestoneService.instance.getMilestoneTrackerSummary(
        studyId: sid,
      );
      if (!mounted) return;

      if (data['ok'] == true) {
        setState(() {
          _loading = false;
          _summary = Map<String, dynamic>.from(data);
          _studyId = data['study_id'] is String ? data['study_id'] as String : sid;
          _helpMessage = null;
        });
        return;
      }

      if (data['not_enrolled'] == true) {
        setState(() {
          _loading = false;
          _summary = null;
          _studyId = null;
          _helpMessage =
              'Your account is not fully linked for research yet. Finish research onboarding and '
              'make sure your profile shows you are a research participant so a study ID can be assigned.';
        });
        return;
      }

      setState(() {
        _loading = false;
        _summary = null;
        _studyId = sid;
        _helpMessage = 'Milestone tracker could not be loaded. Pull to refresh your profile or try again.';
      });
    } catch (e, st) {
      debugPrint('HomeMilestoneBell: getMilestoneTrackerSummary failed: $e\n$st');
      if (e is FirebaseFunctionsException) {
        debugPrint('HomeMilestoneBell: functions code=${e.code} message=${e.message}');
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _summary = null;
        _studyId = null;
        _helpMessage = e is FirebaseFunctionsException
            ? 'Could not reach research services (${e.code}). Check your connection and that the app '
                'is using the same Firebase project as your deployed functions (region us-central1).'
            : 'Could not load milestones. Please try again.';
      });
    }
  }

  bool get _showDot => _summary != null && _summary!['badge_dot'] == true;

  Future<void> _openTracker() async {
    if (_summary != null && (_studyId != null || _summary!['study_id'] is String)) {
      final sid = _studyId ?? _summary!['study_id'] as String;
      final nav = Navigator.of(context);
      final h = MediaQuery.sizeOf(context).height;
      // Fill and corner radius come from the Hearth bottom-sheet theme.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
            child: SizedBox(
              height: h * 0.78,
              child: MilestoneTrackerSheet(
                navigator: nav,
                summary: _summary!,
                studyId: sid,
                onRefresh: _load,
              ),
            ),
          );
        },
      );
      await _load();
      return;
    }

    if (!mounted) return;
    await showHearthSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestone check-ins',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              _helpMessage ??
                  'Complete research onboarding in your profile so we can assign a study ID and '
                  'show your milestone journey here.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                  child: const Text('Close'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(_load());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null || widget.profile!.isResearchParticipant != true) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 22,
              color: AppTheme.brandPurple.withValues(alpha: 0.35),
            ),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandPurple),
            ),
          ],
        ),
      );
    }

    // 44 surface circle; the dot sits on the bell's shoulder with a surface ring.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        HearthCircleButton(
          icon: Icons.notifications_none,
          iconSize: 22,
          iconColor: AppTheme.brandPurple,
          onPressed: _openTracker,
        ),
        if (_showDot)
          Positioned(
            right: 8,
            top: 7,
            child: IgnorePointer(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
