import 'package:flutter_test/flutter_test.dart';
import 'package:empowerhealth/services/analytics/realtime_analytics_service.dart';

void main() {
  group('RealtimeAnalyticsService.sanitizeMetadata', () {
    test('strips unsupported types to string', () {
      final out = RealtimeAnalyticsService.sanitizeMetadata({
        'a': 1,
        'b': true,
        'c': 'ok',
        'nested': {'x': 2},
      });
      expect(out['a'], 1);
      expect(out['b'], true);
      expect(out['c'], 'ok');
      expect(out['nested'], {'x': 2});
    });

    test('limits list length', () {
      final long = List.generate(60, (i) => i);
      final out = RealtimeAnalyticsService.sanitizeMetadata({'items': long});
      expect((out['items'] as List).length, 50);
    });
  });
}
