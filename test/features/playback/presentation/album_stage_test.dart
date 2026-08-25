import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../flutter_test_config.dart';

/// The insertion and the spin (UC-21 main flow, FR-PL-07).
void main() {
  Widget staged({
    required AlbumMedium medium,
    required bool insert,
    bool isPlaying = true,
    bool reduceMotion = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: ThemeData(extensions: const [AlbumPalette.standard]),
      home: Scaffold(
        body: Center(
          child: AlbumStage(
            medium: medium,
            isPlaying: isPlaying,
            insert: insert,
            title: 'Paranoid Android',
            artist: 'Radiohead',
            album: 'OK Computer',
          ),
        ),
      ),
    ),
  );

  group('the insertion (main flow steps 2 and 3)', () {
    testWidgets(
      'GivenAnInsertion_WhenItBegins_ThenTheCaseIsShownAndTheDeviceIsOpen',
      (tester) async {
        await tester.pumpWidget(staged(medium: AlbumMedium.disc, insert: true));
        await tester.pump(const Duration(milliseconds: 700));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/insertion-begins.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    testWidgets(
      'GivenAnInsertion_WhenItFinishes_ThenTheCaseIsGoneAndTheDeviceIsClosed',
      (tester) async {
        await tester.pumpWidget(staged(medium: AlbumMedium.disc, insert: true));
        await tester.pump(const Duration(milliseconds: 4400));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/insertion-ends.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    testWidgets('GivenAnInsertion_WhenItFinishes_ThenItSaysSo', (tester) async {
      // The screen has to know: it is what decides that the next track of
      // the same record does not get another insertion.
      var done = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            theme: ThemeData(extensions: const [AlbumPalette.standard]),
            home: Scaffold(
              body: AlbumStage(
                medium: AlbumMedium.vinyl,
                isPlaying: true,
                insert: true,
                title: 'Airbag',
                artist: 'Radiohead',
                album: 'OK Computer',
                onInserted: () => done = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 4500));

      expect(done, isTrue);
    });

    testWidgets(
      'GivenNoInsertionIsOwed_WhenTheStageOpens_ThenTheMediumIsAlreadySeated',
      (tester) async {
        // Skipping to the next track of a record already on the platter does
        // not take it off and put it back.
        await tester.pumpWidget(
          staged(medium: AlbumMedium.vinyl, insert: false),
        );
        await tester.pump(const Duration(milliseconds: 16));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/seated.png'),
        );
      },
      skip: !goldensAreComparable,
    );
  });

  group('the spin (main flow steps 4 and 5)', () {
    testWidgets('GivenAPlayingStage_WhenTimePasses_ThenTheMediumHasTurned', (
      tester,
    ) async {
      await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
      await tester.pump(const Duration(milliseconds: 16));
      final first = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(AlbumStage),
              matching: find.byType(CustomPaint),
            )
            .last,
      );

      await tester.pump(const Duration(milliseconds: 400));
      final later = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(AlbumStage),
              matching: find.byType(CustomPaint),
            )
            .last,
      );

      expect(later.painter, isNot(equals(first.painter)));
    });

    testWidgets('GivenAPausedStage_WhenTimePasses_ThenItHoldsWhereItStopped', (
      tester,
    ) async {
      // Held, not reset: the record stays where the needle left it.
      await tester.pumpWidget(
        staged(medium: AlbumMedium.vinyl, insert: false, isPlaying: false),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await expectLater(
        find.byType(AlbumStage),
        matchesGoldenFile('goldens/paused.png'),
      );

      await tester.pump(const Duration(milliseconds: 900));

      await expectLater(
        find.byType(AlbumStage),
        matchesGoldenFile('goldens/paused.png'),
      );
    }, skip: !goldensAreComparable);
  });

  group('reduced motion (AF-04)', () {
    testWidgets(
      'GivenReducedMotion_WhenTheStageOpens_ThenTheMediumIsSeatedAndStill',
      (tester) async {
        await tester.pumpWidget(
          staged(medium: AlbumMedium.tape, insert: true, reduceMotion: true),
        );
        await tester.pump(const Duration(milliseconds: 16));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/reduced-motion.png'),
        );

        // No ticker may be running: a controller repeating under a still
        // medium burns a frame's work every frame for something nobody sees.
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
      skip: !goldensAreComparable,
    );
  });
}
