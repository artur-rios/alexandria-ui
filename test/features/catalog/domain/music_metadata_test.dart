import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local validation and the patch shape (UC-15, FR-ME-01, FR-ME-03).
void main() {
  group('the patch the core takes', () {
    test('GivenAFullRecord_WhenPatched_ThenEveryFieldIsSentWithTheTypeTag', () {
      const metadata = MusicMetadata(
        title: 'So What',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        year: 1959,
        genre: 'Jazz',
        track: 1,
      );

      expect(metadata.toPatch(), {
        // The tag the core checks the file's own subtype against.
        'type': 'audio',
        'title': 'So What',
        'artist': 'Miles Davis',
        'album': 'Kind of Blue',
        'year': 1959,
        'genre': 'Jazz',
        'track': 1,
      });
    });

    test('GivenAClearedField_WhenPatched_ThenItIsAbsentRatherThanEmpty', () {
      // The core's patch is a full replace: a field the body leaves out is
      // written as NULL. Sending an empty string would store an empty string,
      // which is not the same as clearing it.
      const metadata = MusicMetadata(title: 'So What');

      expect(metadata.toPatch(), {'type': 'audio', 'title': 'So What'});
    });
  });

  group('reading what the core reported', () {
    test('GivenADetailMetadataMap_WhenRead_ThenTheNumbersAreParsed', () {
      final metadata = MusicMetadata.fromDetails(const {
        'title': 'So What',
        'year': '1959',
        'track': '1',
      });

      expect(metadata.year, 1959);
      expect(metadata.track, 1);
      expect(metadata.artist, isNull);
    });
  });

  group('local validation (AF-01)', () {
    MusicDraft draftWith(MusicField field, String value) => {
      ...draftFrom(const MusicMetadata()),
      field: value,
    };

    test('GivenAValidRecord_WhenValidated_ThenNothingIsMarked', () {
      expect(
        validateDraft(draftFrom(const MusicMetadata(year: 1959, track: 1))),
        isEmpty,
      );
    });

    test('GivenEveryFieldBlank_WhenValidated_ThenNothingIsMarked', () {
      // Blank is how a field is cleared, not an error.
      expect(validateDraft(draftFrom(const MusicMetadata())), isEmpty);
    });

    test('GivenAYearThatIsNotANumber_WhenValidated_ThenItIsMarked', () {
      expect(validateDraft(draftWith(MusicField.year, 'nineteen')), {
        MusicField.year: MusicFieldError.notANumber,
      });
    });

    test('GivenAYearBeforeRecordedSound_WhenValidated_ThenItIsMarked', () {
      expect(validateDraft(draftWith(MusicField.year, '195')), {
        MusicField.year: MusicFieldError.yearOutOfRange,
      });
    });

    test('GivenATrackOfZero_WhenValidated_ThenItIsMarked', () {
      expect(validateDraft(draftWith(MusicField.track, '0')), {
        MusicField.track: MusicFieldError.trackNotPositive,
      });
    });

    test('GivenAnOverlongTitle_WhenValidated_ThenItIsMarked', () {
      expect(validateDraft(draftWith(MusicField.title, 'a' * 300)), {
        MusicField.title: MusicFieldError.tooLong,
      });
    });

    test('GivenTwoBadFields_WhenValidated_ThenBothAreMarked', () {
      // Every field is checked rather than stopping at the first, so the owner
      // sees everything to fix at once.
      final draft = {
        ...draftFrom(const MusicMetadata()),
        MusicField.year: 'nineteen',
        MusicField.track: '-2',
      };

      expect(validateDraft(draft).keys, {MusicField.year, MusicField.track});
    });
  });

  group('the metadata a draft becomes', () {
    test('GivenPaddedText_WhenParsed_ThenItIsTrimmed', () {
      final draft = {
        ...draftFrom(const MusicMetadata()),
        MusicField.title: '  So What  ',
      };

      expect(metadataFrom(draft).title, 'So What');
    });

    test('GivenABlankField_WhenParsed_ThenItIsNullRatherThanEmpty', () {
      final draft = {
        ...draftFrom(const MusicMetadata(title: 'So What')),
        MusicField.title: '   ',
      };

      expect(metadataFrom(draft).title, isNull);
    });

    test('GivenARoundTrip_WhenParsed_ThenItEqualsWhatItStartedAs', () {
      // What AF-04 compares against: a draft nobody touched must parse back to
      // exactly what the file held, or every open would look like a change.
      const original = MusicMetadata(
        title: 'So What',
        artist: 'Miles Davis',
        year: 1959,
        track: 1,
      );

      expect(metadataFrom(draftFrom(original)), original);
    });
  });
}
