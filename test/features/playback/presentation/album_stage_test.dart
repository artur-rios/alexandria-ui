import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
import 'package:alexandria_ui/features/playback/presentation/media/disc_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/vinyl_painter.dart';
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
      // Every real host wires these up (they are what `MaterialApp` needs to
      // resolve `AppLocalizations.of` at all); a stage test is not exempt
      // just because it is only checking motion.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  /// The medium's own `CustomPaint`, found among the stage's four layers
  /// (device chassis, medium, device foreground, case) by the type of
  /// painter it carries rather than by position — the layer order is an
  /// implementation detail these tests should not have to track.
  VinylPainter vinylPainterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(AlbumStage),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((widget) => widget.painter)
      .whereType<VinylPainter>()
      .single;

  /// [DiscPainter]'s own `CustomPaint`, found the same way [vinylPainterOf]
  /// finds [VinylPainter]'s.
  DiscPainter discPainterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(AlbumStage),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((widget) => widget.painter)
      .whereType<DiscPainter>()
      .single;

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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets(
      'GivenNoInsertionIsOwed_WhenTheStageOpens_ThenNothingIsReportedFinished',
      (tester) async {
        // `_insertion.value = 1` (no insertion owed) drives the controller
        // to `completed` exactly like a real insertion finishing does — the
        // screen must be able to tell the two apart, because Task 6 treats
        // "an insertion finished" as "stop owing one", and a stage that
        // never played one has nothing to stop owing.
        var reported = false;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: MaterialApp(
              theme: ThemeData(extensions: const [AlbumPalette.standard]),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AlbumStage(
                  medium: AlbumMedium.vinyl,
                  isPlaying: true,
                  insert: false,
                  title: 'Airbag',
                  artist: 'Radiohead',
                  album: 'OK Computer',
                  onInserted: () => reported = true,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));

        expect(reported, isFalse);
      },
    );
  });

  group('the spin (main flow steps 4 and 5)', () {
    testWidgets('GivenAPlayingStage_WhenTimePasses_ThenTheMediumHasTurned', (
      tester,
    ) async {
      // `vinylPainterOf` (the file's own helper, already used by the paused
      // test below) rather than `.last` and identity comparison: `.last` is
      // the device's foreground painter, not the medium, and no painter here
      // overrides `==`, so two distinct instances are never `equal` even when
      // both describe a stopped, reset or absent spin — a diff on `.painter`
      // identity can never fail for the reason this test's name claims
      // (Finding 2). Asserting the `turns` value itself actually advanced is
      // what a "the medium has turned" test has to check.
      await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
      await tester.pump(const Duration(milliseconds: 16));
      final first = vinylPainterOf(tester).turns;

      await tester.pump(const Duration(milliseconds: 400));
      final later = vinylPainterOf(tester).turns;

      expect(later, isNot(first));
    });

    testWidgets('GivenAPausedStage_WhenTimePasses_ThenItHoldsWhereItStopped', (
      tester,
    ) async {
      // Mounted playing, not paused, and left to turn for a while first: a
      // test that starts paused never leaves `turns == 0`, so a reset, a
      // reversal, or a spin that never started at all would all produce the
      // same byte-identical goldens this test would then wrongly pass.
      await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
      await tester.pump(const Duration(milliseconds: 400));

      // Pausing through `pumpWidget` — not a fresh mount — is what exercises
      // `didUpdateWidget`'s `stop()`, the same path a real pause takes.
      await tester.pumpWidget(
        staged(medium: AlbumMedium.vinyl, insert: false, isPlaying: false),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // Held, not reset: the record stays where the needle left it. Checked
      // directly, not just by the golden comparison below, so a silent
      // reset to `turns == 0` fails on the value rather than merely risking
      // a golden diff too small for the comparator's tolerance to catch.
      final held = vinylPainterOf(tester).turns;
      expect(held, isNot(0));

      await expectLater(
        find.byType(AlbumStage),
        matchesGoldenFile('goldens/paused.png'),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(vinylPainterOf(tester).turns, held);
      await expectLater(
        find.byType(AlbumStage),
        matchesGoldenFile('goldens/paused.png'),
      );
    }, skip: !goldensAreComparable);

    testWidgets(
      'GivenPausedPlayback_WhenItResumes_ThenTheMotionContinues',
      (tester) async {
        // Restores coverage lost across the branch's test shuffles
        // (Finding 6): resuming from where a pause left off is named in the
        // design's own testing section, and — until this test — nothing in
        // the stage asserted it. Played, paused, then played again, all
        // through `pumpWidget`/`didUpdateWidget`, the same path a real
        // pause-then-resume takes.
        await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
        await tester.pump(const Duration(milliseconds: 400));

        await tester.pumpWidget(
          staged(medium: AlbumMedium.vinyl, insert: false, isPlaying: false),
        );
        await tester.pump(const Duration(milliseconds: 16));
        final atPause = vinylPainterOf(tester).turns;

        // Held while paused — the same assertion the test above makes, kept
        // here too so a resume test that starts from a spin that never
        // actually stopped could not pass this by accident.
        await tester.pump(const Duration(milliseconds: 300));
        expect(vinylPainterOf(tester).turns, atPause);

        await tester.pumpWidget(
          staged(medium: AlbumMedium.vinyl, insert: false, isPlaying: true),
        );
        await tester.pump(const Duration(milliseconds: 400));

        // Continues from where it stopped, not from zero: a reset on resume
        // would still satisfy "the medium has turned", so the value is
        // checked against where the pause left it rather than merely against
        // zero.
        expect(vinylPainterOf(tester).turns, isNot(atPause));
      },
    );

    testWidgets(
      'GivenADisc_WhenItSpins_ThenTheRateComesFromSpinPeriodFor',
      (tester) async {
        // Finding 6: `spinPeriodFor` is the single source of truth for every
        // medium's spin rate — this proves the stage actually reads it
        // rather than keeping its own copy, by pumping exactly one of that
        // function's own periods and checking the spin has returned to the
        // same phase it started at. A hardcoded rate that happened to differ
        // from `spinPeriodFor(AlbumMedium.disc)` would land at a different
        // phase after the same wall-clock wait, which this would catch.
        await tester.pumpWidget(staged(medium: AlbumMedium.disc, insert: false));
        await tester.pump(const Duration(milliseconds: 137));
        final before = discPainterOf(tester).turns;

        await tester.pump(spinPeriodFor(AlbumMedium.disc));
        final after = discPainterOf(tester).turns;

        expect(after, closeTo(before, 1e-9));
      },
    );
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
      },
      skip: !goldensAreComparable,
    );

    // Not golden-gated, unlike the appearance check above: the no-ticker
    // guarantee is a scheduling fact, not a pixel comparison, so it has to
    // run on every platform this suite runs on rather than only the ones
    // `goldensAreComparable` allows.
    testWidgets('GivenReducedMotion_WhenTheStageOpens_ThenNoFrameIsScheduled', (
      tester,
    ) async {
      await tester.pumpWidget(
        staged(medium: AlbumMedium.tape, insert: true, reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // No ticker may be running: a controller repeating under a still
      // medium burns a frame's work every frame for something nobody sees.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
