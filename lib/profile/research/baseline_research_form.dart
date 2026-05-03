import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../models/user_profile.dart';
import '../../research/research_codes.dart';
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

  Widget _buildPageBody() {
    switch (_page) {
      case _BaselinePage.age:
        return TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'What is your age (in years)?',
            border: OutlineInputBorder(),
            helperText: 'Research baseline — numbers only',
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
          return TextFormField(
            controller: _gestController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'How many weeks pregnant are you? (4–42)',
              border: OutlineInputBorder(),
            ),
          );
        }
        if (_pp == 2) {
          return TextFormField(
            controller: _ppMonthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'How many months since delivery? (0–48)',
              border: OutlineInputBorder(),
            ),
          );
        }
        return const Text('Go back and select pregnancy or postpartum.');
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
        return TextFormField(
          controller: _insuranceOtherController,
          decoration: const InputDecoration(
            labelText: 'Describe your insurance (other)',
            border: OutlineInputBorder(),
            helperText: 'Do not include names or email addresses',
          ),
          maxLength: 500,
          maxLines: 3,
        );
      case _BaselinePage.supportNavigation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support person / navigation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Were you able to navigate care with a support person?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _supportNav,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.brandPurple,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'How confident do you feel advocating for yourself? (1 = low, 5 = high)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _advocacy,
              decoration: const InputDecoration(
                labelText: 'Rating',
                border: OutlineInputBorder(),
              ),
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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Baseline · Question ${_stepOrdinal()} of ${_stepTotal()}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPurple,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPageBody(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (canBack)
                OutlinedButton(
                  onPressed: widget.isSubmitting ? null : _goBack,
                  child: const Text('Back'),
                ),
              if (canBack) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () async {
                          await _goNext();
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.brandPurple,
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLast ? 'Submit research baseline' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
