import 'package:flutter_test/flutter_test.dart';
import 'package:empowerhealth/beta/beta_checklist.dart';

void main() {
  group('beta checklist items', () {
    test('ids are unique', () {
      final ids = kBetaChecklistItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every item has a trigger or is marked done manually', () {
      const manual = {'assistant', 'care_checkin'};
      for (final item in kBetaChecklistItems) {
        if (item.triggers.isEmpty) {
          expect(
            manual,
            contains(item.id),
            reason: '${item.id} has no trigger',
          );
        } else {
          expect(item.isManual, isFalse);
        }
      }
    });

    test('titles and subtitles are filled in', () {
      for (final item in kBetaChecklistItems) {
        expect(item.title.trim(), isNotEmpty);
        expect(item.subtitle.trim(), isNotEmpty);
      }
    });

    test('events map to the expected items', () {
      expect(betaItemsForEvent('visit_summary_created').map((i) => i.id), [
        'visit_summary',
      ]);
      expect(betaItemsForEvent('community_post_replied').map((i) => i.id), [
        'community_post',
      ]);
      expect(betaItemsForEvent('immediate_support_opened').map((i) => i.id), [
        'support',
      ]);
      expect(betaItemsForEvent('beta_checklist_item_completed'), isEmpty);
      expect(betaItemsForEvent('unknown_event'), isEmpty);
    });

    test('betaItemById finds items', () {
      expect(betaItemById('birth_plan')?.title, 'Create a birth plan');
      expect(betaItemById('nope'), isNull);
    });
  });

  group('remaining count', () {
    final total = kBetaChecklistItems.length;
    final allIds = kBetaChecklistItems.map((i) => i.id).toSet();

    test('nothing done counts every item plus the daily goal', () {
      expect(betaRemainingCount({}, 0), total + 1);
    });

    test('daily goal drops off at 10 minutes', () {
      expect(betaRemainingCount({}, kBetaDailyGoalSeconds - 60), total + 1);
      expect(betaRemainingCount({}, kBetaDailyGoalSeconds), total);
      expect(betaRemainingCount({}, kBetaDailyGoalSeconds + 300), total);
    });

    test('completed items are subtracted and unknown ids ignored', () {
      expect(betaRemainingCount({'assistant', 'profile'}, 0), total - 1);
      expect(betaRemainingCount({'assistant', 'not_an_item'}, 0), total);
    });

    test('all done with the goal met is zero', () {
      expect(betaRemainingCount(allIds, kBetaDailyGoalSeconds), 0);
      expect(betaRemainingCount(allIds, 0), 1);
    });
  });

  test('date key is zero-padded local yyyy-MM-dd', () {
    expect(betaDateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    expect(betaDateKey(DateTime(2026, 12, 31)), '2026-12-31');
  });
}
