import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
import '../design_system/hearth.dart';
import '../services/database_service.dart';
import '../utils/pregnancy_utils.dart';

/// Trimester journey with body changes and baby growth (NewUI-aligned).
class PregnancyJourneyScreen extends StatefulWidget {
  const PregnancyJourneyScreen({super.key});

  @override
  State<PregnancyJourneyScreen> createState() => _PregnancyJourneyScreenState();
}

class _PregnancyJourneyScreenState extends State<PregnancyJourneyScreen> {
  final _databaseService = DatabaseService();
  final _auth = FirebaseAuth.instance;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final profile = await _databaseService.getUserProfile(uid);
      if (mounted) {
        setState(() => _dueDate = profile?.dueDate);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final weeksPregnant = PregnancyUtils.calculateWeeksPregnant(_dueDate);
    final trimester = PregnancyUtils.calculateTrimester(_dueDate);
    final progress = weeksPregnant > 0 ? (weeksPregnant / 40).clamp(0.0, 1.0) : 0.0;
    final remaining = weeksPregnant > 0 ? (40 - weeksPregnant).clamp(0, 40) : 40;

    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 672),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HearthPushedHeader(
                    backLabel: 'Home',
                    onBack: () => Navigator.maybePop(context),
                    titleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (weeksPregnant > 0) ...[
                          _WeekPill(weeksPregnant: weeksPregnant),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          weeksPregnant > 0
                              ? PregnancyUtils.trimesterDisplayTitle(trimester)
                              : 'Your pregnancy journey',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weeksPregnant > 0
                              ? PregnancyUtils.trimesterSupportMessage(trimester)
                              : 'When you add your due date in your profile, we can show trimester details here.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (weeksPregnant > 0) ...[
                          _ProgressHero(
                            progress: progress,
                            weeksPregnant: weeksPregnant,
                            trimester: trimester,
                            weeksRemaining: remaining,
                          ),
                          const SizedBox(height: 20),
                          _BodyCard(trimester: trimester),
                          const SizedBox(height: 20),
                          _BabyCard(trimester: trimester, weeksPregnant: weeksPregnant),
                          const SizedBox(height: 20),
                        ],
                        HearthFeatureCard(
                          padding: const EdgeInsets.all(22),
                          child: Text(
                            'Every pregnancy is unique. If something doesn’t feel right or you have concerns, '
                            'it’s always okay to reach out to your care team.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekPill extends StatelessWidget {
  final int weeksPregnant;

  const _WeekPill({required this.weeksPregnant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const ShapeDecoration(
        color: AppTheme.surface,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.borderWarm)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.brandGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Week $weeksPregnant',
            style: hearthCaptionStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final double progress;
  final int weeksPregnant;
  final String trimester;
  final int weeksRemaining;

  const _ProgressHero({
    required this.progress,
    required this.weeksPregnant,
    required this.trimester,
    required this.weeksRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return HearthFeatureCard(
      tone: HearthTone.purple,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.brandPurpleMid,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandGold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$weeksPregnant of 40 weeks',
            style: hearthCaptionStyle.copyWith(color: AppTheme.onPurpleSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Current trimester',
                  value: trimester == 'First'
                      ? 'First'
                      : trimester == 'Second'
                          ? 'Second'
                          : 'Third',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Weeks remaining',
                  value: '$weeksRemaining weeks',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandPurpleMid,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              color: AppTheme.onPurpleSecondary,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.sansFamily,
              color: AppTheme.onPurple,
              fontSize: 17,
              height: 24 / 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _subheadStyle = TextStyle(
  fontFamily: AppTheme.sansFamily,
  fontSize: 14,
  height: 20 / 14,
  fontWeight: FontWeight.w600,
  color: AppTheme.ink,
);

class _BodyCard extends StatelessWidget {
  final String trimester;

  const _BodyCard({required this.trimester});

  @override
  Widget build(BuildContext context) {
    final feelings = PregnancyUtils.trimesterBodyFeelings(trimester);
    final helps = PregnancyUtils.trimesterBodyHelp(trimester);

    return _SectionCard(
      icon: Icons.person_outline_rounded,
      sectionLabel: 'Your body',
      title: 'Changes this trimester',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What you might be feeling:', style: _subheadStyle),
          const SizedBox(height: 10),
          ...feelings.map((t) => _BulletLine(text: t, dotColor: AppTheme.brandGold)),
          const Divider(height: 28, color: AppTheme.borderWarm),
          const Text('What can help:', style: _subheadStyle),
          const SizedBox(height: 10),
          ...helps.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.favorite_border, size: 18, color: AppTheme.brandPurple),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: hearthCardBodyStyle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BabyCard extends StatelessWidget {
  final String trimester;
  final int weeksPregnant;

  const _BabyCard({required this.trimester, required this.weeksPregnant});

  @override
  Widget build(BuildContext context) {
    final dev = PregnancyUtils.trimesterBabyDevelopment(trimester);
    final hint = PregnancyUtils.trimesterBabySizeHint(trimester, weeksPregnant);

    return _SectionCard(
      icon: Icons.child_care_outlined,
      sectionLabel: 'Your baby',
      title: 'Growth this trimester',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.tintWarm,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.auto_awesome_outlined, size: 20, color: AppTheme.brandPurple),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(hint, style: hearthCardBodyStyle)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('What’s developing:', style: _subheadStyle),
          const SizedBox(height: 10),
          ...dev.map((t) => _BulletLine(text: t, dotColor: AppTheme.brandPurple)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String sectionLabel;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.sectionLabel,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HearthIconChip(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionLabel,
                      style: hearthCaptionStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color dotColor;

  const _BulletLine({required this.text, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RichBoldLine(text: text),
          ),
        ],
      ),
    );
  }
}

/// Parses `**bold** rest` into TextSpan for light reading.
class _RichBoldLine extends StatelessWidget {
  final String text;

  const _RichBoldLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, m.start),
          style: hearthCardBodyStyle,
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: hearthCardBodyStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ));
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: hearthCardBodyStyle,
      ));
    }
    return Text.rich(TextSpan(children: spans));
  }
}
