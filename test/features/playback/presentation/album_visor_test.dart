import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/application/album_animation_controller.dart';
import 'package:alexandria_ui/features/playback/application/album_cover_controller.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_cover.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/album_visor.dart';
import 'package:alexandria_ui/features/playback/presentation/media/disc_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/vinyl_painter.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../flutter_test_config.dart';

/// The recessed window in the playback bar (UC-21, FR-PL-07, Task 8).
void main() {
  final track = aFile(uuid: 'kob-1', name: 'So What.flac');

  AudioPlaybackState playingState({bool isPlaying = true}) => AudioPlaybackState(
    queue: PlaybackQueue(
      tracks: [track],
      kind: QueueKind.album,
      label: 'Kind of Blue',
    ),
    stage: AudioStage.playing,
    status: PlaybackStatus(isPlaying: isPlaying),
  );

  /// Pumps the real [PlaybackBar] over fixed, hand-built states for the two
  /// providers it consumes through [AlbumVisor] — the same seam
  /// `background_activity_strip_test.dart` uses for `ActiveRunsController`,
  /// rather than driving playback through the whole shell: every rule here is
  /// the visor's own, and nothing about it depends on a signed-in session or
  /// a real catalog.
  Future<_Fixtures> pumpBar(
    WidgetTester tester, {
    required AudioPlaybackState audio,
    AlbumMedium? medium,
    bool reduceMotion = false,
    AlbumCover cover = const AlbumCoverDesigned(),
  }) async {
    final audioController = _FixedAudioPlaybackController(audio);
    final animationController = _FixedAlbumAnimationController(
      AlbumAnimationState(medium: medium),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlaybackControllerProvider.overrideWith(() => audioController),
          albumAnimationControllerProvider.overrideWith(
            () => animationController,
          ),
          albumCoverControllerProvider.overrideWith(
            () => _FixedAlbumCoverController(cover),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: MaterialApp(
            theme: ThemeData(extensions: const [AlbumPalette.standard]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Align(child: PlaybackBar())),
          ),
        ),
      ),
    );
    await tester.pump();

    return _Fixtures(audio: audioController, animation: animationController);
  }

  /// The medium's own `CustomPaint`, found among the visor's layers by the
  /// type of painter it carries rather than by position — mirrors
  /// `album_stage_test.dart`'s `vinylPainterOf`.
  VinylPainter vinylPainterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(AlbumVisor),
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
          of: find.byType(AlbumVisor),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((widget) => widget.painter)
      .whereType<DiscPainter>()
      .single;

  testWidgets(
    'GivenSomethingPlaying_WhenTheBarIsShown_ThenTheVisorShowsItsMedium',
    (tester) async {
      await pumpBar(
        tester,
        audio: playingState(),
        medium: AlbumMedium.vinyl,
      );

      expect(find.byType(AlbumVisor), findsOneWidget);
      expect(vinylPainterOf(tester), isNotNull);
    },
  );

  testWidgets('GivenTheAnimationIsOff_WhenTheBarIsShown_ThenThereIsNoVisor', (
    tester,
  ) async {
    // `medium: null` is exactly what `AlbumAnimationController` reports for
    // `AlbumAnimationMode.off` — there is no separate "on but hidden" state
    // for this test to have to fake.
    await pumpBar(tester, audio: playingState(), medium: null);

    // `AlbumVisor` is always in the bar's widget tree — it decides for
    // itself, on every rebuild, whether there is anything to draw — so
    // "no visor" is checked as "renders nothing" rather than "is absent".
    expect(find.byType(AlbumVisor), findsOneWidget);
    expect(tester.getSize(find.byType(AlbumVisor)), Size.zero);
  });

  testWidgets('GivenNothingPlaying_WhenTheBarIsShown_ThenThereIsNoVisor', (
    tester,
  ) async {
    // The mode is on, but nothing is queued — `current` is `null`. Unlike
    // the "animation off" case above, the bar itself does not even mount
    // `AlbumVisor` here: an idle bar shows its own placeholder row instead
    // (`playback_bar.dart`'s `current == null` branch), which is a second,
    // independent way for "there is no visor" to hold.
    await pumpBar(
      tester,
      audio: const AudioPlaybackState(),
      medium: AlbumMedium.vinyl,
    );

    expect(find.byType(AlbumVisor), findsNothing);
  });

  testWidgets(
    'GivenAPausedTrack_WhenTimePasses_ThenTheVisorHoldsWhereItStopped',
    (tester) async {
      // Mounted playing, not paused, and left to turn for a while first —
      // exactly `album_stage_test.dart`'s own reasoning: a test that starts
      // paused never leaves `turns == 0`, so a reset, a reversal, or a spin
      // that never started at all would all pass this test by accident.
      final fixtures = await pumpBar(
        tester,
        audio: playingState(),
        medium: AlbumMedium.vinyl,
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Pausing by pushing a new state through the provider — not a fresh
      // mount — is what exercises the visor's `ref.listen` path, the same
      // path a real pause takes.
      fixtures.audio.seed(playingState(isPlaying: false));
      await tester.pump(const Duration(milliseconds: 16));

      // Held, not reset: checked directly, not only by the golden below, so
      // a silent reset to `turns == 0` fails on the value rather than merely
      // risking a golden diff too small for the comparator's tolerance to
      // catch.
      final held = vinylPainterOf(tester).turns;
      expect(held, isNot(0));

      await expectLater(
        find.byType(AlbumVisor),
        matchesGoldenFile('goldens/visor-paused.png'),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(vinylPainterOf(tester).turns, held);
      await expectLater(
        find.byType(AlbumVisor),
        matchesGoldenFile('goldens/visor-paused.png'),
      );
    },
    skip: !goldensAreComparable,
  );

  testWidgets(
    'GivenPausedPlayback_WhenItResumes_ThenTheMotionContinues',
    (tester) async {
      // Restores coverage lost across the branch's test shuffles
      // (Finding 6) — the visor's own version of the same pause-then-resume
      // check `album_stage_test.dart` makes for `AlbumStage`.
      final fixtures = await pumpBar(
        tester,
        audio: playingState(),
        medium: AlbumMedium.vinyl,
      );
      await tester.pump(const Duration(milliseconds: 400));

      fixtures.audio.seed(playingState(isPlaying: false));
      await tester.pump(const Duration(milliseconds: 16));
      final atPause = vinylPainterOf(tester).turns;

      await tester.pump(const Duration(milliseconds: 300));
      expect(vinylPainterOf(tester).turns, atPause);

      fixtures.audio.seed(playingState());
      // `repeat()`'s ticker sets its own start time on the *first* frame it
      // ticks in, so the pump that first observes the resumed state has to
      // land before the pump that measures real elapsed time against it —
      // otherwise the first tick after `repeat()` would read as zero elapsed,
      // same as `AlbumStage`'s own resume test relies on `pumpWidget` for.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 400));

      expect(vinylPainterOf(tester).turns, isNot(atPause));
    },
  );

  testWidgets(
    'GivenADisc_WhenItSpins_ThenTheRateComesFromSpinPeriodFor',
    (tester) async {
      // Finding 6: the visor's own version of `album_stage_test.dart`'s spin
      // rate check — both widgets have to read `spinPeriodFor` rather than
      // keep their own copy of these numbers.
      await pumpBar(
        tester,
        audio: playingState(),
        medium: AlbumMedium.disc,
      );
      await tester.pump(const Duration(milliseconds: 137));
      final before = discPainterOf(tester).turns;

      await tester.pump(spinPeriodFor(AlbumMedium.disc));
      final after = discPainterOf(tester).turns;

      expect(after, closeTo(before, 1e-9));
    },
  );

  group('the album\'s own cover (UC-21, FR-UX-01)', () {
    testWidgets(
      'GivenAFetchedCover_WhenTheBarIsShown_ThenTheSleeveIsInTheRecess',
      (tester) async {
        // What the owner asked for, and what a bar on screen all session is
        // actually good for: a spinning disc is the same drawing for every
        // album ever played, where the sleeve says which record is on.
        final cover = await aCover();
        addTearDown(cover.dispose);

        await pumpBar(
          tester,
          audio: playingState(),
          medium: AlbumMedium.disc,
          cover: AlbumCoverFetched(image: cover),
        );

        expect(
          tester.widget<RawImage>(find.byType(RawImage)).image,
          same(cover),
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter is DiscPainter,
          ),
          findsNothing,
          reason: 'the medium is the fallback, not a layer under the picture',
        );
      },
    );

    testWidgets(
      'GivenNoCover_WhenTheBarIsShown_ThenTheMediumTurnsAsBefore',
      (tester) async {
        // Common rather than exceptional: plenty of files carry no embedded
        // picture, and a bar that showed an empty recess for them would be
        // worse than the disc it used to show for everything.
        await pumpBar(
          tester,
          audio: playingState(),
          medium: AlbumMedium.disc,
        );

        expect(find.byType(RawImage), findsNothing);
        expect(discPainterOf(tester), isNotNull);
      },
    );

    testWidgets(
      'GivenAFetchedCover_WhenTimePasses_ThenNoTickerRunsBehindIt',
      (tester) async {
        // A photograph does not turn, so nothing should be scheduling frames
        // for it — the same waste the reduced-motion case avoids.
        final cover = await aCover();
        addTearDown(cover.dispose);

        await pumpBar(
          tester,
          audio: playingState(),
          medium: AlbumMedium.disc,
          cover: AlbumCoverFetched(image: cover),
        );
        await tester.pump(const Duration(milliseconds: 16));

        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );
  });

  testWidgets('GivenReducedMotion_WhenTheVisorIsShown_ThenItIsStill', (
    tester,
  ) async {
    await pumpBar(
      tester,
      audio: playingState(),
      medium: AlbumMedium.tape,
      reduceMotion: true,
    );
    await tester.pump(const Duration(milliseconds: 16));

    // No ticker may be running: a controller repeating under a still medium
    // burns a frame's work every frame for something nobody sees.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

/// The two fixed controllers a test built with [pumpBar] can still reach.
class _Fixtures {
  const _Fixtures({required this.audio, required this.animation});

  final _FixedAudioPlaybackController audio;
  final _FixedAlbumAnimationController animation;
}

/// An [AudioPlaybackController] that answers with a fixed state, and can be
/// re-seeded to push a new one through the provider the way a real change in
/// playback would — mirrors `RecordingActiveRunsController` in
/// `background_activity_strip_test.dart`.
class _FixedAudioPlaybackController extends AudioPlaybackController {
  _FixedAudioPlaybackController(this._state);

  AudioPlaybackState _state;
  bool _built = false;

  @override
  AudioPlaybackState build() {
    _built = true;
    return _state;
  }

  /// Replaces the state, and — once mounted — publishes it the way the real
  /// controller's own state assignments do.
  void seed(AudioPlaybackState next) {
    _state = next;
    if (_built) state = next;
  }
}

/// An [AlbumAnimationController] that answers with a fixed state.
class _FixedAlbumAnimationController extends AlbumAnimationController {
  _FixedAlbumAnimationController(this._state);

  final AlbumAnimationState _state;

  @override
  AlbumAnimationState build() => _state;
}

/// An [AlbumCoverController] holding a fixed cover, so the visor can be shown
/// what a fetched sleeve looks like without a catalog behind it.
class _FixedAlbumCoverController extends AlbumCoverController {
  _FixedAlbumCoverController(this._cover);

  final AlbumCover _cover;

  @override
  AlbumCover build() => _cover;
}

/// A small square image, standing in for an album's own picture — the same
/// stand-in `album_stage_test.dart` builds for the case.
Future<ui.Image> aCover() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 20, 20),
    Paint()..color = const Color(0xFF808080),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(20, 20);
  } finally {
    picture.dispose();
  }
}
