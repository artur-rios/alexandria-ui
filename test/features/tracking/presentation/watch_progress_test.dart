import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/file_details.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/catalog/domain/video_metadata.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_desktop/features/tracking/domain/watchlist.dart';
import 'package:alexandria_desktop/features/tracking/domain/watchlist_gateway.dart';
import 'package:alexandria_desktop/features/tracking/presentation/watchlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_watchlist_gateway.dart';
import '../../../support/shell_harness.dart';

/// Recording how far through something the owner is (UC-30, FR-TR-05 …
/// FR-TR-07).
void main() {
  const seriesUuid = 'series-1';
  const movieUuid = 'movie-1';

  /// A watchlist tracking one series and one film.
  Watchlist evenings({
    WatchState seriesState = WatchState.watching,
    int? currentEpisode = 3,
    int? totalEpisodes = 12,
  }) => Watchlist(
    uuid: 'wl-1',
    name: 'Evenings',
    items: [
      WatchProgress(
        watchlistUuid: 'wl-1',
        videoUuid: seriesUuid,
        state: seriesState,
        currentEpisode: currentEpisode,
        totalEpisodes: totalEpisodes,
      ),
      const WatchProgress(
        watchlistUuid: 'wl-1',
        videoUuid: movieUuid,
        state: WatchState.pending,
      ),
    ],
  );

  /// Signs in, opens the watchlists screen, and expands the one watchlist.
  Future<({ProviderContainer container, FakeWatchlistGateway gateway})>
  openProgress(
    WidgetTester tester, {
    List<Watchlist>? watchlists,
    List<WatchlistWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final series = aFile(
      uuid: seriesUuid,
      name: 'Twin Peaks.mkv',
      type: LibraryType.video,
    );
    final movie = aFile(
      uuid: movieUuid,
      name: 'Stalker.mkv',
      type: LibraryType.video,
    );

    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.video: CatalogListing.loaded(files: [series, movie]),
      },
    );
    catalog.details[seriesUuid] = FileDetailsOutcome.read(
      details: FileDetails(
        file: series,
        metadata: {'mediaKind': MediaKind.series.wireName},
      ),
    );
    catalog.details[movieUuid] = FileDetailsOutcome.read(
      details: FileDetails(
        file: movie,
        metadata: {'mediaKind': MediaKind.movie.wireName},
      ),
    );

    final gateway = FakeWatchlistGateway(watchlists: watchlists ?? [evenings()])
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        watchlistGatewayProvider.overrideWithValue(gateway),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.videos.icon),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.tap(find.text(l10n.watchlistsOpen));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evenings'));
    await tester.pumpAndSettle();

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the progress editor on the item called [name].
  ///
  /// Scoped to the screen: the videos listing behind the dialog shows the same
  /// file names.
  Future<void> openEditorFor(WidgetTester tester, String name) async {
    await tester.tap(
      find.descendant(
        of: find.byType(WatchlistsScreen),
        matching: find.text(name),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeEpisode(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.enterText(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      value,
    );
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(messages(tester).watchProgressSave));
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    // Step 2: each item's state, and where in a series the owner is.
    testWidgets('GivenAWatchlist_WhenItIsOpened_ThenEachItemsStateIsShown', (
      tester,
    ) async {
      await openProgress(tester);

      expect(
        find.descendant(
          of: find.byType(WatchlistsScreen),
          matching: find.text('Twin Peaks.mkv'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(messages(tester).watchStateWatching),
        findsOneWidget,
      );
      expect(
        find.textContaining(messages(tester).watchEpisodeOf(3, 12)),
        findsOneWidget,
      );
    });

    // Step 3.
    testWidgets('GivenAnItem_WhenItsStateIsChanged_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openProgress(tester);

      await openEditorFor(tester, 'Stalker.mkv');
      await tester.tap(find.text(messages(tester).watchStateWatched));
      await tester.pumpAndSettle();
      await save(tester);

      expect(opened.gateway.progressUpdates, hasLength(1));
      expect(opened.gateway.progressUpdates.single.video, movieUuid);
      expect(opened.gateway.progressUpdates.single.state, WatchState.watched);
    });

    // Step 4, for a series.
    testWidgets('GivenASeries_WhenTheEpisodeIsSet_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await typeEpisode(tester, messages(tester).watchCurrentEpisodeLabel, '5');
      await save(tester);

      expect(opened.gateway.progressUpdates.single.currentEpisode, 5);
      expect(opened.gateway.progressUpdates.single.totalEpisodes, 12);
    });

    testWidgets('GivenASavedUpdate_WhenTheCoreStoresIt_ThenTheScreenShowsIt', (
      tester,
    ) async {
      await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await typeEpisode(tester, messages(tester).watchCurrentEpisodeLabel, '5');
      await save(tester);

      expect(
        find.textContaining(messages(tester).watchEpisodeOf(5, 12)),
        findsOneWidget,
      );
    });
  });

  // AF-01: the item is a movie.
  group('a movie', () {
    testWidgets('GivenAMovie_WhenItsProgressIsOpened_ThenNoEpisodeIsOffered', (
      tester,
    ) async {
      await openProgress(tester);

      await openEditorFor(tester, 'Stalker.mkv');

      expect(
        find.text(messages(tester).watchCurrentEpisodeLabel),
        findsNothing,
      );
      expect(find.text(messages(tester).watchStateWatched), findsWidgets);
    });

    testWidgets('GivenASeries_WhenItsProgressIsOpened_ThenEpisodesAreOffered', (
      tester,
    ) async {
      await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');

      expect(
        find.text(messages(tester).watchCurrentEpisodeLabel),
        findsOneWidget,
      );
      expect(
        find.text(messages(tester).watchTotalEpisodesLabel),
        findsOneWidget,
      );
    });

    // An episode number on something nobody marked a series would be this
    // application inventing the marking UC-16 exists to set.
    testWidgets('GivenAMovie_WhenItsStateIsSaved_ThenNoEpisodeIsSent', (
      tester,
    ) async {
      final opened = await openProgress(tester);

      await openEditorFor(tester, 'Stalker.mkv');
      await save(tester);

      expect(opened.gateway.progressUpdates.single.currentEpisode, isNull);
      expect(opened.gateway.progressUpdates.single.totalEpisodes, isNull);
    });
  });

  // AF-02: the episode number is not usable.
  group('an episode the screen refuses', () {
    testWidgets('GivenWordsInsteadOfANumber_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await typeEpisode(
        tester,
        messages(tester).watchCurrentEpisodeLabel,
        'five',
      );
      await save(tester);

      expect(opened.gateway.progressUpdates, isEmpty);
      expect(
        find.text(messages(tester).watchEpisodeNotANumber),
        findsOneWidget,
      );
    });

    testWidgets('GivenAnEpisodePastTheTotal_WhenSaved_ThenItIsMarked', (
      tester,
    ) async {
      final opened = await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await typeEpisode(
        tester,
        messages(tester).watchCurrentEpisodeLabel,
        '99',
      );
      await save(tester);

      expect(opened.gateway.progressUpdates, isEmpty);
      expect(
        find.text(messages(tester).watchEpisodeBeyondTotal),
        findsOneWidget,
      );
    });

    testWidgets('GivenZero_WhenSaved_ThenItIsMarked', (tester) async {
      await openProgress(tester);

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await typeEpisode(tester, messages(tester).watchCurrentEpisodeLabel, '0');
      await save(tester);

      expect(
        find.text(messages(tester).watchEpisodeNotPositive),
        findsOneWidget,
      );
    });
  });

  // AF-03: the core rejects the state as invalid.
  group('a state the core refuses', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheEditorStaysOpen', (
      tester,
    ) async {
      await openProgress(
        tester,
        writeOutcomes: const [
          WatchlistWrite.failed(
            failure: Failure.invalidState(
              family: CoreStatusFamily.watchlist,
              code: WATCHLIST_ERR_INVALID_STATE,
            ),
          ),
        ],
      );

      await openEditorFor(tester, 'Stalker.mkv');
      await tester.tap(find.text(messages(tester).watchStateWatched));
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.text(messages(tester).watchProgressSave), findsOneWidget);
    });

    // The stored progress is unchanged, so the screen still shows it.
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheStoredStateStands', (
      tester,
    ) async {
      await openProgress(
        tester,
        writeOutcomes: const [
          WatchlistWrite.failed(
            failure: Failure.invalidState(
              family: CoreStatusFamily.watchlist,
              code: WATCHLIST_ERR_INVALID_STATE,
            ),
          ),
        ],
      );

      await openEditorFor(tester, 'Stalker.mkv');
      await tester.tap(find.text(messages(tester).watchStateWatched));
      await tester.pumpAndSettle();
      await save(tester);

      expect(
        find.textContaining(messages(tester).watchStatePending),
        findsWidgets,
      );
    });
  });

  // AF-05: the same video in several watchlists.
  group('a video in more than one watchlist', () {
    testWidgets('GivenTwoWatchlists_WhenProgressIsSet_ThenOnlyOneIsTouched', (
      tester,
    ) async {
      final opened = await openProgress(
        tester,
        watchlists: [
          evenings(),
          const Watchlist(
            uuid: 'wl-2',
            name: 'Rewatches',
            items: [
              WatchProgress(
                watchlistUuid: 'wl-2',
                videoUuid: seriesUuid,
                state: WatchState.pending,
              ),
            ],
          ),
        ],
      );

      await openEditorFor(tester, 'Twin Peaks.mkv');
      await tester.tap(find.text(messages(tester).watchStateWatched));
      await tester.pumpAndSettle();
      await save(tester);

      // The update names the watchlist it belongs to, so the other list's
      // progress is untouched.
      expect(opened.gateway.progressUpdates.single.watchlist, 'wl-1');
      expect(
        opened.gateway.watchlists
            .firstWhere((watchlist) => watchlist.uuid == 'wl-2')
            .progressFor(seriesUuid)
            ?.state,
        WatchState.pending,
      );
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenProgressIsEdited_ThenItRendersInThatBrightness',
        (tester) async {
          await openProgress(tester, themeMode: themeMode);
          await openEditorFor(tester, 'Twin Peaks.mkv');

          expect(
            Theme.of(
              tester.element(find.text(messages(tester).watchProgressSave)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenProgressIsEdited_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openProgress(tester, locale: locale);
          await openEditorFor(tester, 'Twin Peaks.mkv');
          await typeEpisode(
            tester,
            messages(tester).watchCurrentEpisodeLabel,
            '0',
          );
          await save(tester);

          expect(
            find.textContaining(RegExp('watch[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
