import 'package:flutter/material.dart';

import '../Home/Learning Modules/learning_module_detail_screen.dart';

class PregnancyLossLearningTopic {
  const PregnancyLossLearningTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.markdownBody,
    this.listIcon = Icons.menu_book_outlined,
  });

  final String id;
  final String title;
  final String subtitle;
  final String markdownBody;
  final IconData listIcon;
}

const List<PregnancyLossLearningTopic> kPregnancyLossLearningTopics = [
  PregnancyLossLearningTopic(
    id: 'understanding_loss',
    title: 'Understanding pregnancy loss',
    subtitle:
        'Gentle, plain-language information about what may happen and what questions you can ask.',
    listIcon: Icons.psychology_alt_outlined,
    markdownBody: '''
This guide focuses on **what happened in medical terms** and what your team may know or still be figuring out.

## Medical terms you may hear
Providers may use different words depending on timing and circumstances. Common terms include miscarriage (loss before 20 weeks in many settings), stillbirth (loss at or after 20 weeks), ectopic pregnancy (pregnancy outside the uterus), molar pregnancy, or blighted ovum.

Your care team may order blood tests (such as hCG), ultrasound, or other imaging. Some people have a procedure such as dilation and curettage (D&C) or medication to help the uterus pass tissue. Others may complete the process without surgery.

## Testing and what it can show
Testing does not always identify a clear cause. In some cases, providers may recommend genetic testing, bloodwork, imaging, or no further testing at all.

Chromosome changes in the pregnancy are a common finding when tissue is tested, especially in early loss. That does not predict every future pregnancy, but it is one piece of information your team may discuss.

Hormone levels often need time to return toward pre-pregnancy patterns. Your provider can explain what blood results mean for follow-up timing.

## Follow-up care after diagnosis
- A follow-up visit to confirm bleeding has slowed and the uterus is recovering
- Repeat blood tests until hCG falls to an expected range
- Discussion of birth control or timing of future pregnancies, only if you want that conversation
- Referral to mental health services, social work, or community programs if you ask

## Questions you can ask your provider
- *"Can you explain what happened using everyday words?"*
- *"What tests were done, and what did they show?"*
- *"Will I need more blood tests or another ultrasound?"*
- *"When is it safe to use tampons, have sex, or exercise?"*
- *"What paperwork or leave from work might I need?"*

## When to contact a provider urgently
Contact your care team the same day or urgently (per their instructions) for heavy bleeding (soaking a pad in an hour or less), fever, severe abdominal pain, dizziness, fainting, foul-smelling discharge, or chills.

If you had surgery or medication, follow the specific warning signs on your discharge instructions.
''',
  ),
  PregnancyLossLearningTopic(
    id: 'body_after_loss',
    title: 'Caring for your body after loss',
    subtitle:
        'Learn what follow-up care may involve and when to reach out for help.',
    listIcon: Icons.healing_outlined,
    markdownBody: '''
This guide is about **physical recovery** — bleeding, pain, hormones, and what to track before your next visit.

## Bleeding, cramping, and fatigue
Physical recovery may involve bleeding (often like a heavy period at first), cramping, fatigue, breast changes, and hormone shifts. Timing varies by how far along the pregnancy was and whether you had medication or a procedure.

Bleeding often lasts days to a few weeks. It may stop and start. Cramping usually eases over several days.

Breast tenderness or milk coming in can happen if the pregnancy was further along. Your provider can discuss ways to reduce discomfort if that occurs.

## What your team will monitor
Your team may not be able to give an exact day when bleeding will stop or when hormones will normalize. They can describe typical ranges and what they will check at follow-up.

## Follow-up visits and labs
- Office or telehealth check to review bleeding, pain, and mood
- Blood tests to track hCG until it falls appropriately
- Ultrasound if there is concern tissue remains in the uterus
- Rh immune globulin (Rhogam) if you are Rh-negative and it applies to your situation
- Updated list of safe medications for pain or sleep

## Daily care between visits
- Use pads (not tampons or cups) until your provider says otherwise
- Rest when tired; light walking is often okay if you feel up to it
- Keep a simple log: bleeding amount, pain level, temperature if you are checking it
- Bring your log and questions to follow-up visits

## Questions about physical recovery
- *"What follow-up care do I need, and when?"*
- *"What symptoms are expected versus concerning?"*
- *"When can I return to work, exercise, or sexual activity?"*
- *"Do I need any vaccines, supplements, or lab work?"*
- *"Who do I call after hours if something changes?"*

## Physical warning signs
Seek care promptly for soaking through more than one pad per hour, passing large clots with dizziness, fever over 100.4°F (38°C), worsening pain, or symptoms your discharge sheet lists as urgent.
''',
  ),
  PregnancyLossLearningTopic(
    id: 'grief_support',
    title: 'Grief and emotional support',
    subtitle:
        'Support for the emotional side of loss, at your own pace.',
    listIcon: Icons.favorite_outline,
    markdownBody: '''
This guide is about **emotional responses** — not a checklist you have to match, and not a timeline you must follow.

## Feelings that are commonly reported
Emotional responses after pregnancy loss vary widely. Some people feel sadness, anger, numbness, guilt, irritability, or difficulty concentrating. Others focus on practical tasks first and feel emotions more later.

Sleep disruption, appetite changes, and trouble focusing at work are common for a period of time. These responses do not follow a fixed schedule.

Partners and family members may react differently. That can affect communication at home.

## What providers cannot measure on a lab test
There is no lab test for grief or stress. Providers cannot predict exactly how long difficult feelings will last.

If mood symptoms are severe, persistent, or include thoughts of self-harm, that is a medical and safety concern your care team should know about.

## Types of support you can ask for
- Screening questions about mood at an OB, primary care, or emergency visit
- Referral to therapy, psychiatry, or a support group
- Information about the National Maternal Mental Health Hotline (call or text 1-833-TLC-MAMA / 1-833-853-6262) or Postpartum Support International
- Work or school accommodation letters if you request them

## Gentle steps that help some people
- Reduce non-essential tasks for a short period if possible
- Identify one person you can contact for logistical help (rides, meals, childcare)
- Write down mood and sleep patterns if you meet with a counselor or provider
- Limit exposure to triggers (social media announcements, certain events) if helpful

## Talking about mood with a clinician
- *"Is what I am feeling within a range you often see after loss?"*
- *"When would you recommend therapy or medication?"*
- *"Can you refer me to local support groups or counselors?"*
- *"What should I do if I have scary or intrusive thoughts?"*

## If you need help right now
Contact a provider or crisis line immediately if you have thoughts of harming yourself, feel unable to care for yourself, or feel out of touch with reality.

For 24/7 support in the U.S., you can call or text **988** or use the maternal mental health hotline above. These are external services, not counselors inside this app.
''',
  ),
  PregnancyLossLearningTopic(
    id: 'talking_provider',
    title: 'Talking to your provider',
    subtitle:
        'Prepare words and questions for your next visit.',
    listIcon: Icons.record_voice_over_outlined,
    markdownBody: '''
This guide helps you **prepare for conversations** with your care team — before, during, and between visits.

## Who you might see and why
Follow-up visits may focus on physical recovery first. You can still ask for time to discuss emotional needs, paperwork, or future planning.

You may meet with an OB, midwife, family medicine clinician, or emergency department team depending on where loss was diagnosed. Each setting has different resources.

## Information your team may have today
Providers may not have answers to every question immediately. You can ask what is known today and what will be addressed at a later visit.

## What a follow-up visit may cover
- Review of symptoms and exam or ultrasound if needed
- Lab orders and explanation of results
- Referrals (mental health, social work, Maternal-Fetal Medicine)
- Completion of forms for work, bereavement policies, or vital records where applicable

## Preparing for your appointment
- List your top three questions in order of priority
- Note dates: when bleeding started, procedures, medications taken
- Bring a support person if allowed and if you want one
- Ask for written instructions or a patient portal message summary

## Phrases that ask for plain language
- *"Please explain that in simpler words."*
- *"What are my options from here, and what are the pros and cons?"*
- *"I need a moment before we decide."*
- *"Can we schedule a separate visit to talk about the future?"*

## Questions about records and next steps
- *"What should I watch for before our next visit?"*
- *"What records will I receive, and how do I get copies?"*
- *"If I become pregnant again later, when should I call your office?"*
- *"Are there hospital or community resources for burial, cremation, or memorial options?"*

## Between scheduled visits
Use the contact method your team gave you (nurse line, portal, on-call number) for new or worsening physical symptoms or urgent emotional safety concerns.
''',
  ),
  PregnancyLossLearningTopic(
    id: 'future_when_ready',
    title: 'Support for the future, if or when you\'re ready',
    subtitle:
        'There is no timeline you have to follow.',
    listIcon: Icons.calendar_month_outlined,
    markdownBody: '''
This guide is only for when **you** want to talk about future care — there is no required timeline.

## You choose if and when to discuss the future
There is no required timeline for discussing a future pregnancy. Some people want information at the first follow-up visit; others prefer to wait months or years.

When you are ready, conversations may cover optimal spacing between pregnancies, managing chronic conditions, medication safety, and whether extra monitoring is recommended.

## What medicine can and cannot promise
Even with testing, providers may not be able to guarantee outcomes for a future pregnancy. They can explain statistics for your situation without making promises.

Genetic counseling may be offered after certain losses or if you have family history concerns. Attendance is optional.

## Topics that may come up at a preconception visit
- Preconception visit with OB or Maternal-Fetal Medicine
- Review of vaccines (such as rubella immunity), folic acid, and medications
- Planning for conditions like diabetes, hypertension, or thyroid disease
- Discussion of mental health readiness and support plan

## Getting your records in order
- Request written summary of prior loss and tests from your records
- List medications and supplements you take
- Note menstrual cycle return (first period often comes in 4–8 weeks, but timing varies)
- Decide whether you want a partner or support person at future visits

## Questions if you are considering another pregnancy
- *"Based on my history, is there testing you recommend before another pregnancy?"*
- *"How long do you suggest waiting, and why?"*
- *"Would I need early ultrasound or other monitoring next time?"*
- *"What should I do if I have anxiety in a future pregnancy?"*
- *"I am not planning another pregnancy — what ongoing care do I still need?"*

## If you become pregnant again
Contact your care team as early as you feel comfortable so they can schedule appropriate dating and monitoring.

For any new physical symptoms before you are ready to discuss pregnancy, you can still book a general follow-up visit.
''',
  ),
];

void openPregnancyLossLearningTopic(
  BuildContext context,
  PregnancyLossLearningTopic topic,
) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/pregnancy-loss/learn/${topic.id}'),
      builder: (context) => LearningModuleDetailScreen(
        key: ValueKey('pregnancy_loss_module_${topic.id}'),
        moduleId: topic.id,
        title: topic.title,
        content: topic.markdownBody,
        icon: '📘',
      ),
    ),
  );
}

PregnancyLossLearningTopic? pregnancyLossTopicById(String id) {
  for (final t in kPregnancyLossLearningTopics) {
    if (t.id == id) return t;
  }
  return null;
}
