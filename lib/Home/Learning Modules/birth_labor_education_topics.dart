import 'package:flutter/material.dart';

import 'learning_module_detail_screen.dart';

/// Short, static birth & hospital education topics (Learning center).
class BirthLaborEducationTopic {
  const BirthLaborEducationTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.markdownBody,
  });

  final String id;
  final String title;
  final String subtitle;
  final String markdownBody;
}

const List<BirthLaborEducationTopic> birthLaborEducationTopics = [
  BirthLaborEducationTopic(
    id: 'labor-basics',
    title: 'Labor & delivery basics',
    subtitle: 'Stages, timing, and when to call',
    markdownBody: '''
## What this is
Labor is your body’s process of opening the cervix and helping your baby move through the birth canal. It often starts with mild cramps or backache that get stronger and closer together.

## What you might notice
- **Early labor**: irregular contractions, sometimes hours apart; you can usually rest at home.
- **Active labor**: contractions get stronger, longer, and closer; many people head to the hospital or birth center then.
- **Pushing stage**: you may feel strong pressure and the urge to push with contractions.

## When to call your provider
Follow the instructions your team gave you. In general, call right away for bleeding like a period, fluid leaking, baby moving less, severe pain, or if you are unsure you are safe.

## How to speak up
You can say: *“How far apart should my contractions be before I come in?”* or *“I’m not sure if this is labor — can you help me decide?”*
''',
  ),
  BirthLaborEducationTopic(
    id: 'admission-checklist',
    title: 'Hospital admission checklist',
    subtitle: 'ID, comfort items, support person',
    markdownBody: '''
## What to bring
- **ID and insurance card** (if you use insurance).
- **Phone charger** and a list of questions for your team.
- **Comfort items**: loose clothes, snacks if allowed, lip balm, hair ties.
- **Support person** contact info and anything your hospital asked you to pack.

## At check-in
You can ask: *“What happens next?”* and *“Can my support person stay with me?”*

## Remember
Plans can change. You still have the right to understand what is offered and to ask questions.
''',
  ),
  BirthLaborEducationTopic(
    id: 'triage',
    title: 'Triage & first assessment',
    subtitle: 'What happens when you arrive in labor',
    markdownBody: '''
## What triage means
**Triage** is a quick check to see how you and your baby are doing and how urgent your care is. Staff may monitor contractions, check vitals, and sometimes use monitors on your belly.

## What you can ask
- *“Can you tell me what each monitor is for?”*
- *“Can I move or change positions?”*
- *“When will I see my provider?”*

## If you feel rushed
It’s okay to say: *“I need a minute to understand before we decide.”*
''',
  ),
  BirthLaborEducationTopic(
    id: 'during-delivery',
    title: 'What to expect during delivery',
    subtitle: 'Pushing, positions, and support',
    markdownBody: '''
## During pushing
Your team will guide your breathing and pushing. Positions may change (side-lying, hands and knees, squat bar) depending on safety and your hospital’s setup.

## Pain and comfort
Options can include movement, water (if available), medication, or other tools. You can ask what is available **right now** and what the trade-offs are in plain words.

## After birth
Many places do skin-to-skin and feeding support when it is safe. Ask what is typical for your hospital.
''',
  ),
  BirthLaborEducationTopic(
    id: 'speak-up',
    title: 'When and how to speak up',
    subtitle: 'Clear phrases that help',
    markdownBody: '''
## Why it matters
Speaking up helps your team understand pain, fear, or confusion. You are not bothering anyone by asking for clarity.

## Phrases you can use
- *“Please explain that in simpler words.”*
- *“I need a minute before I decide.”*
- *“What are my other options?”*
- *“I’m scared — can someone stay with me?”*

## When to escalate
If you feel ignored after asking, you can ask for the charge nurse or patient advocate. You deserve respectful, understandable care.
''',
  ),
];

/// Opens [LearningModuleDetailScreen] with static markdown (no Firestore task).
void openBirthLaborTopic(BuildContext context, BirthLaborEducationTopic topic) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => LearningModuleDetailScreen(
        title: topic.title,
        content: topic.markdownBody,
        icon: '📘',
      ),
    ),
  );
}
