import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/core/settings/settings_store.dart';
import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/catalog/domain/view_layout.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Switching the view layout (UC-10, FR-CT-03, FR-CT-04).
void main() {
  /// Signs in and opens a listing with two files in it.
  Future<ProviderContainer> openListing(
    WidgetTester tester, {
    SettingsStore? settings,
    Size surfaceSize = const Size(1440, 900),
    Locale? locale,
  }) async {
    final container = await tester.pumpShell(
      settings: settings,
      surfaceSize: surfaceSize,
      locale: locale,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(
            listings: {
              LibraryType.audio: CatalogListing.loaded(
                files: [
                  aFile(),
                  aFile(
                    uuid: 'b',
                    name: 'Blue Train.flac',
                    path: '/home/owner/music/Blue Train.flac',
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.music.icon),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  /// Presses the switcher's segment for [layout].
  Future<void> chooseLayout(WidgetTester tester, ViewLayout layout) async {
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    final label = switch (layout) {
      ViewLayout.list => l10n.layoutList,
      ViewLayout.detailedList => l10n.layoutDetailedList,
      ViewLayout.grid => l10n.layoutGrid,
    };

    await tester.tap(find.byTooltip(label));
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    testWidgets('GivenAListing_WhenItOpens_ThenTheThreeLayoutsAreOffered', (
      tester,
    ) async {
      await openListing(tester);

      expect(find.byType(SegmentedButton<ViewLayout>), findsOneWidget);
    });

    testWidgets('GivenTheList_WhenTheGridIsChosen_ThenTilesAreDrawn', (
      tester,
    ) async {
      await openListing(tester);
      expect(find.byType(GridView), findsNothing);

      await chooseLayout(tester, ViewLayout.grid);

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Kind of Blue.flac'), findsOneWidget);
    });

    testWidgets('GivenTheList_WhenDetailsAreChosen_ThenEachRowShowsItsPath', (
      tester,
    ) async {
      await openListing(tester);
      expect(find.text('/home/owner/music/Kind of Blue.flac'), findsNothing);

      await chooseLayout(tester, ViewLayout.detailedList);

      expect(find.text('/home/owner/music/Kind of Blue.flac'), findsOneWidget);
    });

    testWidgets('GivenAChosenLayout_WhenItIsChosen_ThenItIsWritten', (
      tester,
    ) async {
      final settings = InMemorySettingsStore();
      await openListing(tester, settings: settings);

      await chooseLayout(tester, ViewLayout.grid);

      expect(settings.entries.values.join(), contains('grid'));
    });
  });

  group('the choice sticks per type (FR-CT-04)', () {
    testWidgets('GivenAGridForOneType_WhenAnotherIsOpened_ThenItIsAList', (
      tester,
    ) async {
      await openListing(tester);
      await chooseLayout(tester, ViewLayout.grid);

      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.images.icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('GivenAGridForOneType_WhenItIsReopened_ThenItIsStillAGrid', (
      tester,
    ) async {
      await openListing(tester);
      await chooseLayout(tester, ViewLayout.grid);

      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.images.icon),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.music.icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('the window is too narrow (AF-01)', () {
    testWidgets('GivenDetailsAtTheMinimumWindow_WhenDrawn_ThenTheListIsUsed', (
      tester,
    ) async {
      await openListing(tester, surfaceSize: Breakpoint.minimumWindowSize);

      await chooseLayout(tester, ViewLayout.detailedList);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.layoutSubstituted), findsOneWidget);
      // The substitution is stated, and the path column is not clipped onto
      // the name — it is simply not drawn.
      expect(find.text('/home/owner/music/Kind of Blue.flac'), findsNothing);
    });

    testWidgets('GivenAFittingLayout_WhenDrawn_ThenNoSubstitutionIsClaimed', (
      tester,
    ) async {
      await openListing(tester);

      await chooseLayout(tester, ViewLayout.detailedList);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.layoutSubstituted), findsNothing);
    });
  });

  group('the store cannot be written (AF-02)', () {
    testWidgets('GivenTheStoreRefuses_WhenALayoutIsChosen_ThenItStillApplies', (
      tester,
    ) async {
      await openListing(tester, settings: FailingSettingsStore());

      await chooseLayout(tester, ViewLayout.grid);

      expect(find.byType(GridView), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.layoutUnsaved), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheSwitcherIsShown_ThenItIsLocalized', (
      tester,
    ) async {
      await openListing(tester, locale: locale);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      for (final label in [
        l10n.layoutList,
        l10n.layoutDetailedList,
        l10n.layoutGrid,
      ]) {
        expect(label, isNot(startsWith('layout')));
        expect(find.byTooltip(label), findsOneWidget);
      }
    });
  }
}
