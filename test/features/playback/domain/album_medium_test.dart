import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the mode the owner chose (FR-PL-11)', () {
    test('GivenTheByYearMode_WhenAMediumIsPicked_ThenTheYearDecides', () {
      // The rule that already exists, now reached through the mode rather
      // than called directly.
      expect(mediumFor(AlbumAnimationMode.byYear, 1971), AlbumMedium.vinyl);
      expect(mediumFor(AlbumAnimationMode.byYear, 1988), AlbumMedium.tape);
      expect(mediumFor(AlbumAnimationMode.byYear, 2001), AlbumMedium.disc);
    });

    test('GivenAPinnedMode_WhenAMediumIsPicked_ThenTheYearIsIgnored', () {
      // The point of pinning: an owner who wants records wants records, and
      // the album's year is not an argument against that.
      expect(mediumFor(AlbumAnimationMode.vinyl, 2001), AlbumMedium.vinyl);
      expect(mediumFor(AlbumAnimationMode.tape, 1971), AlbumMedium.tape);
      expect(mediumFor(AlbumAnimationMode.disc, 1971), AlbumMedium.disc);
    });

    test('GivenTheOffMode_WhenAMediumIsPicked_ThenThereIsNone', () {
      expect(mediumFor(AlbumAnimationMode.off, 1971), isNull);
    });

    test('GivenNoYear_WhenTheModeIsByYear_ThenItIsADisc', () {
      // Unchanged from `mediumForYear`: the medium a file most likely came
      // from, and the one an owner is least likely to find surprising.
      expect(mediumFor(AlbumAnimationMode.byYear, null), AlbumMedium.disc);
    });
  });

  group('the spin rate (Finding 6)', () {
    // `spinPeriodFor` had no test of its own: `AlbumStage` (Task 5) and
    // `AlbumVisor` (Task 8) both draw from it rather than keeping their own
    // copy of these numbers specifically so the two could never drift apart —
    // pinned here as the single source of truth those two widgets' own tests
    // (`album_stage_test.dart`, `album_visor_test.dart`) assume holds.
    test('GivenARecord_WhenTheSpinRateIsRead_ThenItIsOneAndAHalfSeconds', () {
      expect(
        spinPeriodFor(AlbumMedium.vinyl),
        const Duration(milliseconds: 1500),
      );
    });

    test(
      'GivenADisc_WhenTheSpinRateIsRead_ThenItIsNineHundredMilliseconds',
      () {
        expect(
          spinPeriodFor(AlbumMedium.disc),
          const Duration(milliseconds: 900),
        );
      },
    );

    test(
      'GivenACassette_WhenTheSpinRateIsRead_ThenItIsOnePointEightSeconds',
      () {
        expect(
          spinPeriodFor(AlbumMedium.tape),
          const Duration(milliseconds: 1800),
        );
      },
    );
  });
}
