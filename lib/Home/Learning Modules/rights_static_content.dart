import 'package:flutter/material.dart';

/// Calm, empowering copy aligned with NewUI [KnowYourRights.tsx] (not legal/warning tone).
class RightsStaticTopic {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> iconBgGradient;
  final Color iconColor;
  final String whatThisMeans;
  final List<String> whatYouCanSay;
  final List<String> questionsToAsk;
  final String whenToAskForHelp;

  const RightsStaticTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgGradient,
    required this.iconColor,
    required this.whatThisMeans,
    required this.whatYouCanSay,
    required this.questionsToAsk,
    required this.whenToAskForHelp,
  });
}

/// Core “Know your rights” topics (static — matches NewUI).
const List<RightsStaticTopic> rightsStaticTopicsNewUi = [
  RightsStaticTopic(
    id: 'ask-questions',
    title: 'Your right to ask questions',
    description: 'You deserve clear answers about your care',
    icon: Icons.chat_bubble_outline_rounded,
    iconBgGradient: [Color(0xFFF5EEE0), Color(0xFFEBE0D6)],
    iconColor: Color(0xFFD4A574),
    whatThisMeans:
        'You have the right to ask questions and get clear answers. Your care team should explain things in a way you can understand.',
    whatYouCanSay: [
      'Can you explain that in a simpler way?',
      'I need a moment to think before deciding.',
      'Can you tell me more about why this is needed?',
    ],
    questionsToAsk: [
      'What are my options?',
      'What happens if I wait?',
      'Are there risks I should know about?',
      'How will this affect my baby?',
    ],
    whenToAskForHelp:
        'If you feel rushed or pressured to make a decision without understanding it fully, it’s okay to ask for more time or speak with another member of your care team.',
  ),
  RightsStaticTopic(
    id: 'informed-consent',
    title: 'Your right to informed consent',
    description: 'Understanding your choices before any procedure',
    icon: Icons.shield_outlined,
    iconBgGradient: [Color(0xFFE8E0F0), Color(0xFFEDE7F3)],
    iconColor: Color(0xFF8B7AA8),
    whatThisMeans:
        'Before any procedure or treatment, your provider should explain what will happen, why it’s recommended, and what other options you have. You have the right to say yes or no.',
    whatYouCanSay: [
      'I’d like to understand what this procedure involves.',
      'What are the alternatives?',
      'I need more time to decide.',
      'Can I talk to my support person first?',
    ],
    questionsToAsk: [
      'Why is this procedure recommended for me?',
      'What are the benefits and risks?',
      'What happens if I choose not to do this?',
      'How much time do I have to decide?',
    ],
    whenToAskForHelp:
        'If you feel like you’re being asked to consent to something you don’t understand, or if you feel uncomfortable, you can ask to speak with a patient advocate or nurse.',
  ),
  RightsStaticTopic(
    id: 'pain-management',
    title: 'Your right to pain management',
    description: 'Asking for comfort during labor and delivery',
    icon: Icons.favorite_border_rounded,
    iconBgGradient: [Color(0xFFF8EDF3), Color(0xFFFDF5F9)],
    iconColor: Color(0xFFC9A9C0),
    whatThisMeans:
        'You have the right to ask for pain relief during labor and delivery. Your preferences about pain management should be respected.',
    whatYouCanSay: [
      'I’m experiencing pain and would like to discuss my options.',
      'Can we talk about pain management choices?',
      'I’d like to try a specific method for pain relief.',
      'This isn’t working for me. What else can we try?',
    ],
    questionsToAsk: [
      'What pain management options are available?',
      'How will this affect my baby?',
      'Can I change my mind later?',
      'What are the side effects?',
    ],
    whenToAskForHelp:
        'If your requests for pain management are being dismissed or ignored, ask to speak with a charge nurse or patient advocate.',
  ),
  RightsStaticTopic(
    id: 'support-person',
    title: 'Your right to a support person',
    description: 'Having someone you trust by your side',
    icon: Icons.volunteer_activism_outlined,
    iconBgGradient: [Color(0xFFF9F2E8), Color(0xFFFEF9F5)],
    iconColor: Color(0xFFD4A574),
    whatThisMeans:
        'You have the right to have a support person with you during labor, delivery, and recovery. This could be a partner, family member, doula, or friend.',
    whatYouCanSay: [
      'I’d like my support person to stay with me.',
      'Can my doula be present during delivery?',
      'I need my support person here for this decision.',
      'When will my support person be able to join me?',
    ],
    questionsToAsk: [
      'Can my support person be with me during all procedures?',
      'What are the visitor policies?',
      'Can I have more than one support person?',
      'Will my support person need to leave at any point?',
    ],
    whenToAskForHelp:
        'If you’re being told you can’t have a support person when you were expecting to, ask to speak with a supervisor or patient advocate about the hospital’s policies.',
  ),
  RightsStaticTopic(
    id: 'understand-care',
    title: 'Your right to understand your care',
    description: 'Getting information in words that make sense',
    icon: Icons.help_outline_rounded,
    iconBgGradient: [Color(0xFFDCE8E4), Color(0xFFE8F0ED)],
    iconColor: Color(0xFF7D9D92),
    whatThisMeans:
        'You have the right to receive information about your care in language you can understand. If medical terms are confusing, your care team should explain them clearly.',
    whatYouCanSay: [
      'Can you use simpler words to explain that?',
      'I don’t understand. Can you explain it differently?',
      'Can you write that down for me?',
      'Do you have any handouts I can read?',
    ],
    questionsToAsk: [
      'What does that medical term mean?',
      'Can you show me on a picture or diagram?',
      'What should I watch for at home?',
      'When should I call if something doesn’t feel right?',
    ],
    whenToAskForHelp:
        'If you’re not getting clear answers or feel like your questions are being dismissed, you can ask for a patient advocate or speak with another provider.',
  ),
];
