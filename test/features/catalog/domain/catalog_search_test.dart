import 'package:alexandria_ui/features/catalog/domain/catalog_search.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
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

  group('matching the file', () {
    test('GivenANameContainingTheTerm_WhenMatched_ThenItMatches', () {
      expect(
        matchesSearch(
          FileDetails(file: aFile(name: 'Deep Blue Sea.md')),
          'blue',
        ),
        isTrue,
      );
    });

    test('GivenADifferentCase_WhenMatched_ThenItStillMatches', () {
      expect(
        matchesSearch(
          FileDetails(file: aFile(name: 'Deep Blue Sea.md')),
          'BLUE',
        ),
        isTrue,
      );
    });

    test('GivenTheTermOnlyInThePath_WhenMatched_ThenItMatches', () {
      expect(
        matchesSearch(
          FileDetails(
            file: aFile(
              name: 'notes01.md',
              path: '/home/owner/ocean/notes01.md',
            ),
          ),
          'ocean',
        ),
        isTrue,
      );
    });

    test('GivenNoOccurrence_WhenMatched_ThenItDoesNotMatch', () {
      expect(
        matchesSearch(
          FileDetails(file: aFile(name: 'Deep Blue Sea.md')),
          'reggae',
        ),
        isFalse,
      );
    });

    test('GivenABlankTerm_WhenMatched_ThenNothingMatches', () {
      // A blank term is not a search that matches everything.
      expect(matchesSearch(FileDetails(file: aFile()), '   '), isFalse);
    });
  });

  group('matching the metadata (FR-CT-06)', () {
    test('GivenATermInTheMetadata_WhenMatched_ThenItMatches', () {
      // The row carries its metadata already — this is what a listing now
      // answers, so an owner searching a film's title finds it.
      expect(
        matchesSearch(
          FileDetails(
            file: aFile(name: 'DISKNAME-01.mkv'),
            metadata: const {'title': 'Solaris'},
          ),
          'solaris',
        ),
        isTrue,
      );
    });

    test(
      'GivenATermMatchingOnlyOneTag_WhenAnUnrelatedFileNameIsSearched_ThenItStillMatches',
      () {
        // The file name shares nothing with the tag, and it still matches:
        // the metadata alone is enough.
        expect(
          matchesSearch(
            FileDetails(
              file: aFile(name: 'DISKNAME-01.mkv'),
              metadata: const {'resolution': 'Widescreen'},
            ),
            'widescreen',
          ),
          isTrue,
        );
      },
    );

    test(
      'GivenNoMetadataValueContainsTheTerm_WhenMatched_ThenItDoesNotMatch',
      () {
        expect(
          matchesSearch(
            FileDetails(
              file: aFile(name: 'DISKNAME-01.mkv'),
              metadata: const {'title': 'Solaris', 'resolution': 'Widescreen'},
            ),
            'reggae',
          ),
          isFalse,
        );
      },
    );
  });

  group('results', () {
    final files = [
      FileDetails(
        file: aFile(uuid: '1', name: 'Deep Blue Sea.md'),
      ),
      FileDetails(
        file: aFile(uuid: '2', name: 'Blue Planet.md'),
      ),
      FileDetails(
        file: aFile(uuid: '3', name: 'Giant Squid.md'),
      ),
      FileDetails(
        file: aFile(uuid: '4', name: 'blue.png', type: FileType.image),
      ),
    ];

    test('GivenATerm_WhenTheCatalogIsSearched_ThenOnlyMatchesAreReturned', () {
      final results = searchResults(files, 'blue');

      expect(results.map((details) => details.file.uuid), ['1', '2', '4']);
    });

    test('GivenATerm_WhenTheCatalogIsSearched_ThenTypesAreNotFilteredOut', () {
      // Across every type at once: the image matches on the same footing.
      expect(
        searchResults(files, 'blue').map((details) => details.file.type),
        contains(FileType.image),
      );
    });

    test('GivenNoMatch_WhenTheCatalogIsSearched_ThenNothingIsReturned', () {
      expect(searchResults(files, 'reggae'), isEmpty);
    });
  });

  group('highlighting (main flow step 3)', () {
    test('GivenTheTermInTheName_WhenItIsHighlighted_ThenTheSpanIsFound', () {
      expect(highlightRange('Deep Blue Sea.md', 'blue'), (start: 5, end: 9));
    });

    test('GivenTheTermIsNotInTheText_WhenHighlighted_ThenThereIsNoSpan', () {
      // Matched on its path rather than its name: there is nothing in the
      // name to mark, and inventing a mark would point at the wrong thing.
      expect(highlightRange('notes01.md', 'ocean'), isNull);
    });

    test('GivenABlankTerm_WhenHighlighted_ThenThereIsNoSpan', () {
      expect(highlightRange('anything', '  '), isNull);
    });
  });
}
