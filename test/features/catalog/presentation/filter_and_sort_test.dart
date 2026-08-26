import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Filtering and ordering a listing from the screen (UC-12).
void main() {
  /// Signs in and opens a listing (UC-12 is generic across types; video
  /// stands in for it now that music has its own browsing area, UC-46).
  Future<ProviderContainer> openListing(
    WidgetTester tester, {
    Map<LibraryType, CatalogListing>? listings,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: const Size(1440, 900),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(
            listings:
                listings ??
                {
                  LibraryType.video: loadedDetails([
                    aFile(
                      uuid: '1',
                      name: 'zebra.mp4',
                      type: LibraryType.video,
                    ),
                    aFile(
                      uuid: '2',
                      name: 'apple.mp4',
                      type: LibraryType.video,
                    ),
                  ]),
                },
          ),
        ),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.videos.icon),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  /// Opens the filter menu.
  Future<void> openMenu(WidgetTester tester) async {
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.tap(find.text(l10n.filtersLabel));
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    testWidgets('GivenAListing_WhenItOpens_ThenFiltersAndOrderAreOffered', (
      tester,
    ) async {
      await openListing(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(find.text(l10n.filtersLabel), findsOneWidget);
    });

    testWidgets('GivenTheMenu_WhenItOpens_ThenBothFiltersAndSortsAreThere', (
      tester,
    ) async {
      await openListing(tester);

      await openMenu(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.filterLifecycleDeleted), findsOneWidget);
      expect(find.text(l10n.sortByIndexed), findsOneWidget);
      expect(find.text(l10n.sortDescending), findsOneWidget);
    });

    testWidgets(
      'GivenTheDefaultOrder_WhenItIsReversed_ThenTheListingReorders',
      (tester) async {
        final container = await openListing(tester);
        expect(
          container.read(listingControllerProvider).value!.first.name,
          'apple.mp4',
        );

        await openMenu(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        await tester.tap(find.text(l10n.sortDescending));
        await tester.pumpAndSettle();

        expect(
          container.read(listingControllerProvider).value!.first.name,
          'zebra.mp4',
        );
      },
    );

    testWidgets('GivenADeletedFilter_WhenItIsChosen_ThenTheCoreIsAskedForIt', (
      tester,
    ) async {
      final container = await openListing(tester);

      await openMenu(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.filterLifecycleDeleted));
      await tester.pumpAndSettle();

      expect(
        container
            .read(listingViewControllerProvider)
            .forType(LibraryType.video)
            .lifecycle,
        LifecycleFilter.deleted,
      );
    });
  });

  group('nothing matches the filters (AF-01)', () {
    testWidgets('GivenFiltersThatMatchNothing_WhenApplied_ThenClearIsOffered', (
      tester,
    ) async {
      final container = await openListing(
        tester,
        listings: {
          LibraryType.video: loadedDetails([aFile(type: LibraryType.video)]),
        },
      );

      // Filtered to a state the fake answers nothing for.
      await container
          .read(listingViewControllerProvider.notifier)
          .apply(
            LibraryType.video,
            const ListingView(lifecycle: LifecycleFilter.deleted),
          );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      // The message names the filters rather than claiming the library is
      // empty, which is a different thing with a different answer.
      expect(find.text(l10n.filtersEmpty), findsOneWidget);
      expect(find.text(l10n.catalogEmptyFirstRun), findsNothing);
      expect(find.text(l10n.filtersClear), findsWidgets);
    });

    testWidgets('GivenTheEmptyState_WhenClearIsPressed_ThenTheListingReturns', (
      tester,
    ) async {
      final container = await openListing(
        tester,
        listings: {
          LibraryType.video: loadedDetails([aFile(type: LibraryType.video)]),
        },
      );
      await container
          .read(listingViewControllerProvider.notifier)
          .apply(
            LibraryType.video,
            const ListingView(lifecycle: LifecycleFilter.deleted),
          );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await tester.tap(find.text(l10n.filtersClear).last);
      await tester.pumpAndSettle();

      expect(find.text('Kind of Blue.flac'), findsOneWidget);
    });
  });

  group('the core refuses the filter (AF-04)', () {
    testWidgets('GivenTheCoreRefuses_WhenAFilterIsApplied_ThenItSaysSo', (
      tester,
    ) async {
      final container = await openListing(
        tester,
        listings: {
          LibraryType.video: const CatalogListing.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.file,
              code: 1,
            ),
          ),
        },
      );

      await container
          .read(listingViewControllerProvider.notifier)
          .apply(
            LibraryType.video,
            const ListingView(lifecycle: LifecycleFilter.all),
          );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.filtersRejected), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheMenuOpens_ThenItIsLocalized', (
      tester,
    ) async {
      await openListing(tester, locale: locale);

      await openMenu(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      for (final label in [
        l10n.filterLifecycle,
        l10n.sortLabel,
        l10n.sortByName,
      ]) {
        expect(label, isNot(startsWith('filter')));
        expect(label, isNot(startsWith('sort')));
        expect(find.text(label), findsWidgets);
      }
    });
  }
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openListing(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(ShellScreen).first)).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
