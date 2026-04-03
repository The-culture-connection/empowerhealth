import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../cors/ui_theme.dart';
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
      backgroundColor: AppTheme.backgroundWarm,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: MediaQuery.sizeOf(context).width * 0.2,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A574).withOpacity(0.2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height * 0.12,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB899D4).withOpacity(0.14),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 22, color: AppTheme.textMuted),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.3,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (weeksPregnant > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A574),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Week $weeksPregnant',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                letterSpacing: 0.36,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      weeksPregnant > 0
                          ? PregnancyUtils.trimesterDisplayTitle(trimester)
                          : 'Your pregnancy journey',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.32,
                        color: Color(0xFF2D2235),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      weeksPregnant > 0
                          ? PregnancyUtils.trimesterSupportMessage(trimester)
                          : 'When you add your due date in your profile, we can show trimester details here.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    if (weeksPregnant > 0) ...[
                      const SizedBox(height: 28),
                      _ProgressHero(
                        progress: progress,
                        weeksPregnant: weeksPregnant,
                        trimester: trimester,
                        weeksRemaining: remaining,
                      ),
                      const SizedBox(height: 24),
                      _BodyCard(trimester: trimester),
                      const SizedBox(height: 20),
                      _BabyCard(trimester: trimester, weeksPregnant: weeksPregnant),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5EEE0), Color(0xFFFAF8F4), Color(0xFFEBE0D6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderLight.withOpacity(0.4)),
                        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 18, y: 3),
                      ),
                      child: Text(
                        'Every pregnancy is unique. If something doesn’t feel right or you have concerns, '
                        'it’s always okay to reach out to your care team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryActionGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF663399).withOpacity(0.22),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -16,
            right: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4A574).withOpacity(0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppTheme.brandWhite.withOpacity(0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE0B589)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$weeksPregnant of 40 weeks',
                style: TextStyle(
                  color: const Color(0xFFE8DFF0),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 20),
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
        color: AppTheme.brandWhite.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.brandWhite.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFE8DFF0),
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5F0F7),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  final String trimester;

  const _BodyCard({required this.trimester});

  @override
  Widget build(BuildContext context) {
    final feelings = PregnancyUtils.trimesterBodyFeelings(trimester);
    final helps = PregnancyUtils.trimesterBodyHelp(trimester);

    return _SectionCard(
      icon: Icons.person_outline_rounded,
      iconGradient: const [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
      iconColor: const Color(0xFFD4A574),
      sectionLabel: 'YOUR BODY',
      title: 'Changes this trimester',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you might be feeling:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...feelings.map((t) => _BulletLine(text: t, dotColor: const Color(0xFFD4A574))),
          const Divider(height: 28, color: Color(0xFFE8E0F0)),
          Text(
            'What can help:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...helps.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_border, size: 18, color: const Color(0xFF8B7AA8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
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
      iconGradient: const [Color(0xFFE8E0F0), Color(0xFFD8CFE5)],
      iconColor: AppTheme.brandPurple,
      sectionLabel: 'YOUR BABY',
      title: 'Growth this trimester',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5EEE0).withOpacity(0.45),
                  const Color(0xFFEBE0D6).withOpacity(0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 22, color: const Color(0xFFD4A574)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What’s developing:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...dev.map((t) => _BulletLine(text: t, dotColor: const Color(0xFF8B7AA8))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final Color iconColor;
  final String sectionLabel;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconGradient,
    required this.iconColor,
    required this.sectionLabel,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.08, blur: 24, y: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandPurple.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2235),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
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
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w300,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans));
  }
}
