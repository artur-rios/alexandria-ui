import 'package:alexandria_desktop/features/catalog/domain/video_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// A video file's editable metadata (UC-16, FR-ME-02, FR-ME-03).
void main() {
  group('reading what the core holds', () {
    test('GivenTheCoresMetadata_WhenItIsRead_ThenEveryFieldIsCarriedOver', () {
      final metadata = VideoMetadata.fromDetails(const {
        'title': 'Stalker',
        'year': '1979',
        'resolution': '1920x1080',
        'mediaKind': 'movie',
      });

      expect(metadata.title, 'Stalker');
      expect(metadata.year, 1979);
      expect(metadata.resolution, '1920x1080');
      expect(metadata.mediaKind, MediaKind.movie);
    });

    test(
      'GivenAMarkingTheApplicationDoesNotKnow_WhenItIsRead_ThenItIsAbsent',
      () {
        final metadata = VideoMetadata.fromDetails(const {
          'mediaKind': 'documentary',
        });

        expect(metadata.mediaKind, isNull);
      },
    );

    test('GivenNoMetadata_WhenItIsRead_ThenEveryFieldIsEmpty', () {
      expect(VideoMetadata.fromDetails(const {}), const VideoMetadata());
    });
  });

  group('the patch the core takes', () {
    test('GivenAFullRecord_WhenItIsSent_ThenItIsTaggedAsVideo', () {
      expect(const VideoMetadata().toPatch()['type'], 'video');
    });

    test('GivenAMarking_WhenItIsSent_ThenItGoesAsTheCoresOwnName', () {
      const metadata = VideoMetadata(mediaKind: MediaKind.series);

      expect(metadata.toPatch()['mediaKind'], 'series');
    });

    // A field the body omits is written as NULL, which is how it is cleared.
    test('GivenAClearedField_WhenItIsSent_ThenItIsLeftOut', () {
      const metadata = VideoMetadata(title: 'Solaris');

      expect(metadata.toPatch().containsKey('year'), isFalse);
      expect(metadata.toPatch().containsKey('resolution'), isFalse);
    });
  });

  // AF-01: local validation, before the core is called.
  group('validation', () {
    VideoDraft draftWith(VideoField field, String value) => {
      ...draftFromVideo(const VideoMetadata()),
      field: value,
    };

    test('GivenAnEmptyDraft_WhenItIsValidated_ThenNothingIsWrong', () {
      expect(
        validateVideoDraft(draftFromVideo(const VideoMetadata())),
        isEmpty,
      );
    });

    test('GivenAYearThatIsNotANumber_WhenItIsValidated_ThenItIsMarked', () {
      expect(
        validateVideoDraft(
          draftWith(VideoField.year, 'nineteen'),
        )[VideoField.year],
        VideoFieldError.notANumber,
      );
    });

    test('GivenAYearBeforeFilmExisted_WhenItIsValidated_ThenItIsMarked', () {
      expect(
        validateVideoDraft(draftWith(VideoField.year, '204'))[VideoField.year],
        VideoFieldError.yearOutOfRange,
      );
    });

    test('GivenTheEarliestYear_WhenItIsValidated_ThenItIsAccepted', () {
      expect(
        validateVideoDraft(draftWith(VideoField.year, '$earliestVideoYear')),
        isEmpty,
      );
    });

    test('GivenATitleTooLongForTheCore_WhenItIsValidated_ThenItIsMarked', () {
      final tooLong = 'x' * (maxVideoFieldLength + 1);

      expect(
        validateVideoDraft(
          draftWith(VideoField.title, tooLong),
        )[VideoField.title],
        VideoFieldError.tooLong,
      );
    });

    // Every field is checked, so the owner sees everything to fix at once.
    test('GivenTwoBadFields_WhenItIsValidated_ThenBothAreMarked', () {
      final draft = {
        ...draftFromVideo(const VideoMetadata()),
        VideoField.year: 'soon',
        VideoField.resolution: 'x' * (maxVideoFieldLength + 1),
      };

      expect(validateVideoDraft(draft), hasLength(2));
    });

    // The marking is picked from two options, so there is nothing about it
    // left to be wrong.
    test('GivenAPickedMarking_WhenItIsValidated_ThenNothingIsWrong', () {
      expect(
        validateVideoDraft(draftWith(VideoField.mediaKind, 'series')),
        isEmpty,
      );
    });
  });

  group('reading a draft back', () {
    test('GivenADraft_WhenItIsRead_ThenItIsTheMetadataItDescribes', () {
      const metadata = VideoMetadata(
        title: 'Andrei Rublev',
        year: 1966,
        resolution: '1280x720',
        mediaKind: MediaKind.movie,
      );

      expect(videoMetadataFrom(draftFromVideo(metadata)), metadata);
    });

    test('GivenABlankedField_WhenItIsRead_ThenItIsNull', () {
      final draft = {
        ...draftFromVideo(const VideoMetadata(title: 'Mirror')),
        VideoField.title: '   ',
      };

      expect(videoMetadataFrom(draft).title, isNull);
    });
  });
}
