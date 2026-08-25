import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/application/album_animation_controller.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/album_visor.dart';
import 'package:alexandria_ui/features/playback/presentation/media/vinyl_painter.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
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
