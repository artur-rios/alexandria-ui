import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/catalog/presentation/home_dashboard.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/tracking/domain/reading_list.dart';
import 'package:alexandria_ui/features/tracking/domain/watchlist.dart';
import 'package:alexandria_ui/features/viewers/presentation/document_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/fake_reading_list_gateway.dart';
import '../../../support/fake_watchlist_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// The home dashboard (UC-14, FR-CT-11).
void main() {
  /// Signs in, which lands on the dashboard.
  Future<ProviderContainer> openDashboard(
    WidgetTester tester, {
    Map<FileType, CatalogListing>? listings,
    FakeCatalogGateway? gateway,
    FakeIndexGateway? indexGateway,
    Locale? locale,
    List<Watchlist> watchlists = const [],
    List<ReadingList> readingLists = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      // Off, so `establish`'s own unawaited call to `begin()` (FR-LB-21)
      // does not itself start a refresh through a gateway a test here
      // configured for its own scenario, racing the run the test drives.
      settings: InMemorySettingsStore(
        themeMode: themeMode,
        locale: locale,
        rechecksAtStartup: false,
      ),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          gateway ?? FakeCatalogGateway(listings: listings),
        ),
        if (indexGateway != null)
          indexGatewayProvider.overrideWithValue(indexGateway),
        // The folder these tests scan has to be registered, because a run
        // reads its scope from the store and is refused outright when no
        // source answers the path (UC-05). A dashboard showing a run over a
        // folder nobody registered was never a reachable state.
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore([
            LibrarySource(
              path: '/home/owner/music',
              label: 'music',
              registeredAt: DateTime.utc(2026, 8, 19, 10, 30),
            ),
          ]),
        ),
        watchlistGatewayProvider.overrideWithValue(
          FakeWatchlistGateway(watchlists: watchlists),
        ),
        readingListGatewayProvider.overrideWithValue(
          FakeReadingListGateway(readingLists: readingLists),
        ),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    await tester.pumpAndSettle();

    return container;
  }

  /// A library with three documents, added on three different days.
  ///
  /// A non-audio type, deliberately: most of the tests below only need a
  /// stocked catalog, and a document is named by its file name with no
  /// metadata detour — audio's own naming (FR-CT-13) gets its own fixtures
  /// further down, where the distinction is the point.
  Map<FileType, CatalogListing> aLibrary() => {
    FileType.document: loadedDetails([
      aFile(
        uuid: '1',
        name: 'oldest.pdf',
        type: FileType.document,
        indexedAt: DateTime.utc(2026, 1),
      ),
      aFile(
        uuid: '2',
        name: 'newest.pdf',
        type: FileType.document,
        indexedAt: DateTime.utc(2026, 3),
      ),
      aFile(
        uuid: '3',
        name: 'middle.pdf',
        type: FileType.document,
        indexedAt: DateTime.utc(2026, 2),
      ),
    ]),
  };

  group('the main flow', () {
    testWidgets('GivenASignedInOwner_WhenTheShellOpens_ThenItIsTheDashboard', (
      tester,
    ) async {
      // UC-14 main flow step 1, and the reason the panel has a home entry.
      await openDashboard(tester, listings: aLibrary());

      expect(find.byType(HomeDashboard), findsOneWidget);
    });

    testWidgets(
      'GivenAStockedLibrary_WhenTheDashboardOpens_ThenAllSectionsShow',
      (tester) async {
        await openDashboard(tester, listings: aLibrary());
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.text(l10n.dashboardRecent), findsOneWidget);
        expect(find.text(l10n.dashboardInProgress), findsOneWidget);
        expect(find.text(l10n.dashboardCounts), findsOneWidget);
        expect(find.text(l10n.dashboardLastRun), findsOneWidget);
      },
    );

    testWidgets(
      'GivenFilesAddedOnDifferentDays_WhenShown_ThenTheNewestIsFirst',
      (tester) async {
        await openDashboard(tester, listings: aLibrary());

        final titles = tester
            .widgetList<ListTile>(find.byType(ListTile))
            .map((tile) => (tile.title! as Text).data)
            .toList();
        // Newest first, oldest last: the dashboard is a glance at what has
        // just arrived.
        expect(titles, ['newest.pdf', 'middle.pdf', 'oldest.pdf']);
      },
    );

    testWidgets('GivenARecentFile_WhenItIsOpened_ThenTheFileItselfOpens', (
      tester,
    ) async {
      // Main flow step 4: opening from here behaves as opening from a listing,
      // because it is the same call — and a listing row opens the file rather
      // than a dialog about it (`openFile`).
      await openDashboard(tester, listings: aLibrary());

      await tester.tap(find.text('newest.pdf'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewerScreen), findsOneWidget);
      expect(find.byType(FileDetailsView), findsNothing);
    });

    testWidgets(
      'GivenAStockedLibrary_WhenTheCountsShow_ThenEachTypeIsCounted',
      (tester) async {
        await openDashboard(tester, listings: aLibrary());

        expect(find.byType(Chip), findsWidgets);
      },
    );
  });

  group('audio in the recent list (FR-CT-13)', () {
    testWidgets(
      'GivenARecentAudioFile_WhenShown_ThenItsMetadataTitleAppearsNotItsName',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: '1',
            name: 'track01.flac',
            title: 'So What',
            indexedAt: DateTime.utc(2026, 1),
          );

        await openDashboard(tester, gateway: gateway);

        expect(find.text('So What'), findsOneWidget);
        expect(find.text('track01.flac'), findsNothing);
      },
    );

    testWidgets(
      'GivenARecentUntaggedAudioFile_WhenShown_ThenTheUnknownTitleWordAppears',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: '1',
            name: 'track01.flac',
            indexedAt: DateTime.utc(2026, 1),
          );

        await openDashboard(tester, gateway: gateway);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.text(l10n.musicUnknownTitle), findsOneWidget);
        expect(find.text('track01.flac'), findsNothing);
      },
    );

    testWidgets(
      'GivenAMixOfTypes_WhenShown_ThenOnlyTheNonAudioFileIsNamedByItsFile',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: '1',
            name: 'track01.flac',
            title: 'So What',
            indexedAt: DateTime.utc(2026, 1),
          )
          ..addFile(uuid: '2', name: 'itinerary.pdf', type: FileType.document);

        await openDashboard(tester, gateway: gateway);

        expect(find.text('So What'), findsOneWidget);
        expect(find.text('itinerary.pdf'), findsOneWidget);
        expect(find.text('track01.flac'), findsNothing);
      },
    );

    testWidgets(
      'GivenAudioOutsideTheRecentList_WhenTheDashboardShows_ThenItsDetailsAreNeverRead',
      (tester) async {
        // Naming the one audio file the dashboard actually shows reads
        // `musicLibraryProvider`, which is one gateway listing call rather
        // than a per-file `fileDetails` read — proved here by adding audio
        // files old enough to fall outside RecentFilesController.limit and
        // asserting no file's details are ever asked for individually.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'shown',
            name: 'track01.flac',
            title: 'So What',
            indexedAt: DateTime.utc(2026, 1, 10),
          )
          ..addAudio(
            uuid: 'buried-1',
            name: 'old1.flac',
            title: 'Freddie Freeloader',
            indexedAt: DateTime.utc(2020, 1, 1),
          )
          ..addAudio(
            uuid: 'buried-2',
            name: 'old2.flac',
            title: 'Blue in Green',
            indexedAt: DateTime.utc(2019, 1, 1),
          );
        for (var i = 0; i < 8; i++) {
          gateway.addFile(
            uuid: 'doc-$i',
            name: 'doc-$i.pdf',
            type: FileType.document,
            indexedAt: DateTime.utc(2026, 1, 5),
          );
        }

        await openDashboard(tester, gateway: gateway);

        expect(find.text('So What'), findsOneWidget);
        expect(gateway.detailsRequested, isEmpty);
      },
    );
  });

  group('the catalog is empty (AF-01)', () {
    testWidgets('GivenNothingCatalogued_WhenTheDashboardOpens_ThenGuidance', (
      tester,
    ) async {
      await openDashboard(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(find.text(l10n.catalogEmptyFirstRun), findsOneWidget);
      // Four empty sections would be four ways of saying the same thing.
      expect(find.text(l10n.dashboardRecent), findsNothing);

      await tester.tap(find.text(l10n.catalogEmptyAddFolder));
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySourcesScreen), findsOneWidget);
    });
  });

  group('what the owner is part-way through (main flow step 2)', () {
    testWidgets(
      'GivenAVideoBeingWatched_WhenTheDashboardOpens_ThenItIsListed',
      (tester) async {
        await openDashboard(
          tester,
          listings: aLibrary(),
          watchlists: [
            const Watchlist(
              uuid: 'wl-1',
              name: 'Evenings',
              items: [
                WatchProgress(
                  watchlistUuid: 'wl-1',
                  videoUuid: '2',
                  state: WatchState.watching,
                ),
              ],
            ),
          ],
        );

        // The watchlist's name, which only this section renders — the file
        // itself also appears under "recently added".
        expect(find.textContaining('Evenings'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAnItemBeingRead_WhenTheDashboardOpens_ThenItsListIsNamed',
      (tester) async {
        await openDashboard(
          tester,
          listings: aLibrary(),
          readingLists: [
            const ReadingList(
              uuid: 'rl-1',
              name: 'Winter',
              items: [
                ReadingProgress(
                  readingListUuid: 'rl-1',
                  itemUuid: '3',
                  targetKind: ReadingTargetKind.document,
                  state: ReadingState.reading,
                ),
              ],
            ),
          ],
        );

        expect(find.textContaining('Winter'), findsOneWidget);
      },
    );

    testWidgets('GivenAnItemInProgress_WhenItIsOpened_ThenTheDetailsAppear', (
      tester,
    ) async {
      // Main flow step 4: opening from here behaves as opening from a
      // listing, because it is the same view.
      await openDashboard(
        tester,
        listings: aLibrary(),
        watchlists: [
          const Watchlist(
            uuid: 'wl-1',
            name: 'Evenings',
            items: [
              WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: '1',
                state: WatchState.watching,
              ),
            ],
          ),
        ],
      );

      await tester.tap(find.textContaining('Evenings'));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
    });
  });

  group('nothing is in progress (AF-02)', () {
    testWidgets(
      'GivenNoWatchlists_WhenTheDashboardOpens_ThenTheSectionSaysSo',
      (tester) async {
        await openDashboard(tester, listings: aLibrary());
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.text(l10n.dashboardInProgressNone), findsOneWidget);
      },
    );

    testWidgets(
      'GivenEverythingFinished_WhenTheDashboardOpens_ThenNothingIsListed',
      (tester) async {
        // Watched and read are not in progress: the section is what is still
        // open, not what the lists hold.
        await openDashboard(
          tester,
          listings: aLibrary(),
          watchlists: [
            const Watchlist(
              uuid: 'wl-1',
              name: 'Evenings',
              items: [
                WatchProgress(
                  watchlistUuid: 'wl-1',
                  videoUuid: '2',
                  state: WatchState.watched,
                ),
              ],
            ),
          ],
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.text(l10n.dashboardInProgressNone), findsOneWidget);
      },
    );
  });

  group('a section fails (AF-03)', () {
    testWidgets(
      'GivenOneSectionFails_WhenTheDashboardOpens_ThenTheRestRender',
      (tester) async {
        // The catalog query the recent section reads fails, and the counts,
        // in-progress and last-run sections still render.
        await openDashboard(
          tester,
          listings: {
            FileType.audio: const CatalogListing.failed(
              failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
            ),
            FileType.image: loadedDetails([
              aFile(uuid: 'i', name: 'a.png', type: FileType.image),
            ]),
          },
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.text(l10n.dashboardInProgress), findsOneWidget);
        expect(find.text(l10n.dashboardCounts), findsOneWidget);
        expect(find.text(l10n.dashboardLastRun), findsOneWidget);
      },
    );
  });

  group('a run is in flight (AF-04)', () {
    testWidgets('GivenARunning_WhenTheDashboardShowsIt_ThenItSaysSo', (
      tester,
    ) async {
      final indexGateway = FakeIndexGateway()..readOutcomes = [runningRun()];
      final container = await openDashboard(
        tester,
        listings: aLibrary(),
        indexGateway: indexGateway,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.dashboardLastRunNone), findsOneWidget);

      await container
          .read(indexRunsControllerProvider.notifier)
          .startIndex('/home/owner/music');
      await tester.pump();

      expect(find.text(l10n.dashboardLastRunRunning), findsOneWidget);

      // The run is deliberately still going, so the poller is stopped here.
      container.dispose();
    });

    testWidgets('GivenAFinishedRun_WhenTheDashboardShowsIt_ThenItSaysSo', (
      tester,
    ) async {
      final container = await openDashboard(
        tester,
        listings: aLibrary(),
        indexGateway: FakeIndexGateway(),
      );

      await container
          .read(indexRunsControllerProvider.notifier)
          .startIndex('/home/owner/music');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.dashboardLastRunComplete), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheDashboardOpens_ThenItIsLocalized', (
      tester,
    ) async {
      await openDashboard(tester, listings: aLibrary(), locale: locale);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      for (final label in [
        l10n.dashboardRecent,
        l10n.dashboardInProgress,
        l10n.dashboardCounts,
        l10n.dashboardLastRun,
      ]) {
        expect(label, isNot(startsWith('dashboard')));
        expect(find.text(label), findsOneWidget);
      }
    });
  }

  testWidgets('GivenOneTypeFails_WhenTheRecentSectionLoads_ThenItDegrades', (
    tester,
  ) async {
    // A type that cannot be read does not fail the section — it makes the
    // answer partial, which is the behaviour UC-11 established and which this
    // section inherits by reading the same catalog. AF-03 is about a section
    // containing its own failure, and each section has its own AsyncStateView
    // and its own retry; what this asserts is that one bad type does not cost
    // the owner the files that did load.
    await openDashboard(
      tester,
      listings: {
        FileType.audio: const CatalogListing.failed(
          failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
        ),
        FileType.image: loadedDetails([
          aFile(uuid: 'i', name: 'a.png', type: FileType.image),
        ]),
      },
    );

    expect(find.byType(HomeDashboard), findsOneWidget);
    expect(find.text('a.png'), findsOneWidget);
  });
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openDashboard(tester, listings: aLibrary(), themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(HomeDashboard).first),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
