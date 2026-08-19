import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_desktop/features/catalog/presentation/home_dashboard.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/shell_harness.dart';

/// The home dashboard (UC-14, FR-CT-11).
void main() {
  /// Signs in, which lands on the dashboard.
  Future<ProviderContainer> openDashboard(
    WidgetTester tester, {
    Map<LibraryType, CatalogListing>? listings,
    FakeIndexGateway? indexGateway,
    Locale? locale,
  }) async {
    final container = await tester.pumpShell(
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(listings: listings),
        ),
        if (indexGateway != null)
          indexGatewayProvider.overrideWithValue(indexGateway),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    await tester.pumpAndSettle();

    return container;
  }

  /// A library with three audio files, added on three different days.
  Map<LibraryType, CatalogListing> aLibrary() => {
    LibraryType.audio: CatalogListing.loaded(
      files: [
        aFile(uuid: '1', name: 'oldest.flac', indexedAt: DateTime.utc(2026, 1)),
        aFile(uuid: '2', name: 'newest.flac', indexedAt: DateTime.utc(2026, 3)),
        aFile(uuid: '3', name: 'middle.flac', indexedAt: DateTime.utc(2026, 2)),
      ],
    ),
  };

  group('the main flow', () {
    testWidgets('GivenASignedInOwner_WhenTheShellOpens_ThenItIsTheDashboard',
        (tester) async {
      // UC-14 main flow step 1, and the reason the panel has a home entry.
      await openDashboard(tester, listings: aLibrary());

      expect(find.byType(HomeDashboard), findsOneWidget);
    });

    testWidgets('GivenAStockedLibrary_WhenTheDashboardOpens_ThenAllSectionsShow',
        (tester) async {
      await openDashboard(tester, listings: aLibrary());
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

      expect(find.text(l10n.dashboardRecent), findsOneWidget);
      expect(find.text(l10n.dashboardInProgress), findsOneWidget);
      expect(find.text(l10n.dashboardCounts), findsOneWidget);
      expect(find.text(l10n.dashboardLastRun), findsOneWidget);
    });

    testWidgets('GivenFilesAddedOnDifferentDays_WhenShown_ThenTheNewestIsFirst',
        (tester) async {
      await openDashboard(tester, listings: aLibrary());

      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      // Newest first, oldest last: the dashboard is a glance at what has
      // just arrived.
      expect(titles, ['newest.flac', 'middle.flac', 'oldest.flac']);
    });

    testWidgets('GivenARecentFile_WhenItIsOpened_ThenTheDetailsAppear',
        (tester) async {
      // Main flow step 4: opening from here behaves as opening from a listing,
      // because it is the same view.
      await openDashboard(tester, listings: aLibrary());

      await tester.tap(find.text('newest.flac'));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
    });

    testWidgets('GivenAStockedLibrary_WhenTheCountsShow_ThenEachTypeIsCounted',
        (tester) async {
      await openDashboard(tester, listings: aLibrary());

      expect(find.byType(Chip), findsWidgets);
    });
  });

  group('the catalog is empty (AF-01)', () {
    testWidgets('GivenNothingCatalogued_WhenTheDashboardOpens_ThenGuidance',
        (tester) async {
      await openDashboard(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

      expect(find.text(l10n.catalogEmptyFirstRun), findsOneWidget);
      // Four empty sections would be four ways of saying the same thing.
      expect(find.text(l10n.dashboardRecent), findsNothing);

      await tester.tap(find.text(l10n.catalogEmptyAddFolder));
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySourcesScreen), findsOneWidget);
    });
  });

  group('nothing is in progress (AF-02)', () {
    testWidgets('GivenNoWatchlists_WhenTheDashboardOpens_ThenTheSectionSaysSo',
        (tester) async {
      // Always the state today: watchlists and reading lists are M-09's. The
      // section states it rather than rendering an empty box.
      await openDashboard(tester, listings: aLibrary());
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

      expect(find.text(l10n.dashboardInProgressNone), findsOneWidget);
    });
  });

  group('a section fails (AF-03)', () {
    testWidgets('GivenOneSectionFails_WhenTheDashboardOpens_ThenTheRestRender',
        (tester) async {
      // The catalog query the recent section reads fails, and the counts,
      // in-progress and last-run sections still render.
      await openDashboard(
        tester,
        listings: {
          LibraryType.audio: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
          LibraryType.image: CatalogListing.loaded(
            files: [aFile(uuid: 'i', name: 'a.png', type: LibraryType.image)],
          ),
        },
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

      expect(find.text(l10n.dashboardInProgress), findsOneWidget);
      expect(find.text(l10n.dashboardCounts), findsOneWidget);
      expect(find.text(l10n.dashboardLastRun), findsOneWidget);
    });
  });

  group('a run is in flight (AF-04)', () {
    testWidgets('GivenARunning_WhenTheDashboardShowsIt_ThenItSaysSo',
        (tester) async {
      final indexGateway = FakeIndexGateway()..readOutcomes = [runningRun()];
      final container = await openDashboard(
        tester,
        listings: aLibrary(),
        indexGateway: indexGateway,
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.dashboardLastRunNone), findsOneWidget);

      await container
          .read(indexRunsControllerProvider.notifier)
          .startIndex('/home/owner/music');
      await tester.pump();

      expect(find.text(l10n.dashboardLastRunRunning), findsOneWidget);

      // The run is deliberately still going, so the poller is stopped here.
      container.dispose();
    });

    testWidgets('GivenAFinishedRun_WhenTheDashboardShowsIt_ThenItSaysSo',
        (tester) async {
      final container = await openDashboard(
        tester,
        listings: aLibrary(),
        indexGateway: FakeIndexGateway(),
      );

      await container
          .read(indexRunsControllerProvider.notifier)
          .startIndex('/home/owner/music');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.dashboardLastRunComplete), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheDashboardOpens_ThenItIsLocalized',
        (tester) async {
      await openDashboard(tester, listings: aLibrary(), locale: locale);

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
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

  testWidgets('GivenOneTypeFails_WhenTheRecentSectionLoads_ThenItDegrades',
      (tester) async {
    // A type that cannot be read does not fail the section — it makes the
    // answer partial, which is the behaviour UC-11 established and which this
    // section inherits by reading the same catalog. AF-03 is about a section
    // containing its own failure, and each section has its own AsyncStateView
    // and its own retry; what this asserts is that one bad type does not cost
    // the owner the files that did load.
    await openDashboard(
      tester,
      listings: {
        LibraryType.audio: const CatalogListing.failed(
          failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
        ),
        LibraryType.image: CatalogListing.loaded(
          files: [aFile(uuid: 'i', name: 'a.png', type: LibraryType.image)],
        ),
      },
    );

    expect(find.byType(HomeDashboard), findsOneWidget);
    expect(find.text('a.png'), findsOneWidget);
  });
}
