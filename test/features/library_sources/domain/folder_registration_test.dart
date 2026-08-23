import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules that decide whether a folder can be registered
/// (FR-LB-02, UC-05 AF-02 … AF-04).
void main() {
  LibrarySource source(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: DateTime.utc(2026, 8, 19),
  );

  group('normalizing a path', () {
    test('GivenABackslashPath_WhenItIsNormalized_ThenItUsesForwardSlashes', () {
      expect(normalizeFolderPath(r'C:\Music\Albums'), 'C:/Music/Albums');
    });

    test('GivenATrailingSeparator_WhenItIsNormalized_ThenItIsDropped', () {
      expect(normalizeFolderPath('/home/owner/music/'), '/home/owner/music');
    });

    test('GivenARoot_WhenItIsNormalized_ThenItKeepsItsSeparator', () {
      expect(normalizeFolderPath('/'), '/');
    });

    test('GivenTwoSpellingsOfAFolder_WhenNormalized_ThenTheyAreEqual', () {
      expect(
        normalizeFolderPath(r'C:\Music\'),
        normalizeFolderPath('C:/Music'),
      );
    });

    test('GivenDifferentCases_WhenNormalized_ThenTheyStayDifferent', () {
      // Deliberate: Linux paths are case-sensitive, and folding case here
      // would merge two genuinely different folders to spare Windows a
      // duplicate the owner would notice immediately.
      expect(
        normalizeFolderPath('/home/owner/Music'),
        isNot(normalizeFolderPath('/home/owner/music')),
      );
    });
  });

  group('the default label', () {
    test('GivenAFolder_WhenItIsRegistered_ThenItsOwnNameIsTheLabel', () {
      expect(defaultLabelFor('/home/owner/music'), 'music');
    });

    test('GivenABackslashPath_WhenItIsRegistered_ThenTheNameIsStillFound', () {
      expect(defaultLabelFor(r'D:\Media\Comics'), 'Comics');
    });

    test('GivenATrailingSeparator_WhenItIsRegistered_ThenTheNameIsFound', () {
      expect(defaultLabelFor('/home/owner/music/'), 'music');
    });

    test('GivenAFilesystemRoot_WhenItIsRegistered_ThenTheLabelIsNotEmpty', () {
      // A blank label would list as an empty row.
      expect(defaultLabelFor('/'), isNotEmpty);
    });
  });

  group('conflicts', () {
    test('GivenNoRegisteredFolders_WhenOneIsChecked_ThenThereIsNoConflict', () {
      expect(conflictingSource('/home/owner/music', const []), isNull);
    });

    test('GivenAnUnrelatedFolder_WhenOneIsChecked_ThenThereIsNoConflict', () {
      expect(
        conflictingSource('/home/owner/music', [source('/home/owner/books')]),
        isNull,
      );
    });

    test('GivenTheSameFolder_WhenItIsChecked_ThenItConflicts', () {
      final existing = source('/home/owner/music');

      expect(conflictingSource('/home/owner/music', [existing]), existing);
    });

    test('GivenTheSameFolderSpeltDifferently_WhenChecked_ThenItConflicts', () {
      final existing = source(r'C:\Music');

      expect(conflictingSource('C:/Music/', [existing]), existing);
    });

    test('GivenAFolderInsideARegisteredOne_WhenChecked_ThenItConflicts', () {
      final existing = source('/home/owner/media');

      expect(
        conflictingSource('/home/owner/media/music', [existing]),
        existing,
      );
    });

    test(
      'GivenAFolderContainingARegisteredOne_WhenChecked_ThenItConflicts',
      () {
        final existing = source('/home/owner/media/music');

        expect(conflictingSource('/home/owner/media', [existing]), existing);
      },
    );

    test(
      'GivenASiblingWithASharedPrefix_WhenChecked_ThenItDoesNotConflict',
      () {
        // The bug this guards: without the separator, "/music" prefixes
        // "/music-videos" and two unrelated folders read as overlapping.
        expect(
          conflictingSource('/home/owner/music-videos', [
            source('/home/owner/music'),
          ]),
          isNull,
        );
      },
    );
  });

  group('the verdict', () {
    test('GivenAMissingFolder_WhenItIsJudged_ThenItIsMissing', () {
      expect(
        verdictFor(
          path: '/nowhere',
          exists: false,
          readable: false,
          registered: const [],
        ),
        FolderRegistrationVerdict.missing,
      );
    });

    test('GivenAMissingFolderAlreadyRegistered_WhenJudged_ThenItIsMissing', () {
      // Existence is checked first: saying "already registered" about a folder
      // that is gone sends the owner after the wrong problem.
      expect(
        verdictFor(
          path: '/home/owner/music',
          exists: false,
          readable: false,
          registered: [source('/home/owner/music')],
        ),
        FolderRegistrationVerdict.missing,
      );
    });

    test('GivenAnUnreadableFolder_WhenItIsJudged_ThenItIsUnreadable', () {
      expect(
        verdictFor(
          path: '/root/private',
          exists: true,
          readable: false,
          registered: const [],
        ),
        FolderRegistrationVerdict.unreadable,
      );
    });

    test('GivenAnAcceptableFolder_WhenItIsJudged_ThenItIsAcceptable', () {
      expect(
        verdictFor(
          path: '/home/owner/music',
          exists: true,
          readable: true,
          registered: const [],
        ),
        FolderRegistrationVerdict.acceptable,
      );
    });

    test('GivenAnAlreadyRegisteredFolder_WhenJudged_ThenItSaysSo', () {
      expect(
        verdictFor(
          path: '/home/owner/music',
          exists: true,
          readable: true,
          registered: [source('/home/owner/music')],
        ),
        FolderRegistrationVerdict.alreadyRegistered,
      );
    });

    test('GivenAnOverlappingFolder_WhenItIsJudged_ThenItOverlaps', () {
      expect(
        verdictFor(
          path: '/home/owner/media/music',
          exists: true,
          readable: true,
          registered: [source('/home/owner/media')],
        ),
        FolderRegistrationVerdict.overlaps,
      );
    });
  });

  group('which verdicts refuse', () {
    test('GivenAnOverlap_WhenItIsJudged_ThenItDoesNotRefuse', () {
      // AF-04 is a warning the owner can accept, not a refusal.
      expect(refuses(FolderRegistrationVerdict.overlaps), isFalse);
    });

    test('GivenAnAcceptableFolder_WhenItIsJudged_ThenItDoesNotRefuse', () {
      expect(refuses(FolderRegistrationVerdict.acceptable), isFalse);
    });

    for (final verdict in [
      FolderRegistrationVerdict.missing,
      FolderRegistrationVerdict.unreadable,
      FolderRegistrationVerdict.alreadyRegistered,
    ]) {
      test('Given${verdict.name}_WhenItIsJudged_ThenItRefuses', () {
        expect(refuses(verdict), isTrue);
      });
    }
  });
}
