import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../models/user_profile.dart';
import '../../research/research_codes.dart';
import '../../widgets/step_scroll.dart';
import 'insurance_question.dart';
import 'pregnancy_postpartum_question.dart';

enum _BaselinePage {
  age,
  pregnancyPostpartum,
  pregnancyFollowUp,
  insurance,
  insuranceOther,
  supportNavigation,
  advocacy,
}

/// One baseline question per step; [onSubmit] receives the full payload on final submit.
class BaselineResearchForm extends StatefulWidget {
  const BaselineResearchForm({
    super.key,
    required this.profile,
    required this.recruitmentPathway,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final UserProfile profile;
  final int recruitmentPathway;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final bool isSubmitting;

  @override
  State<BaselineResearchForm> createState() => _BaselineResearchFormState();
}

class _BaselineResearchFormState extends State<BaselineResearchForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _gestController;
  late final TextEditingController _ppMonthController;
  late final TextEditingController _insuranceOtherController;
  final StepScrollController _scrollController = StepScrollController();

  _BaselinePage _page = _BaselinePage.age;
  int? _pp;
  int? _insuranceType;
  int? _supportNav;
  int? _advocacy;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '${widget.profile.age}');
    _gestController = TextEditingController(
      text: _suggestedGestWeek(widget.profile),
    );
    _ppMonthController = TextEditingController(
      text: widget.profile.childAgeMonths?.toString() ?? '',
    );
    _insuranceOtherController = TextEditingController();
    _pp = widget.profile.isPregnant
        ? 1
        : widget.profile.isPostpartum
            ? 2
            : null;
    _insuranceType = insuranceTypeCodeFromProfileLabel(widget.profile.insuranceType);
    if (_insuranceType != 5) {
      _insuranceOtherController.text = '';
    }
  }

  String _suggestedGestWeek(UserProfile p) {
    if (!p.isPregnant || p.dueDate == null) return '';
    final daysUntilDue = p.dueDate!.difference(DateTime.now()).inDays;
    final g = 40 - (daysUntilDue / 7).floor();
    if (g < 4 || g > 42) return '';
    return '$g';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _gestController.dispose();
    _ppMonthController.dispose();
    _insuranceOtherController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _BaselinePage? _nextPage(_BaselinePage current) {
    switch (current) {
      case _BaselinePage.age:
        return _BaselinePage.pregnancyPostpartum;
      case _BaselinePage.pregnancyPostpartum:
        return _BaselinePage.pregnancyFollowUp;
      case _BaselinePage.pregnancyFollowUp:
        return _BaselinePage.insurance;
      case _BaselinePage.insurance:
        return _insuranceType == 5
            ? _BaselinePage.insuranceOther
            : _BaselinePage.supportNavigation;
      case _BaselinePage.insuranceOther:
        return _BaselinePage.supportNavigation;
      case _BaselinePage.supportNavigation:
        return _BaselinePage.advocacy;
      case _BaselinePage.advocacy:
        return null;
    }
  }

  _BaselinePage? _previousPage(_BaselinePage current) {
    switch (current) {
      case _BaselinePage.age:
        return null;
      case _BaselinePage.pregnancyPostpartum:
        return _BaselinePage.age;
      case _BaselinePage.pregnancyFollowUp:
        return _BaselinePage.pregnancyPostpartum;
      case _BaselinePage.insurance:
        return _BaselinePage.pregnancyFollowUp;
      case _BaselinePage.insuranceOther:
        return _BaselinePage.insurance;
      case _BaselinePage.supportNavigation:
        return _insuranceType == 5
            ? _BaselinePage.insuranceOther
            : _BaselinePage.insurance;
      case _BaselinePage.advocacy:
        return _BaselinePage.supportNavigation;
    }
  }

  int _stepOrdinal() {
    int n = 1;
    for (var p = _BaselinePage.age; p != _page; p = _nextPage(p)!) {
      n++;
    }
    return n;
  }

  int _stepTotal() {
    int n = 1;
    for (var p = _BaselinePage.age; _nextPage(p) != null; p = _nextPage(p)!) {
      n++;
    }
    return n;
  }

  bool _validateCurrentPage() {
    switch (_page) {
      case _BaselinePage.age:
        final n = int.tryParse(_ageController.text.trim());
        if (n == null || n < 13 || n > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid age (13–100)')),
          );
          return false;
        }
        return true;
      case _BaselinePage.pregnancyPostpartum:
        if (_pp == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select pregnancy or postpartum')),
          );
          return false;
        }
        return true;
      case _BaselinePage.pregnancyFollowUp:
        if (_pp == 1) {
          final g = int.tryParse(_gestController.text.trim());
          if (g == null || g < 4 || g > 42) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter gestational week (4–42)')),
            );
            return false;
          }
        } else if (_pp == 2) {
          final m = int.tryParse(_ppMonthController.text.trim());
          if (m == null || m < 0 || m > 48) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter months since delivery (0–48)')),
            );
            return false;
          }
        }
        return true;
      case _BaselinePage.insurance:
        if (_insuranceType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select insurance type')),
          );
          return false;
        }
        return true;
      case _BaselinePage.insuranceOther:
        if (_insuranceOtherController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Describe other insurance')),
          );
          return false;
        }
        return true;
      case _BaselinePage.supportNavigation:
        if (_supportNav == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select an option')),
          );
          return false;
        }
        return true;
      case _BaselinePage.advocacy:
        if (_advocacy == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select confidence (1–5)')),
          );
          return false;
        }
        return true;
    }
  }

  Future<void> _goNext() async {
    if (!_validateCurrentPage()) return;
    final next = _nextPage(_page);
    if (next == null) {
      await _submitAll();
      return;
    }
    setState(() => _page = next);
  }

  void _goBack() {
    final prev = _previousPage(_page);
    if (prev == null) return;
    setState(() => _page = prev);
  }

  Future<void> _submitAll() async {
    final age = int.parse(_ageController.text.trim());
    final payload = <String, dynamic>{
      'recruitment_pathway': widget.recruitmentPathway,
      'age_years': age,
      'pp_status': _pp,
      'insurance_type': _insuranceType,
      'support_person_nav': _supportNav,
      'baseline_advocacy_conf': _advocacy,
    };
    if (_pp == 1) {
      payload['gest_week'] = int.parse(_gestController.text.trim());
    }
    if (_pp == 2) {
      payload['postpartum_month'] = int.parse(_ppMonthController.text.trim());
    }
    if (_insuranceType == 5) {
      payload['insurance_other'] = _insuranceOtherController.text.trim();
    }
    await widget.onSubmit(payload);
  }

  // Hearth puts field labels above the field rather than inside it.
  Widget _labelled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildPageBody() {
    final textTheme = Theme.of(context).textTheme;
    const dropdownIcon = Icon(Icons.expand_more, color: AppTheme.brandPurple);
    switch (_page) {
      case _BaselinePage.age:
        return _labelled(
          'What is your age (in years)?',
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              helperText: 'Research baseline: numbers only',
            ),
          ),
        );
      case _BaselinePage.pregnancyPostpartum:
        return PregnancyPostpartumQuestion(
          ppStatus: _pp,
          onPpChanged: (v) => setState(() {
            _pp = v;
            if (v != 1) _gestController.clear();
            if (v != 2) _ppMonthController.clear();
          }),
        );
      case _BaselinePage.pregnancyFollowUp:
        if (_pp == 1) {
          return _labelled(
            'How many weeks pregnant are you? (4–42)',
            TextFormField(
              controller: _gestController,
              keyboardType: TextInputType.number,
            ),
          );
        }
        if (_pp == 2) {
          return _labelled(
            'How many months since delivery? (0–48)',
            TextFormField(
              controller: _ppMonthController,
              keyboardType: TextInputType.number,
            ),
          );
        }
        return Text(
          'Go back and select pregnancy or postpartum.',
          style: textTheme.bodyLarge,
        );
      case _BaselinePage.insurance:
        return InsuranceQuestion(
          insuranceType: _insuranceType,
          onInsuranceChanged: (v) => setState(() {
            _insuranceType = v;
            if (v != 5) _insuranceOtherController.clear();
          }),
          otherController: _insuranceOtherController,
          showOtherField: false,
        );
      case _BaselinePage.insuranceOther:
        return _labelled(
          'Describe your insurance (other)',
          TextFormField(
            controller: _insuranceOtherController,
            decoration: const InputDecoration(
              helperText: 'Do not include names or email addresses',
            ),
            maxLength: 500,
            maxLines: 3,
          ),
        );
      case _BaselinePage.supportNavigation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support person / navigation',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Were you able to navigate care with a support person?',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Your answer', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _supportNav,
              icon: dropdownIcon,
              decoration: const InputDecoration(),
              selectedItemBuilder: (context) {
                return kSupportPersonNavOptions.map((e) {
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      e.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: kSupportPersonNavOptions
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _supportNav = v),
            ),
          ],
        );
      case _BaselinePage.advocacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advocacy confidence',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'How confident do you feel advocating for yourself? (1 = low, 5 = high)',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Rating', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _advocacy,
              icon: dropdownIcon,
              decoration: const InputDecoration(),
              items: List.generate(
                5,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (v) => setState(() => _advocacy = v),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _nextPage(_page) == null;
    final canBack = _previousPage(_page) != null;
    // Each question starts at the top of the scroll area.
    _scrollController.syncStep(_page);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Baseline · Question ${_stepOrdinal()} of ${_stepTotal()}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  color: AppTheme.brandPurple,
                ),
          ),
          const SizedBox(height: 12),
          HearthStepProgress(step: _stepOrdinal(), total: _stepTotal()),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPageBody(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (canBack)
                Expanded(
                  child: HearthButton.secondary(
                    label: 'Back',
                    onPressed: widget.isSubmitting ? null : _goBack,
                  ),
                ),
              if (canBack) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: HearthButton.primary(
                  label: isLast ? 'Submit research baseline' : 'Next',
                  loading: widget.isSubmitting,
                  onPressed: widget.isSubmitting
                      ? null
                      : () async {
                          await _goNext();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
