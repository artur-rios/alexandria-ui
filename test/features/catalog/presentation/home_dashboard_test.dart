import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/catalog_search_view.dart';
import 'package:alexandria_ui/features/catalog/presentation/home_dashboard.dart';
import 'package:alexandria_ui/features/libraries/domain/catalog_stats.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// The home screen: the favorite libraries and the totals (libraries design
/// §6).
void main() {
  Library library(String name, {bool favorite = false}) => Library(
    uuid: 'uuid-$name',
    name: name,
    rootPath: '/media/$name',
    favorite: favorite,
  );

  CatalogStats statsOf({int libraries = 0, Map<FileType, int>? counts}) =>
      CatalogStats(
        libraries: libraries,
        filesByType: {
          for (final type in FileType.values) type: counts?[type] ?? 0,
        },
      );

  Future<ProviderContainer> openHome(
    WidgetTester tester, {
    FakeLibraryGateway? gateway,
    FakeIndexGateway? indexGateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(1440, 1000),
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: size,
      settings: InMemorySettingsStore(
        themeMode: themeMode,
        locale: locale,
        rechecksAtStartup: false,
      ),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(
          gateway ?? FakeLibraryGateway(),
        ),
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        if (indexGateway != null)
          indexGatewayProvider.overrideWithValue(indexGateway),
        folderPickerProvider.overrideWithValue(FakeFolderPicker()),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    await tester.pumpAndSettle();

    return container;
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Finder inHome(Finder finder) =>
      find.descendant(of: find.byType(HomeDashboard), matching: finder);

  group('the favorite libraries', () {
    testWidgets('GivenFavoritesZetaAndAlpha_WhenHomeOpens_ThenAlphaIsFirst', (
      tester,
    ) async {
      final gateway = FakeLibraryGateway(
        libraries: [
          library('Zeta', favorite: true),
          library('alpha', favorite: true),
          library('Other'),
        ],
      );
      await openHome(tester, gateway: gateway);

      expect(inHome(find.byType(Card)), findsNWidgets(2));
      final alpha = tester.getTopLeft(inHome(find.text('alpha')));
      final zeta = tester.getTopLeft(inHome(find.text('Zeta')));
      expect(alpha.dy < zeta.dy || alpha.dx < zeta.dx, isTrue);
      expect(inHome(find.text('Other')), findsNothing);
    });

    testWidgets('GivenAFavorite_WhenHomeOpens_ThenItShowsNameAndRootPath', (
      tester,
    ) async {
      await openHome(
        tester,
        gateway: FakeLibraryGateway(
          libraries: [library('Films', favorite: true)],
        ),
      );

      expect(inHome(find.text('Films')), findsOneWidget);
      expect(inHome(find.text('/media/Films')), findsOneWidget);
    });

    testWidgets('GivenAFavorite_WhenItIsTapped_ThenTheLibraryOpens', (
      tester,
    ) async {
      final container = await openHome(
        tester,
        gateway: FakeLibraryGateway(
          libraries: [library('Films', favorite: true)],
        ),
      );

      await tester.tap(inHome(find.text('Films')));
      await tester.pumpAndSettle();

      expect(
        container.read(shellControllerProvider),
        const LibraryDestination('uuid-Films'),
      );
    });

    testWidgets('GivenARunningLibrary_WhenHomeOpens_ThenTheCardSaysSo', (
      tester,
    ) async {
      final container = await openHome(
        tester,
        gateway: FakeLibraryGateway(
          libraries: [library('Films', favorite: true)],
        ),
        indexGateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );
      await container
          .read(indexRunsControllerProvider.notifier)
          .startLibraryIndex('uuid-Films');
      await tester.pump();

      expect(inHome(find.text(l10nOf(tester).libraryRunStarting)), findsOne);

      // The run is deliberately still going, so the poller is stopped here.
      container.dispose();
    });

    testWidgets('GivenNoFavorites_WhenHomeOpens_ThenItSaysHowToMarkOne', (
      tester,
    ) async {
      await openHome(
        tester,
        gateway: FakeLibraryGateway(libraries: [library('Films')]),
      );

      expect(
        inHome(find.text(l10nOf(tester).homeFavoritesNone)),
        findsOneWidget,
      );
      expect(
        find.text('Mark a library as a favorite to see it here'),
        findsOne,
      );
    });

    testWidgets('GivenTheListFails_WhenHomeOpens_ThenNoFirstRunIsShown', (
      tester,
    ) async {
      final gateway = FakeLibraryGateway()
        ..browseOutcome = const LibraryBrowse.failed(
          failure: Failure.disk(family: CoreStatusFamily.library, code: 6),
        );
      await openHome(tester, gateway: gateway);

      expect(find.text(l10nOf(tester).catalogEmptyFirstRun), findsNothing);
      expect(inHome(find.text(l10nOf(tester).retry)), findsWidgets);
    });
  });

  group('the statistics', () {
    testWidgets('GivenTotals_WhenHomeOpens_ThenTheLibrariesAndEveryTypeShow', (
      tester,
    ) async {
      final gateway =
          FakeLibraryGateway(libraries: [library('a'), library('b')])
            ..statsOutcome = statsOf(
              libraries: 3,
              counts: {
                FileType.video: 12,
                FileType.audio: 0,
                FileType.image: 7,
              },
            );
      await openHome(tester, gateway: gateway);
      final l10n = l10nOf(tester);

      expect(inHome(find.text('3 libraries')), findsOneWidget);
      final expected = {
        FileType.video: '12',
        FileType.audio: '0',
        FileType.document: '0',
        FileType.comic: '0',
        FileType.text: '0',
        FileType.html: '0',
        FileType.image: '7',
      };
      for (final MapEntry(:key, :value) in expected.entries) {
        final row = inHome(find.byKey(ValueKey('home-stat-${key.wireName}')));
        expect(row, findsOneWidget, reason: key.wireName);
        expect(
          find.descendant(of: row, matching: find.text(key.label(l10n))),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.text(value)),
          findsOneWidget,
        );
      }
    });

    testWidgets('GivenOneLibrary_WhenHomeOpens_ThenItReadsInTheSingular', (
      tester,
    ) async {
      final gateway = FakeLibraryGateway(libraries: [library('a')])
        ..statsOutcome = statsOf(libraries: 1);
      await openHome(tester, gateway: gateway);

      expect(inHome(find.text('1 library')), findsOneWidget);
    });

    testWidgets(
      'GivenStatsFailAndFavoritesLoad_WhenHomeOpens_ThenOnlyTheStatsFail',
      (tester) async {
        final gateway =
            FakeLibraryGateway(libraries: [library('Films', favorite: true)])
              ..statsFailure = const Failure.disk(
                family: CoreStatusFamily.library,
                code: 6,
              );
        await openHome(tester, gateway: gateway);
        final l10n = l10nOf(tester);

        expect(inHome(find.text('Films')), findsOneWidget);
        expect(inHome(find.text(l10n.retry)), findsOneWidget);
        // No zero it could not count.
        expect(inHome(find.text('0 libraries')), findsNothing);
        expect(inHome(find.text('0')), findsNothing);

        gateway
          ..statsFailure = null
          ..statsOutcome = statsOf(libraries: 1, counts: {FileType.text: 4});
        await tester.tap(inHome(find.text(l10n.retry)));
        await tester.pumpAndSettle();

        expect(inHome(find.text('1 library')), findsOneWidget);
        expect(inHome(find.text(l10n.retry)), findsNothing);
        expect(inHome(find.text('Films')), findsOneWidget);
      },
    );

    testWidgets(
      'GivenFavoritesFailAndStatsLoad_WhenHomeOpens_ThenOnlyTheFavoritesFail',
      (tester) async {
        final gateway = FakeLibraryGateway()
          ..browseOutcome = const LibraryBrowse.failed(
            failure: Failure.disk(family: CoreStatusFamily.library, code: 6),
          )
          ..statsOutcome = statsOf(libraries: 2);
        await openHome(tester, gateway: gateway);

        expect(inHome(find.text('2 libraries')), findsOneWidget);
        expect(inHome(find.text(l10nOf(tester).retry)), findsOneWidget);
      },
    );
  });

  group('the first run', () {
    testWidgets('GivenNoLibraries_WhenHomeOpens_ThenGuidanceFillsTheScreen', (
      tester,
    ) async {
      await openHome(tester);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.catalogEmptyFirstRun), findsOneWidget);
      expect(inHome(find.text(l10n.homeStatistics)), findsNothing);

      await tester.tap(inHome(find.text(l10n.libraryAdd)));
      await tester.pumpAndSettle();

      // The add flow runs where the owner is: no screen opens for it.
      expect(find.byType(LibrariesView), findsNothing);
    });
  });

  group('what home no longer shows', () {
    testWidgets('GivenALibrary_WhenHomeOpens_ThenOnlyTheTwoSectionsShow', (
      tester,
    ) async {
      await openHome(
        tester,
        gateway: FakeLibraryGateway(libraries: [library('a', favorite: true)]),
      );

      for (final gone in [
        'Recently added',
        'In progress',
        'The last scan',
        'What is in the library',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenHomeOpens_ThenItIsLocalized', (tester) async {
      final gateway = FakeLibraryGateway(libraries: [library('a')])
        ..statsOutcome = statsOf(libraries: 2);
      await openHome(tester, gateway: gateway, locale: locale);
      final l10n = l10nOf(tester);

      for (final label in [
        l10n.homeFavorites,
        l10n.homeFavoritesNone,
        l10n.homeStatistics,
        l10n.homeLibraryCount(2),
      ]) {
        expect(label, isNot(startsWith('home')));
        expect(inHome(find.text(label)), findsOneWidget);
      }
    });
  }

  testWidgets(
    'GivenPortuguese_WhenHomeOpens_ThenFavoritesAreCalledPreferidas',
    (tester) async {
      await openHome(
        tester,
        gateway: FakeLibraryGateway(libraries: [library('a')]),
        locale: const Locale('pt', 'BR'),
      );

      expect(l10nOf(tester).homeFavorites, contains('preferidas'));
    },
  );

  testWidgets('GivenTheMinimumWindow_WhenHomeIsFull_ThenNothingOverflows', (
    tester,
  ) async {
    final gateway = FakeLibraryGateway(
      libraries: [
        for (var i = 0; i < 9; i++)
          Library(
            uuid: 'u$i',
            name: 'A library with a rather long name number $i',
            rootPath:
                '/media/a/very/long/path/to/the/root/of/library/number/$i',
            favorite: true,
          ),
      ],
    )..statsOutcome = statsOf(libraries: 9, counts: {FileType.video: 1234567});
    await openHome(tester, gateway: gateway, size: const Size(1024, 640));

    expect(tester.takeException(), isNull);
  });

  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenHomeOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openHome(
            tester,
            gateway: FakeLibraryGateway(libraries: [library('a')]),
            themeMode: mode,
          );

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
