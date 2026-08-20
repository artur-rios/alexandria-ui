import 'package:alexandria_desktop/features/catalog/domain/catalog_search.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Matching a term against the loaded catalog (UC-11, FR-CT-06).
void main() {
  group('what counts as a search (AF-02)', () {
    test('GivenABlankTerm_WhenItIsChecked_ThenItIsNotASearch', () {
      expect(isSearchable(''), isFalse);
    });

    test('GivenWhitespace_WhenItIsChecked_ThenItIsNotASearch', () {
      // Whitespace and blank are the same thing: the owner has not asked a
      // question, so the previous listing is what belongs on screen.
      expect(isSearchable('   '), isFalse);
    });

    test('GivenATerm_WhenItIsChecked_ThenItIsASearch', () {
      expect(isSearchable('blue'), isTrue);
    });
  });

  group('matching', () {
    test('GivenANameContainingTheTerm_WhenMatched_ThenItMatches', () {
      expect(matchesSearch(aFile(name: 'Kind of Blue.flac'), 'blue'), isTrue);
    });

    test('GivenADifferentCase_WhenMatched_ThenItStillMatches', () {
      expect(matchesSearch(aFile(name: 'Kind of Blue.flac'), 'BLUE'), isTrue);
    });

    test('GivenTheTermOnlyInThePath_WhenMatched_ThenItMatches', () {
      expect(
        matchesSearch(
          aFile(name: 'track01.flac', path: '/home/owner/jazz/track01.flac'),
          'jazz',
        ),
        isTrue,
      );
    });

    test('GivenNoOccurrence_WhenMatched_ThenItDoesNotMatch', () {
      expect(
        matchesSearch(aFile(name: 'Kind of Blue.flac'), 'reggae'),
        isFalse,
      );
    });

    test('GivenABlankTerm_WhenMatched_ThenNothingMatches', () {
      // A blank term is not a search that matches everything.
      expect(matchesSearch(aFile(), '   '), isFalse);
    });
  });

  group('results', () {
    final files = [
      aFile(uuid: '1', name: 'Kind of Blue.flac'),
      aFile(uuid: '2', name: 'Blue Train.flac'),
      aFile(uuid: '3', name: 'Giant Steps.flac'),
      aFile(uuid: '4', name: 'blue.png', type: LibraryType.image),
    ];

    test('GivenATerm_WhenTheCatalogIsSearched_ThenOnlyMatchesAreReturned', () {
      final results = searchResults(files, 'blue');

      expect(results.map((file) => file.uuid), ['1', '2', '4']);
    });

    test('GivenATerm_WhenTheCatalogIsSearched_ThenTypesAreNotFilteredOut', () {
      // Across every type at once: the image matches on the same footing.
      expect(
        searchResults(files, 'blue').map((file) => file.type),
        contains(LibraryType.image),
      );
    });

    test('GivenNoMatch_WhenTheCatalogIsSearched_ThenNothingIsReturned', () {
      expect(searchResults(files, 'reggae'), isEmpty);
    });
  });

  group('highlighting (main flow step 3)', () {
    test('GivenTheTermInTheName_WhenItIsHighlighted_ThenTheSpanIsFound', () {
      expect(highlightRange('Kind of Blue.flac', 'blue'), (start: 8, end: 12));
    });

    test('GivenTheTermIsNotInTheText_WhenHighlighted_ThenThereIsNoSpan', () {
      // Matched on its path rather than its name: there is nothing in the
      // name to mark, and inventing a mark would point at the wrong thing.
      expect(highlightRange('track01.flac', 'jazz'), isNull);
    });

    test('GivenABlankTerm_WhenHighlighted_ThenThereIsNoSpan', () {
      expect(highlightRange('anything', '  '), isNull);
    });
  });
}
