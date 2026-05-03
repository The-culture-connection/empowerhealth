import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
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
        const SnackBar(content: Text('Please answer all three questions.'), backgroundColor: Colors.orange),
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
          SnackBar(content: Text('Could not save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _row(String label, bool? value, void Function(bool) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.35)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => onPick(true)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: value == true ? AppTheme.brandPurple.withValues(alpha: 0.12) : null,
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5)),
                  ),
                  child: const Text('Yes'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => onPick(false)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: value == false ? AppTheme.brandPurple.withValues(alpha: 0.12) : null,
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5)),
                  ),
                  child: const Text('No'),
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
      backgroundColor: AppTheme.backgroundWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWarm,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Check-in'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w400, color: AppTheme.textPrimary)),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(widget.subtitle!, style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.45)),
              ],
              const SizedBox(height: 28),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: AppTheme.brandWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandWhite),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
