import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/stats/domain/music_stats.dart';
import 'package:alexandria_ui/features/stats/domain/stats_gateway.dart';
import 'package:alexandria_ui/features/stats/presentation/music_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_stats_gateway.dart';
import '../../../support/shell_harness.dart';

/// Reading what has been played most (play history design).
void main() {
  final played = MusicStats(
    totalPlays: 7,
    distinctTracks: 3,
    firstPlayedAt: DateTime.utc(2026, 8),
    lastPlayedAt: DateTime.utc(2026, 9, 3),
    topTracks: [
      TrackPlays(
        fileUuid: 'f-1',
        title: 'So What',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        plays: 4,
        lastPlayedAt: DateTime.utc(2026, 9, 3),
      ),
      TrackPlays(
        fileUuid: 'f-2',
        title: 'untitled.flac',
        plays: 3,
        lastPlayedAt: DateTime.utc(2026, 9, 2),
      ),
    ],
    topArtists: const [ArtistPlays(artist: 'Miles Davis', plays: 4, tracks: 2)],
    topAlbums: const [
      AlbumPlays(album: 'Kind of Blue', artist: 'Miles Davis', plays: 4),
    ],
    topGenres: const [GenrePlays(genre: 'Jazz', plays: 4)],
  );

  Future<({ProviderContainer container, FakeStatsGateway gateway})> openStats(
    WidgetTester tester, {
    FakeStatsGateway? gateway,
  }) async {
    final theGateway = gateway ?? FakeStatsGateway(stats: played);
    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        statsGatewayProvider.overrideWithValue(theGateway),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.musicStatsOpen);
    await tester.pumpAndSettle();

    return (container: container, gateway: theGateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(MusicStatsScreen)));

  testWidgets('GivenTheLibraryMenu_WhenMusicStatsIsChosen_ThenTheScreenOpens', (
    tester,
  ) async {
    // The menu entry is the only way in, so without it the whole feature is
    // unreachable however well it works.
    await openStats(tester);

    expect(find.byType(MusicStatsScreen), findsOneWidget);
  });

  testWidgets('GivenPlays_WhenTheScreenOpens_ThenEveryRankingIsDrawn', (
    tester,
  ) async {
    final opened = await openStats(tester);
    final l10n = messages(tester);

    expect(find.text(l10n.musicStatsSummary(7, 3)), findsOneWidget);
    expect(find.text(l10n.musicStatsTopTracks), findsOneWidget);
    expect(find.text(l10n.musicStatsTopArtists), findsOneWidget);
    expect(find.text(l10n.musicStatsTopAlbums), findsOneWidget);
    expect(find.text(l10n.musicStatsTopGenres), findsOneWidget);
    expect(find.text('So What'), findsOneWidget);
    // The untagged track is in the ranking under its filename, which is the
    // only name it has.
    expect(find.text('untitled.flac'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
    // The row limit the screen draws is the one the core was asked for.
    expect(opened.gateway.limits, [10]);
  });

  testWidgets('GivenNothingPlayed_WhenTheScreenOpens_ThenItSaysWhatCounts', (
    tester,
  ) async {
    // An empty chart after a few skipped tracks is otherwise
    // indistinguishable from a broken one.
    await openStats(tester, gateway: FakeStatsGateway());

    expect(find.text(messages(tester).musicStatsNone), findsOneWidget);
  });

  testWidgets('GivenTheCoreRefuses_WhenTheScreenOpens_ThenItSaysSoWithARetry', (
    tester,
  ) async {
    final gateway = FakeStatsGateway()
      ..readOutcome = const MusicStatsRead.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.play,
          code: 9,
        ),
      );

    await openStats(tester, gateway: gateway);

    // The shell's failure view, not a spinner left turning and not an empty
    // chart that reads as "you have played nothing".
    final l10n = messages(tester);
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('GivenTheScreenIsOpen_WhenReadAgainIsPressed_ThenTheCoreIsAsked', (
    tester,
  ) async {
    final opened = await openStats(tester);

    await tester.tap(find.byTooltip(messages(tester).musicStatsRefresh));
    await tester.pumpAndSettle();

    // The screen does not follow the music while it is open, so this is the
    // only thing that brings a play recorded since into it.
    expect(opened.gateway.limits, [10, 10]);
  });
}
