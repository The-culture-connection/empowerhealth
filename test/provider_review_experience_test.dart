import 'package:flutter_test/flutter_test.dart';
import 'package:empowerhealth/models/provider.dart';
import 'package:empowerhealth/providers/provider_search_location.dart';
import 'package:empowerhealth/providers/saved_providers_store.dart';

Map<String, dynamic> _explicit(Map<String, bool> answers) => {
      'feltHeard': answers['feltHeard'] == true,
      'feltRespected': answers['feltRespected'] == true,
      'explainedClearly': answers['explainedClearly'] == true,
      'experienceFields': {ReviewExperience.answersKey: answers},
    };

Map<String, dynamic> _legacy({
  bool heard = false,
  bool respected = false,
  bool explained = false,
}) =>
    {
      'feltHeard': heard,
      'feltRespected': respected,
      'explainedClearly': explained,
    };

void main() {
  group('ReviewExperience', () {
    test('one review that skipped every question shows No responses, not 0%',
        () {
      final reviews = [_legacy()];
      final t = ReviewExperience.tally(reviews, ReviewExperience.feltHeard);
      expect(t.answered, 0);
      expect(t.rate, isNull);
      expect(t.label('felt heard'), 'Felt heard: No responses');
    });

    test('explicit answers: yes / answered, skipped ones left out', () {
      final reviews = [
        _explicit({'feltHeard': true, 'feltRespected': false}),
        _explicit({'feltHeard': true}),
        _explicit({}),
      ];
      final heard = ReviewExperience.tally(reviews, ReviewExperience.feltHeard);
      expect(heard.yes, 2);
      expect(heard.answered, 2);
      expect(heard.percent, 100);
      expect(heard.label('felt heard'), '100% felt heard · 2 responses');

      final respected =
          ReviewExperience.tally(reviews, ReviewExperience.feltRespected);
      expect(respected.answered, 1);
      expect(respected.percent, 0);
      expect(respected.label('felt respected'), '0% felt respected · 1 response');

      final explained =
          ReviewExperience.tally(reviews, ReviewExperience.explainedClearly);
      expect(explained.rate, isNull);
    });

    test('legacy checkbox reviews count only when a box was ticked', () {
      final reviews = [
        _legacy(heard: true),
        _legacy(),
      ];
      final heard = ReviewExperience.tally(reviews, ReviewExperience.feltHeard);
      expect(heard.answered, 1);
      expect(heard.percent, 100);
      final respected =
          ReviewExperience.tally(reviews, ReviewExperience.feltRespected);
      expect(respected.answered, 1);
      expect(respected.percent, 0);
    });

    test('withExperienceRates can clear a stale rate', () {
      final p = Provider(name: 'X', feltHeardRate: 0.0);
      final cleared = p.withExperienceRates(
        feltHeard: null,
        feltRespected: 0.5,
        explainedClearly: null,
      );
      expect(cleared.feltHeardRate, isNull);
      expect(cleared.feltRespectedRate, 0.5);
      expect(cleared.name, 'X');
    });
  });

  group('Community rating label and badge', () {
    test('one 5-star review: stars with count, never the badge', () {
      final p = Provider(name: 'X', rating: 5.0, reviewCount: 1);
      expect(p.communityRatingText, '5.0 · 1 community review');
      expect(p.showsMamaApprovedBadge, isFalse);
    });

    test('a rating without reviews is not shown as a community rating', () {
      final p = Provider(name: 'X', rating: 4.5, reviewCount: 0);
      expect(p.showsCommunityRating, isFalse);
      expect(p.communityRatingText, 'No community reviews yet');
    });

    test('three reviews averaging 4+ earn the badge', () {
      final p = Provider(name: 'X', rating: 4.3, reviewCount: 3);
      expect(p.communityRatingText, '4.3 · 3 community reviews');
      expect(p.showsMamaApprovedBadge, isTrue);
    });
  });

  group('Saved provider ids', () {
    test('NPI wins so the same provider maps to one bookmark', () {
      final fromSearch = Provider(name: 'Dr A', npi: '123');
      final fromFirestore = Provider(name: 'Dr A', npi: '123', id: 'abc');
      expect(SavedProvidersStore.docIdFor(fromSearch), 'npi_123');
      expect(SavedProvidersStore.docIdFor(fromFirestore), 'npi_123');
    });

    test('slashes never reach a document id', () {
      final p = Provider(name: 'X', id: 'a/b');
      expect(SavedProvidersStore.docIdFor(p), 'a_b');
    });
  });

  group('ProviderSearchLocation', () {
    tearDown(ProviderSearchLocation.reset);

    test('a new search replaces the previous ZIP', () {
      ProviderSearchLocation.record(zip: '45239', city: 'Cincinnati', radius: 10);
      ProviderSearchLocation.record(zip: '45040', city: 'Mason', radius: 25);
      final last = ProviderSearchLocation.lastSearched.value!;
      expect(last.zip, '45040');
      expect(last.city, 'Mason');
      expect(last.radius, 25);
    });

    test('an incomplete ZIP is not recorded', () {
      ProviderSearchLocation.record(zip: '4504', city: 'Mason', radius: 10);
      expect(ProviderSearchLocation.lastSearched.value, isNull);
    });
  });
}
