import 'package:empowerhealth/assistant/assistant_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maternal emergency (pre-launch review scenarios)', () {
    const cases = [
      'I am 32 weeks pregnant and have a severe headache, blurry vision, and my face is swollen',
      'I had my baby 5 days ago. I have a bad headache, blurry vision and swelling',
      'I am soaking a pad every 30 minutes and I feel dizzy',
      'Bleeding a lot after birth and feeling lightheaded',
      'My baby has not moved today',
      'I have chest pain and trouble breathing',
      'I passed out this morning, I am 3 weeks postpartum',
    ];
    for (final c in cases) {
      test(c, () {
        expect(
          detectAssistantSafety(c),
          AssistantSafetyLevel.maternalEmergency,
        );
      });
    }
  });

  group('mental health crisis', () {
    const cases = [
      'I am three weeks postpartum, crying all the time, not sleeping, and I feel like my family would be better off without me',
      'Sometimes I think about suicide',
      "I can't go on like this",
      "I don't want to be here anymore",
      'I have thoughts of hurting my baby',
    ];
    for (final c in cases) {
      test(c, () {
        expect(
          detectAssistantSafety(c),
          AssistantSafetyLevel.mentalHealthCrisis,
        );
      });
    }
  });

  group('typos still trigger (QA: "killing myseld")', () {
    const crisis = [
      'I am thinking about killing myseld',
      'I am thinking about kiling myslef',
      'i keep thinking about sucide',
      'my family would be beter off withou me',
      'I want to hurt mysef',
    ];
    for (final c in crisis) {
      test(c, () {
        expect(
          detectAssistantSafety(c),
          AssistantSafetyLevel.mentalHealthCrisis,
        );
      });
    }
    const emergency = [
      'I have a sever headache and blury vision',
      'heavy bleding and I feel dizy',
      'I have chets pain',
      'I fainetd this morning',
    ];
    for (final c in emergency) {
      test(c, () {
        expect(
          detectAssistantSafety(c),
          AssistantSafetyLevel.maternalEmergency,
        );
      });
    }
  });

  group('real words near key words stay quiet', () {
    const cases = [
      'Can you help me with spelling in my birth plan?',
      'I have no moment to myself these days',
      'Is it ok to keep fasting while breastfeeding?',
      'I had a chess game with my partner and felt a mild headache',
    ];
    for (final c in cases) {
      test(c, () {
        expect(detectAssistantSafety(c), AssistantSafetyLevel.none);
      });
    }
  });

  group('everyday questions stay quiet', () {
    const cases = [
      'What does gestational diabetes mean? Did I cause it?',
      'I feel like my provider is dismissing my concerns',
      'I live in Cincinnati and need food and a ride to my appointment',
      'What is preeclampsia?',
      'Is a mild headache normal in the first trimester?',
      '',
    ];
    for (final c in cases) {
      test(c.isEmpty ? '(empty)' : c, () {
        expect(detectAssistantSafety(c), AssistantSafetyLevel.none);
      });
    }
  });

  test('field value round-trips', () {
    for (final level in AssistantSafetyLevel.values) {
      expect(assistantSafetyFromField(assistantSafetyFieldValue(level)), level);
    }
  });
}
