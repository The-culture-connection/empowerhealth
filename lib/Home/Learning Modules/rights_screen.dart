import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/analytics_service.dart';
import '../../cors/ui_theme.dart';
import '../../design_system/hearth.dart';
import '../../learning/notes_dialog.dart';
import '../../widgets/medical_citations_section.dart';
import 'learning_module_detail_screen.dart';
import 'rights_static_content.dart';

/// AI-powered deep dives kept from the legacy app (not in NewUI static set).
class _AiRightsTopic {
  final String title;
  final String topic;
  final String description;
  final IconData icon;

  const _AiRightsTopic({
    required this.title,
    required this.topic,
    required this.description,
    required this.icon,
  });
}

const _aiExtras = <_AiRightsTopic>[
  _AiRightsTopic(
    title: 'Refusal of care',
    topic: 'Your Right to Say No',
    description: 'When and how you can refuse or delay treatment',
    icon: Icons.front_hand_outlined,
  ),
  _AiRightsTopic(
    title: 'Birth preferences',
    topic: 'Creating Your Birth Plan',
    description: 'How to share your wishes for labor and delivery',
    icon: Icons.edit_outlined,
  ),
  _AiRightsTopic(
    title: 'Medical records',
    topic: 'Accessing Your Medical Information',
    description: 'How to get copies of your records',
    icon: Icons.folder_outlined,
  ),
  _AiRightsTopic(
    title: 'Second opinions',
    topic: "Getting Another Doctor's View",
    description: 'When and how to seek another perspective',
    icon: Icons.people_outline,
  ),
  _AiRightsTopic(
    title: 'Respectful care',
    topic: 'Dignity and Respect in Healthcare',
    description: 'What respectful maternity care can look like',
    icon: Icons.favorite_border,
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
  final _analytics = AnalyticsService();

  static const _footer =
      'This information is meant to support understanding and communication. It does not replace medical or legal advice.';

  @override
  void initState() {
    super.initState();
    _analytics.logKnowYourRightsViewed(source: 'rights_screen');
  }

  Future<void> _openAiTopic(_AiRightsTopic t) async {
    _analytics.logKnowYourRightsViewed(
      source: 'ai_topic',
      topicId: t.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      topicTitle: t.title,
    );
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
            icon: '',
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
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const HearthPushedHeader(
              backLabel: 'Learning center',
              title: 'Know Your Rights',
              subtitle:
                  'You have the right to be heard, respected, and informed during your care.',
              padding: EdgeInsets.fromLTRB(0, 20, 0, 24),
            ),
            ...rightsStaticTopicsNewUi.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RightsTile(
                    title: t.title,
                    description: t.description,
                    icon: t.icon,
                    onTap: () {
                      _analytics.logKnowYourRightsViewed(
                        source: 'static_topic',
                        topicId: t.title
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
                        topicTitle: t.title,
                      );
                      setState(() => _staticDetail = t);
                    },
                  ),
                )),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 14),
              child: HearthSectionHeading('More topics (personalized)'),
            ),
            ..._aiExtras.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RightsTile(
                    title: t.title,
                    description: t.description,
                    icon: t.icon,
                    onTap: () => _openAiTopic(t),
                  ),
                )),
            const SizedBox(height: 12),
            HearthFeatureCard(
              padding: const EdgeInsets.all(22),
              child: Text(
                _footer,
                textAlign: TextAlign.center,
                style: hearthCardBodyStyle.copyWith(fontSize: 13, height: 19 / 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightsTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RightsTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HearthIconChip(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: hearthCardTitleStyle.copyWith(fontSize: 17, height: 24 / 17),
                ),
                const SizedBox(height: 4),
                Text(description, style: hearthCardBodyStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 13),
            child: Icon(Icons.chevron_right, color: AppTheme.brandPurple, size: 20),
          ),
        ],
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

  // Quotes and questions sit beside a 44px save button, so the first line is
  // nudged down to centre on it.
  static const _itemText = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 14,
    height: 21 / 14,
    color: AppTheme.ink,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            HearthPushedHeader(
              onBack: onBack,
              backLabel: 'All rights',
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  HearthIconChip(topic.icon),
                  const SizedBox(height: 14),
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            _DetailCard(
              heading: 'What this means',
              child: Text(
                topic.whatThisMeans,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              heading: 'What you can say',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topic.whatYouCanSay
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 13),
                              child: Icon(Icons.chat_bubble_outline,
                                  size: 18, color: AppTheme.brandGold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 11),
                                child: Text('“$s”', style: _itemText),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Save to Journal',
                              icon: const Icon(Icons.bookmark_add_outlined,
                                  size: 20, color: AppTheme.brandPurple),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => NotesDialog(
                                    moduleTitle: topic.title,
                                    preFilledText: s,
                                    initialTag:
                                        NotesDialog.categoryForSection(
                                            'know_your_rights'),
                                  ),
                                );
                              },
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
              heading: 'Questions you may want to ask',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topic.questionsToAsk
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 13),
                              child: Icon(Icons.check_circle_outline,
                                  size: 18, color: AppTheme.brandPurple),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 11),
                                child: Text(s, style: _itemText),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Save to Journal',
                              icon: const Icon(Icons.bookmark_add_outlined,
                                  size: 20, color: AppTheme.brandPurple),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => NotesDialog(
                                    moduleTitle: topic.title,
                                    preFilledText: s,
                                    initialTag:
                                        NotesDialog.categoryForSection(
                                            'questions_to_ask'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            HearthFeatureCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.favorite_border, color: AppTheme.brandPurple, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('When to ask for help', style: hearthCardTitleStyle),
                        const SizedBox(height: 6),
                        Text(topic.whenToAskForHelp, style: hearthCardBodyStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MedicalCitationsSection(topic: 'rights ${topic.title}'),
            const SizedBox(height: 16),
            HearthCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                footer,
                textAlign: TextAlign.center,
                style: hearthCardBodyStyle.copyWith(fontSize: 13, height: 19 / 13),
              ),
            ),
          ],
        ),
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
    return SizedBox(
      width: double.infinity,
      child: HearthCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
