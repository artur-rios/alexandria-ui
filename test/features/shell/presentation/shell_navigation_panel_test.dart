import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/shell_harness.dart';

/// The left menu (FR-UX-01, FR-UX-02, spec §3), and the bar's two menus
/// beside it (UC-37 main flow step 1).
void main() {
  /// Pumps the shell at [width], 900 logical pixels tall.
  Future<void> pumpPanel(WidgetTester tester, {required double width}) =>
      tester.pumpShell(surfaceSize: Size(width, 900));

  group('the menu bar triggers', () {
    testWidgets(
      'GivenTheExtendedBreakpoint_WhenBuilt_ThenBothTriggersShowLabels',
      (tester) async {
        await pumpPanel(tester, width: Breakpoint.expandedMinWidth);

        expect(find.text('Library'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    // FR-UX-02: no entry is dropped at any breakpoint. At the minimum window
    // the label becomes a tooltip rather than disappearing — and "becomes"
    // has to mean the tooltip can actually be revealed, not merely that a
    // Tooltip widget is present somewhere in the tree, so this measures the
    // rendered size of the region a pointer would have to hover to see it.
    testWidgets(
      'GivenTheMinimumWindow_WhenBuilt_ThenBothTriggersKeepReachableTooltips',
      (tester) async {
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);

        for (final message in ['Library', 'Open settings']) {
          final size = tester.getSize(find.byTooltip(message));
          expect(size.width, greaterThan(0), reason: message);
          expect(size.height, greaterThan(0), reason: message);
        }
      },
    );

    testWidgets('GivenTheToolsMenu_WhenOpened_ThenItsSixScreensAreGrouped', (
      tester,
    ) async {
      await pumpPanel(tester, width: 1400);
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(find.text('Tracking'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Watchlists'), findsOneWidget);
    });
  });

  group('the libraries in the left menu (spec §3)', () {
    Library library(
      String name, {
      String? uuid,
      bool pinned = false,
      bool favorite = false,
    }) => Library(
      uuid: uuid ?? 'lib-$name',
      name: name,
      rootPath: '/$name',
      pinned: pinned,
      favorite: favorite,
    );

    /// Pumps the shell over [libraries], and answers the gateway and the
    /// container it reads them from.
    Future<({ProviderContainer container, FakeLibraryGateway gateway})> open(
      WidgetTester tester,
      List<Library> libraries, {
      Size surfaceSize = const Size(1280, 900),
      FakeFolderPicker? picker,
    }) async {
      final gateway = FakeLibraryGateway(libraries: libraries);
      final container = await tester.pumpShell(
        surfaceSize: surfaceSize,
        extraOverrides: [
          libraryGatewayProvider.overrideWithValue(gateway),
          folderPickerProvider.overrideWithValue(picker ?? FakeFolderPicker()),
        ],
      );

      return (container: container, gateway: gateway);
    }

    Finder panel() => find.byType(ShellNavigationPanel);

    /// The entry labelled [label], at a tier that shows labels.
    Finder entry(String label) =>
        find.descendant(of: panel(), matching: find.text(label));

    Finder divider() =>
        find.descendant(of: panel(), matching: find.byType(Divider));

    double top(WidgetTester tester, Finder finder) =>
        tester.getTopLeft(finder).dy;

    /// Expects [labels] down the panel in that order, with the divider
    /// between the entries at [dividerAfter] and the one after it.
    void expectOrder(
      WidgetTester tester,
      List<String> labels, {
      int? dividerAfter,
    }) {
      for (var at = 0; at + 1 < labels.length; at++) {
        expect(
          top(tester, entry(labels[at])),
          lessThan(top(tester, entry(labels[at + 1]))),
          reason: '${labels[at]} comes before ${labels[at + 1]}',
        );
      }
      if (dividerAfter == null) {
        expect(divider(), findsNothing);
      } else {
        expect(divider(), findsOneWidget);
        expect(
          top(tester, divider()),
          greaterThan(top(tester, entry(labels[dividerAfter]))),
        );
        expect(
          top(tester, divider()),
          lessThan(top(tester, entry(labels[dividerAfter + 1]))),
        );
      }
    }

    /// The name field of the rename dialog (the menu bar has a field too).
    Finder nameField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

    Future<void> openContextMenu(WidgetTester tester, String label) async {
      await tester.tap(entry(label), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'GivenPinnedAndOtherLibraries_WhenThePanelIsDrawn_ThenHomeBookmarksPinnedDividerOthers',
      (tester) async {
        await open(tester, [
          library('b'),
          library('A', pinned: true),
          library('c'),
          library('B', pinned: true),
        ]);

        expectOrder(tester, [
          'Home',
          'Bookmarks',
          'A',
          'B',
          'b',
          'c',
        ], dividerAfter: 3);
      },
    );

    testWidgets(
      'GivenNoPinnedLibrary_WhenThePanelIsDrawn_ThenThereIsNoDivider',
      (tester) async {
        await open(tester, [library('b'), library('a')]);

        expectOrder(tester, ['Home', 'Bookmarks', 'a', 'b']);
      },
    );

    testWidgets(
      'GivenEveryLibraryPinned_WhenThePanelIsDrawn_ThenThereIsNoDivider',
      (tester) async {
        await open(tester, [
          library('b', pinned: true),
          library('a', pinned: true),
        ]);

        expectOrder(tester, ['Home', 'Bookmarks', 'a', 'b']);
      },
    );

    testWidgets(
      'GivenLibraries_WhenThePanelIsDrawn_ThenNoFileTypeOrLibrariesPageIsAnEntry',
      (tester) async {
        // The type pages and the libraries page still exist until the
        // library view and the manage dialog replace them, but neither is
        // somewhere the left menu goes.
        await open(tester, [library('Course')]);

        for (final label in [
          'Videos',
          'Music',
          'Books',
          'Comic books',
          'Notes',
          'Pages',
          'Images',
          'Libraries',
        ]) {
          expect(entry(label), findsNothing, reason: label);
        }
        expect(entry('Home'), findsOneWidget);
        expect(entry('Bookmarks'), findsOneWidget);
        expect(entry('Course'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenALibraryEntry_WhenItIsTapped_ThenTheLibraryHeadsTheContentArea',
      (tester) async {
        final (:container, gateway: _) = await open(tester, [
          library('Course', uuid: 'lib-1'),
        ]);

        await tester.tap(entry('Course'));
        await tester.pumpAndSettle();

        expect(
          container.read(shellControllerProvider),
          const LibraryDestination('lib-1'),
        );
        expect(
          find.descendant(
            of: find.byType(ShellContentArea),
            matching: find.text('Course'),
          ),
          findsOneWidget,
        );
      },
    );

    group('when the libraries could not be read', () {
      const failed = 'Libraries didn\'t load. Try again';

      /// The shell over a gateway whose browse fails, at [surfaceSize].
      Future<FakeLibraryGateway> openFailing(
        WidgetTester tester, {
        Size surfaceSize = const Size(1280, 900),
      }) async {
        final gateway = FakeLibraryGateway(libraries: [library('Course')])
          ..browseOutcome = const LibraryBrowse.failed(
            failure: Failure.unexpected(
              family: CoreStatusFamily.library,
              code: 9,
            ),
          );
        await tester.pumpShell(
          surfaceSize: surfaceSize,
          extraOverrides: [
            libraryGatewayProvider.overrideWithValue(gateway),
            folderPickerProvider.overrideWithValue(FakeFolderPicker()),
          ],
        );

        return gateway;
      }

      testWidgets(
        'GivenTheBrowseFails_WhenThePanelIsDrawn_ThenItSaysSoAndOffersNoAdd',
        (tester) async {
          // An empty section would read as "you have no libraries", which
          // is a count the panel never made.
          await openFailing(tester);

          expect(entry(failed), findsOneWidget);
          expect(entry('Add a library'), findsNothing);
        },
      );

      testWidgets(
        'GivenTheBrowseFailed_WhenTheEntryIsTapped_ThenTheLibrariesAreReadAgain',
        (tester) async {
          final gateway = await openFailing(tester);

          gateway.browseOutcome = null;
          await tester.tap(entry(failed));
          await tester.pumpAndSettle();

          expect(entry(failed), findsNothing);
          expect(entry('Course'), findsOneWidget);
        },
      );

      testWidgets(
        'GivenTheBrowseFails_WhenTheEntryIsTapped_ThenTheDestinationDoesNotChange',
        (tester) async {
          await openFailing(tester);
          final container = ProviderScope.containerOf(
            tester.element(find.byType(ShellScreen)),
          );

          await tester.tap(entry(failed));
          await tester.pumpAndSettle();

          expect(
            container.read(shellControllerProvider),
            const HomeDestination(),
          );
          expect(entry(failed), findsOneWidget);
        },
      );

      testWidgets(
        'GivenTheIconsOnlyTier_WhenTheBrowseFails_ThenTheTooltipSaysSoAndRetries',
        (tester) async {
          final gateway = await openFailing(
            tester,
            surfaceSize: Breakpoint.minimumWindowSize,
          );

          final size = tester.getSize(find.byTooltip(failed));
          expect(size.width, greaterThan(0));
          expect(size.height, greaterThan(0));

          gateway.browseOutcome = null;
          await tester.tap(find.byTooltip(failed));
          await tester.pumpAndSettle();

          expect(find.byTooltip(failed), findsNothing);
          expect(find.byTooltip('Course'), findsOneWidget);
        },
      );
    });

    group('with no libraries', () {
      testWidgets(
        'GivenNoLibraries_WhenThePanelIsDrawn_ThenASingleAddLibraryEntryIsShown',
        (tester) async {
          await open(tester, const []);

          expect(entry('Add a library'), findsOneWidget);
          expect(divider(), findsNothing);
        },
      );

      testWidgets(
        'GivenNoLibraries_WhenAddLibraryIsTapped_ThenTheAddFlowStarts',
        (tester) async {
          final picker = FakeFolderPicker();
          final (:container, gateway: _) = await open(
            tester,
            const [],
            picker: picker,
          );

          await tester.tap(entry('Add a library'));
          await tester.pumpAndSettle();

          // `openLibrariesAndAdd`: the libraries page, with the folder picker
          // already open over it.
          expect(
            container.read(shellControllerProvider),
            const LibrariesDestination(),
          );
          expect(picker.openCount, 1);
        },
      );
    });

    group('the context menu', () {
      testWidgets(
        'GivenALibraryEntry_WhenItIsRightClicked_ThenPinFavoriteAndRenameAreOffered',
        (tester) async {
          await open(tester, [library('Course')]);

          await openContextMenu(tester, 'Course');

          expect(find.text('Pin'), findsOneWidget);
          expect(find.text('Add to favorites'), findsOneWidget);
          expect(find.text('Rename…'), findsOneWidget);
        },
      );

      testWidgets(
        'GivenALibraryEntry_WhenItIsLongPressed_ThenTheSameMenuOpens',
        (tester) async {
          await open(tester, [library('Course')]);

          await tester.longPress(entry('Course'));
          await tester.pumpAndSettle();

          expect(find.text('Pin'), findsOneWidget);
          expect(find.text('Add to favorites'), findsOneWidget);
          expect(find.text('Rename…'), findsOneWidget);
        },
      );

      testWidgets(
        'GivenAPinnedFavorite_WhenItsMenuOpens_ThenUnpinAndRemoveAreOfferedWithAStar',
        (tester) async {
          await open(tester, [library('Course', pinned: true, favorite: true)]);

          await openContextMenu(tester, 'Course');

          expect(find.text('Unpin'), findsOneWidget);
          expect(find.text('Remove from favorites'), findsOneWidget);
          expect(
            find.widgetWithIcon(MenuItemButton, Icons.star),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'GivenAnOtherLibrary_WhenPinIsChosen_ThenTheCoreIsAskedAndItMovesIntoThePinned',
        (tester) async {
          final (container: _, :gateway) = await open(tester, [
            library('A', pinned: true),
            library('b'),
            library('c', uuid: 'lib-c'),
          ]);

          await openContextMenu(tester, 'c');
          await tester.tap(find.text('Pin'));
          await tester.pumpAndSettle();

          expect(gateway.pinnedCalls, [(uuid: 'lib-c', pinned: true)]);
          expectOrder(tester, [
            'Home',
            'Bookmarks',
            'A',
            'c',
            'b',
          ], dividerAfter: 3);
        },
      );

      testWidgets(
        'GivenALibrary_WhenAddToFavoritesIsChosen_ThenTheCoreIsAsked',
        (tester) async {
          final (container: _, :gateway) = await open(tester, [
            library('Course', uuid: 'lib-1'),
          ]);

          await openContextMenu(tester, 'Course');
          await tester.tap(find.text('Add to favorites'));
          await tester.pumpAndSettle();

          expect(gateway.favoriteCalls, [(uuid: 'lib-1', favorite: true)]);

          await openContextMenu(tester, 'Course');
          expect(find.text('Remove from favorites'), findsOneWidget);
        },
      );

      testWidgets(
        'GivenTheCoreRefusesAPin_WhenPinIsChosen_ThenASnackbarSaysSoAndTheEntryStays',
        (tester) async {
          final (container: _, :gateway) = await open(tester, [
            library('A', pinned: true),
            library('b'),
            library('c'),
          ]);
          gateway.writeOutcomes.add(
            const LibraryWrite.failed(
              failure: Failure.unexpected(
                family: CoreStatusFamily.library,
                code: 9,
              ),
            ),
          );

          await openContextMenu(tester, 'c');
          await tester.tap(find.text('Pin'));
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.text('The change could not be saved.'),
            ),
            findsOneWidget,
          );
          expectOrder(tester, [
            'Home',
            'Bookmarks',
            'A',
            'b',
            'c',
          ], dividerAfter: 2);
        },
      );

      testWidgets(
        'GivenTheSelectedLibraryIsRenamed_WhenTheListReloads_ThenTheHeadingAndMenuShowTheNewName',
        (tester) async {
          await open(tester, [library('Course', uuid: 'lib-1')]);
          await tester.tap(entry('Course'));
          await tester.pumpAndSettle();

          await openContextMenu(tester, 'Course');
          await tester.tap(find.text('Rename…'));
          await tester.pumpAndSettle();
          await tester.enterText(nameField(), 'Lectures');
          await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(ShellContentArea),
              matching: find.text('Lectures'),
            ),
            findsOneWidget,
          );
          expect(entry('Lectures'), findsOneWidget);
          expect(entry('Course'), findsNothing);
        },
      );

      testWidgets(
        'GivenALibraryIsRenamed_WhenTheListReloads_ThenTheMenuSortsItAgain',
        (tester) async {
          await open(tester, [library('Alpha'), library('Beta')]);

          await openContextMenu(tester, 'Alpha');
          await tester.tap(find.text('Rename…'));
          await tester.pumpAndSettle();
          await tester.enterText(nameField(), 'Zeta');
          await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
          await tester.pumpAndSettle();

          expectOrder(tester, ['Home', 'Bookmarks', 'Beta', 'Zeta']);
        },
      );
    });

    group('at the minimum window (FR-UX-02)', () {
      testWidgets(
        'GivenTheIconsOnlyTier_WhenThePanelIsDrawn_ThenEachLibraryHasItsNameAsATooltip',
        (tester) async {
          await open(tester, [
            library('Course'),
            library('Films', pinned: true),
          ], surfaceSize: Breakpoint.minimumWindowSize);

          for (final name in ['Course', 'Films']) {
            expect(entry(name), findsNothing, reason: 'icons only');
            final size = tester.getSize(find.byTooltip(name));
            expect(size.width, greaterThan(0), reason: name);
            expect(size.height, greaterThan(0), reason: name);
          }
        },
      );

      testWidgets(
        'GivenFortyLibraries_WhenThePanelIsDrawn_ThenNothingOverflowsAndTheLastIsReachable',
        (tester) async {
          final (:container, gateway: _) = await open(tester, [
            for (var n = 1; n <= 40; n++)
              library(
                'Library ${n.toString().padLeft(2, '0')}',
                uuid: 'lib-$n',
              ),
          ], surfaceSize: Breakpoint.minimumWindowSize);

          expect(tester.takeException(), isNull);

          final last = find.byTooltip('Library 40');
          await tester.scrollUntilVisible(
            last,
            200,
            scrollable: find.descendant(
              of: panel(),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.tap(last);
          await tester.pumpAndSettle();

          expect(
            container.read(shellControllerProvider),
            const LibraryDestination('lib-40'),
          );
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
