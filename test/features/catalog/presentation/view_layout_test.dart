import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
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
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      settings: settings,
      surfaceSize: surfaceSize,
      locale: locale,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(
            listings: {
              FileType.video: loadedDetails([
                aFile(
                  type: FileType.video,
                  name: 'Interstellar.mp4',
                  path: '/home/owner/videos/Interstellar.mp4',
                ),
                aFile(
                  uuid: 'b',
                  type: FileType.video,
                  name: 'Inception.mp4',
                  path: '/home/owner/videos/Inception.mp4',
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
      expect(find.text('Interstellar.mp4'), findsOneWidget);
    });

    testWidgets('GivenTheList_WhenDetailsAreChosen_ThenEachRowShowsItsPath', (
      tester,
    ) async {
      await openListing(tester);
      expect(find.text('/home/owner/videos/Interstellar.mp4'), findsNothing);

      await chooseLayout(tester, ViewLayout.detailedList);

      expect(find.text('/home/owner/videos/Interstellar.mp4'), findsOneWidget);
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
          matching: find.byIcon(ShellDestination.videos.icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('the listing is too narrow (AF-01)', () {
    testWidgets('GivenDetailsAtTheMinimumWindow_WhenDrawn_ThenTheListIsUsed', (
      tester,
    ) async {
      // Also what proves the decision is made on the listing rather than the
      // window: 1024 clears the layout's floor, and the listing inside it —
      // about 820 wide once the panel, the divider, and the padding are taken
      // off — does not.
      await openListing(tester, surfaceSize: Breakpoint.minimumWindowSize);

      await chooseLayout(tester, ViewLayout.detailedList);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.layoutSubstituted), findsOneWidget);
      // The substitution is stated, and the path column is not clipped onto
      // the name — it is simply not drawn.
      expect(find.text('/home/owner/videos/Interstellar.mp4'), findsNothing);
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

  group('what the detailed list adds', () {
    testWidgets('GivenTheDetailedList_WhenItFits_ThenThePathIsBesideTheName', (
      tester,
    ) async {
      // FR-CT-03 calls it "list with details": the detail is a second column
      // beside the name, which is what the medium floor exists for.
      await openListing(tester, surfaceSize: const Size(1600, 900));

      await chooseLayout(tester, ViewLayout.detailedList);

      final name = tester.getCenter(find.text('Inception.mp4'));
      final path = tester.getCenter(
        find.text('/home/owner/videos/Inception.mp4'),
      );

      // Beside, not beneath: further right, on the same line.
      expect(path.dx, greaterThan(name.dx));
      expect(path.dy, equals(name.dy));
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
