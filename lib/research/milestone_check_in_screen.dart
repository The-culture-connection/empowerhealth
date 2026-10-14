import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/research/research_milestone_service.dart';

/// Full-screen milestone check-in (three Yes/No items) for research participants.
class MilestoneCheckInScreen extends StatefulWidget {
  const MilestoneCheckInScreen({
    super.key,
    required this.studyId,
    required this.milestoneType,
    this.title = 'Milestone check-in',
    this.subtitle,
  });

  final String studyId;
  final int milestoneType;
  final String title;
  final String? subtitle;

  @override
  State<MilestoneCheckInScreen> createState() => _MilestoneCheckInScreenState();
}

class _MilestoneCheckInScreenState extends State<MilestoneCheckInScreen> {
  bool? _healthQuestion;
  bool? _clearNext;
  bool? _appHelped;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_healthQuestion == null || _clearNext == null || _appHelped == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all three questions.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ResearchMilestoneService.instance.submitMilestoneCheckIn(
        studyId: widget.studyId,
        milestoneType: widget.milestoneType,
        milestoneHealthQuestion: _healthQuestion!,
        milestoneClearNextStep: _clearNext!,
        milestoneAppHelpedNextStep: _appHelped!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Yes / No pill in the selected-chip style, label centred.
  Widget _choice(String label, bool selected, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: selected ? AppTheme.tintWarm : AppTheme.surface,
        foregroundColor: selected ? AppTheme.brandPurple : AppTheme.textSecondary,
        side: selected
            ? const BorderSide(color: AppTheme.brandPurple, width: 2)
            : const BorderSide(color: AppTheme.borderWarm),
        textStyle: TextStyle(
          fontFamily: AppTheme.sansFamily,
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _row(String label, bool? value, void Function(bool) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 15,
              height: 22 / 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _choice(
                  'Yes',
                  value == true,
                  _submitting ? null : () => setState(() => onPick(true)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _choice(
                  'No',
                  value == false,
                  _submitting ? null : () => setState(() => onPick(false)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HearthPushedHeader(
                backLabel: 'Check-in',
                title: widget.title,
                subtitle: widget.subtitle,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      'Did you have a health-related question you wanted to ask a care team?',
                      _healthQuestion,
                      (v) => _healthQuestion = v,
                    ),
                    _row(
                      'Did you feel clear on what your next step in care should be?',
                      _clearNext,
                      (v) => _clearNext = v,
                    ),
                    _row(
                      'Did this app help you figure out or take a next step?',
                      _appHelped,
                      (v) => _appHelped = v,
                    ),
                    HearthButton.primary(
                      label: 'Submit',
                      loading: _submitting,
                      onPressed: _submit,
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
