import 'package:flutter/material.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../models/user_profile.dart';
import '../../research/research_codes.dart';
import '../../services/database_service.dart';
import '../../services/research/research_identity_service.dart';
import '../../privacy/consent_screen.dart';
import 'baseline_research_form.dart';
import 'recruitment_pathway_question.dart';
import 'recruitment_source_question.dart';

/// Phase 1: server-issued [study_id], [research_participants], then baseline callable.
class ResearchOnboardingScreen extends StatefulWidget {
  const ResearchOnboardingScreen({
    super.key,
    required this.profile,
    required this.userId,
  });

  final UserProfile profile;
  final String userId;

  @override
  State<ResearchOnboardingScreen> createState() => _ResearchOnboardingScreenState();
}

class _ResearchOnboardingScreenState extends State<ResearchOnboardingScreen> {
  final _recruitOther = TextEditingController();
  final _identity = ResearchIdentityService.instance;
  final _db = DatabaseService();

  int _step = 0;
  bool _busy = false;
  String? _error;
  bool _pathwaysLoading = true;
  List<MapEntry<int, String>> _pathwayOptions = [];

  late int? _recruitmentSource;
  int? _recruitmentPathway;

  @override
  void initState() {
    super.initState();
    _recruitmentSource = recruitmentSourceCode(widget.profile.recruitmentSource);
    _loadPathways();
  }

  Future<void> _loadPathways() async {
    setState(() => _pathwaysLoading = true);
    try {
      final list = await _identity.listRecruitmentPathways();
      if (!mounted) return;
      setState(() {
        _pathwayOptions = list;
        _pathwaysLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pathwayOptions = List<MapEntry<int, String>>.from(kDefaultRecruitmentPathways);
        _pathwaysLoading = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _recruitOther.dispose();
    super.dispose();
  }

  Future<void> _completeEnrollmentStep() async {
    if (_recruitmentSource == null) {
      setState(() => _error = 'Select how you heard about the study');
      return;
    }
    if (_recruitmentSource == 6 && _recruitOther.text.trim().isEmpty) {
      setState(() => _error = 'Please describe "Other" recruitment source');
      return;
    }
    if (_recruitmentPathway == null) {
      setState(() => _error = 'Select your recruitment pathway');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _identity.createResearchParticipant(
        recruitmentSource: _recruitmentSource!,
        recruitmentSourceOtherText:
            _recruitmentSource == 6 ? _recruitOther.text.trim() : null,
        recruitmentPathway: _recruitmentPathway!,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitBaseline(Map<String, dynamic> payload) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final check = await _identity.validateResearchBaseline(payload);
      final ok = check['ok'] == true;
      if (!ok) {
        final errs = check['errors'];
        throw Exception(errs is List ? errs.join(', ') : 'Validation failed');
      }
      await _identity.submitBaselineResearchData(payload);
      if (!mounted) return;
      final hasConsent = await _db.userHasConsent(widget.userId);
      if (!mounted) return;
      if (hasConsent) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const ConsentScreen(isFirstRun: true),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stepLabel = _step == 0 ? 'Step 1 of 2: About you' : 'Step 2 of 2: Baseline survey';
    // Errors are not emergencies, so they read as a cream note rather than red text.
    Widget errorNote(EdgeInsetsGeometry padding) => Padding(
          padding: padding,
          child: HearthNote(text: _error!),
        );
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HearthPushedHeader(
              title: 'Research enrollment',
              // Matches the AppBar it replaces: back only when there is a route to return to.
              showBack: ModalRoute.of(context)?.impliesAppBarDismissal ?? false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The baseline form draws its own bar, so step 2 shows only the caption.
                    if (_step == 0)
                      HearthStepProgress(step: 1, total: 2, label: stepLabel)
                    else
                      Text(stepLabel, style: hearthCaptionStyle),
                    const SizedBox(height: 12),
                    if (_step == 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Thank you for joining the research cohort. We will store a study ID and '
                        'baseline survey answers without your name or email in the research dataset.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RecruitmentSourceQuestion(
                                value: _recruitmentSource,
                                onChanged: (v) => setState(() => _recruitmentSource = v),
                                otherController: _recruitOther,
                              ),
                              const SizedBox(height: 24),
                              const Divider(color: AppTheme.borderWarm, height: 1),
                              const SizedBox(height: 24),
                              RecruitmentPathwayQuestion(
                                value: _recruitmentPathway,
                                onChanged: (v) => setState(() => _recruitmentPathway = v),
                                pathways: _pathwayOptions,
                                loading: _pathwaysLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) errorNote(const EdgeInsets.only(bottom: 12)),
                      HearthButton.primary(
                        label: 'Continue to baseline',
                        loading: _busy,
                        onPressed: _busy || _pathwaysLoading ? null : _completeEnrollmentStep,
                      ),
                    ] else ...[
                      Expanded(
                        child: BaselineResearchForm(
                          profile: widget.profile,
                          recruitmentPathway: _recruitmentPathway!,
                          isSubmitting: _busy,
                          onSubmit: _submitBaseline,
                        ),
                      ),
                      if (_error != null) errorNote(const EdgeInsets.only(top: 12)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
