import 'package:flutter_test/flutter_test.dart';
import 'package:empowerhealth/models/provider.dart';

double _avg(List<int> ratings) =>
    ratings.fold<double>(0.0, (s, r) => s + r) / ratings.length;

void main() {
  group('Provider.qualifiesForMamaApproved', () {
    test('fewer than 3 reviews never qualifies', () {
      expect(
        Provider.qualifiesForMamaApproved(reviewCount: 2, averageRating: 5.0),
        isFalse,
      );
      expect(
        Provider.qualifiesForMamaApproved(reviewCount: 0, averageRating: 5.0),
        isFalse,
      );
      expect(
        Provider.qualifiesForMamaApproved(
          reviewCount: null,
          averageRating: 5.0,
        ),
        isFalse,
      );
    });

    test('exactly 3 reviews averaging exactly 4.0 qualifies', () {
      expect(
        Provider.qualifiesForMamaApproved(
          reviewCount: 3,
          averageRating: _avg([5, 4, 3]),
        ),
        isTrue,
      );
      expect(
        Provider.qualifiesForMamaApproved(reviewCount: 3, averageRating: 4.0),
        isTrue,
      );
    });

    test('average below 4.0 does not qualify', () {
      expect(
        Provider.qualifiesForMamaApproved(reviewCount: 10, averageRating: 3.99),
        isFalse,
      );
      expect(
        Provider.qualifiesForMamaApproved(
          reviewCount: 3,
          averageRating: _avg([5, 4, 2]),
        ),
        isFalse,
      );
    });

    test('float noise just under 4.0 still counts as 4.0', () {
      expect(
        Provider.qualifiesForMamaApproved(
          reviewCount: 3,
          averageRating: 3.9999999999,
        ),
        isTrue,
      );
    });

    test('missing rating does not qualify', () {
      expect(
        Provider.qualifiesForMamaApproved(reviewCount: 5, averageRating: null),
        isFalse,
      );
    });

    test('getter derives from count + rating, ignoring the legacy flag', () {
      final stale = Provider(
        name: 'Test',
        mamaApproved: true,
        reviewCount: 1,
        rating: 5.0,
      );
      expect(stale.showsMamaApprovedBadge, isFalse);

      final earned = Provider(name: 'Test', reviewCount: 3, rating: 4.0);
      expect(earned.showsMamaApprovedBadge, isTrue);
    });
  });

  group('Provider.formatAverageRating', () {
    test('never rounds a sub-4.0 average up to 4.0', () {
      expect(Provider.formatAverageRating(3.96), '3.9');
      expect(Provider.formatAverageRating(4.0), '4.0');
      expect(Provider.formatAverageRating(_avg([5, 4, 3])), '4.0');
      expect(Provider.formatAverageRating(4.67), '4.6');
    });
  });
}
