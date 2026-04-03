import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../cors/ui_theme.dart';
import 'learning_module_detail_screen.dart';
import 'rights_static_content.dart';

/// AI-powered deep dives kept from the legacy app (not in NewUI static set).
class _AiRightsTopic {
  final String title;
  final String topic;
  final String description;
  final IconData icon;
  final List<Color> iconBgGradient;
  final Color iconColor;

  const _AiRightsTopic({
    required this.title,
    required this.topic,
    required this.description,
    required this.icon,
    required this.iconBgGradient,
    required this.iconColor,
  });
}

const _aiExtras = <_AiRightsTopic>[
  _AiRightsTopic(
    title: 'Refusal of care',
    topic: 'Your Right to Say No',
    description: 'When and how you can refuse or delay treatment',
    icon: Icons.front_hand_outlined,
    iconBgGradient: [Color(0xFFE8E0F0), Color(0xFFD8CFE5)],
    iconColor: Color(0xFF8B7AA8),
  ),
  _AiRightsTopic(
    title: 'Birth preferences',
    topic: 'Creating Your Birth Plan',
    description: 'How to share your wishes for labor and delivery',
    icon: Icons.edit_note_rounded,
    iconBgGradient: [Color(0xFFF9F2E8), Color(0xFFFEF9F5)],
    iconColor: Color(0xFFD4A574),
  ),
  _AiRightsTopic(
    title: 'Medical records',
    topic: 'Accessing Your Medical Information',
    description: 'How to get copies of your records',
    icon: Icons.folder_shared_outlined,
    iconBgGradient: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
    iconColor: Color(0xFFD4A574),
  ),
  _AiRightsTopic(
    title: 'Second opinions',
    topic: "Getting Another Doctor's View",
    description: 'When and how to seek another perspective',
    icon: Icons.groups_2_outlined,
    iconBgGradient: [Color(0xFFDCE8E4), Color(0xFFE8F0ED)],
    iconColor: Color(0xFF7D9D92),
  ),
  _AiRightsTopic(
    title: 'Respectful care',
    topic: 'Dignity and Respect in Healthcare',
    description: 'What respectful maternity care can look like',
    icon: Icons.favorite_outline_rounded,
    iconBgGradient: [Color(0xFFF8EDF3), Color(0xFFFDF5F9)],
    iconColor: Color(0xFFC9A9C0),
  ),
];

class RightsScreen extends StatefulWidget {
  const RightsScreen({super.key});

  @override
  State<RightsScreen> createState() => _RightsScreenState();
}

class _RightsScreenState extends State<RightsScreen> {
  RightsStaticTopic? _staticDetail;
  final _ai = AIService();

  static const _footer =
      'This information is meant to support understanding and communication. It does not replace medical or legal advice.';

  Future<void> _openAiTopic(_AiRightsTopic t) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await _ai.generateRightsContent(topic: t.topic);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearningModuleDetailScreen(
            title: t.title,
            content: result['content'],
            icon: '💜',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load content: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_staticDetail != null) {
      return _StaticDetailView(
        topic: _staticDetail!,
        onBack: () => setState(() => _staticDetail = null),
        footer: _footer,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: MediaQuery.sizeOf(context).width * 0.25,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A574).withOpacity(0.16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB899D4).withOpacity(0.12),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, size: 22, color: AppTheme.textMuted),
                      Text(
                        'Learning center',
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
                const SizedBox(height: 24),
                const Text(
                  'Know Your Rights',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    letterSpacing: -0.32,
                    color: Color(0xFF2D2235),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have the right to be heard, respected, and informed during your care.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEE0).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: AppTheme.brandPurple.withOpacity(0.8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Extra topics below use personalized explanations (AI) — unique to this app.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...rightsStaticTopicsNewUi.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RightsTile(
                        title: t.title,
                        description: t.description,
                        icon: t.icon,
                        iconBgGradient: t.iconBgGradient,
                        iconColor: t.iconColor,
                        onTap: () => setState(() => _staticDetail = t),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    'More topics (personalized)',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandPurple.withOpacity(0.85),
                    ),
                  ),
                ),
                ..._aiExtras.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RightsTile(
                        title: t.title,
                        description: t.description,
                        icon: t.icon,
                        iconBgGradient: t.iconBgGradient,
                        iconColor: t.iconColor,
                        onTap: () => _openAiTopic(t),
                      ),
                    )),
                const SizedBox(height: 8),
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
                    _footer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightsTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> iconBgGradient;
  final Color iconColor;
  final VoidCallback onTap;

  const _RightsTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgGradient,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight.withOpacity(0.45)),
            boxShadow: AppTheme.shadowMedium(opacity: 0.08, blur: 28, y: 6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconBgGradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: Color(0xFF2D2235),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticDetailView extends StatelessWidget {
  final RightsStaticTopic topic;
  final VoidCallback onBack;
  final String footer;

  const _StaticDetailView({
    required this.topic,
    required this.onBack,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWarm,
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: 80,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A574).withOpacity(0.14),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: Icon(Icons.chevron_left, color: AppTheme.textMuted, size: 22),
                  label: Text(
                    'All rights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: topic.iconBgGradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.shadowSoft(opacity: 0.12, blur: 20, y: 6),
                  ),
                  child: Icon(topic.icon, color: topic.iconColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    color: Color(0xFF2D2235),
                  ),
                ),
                const SizedBox(height: 20),
                _DetailCard(
                  heading: 'WHAT THIS MEANS',
                  child: Text(
                    topic.whatThisMeans,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  heading: 'WHAT YOU CAN SAY',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topic.whatYouCanSay
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 18, color: const Color(0xFFD4A574)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '“$s”',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  heading: 'QUESTIONS YOU MAY WANT TO ASK',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topic.questionsToAsk
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 18, color: const Color(0xFF8B7AA8)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5EEE0), Color(0xFFFAF8F4), Color(0xFFEBE0D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderLight.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_border_rounded, color: const Color(0xFFD4A574), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When to ask for help',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              topic.whenToAskForHelp,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight.withOpacity(0.4)),
                  ),
                  child: Text(
                    footer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String heading;
  final Widget child;

  const _DetailCard({required this.heading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.4)),
        boxShadow: AppTheme.shadowSoft(opacity: 0.06, blur: 22, y: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPurple.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
