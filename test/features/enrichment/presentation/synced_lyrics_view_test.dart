import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/enrichment/domain/synced_lyrics.dart';
import 'package:alexandria_ui/features/enrichment/presentation/synced_lyrics_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// Lyrics following the music (music enrichment design).
void main() {
  final lyrics = SyncedLyrics(
    parseLrc(
      '[00:10.00]first line\n'
      '[00:20.00]second line\n'
      '[00:30.00]third line',
    ),
  );

  /// Pumps the view over a real playback controller, and returns a way to
  /// move the engine's position — which is what the highlight follows.
  Future<Future<void> Function(Duration)> pumpLyrics(
    WidgetTester tester, {
    SyncedLyrics? subject,
  }) async {
    final player = FakeMediaPlayer();
    final container = ProviderContainer(
      overrides: <Override>[
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        audioPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: SyncedLyricsView(lyrics: subject ?? lyrics),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The controller has to be playing something for its status to move.
    await container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'track-1'));
    await tester.pumpAndSettle();

    return (Duration at) async {
      player.reportPosition(at);
      await tester.pumpAndSettle();
    };
  }

  /// The style the line with [text] is currently drawn in.
  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style ??
      DefaultTextStyle.of(tester.element(find.text(text))).style;

  testWidgets('GivenLyrics_WhenShown_ThenEveryLineIsReadable', (tester) async {
    // Dimmed, not hidden: reading ahead is half of what lyrics on screen are
    // for.
    await pumpLyrics(tester);

    expect(find.text('first line'), findsOneWidget);
    expect(find.text('second line'), findsOneWidget);
    expect(find.text('third line'), findsOneWidget);
  });

  testWidgets('GivenThePositionReachesALine_WhenItDoes_ThenThatLineStandsOut', (
    tester,
  ) async {
    final seek = await pumpLyrics(tester);

    await seek(const Duration(seconds: 21));

    // The active line is the one drawn in the emphasised style — asserted
    // through the colour the dimmed lines carry and the active one does not.
    final active = styleOf(tester, 'second line');
    final inactive = styleOf(tester, 'third line');
    expect(
      active.color,
      isNot(equals(inactive.color)),
      reason: 'the sung line looked the same as the ones around it',
    );
  });

  testWidgets('GivenAPositionBetweenCues_WhenItIs_ThenTheLastPassedIsLit', (
    tester,
  ) async {
    // Never the nearest: the next line has not been sung yet.
    final seek = await pumpLyrics(tester);

    await seek(const Duration(seconds: 29));

    expect(
      styleOf(tester, 'second line').color,
      isNot(equals(styleOf(tester, 'first line').color)),
    );
  });

  testWidgets('GivenTheTrackIsBeforeTheFirstCue_WhenShown_ThenNothingIsLit', (
    tester,
  ) async {
    // A long intro has nothing to highlight, and lighting the opening line
    // through all of it would be wrong.
    final seek = await pumpLyrics(tester);

    await seek(const Duration(seconds: 2));

    final first = styleOf(tester, 'first line');
    final second = styleOf(tester, 'second line');
    expect(first.color, equals(second.color));
  });

  testWidgets('GivenASeekBackwards_WhenItHappens_ThenTheHighlightFollows', (
    tester,
  ) async {
    // Scrubbing is the case a forward-only implementation gets wrong.
    final seek = await pumpLyrics(tester);
    await seek(const Duration(seconds: 31));
    await seek(const Duration(seconds: 11));

    expect(
      styleOf(tester, 'first line').color,
      isNot(equals(styleOf(tester, 'second line').color)),
    );
  });

  testWidgets('GivenATimedGap_WhenShown_ThenItDrawsNoEmptyLine', (
    tester,
  ) async {
    // An instrumental break occupies its moment — that is what stops the
    // previous line staying lit through a solo — but there is nothing to
    // draw for it.
    final subject = SyncedLyrics(
      parseLrc('[00:10.00]a line\n[00:20.00]\n[00:40.00]after'),
    );
    await pumpLyrics(tester, subject: subject);

    expect(find.text(''), findsNothing);
  });

  testWidgets('GivenTheOwnerScrolls_WhenTheLineChanges_ThenItDoesNotYankBack', (
    tester,
  ) async {
    // Reading ahead is the obvious thing to do, and a view that dragged them
    // back mid-sentence would make it impossible. The assertion is that the
    // scroll position the owner chose survives a line change.
    final many = SyncedLyrics(
      parseLrc(
        List.generate(
          40,
          (i) => '[00:${i.toString().padLeft(2, '0')}.00]line $i',
        ).join('\n'),
      ),
    );
    final seek = await pumpLyrics(tester, subject: many);
    await seek(const Duration(seconds: 1));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    final chosen = tester
        .widget<Scrollable>(find.byType(Scrollable))
        .controller!
        .offset;

    await seek(const Duration(seconds: 2));
    expect(
      tester.widget<Scrollable>(find.byType(Scrollable)).controller!.offset,
      chosen,
      reason: 'the view scrolled away from where the owner had scrolled to',
    );
  });
}
