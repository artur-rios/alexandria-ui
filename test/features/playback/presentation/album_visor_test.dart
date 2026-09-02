import 'dart:ui' as ui;

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/application/album_cover_controller.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_cover.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/album_visor.dart';
import 'package:alexandria_ui/features/playback/presentation/now_playing_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// The album's own cover in the playback bar (UC-21, FR-UX-01).
///
/// What this used to test is gone with the album animation: a record turning
/// in a recess, at the rate a real one turns, holding its angle when paused.
/// The bar shows the sleeve now and nothing else — a drawn record was the
/// same drawing for every album ever played, where the sleeve is the one
/// thing an owner recognises across a room.
void main() {
  final track = aFile(uuid: 'kob-1', name: 'So What.flac');

  AudioPlaybackState playingState() => AudioPlaybackState(
    queue: PlaybackQueue(
      tracks: [track],
      kind: QueueKind.album,
      label: 'Kind of Blue',
    ),
    stage: AudioStage.playing,
    status: const PlaybackStatus(isPlaying: true),
  );

  /// Pumps the real [PlaybackBar] over fixed states for the two providers it
  /// reaches through [AlbumVisor], rather than driving playback through the
  /// whole shell: every rule here is the visor's own, and none of it depends
  /// on a signed-in session or a real catalog.
  Future<void> pumpBar(
    WidgetTester tester, {
    required AudioPlaybackState audio,
    AlbumCover cover = const AlbumCoverDesigned(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlaybackControllerProvider.overrideWith(
            () => _FixedAudioPlaybackController(audio),
          ),
          albumCoverControllerProvider.overrideWith(
            () => _FixedAlbumCoverController(cover),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Align(child: PlaybackBar())),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('GivenAFetchedCover_WhenTheBarIsShown_ThenTheSleeveIsInIt', (
    tester,
  ) async {
    final cover = await aCover();
    addTearDown(cover.dispose);

    await pumpBar(
      tester,
      audio: playingState(),
      cover: AlbumCoverFetched(image: cover),
    );

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(cover));
  });

  testWidgets('GivenNoCover_WhenTheBarIsShown_ThenAPlaceholderStandsIn', (
    tester,
  ) async {
    // Common rather than exceptional: plenty of files carry no embedded
    // picture, and an empty square would read as a bar that failed to draw.
    await pumpBar(tester, audio: playingState());

    expect(find.byType(RawImage), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AlbumVisor),
        matching: find.byIcon(Icons.album_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('GivenNothingPlaying_WhenTheBarIsShown_ThenThereIsNoVisor', (
    tester,
  ) async {
    // An idle bar shows its own placeholder row instead
    // (`playback_bar.dart`'s `current == null` branch).
    await pumpBar(tester, audio: const AudioPlaybackState());

    expect(find.byType(AlbumVisor), findsNothing);
  });

  testWidgets('GivenTheSleeve_WhenItIsPressed_ThenTheFullPlayerOpens', (
    tester,
  ) async {
    // What an owner reaches for: the sleeve they have just recognised, rather
    // than the chevron beside it (UC-21 main flow step 2).
    await pumpBar(tester, audio: playingState());

    await tester.tap(find.byType(AlbumVisor));
    // Bounded pumps, never `pumpAndSettle`: the player that opens carries
    // bars that run for as long as audio does, so nothing in that tree ever
    // settles.
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(NowPlayingScreen), findsOneWidget);
  });

  testWidgets('GivenTheSleeve_WhenTimePasses_ThenNoTickerRunsBehindIt', (
    tester,
  ) async {
    // A sleeve does not move. Nothing here should be scheduling frames for
    // it — which is the whole of what replaced a turning record.
    await pumpBar(tester, audio: playingState());
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

/// An [AudioPlaybackController] answering with a fixed state.
class _FixedAudioPlaybackController extends AudioPlaybackController {
  _FixedAudioPlaybackController(this._state);

  final AudioPlaybackState _state;

  @override
  AudioPlaybackState build() => _state;
}

/// An [AlbumCoverController] holding a fixed cover, so the visor can be shown
/// what a fetched sleeve looks like without a catalog behind it.
class _FixedAlbumCoverController extends AlbumCoverController {
  _FixedAlbumCoverController(this._cover);

  final AlbumCover _cover;

  @override
  AlbumCover build() => _cover;
}

/// A small square image, standing in for an album's own picture.
Future<ui.Image> aCover() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 20, 20),
    Paint()..color = const Color(0xFF3366CC),
  );

  return recorder.endRecording().toImage(20, 20);
}
