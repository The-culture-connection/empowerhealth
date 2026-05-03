import 'dart:async';

import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../models/user_profile.dart';
import '../../research/milestone_tracker_sheet.dart';
import '../../services/research/research_firestore_service.dart';
import '../../services/research/research_milestone_service.dart';

/// Bell on the home header: opens milestone tracker; purple dot when a new check-in is available.
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
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final sid = await ResearchFirestoreService.instance.ensureStudyId(p);
      if (sid == null || !mounted) {
        if (mounted) {
          setState(() {
            _loading = false;
            _summary = null;
            _studyId = null;
          });
        }
        return;
      }
      final data = await ResearchMilestoneService.instance.getMilestoneTrackerSummary(studyId: sid);
      if (!mounted) return;
      if (data['ok'] == true) {
        setState(() {
          _loading = false;
          _summary = Map<String, dynamic>.from(data);
          _studyId = sid;
        });
      } else {
        setState(() {
          _loading = false;
          _summary = null;
          _studyId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _summary = null;
          _studyId = null;
        });
      }
    }
  }

  bool get _showDot => _summary != null && _summary!['badge_dot'] == true;

  Future<void> _openTracker() async {
    if (_summary == null || _studyId == null) return;
    final nav = Navigator.of(context);
    final h = MediaQuery.sizeOf(context).height;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
          child: SizedBox(
            height: h * 0.78,
            child: MilestoneTrackerSheet(
              navigator: nav,
              summary: _summary!,
              studyId: _studyId!,
              onRefresh: _load,
            ),
          ),
        );
      },
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null || widget.profile!.isResearchParticipant != true) {
      return const SizedBox.shrink();
    }
    if (_loading && _summary == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandPurple),
        ),
      );
    }
    if (_summary == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openTracker,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 28,
                color: AppTheme.brandPurple,
              ),
              if (_showDot)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.brandPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
