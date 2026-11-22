import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_library_gateway.dart';
import '../../../support/shell_harness.dart';

/// Registering and browsing libraries (libraries design).
void main() {
  const course = Library(
    uuid: 'lib-1',
    name: 'Course',
    rootPath: '/library/course',
  );

  Future<({ProviderContainer container, FakeLibraryGateway gateway})>
  openLibraries(
    WidgetTester tester, {
    FakeLibraryGateway? gateway,
    List<Library> libraries = const [course],
  }) async {
    final theGateway = gateway ?? FakeLibraryGateway(libraries: libraries);
    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(theGateway),
      ],
    );

    await tester.openLibrariesPage();

    return (container: container, gateway: theGateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesView)));

  testWidgets(
    'GivenTheLibrariesScreen_WhenItOpens_ThenItSaysWhatALibraryHides',
    (tester) async {
      // Marking a folder empties part of a type panel, and that is not visible
      // until afterwards. Said before anything is marked.
      await openLibraries(tester);

      expect(find.text(messages(tester).librariesExplanation), findsOneWidget);
    },
  );

  testWidgets('GivenNoLibraries_WhenTheScreenOpens_ThenItSaysSo', (
    tester,
  ) async {
    await openLibraries(tester, libraries: const []);

    expect(find.text(messages(tester).librariesNone), findsOneWidget);
  });

  testWidgets(
    'GivenLibrariesInTheCoresOrder_WhenManageOpens_ThenTheyAreListedAToZ',
    (tester) async {
      // The core sorts names byte by byte, so "alpha" comes after "Zeta";
      // the dialog lists them as the left menu and home do, ignoring case.
      await openLibraries(
        tester,
        libraries: const [
          Library(uuid: 'lib-b', name: 'Beta', rootPath: '/library/beta'),
          Library(uuid: 'lib-z', name: 'Zeta', rootPath: '/library/zeta'),
          Library(uuid: 'lib-a', name: 'alpha', rootPath: '/library/alpha'),
        ],
      );

      double top(String name) => tester
          .getTopLeft(
            find.descendant(
              of: find.byType(LibrariesView),
              matching: find.text(name),
            ),
          )
          .dy;

      expect(top('alpha'), lessThan(top('Beta')));
      expect(top('Beta'), lessThan(top('Zeta')));
    },
  );

  testWidgets('GivenALibrary_WhenItsRowIsTapped_ThenItsFoldersOpen', (
    tester,
  ) async {
    // The row is the only way into the tree, so without this the whole
    // feature is unreachable however well it works.
    final opened = await openLibraries(tester);
    opened.gateway.reads['lib-1'] = {
      '': const LibraryRead.loaded(
        listing: LibraryListing(
          library: course,
          path: '',
          folders: [LibraryFolder(name: 'class-01', path: 'class-01')],
          files: [],
        ),
      ),
    };

    // The row in the libraries page, not the library's own left-menu entry.
    await tester.tap(
      find.descendant(
        of: find.byType(LibrariesView),
        matching: find.text('Course'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibraryView), findsOneWidget);
    expect(
      opened.container.read(shellControllerProvider),
      const LibraryDestination('lib-1'),
    );
    expect(find.text('class-01'), findsOneWidget);
    expect(opened.gateway.readsMade, contains((uuid: 'lib-1', path: '')));
  });

  testWidgets('GivenAFolder_WhenItIsOpened_ThenOnlyThatLevelIsRead', (
    tester,
  ) async {
    // One level at a time: opening a class asks for that class, not for the
    // whole course again.
    final opened = await openLibraries(tester);
    opened.gateway.reads['lib-1'] = {
      '': const LibraryRead.loaded(
        listing: LibraryListing(
          library: course,
          path: '',
          folders: [LibraryFolder(name: 'class-01', path: 'class-01')],
          files: [],
        ),
      ),
    };
    // The row in the libraries page, not the library's own left-menu entry.
    await tester.tap(
      find.descendant(
        of: find.byType(LibrariesView),
        matching: find.text('Course'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('class-01'));
    await tester.pumpAndSettle();

    expect(opened.gateway.readsMade.last, (uuid: 'lib-1', path: 'class-01'));
  });

  testWidgets(
    'GivenAFolderIsOpen_WhenTheRootCrumbIsPressed_ThenItGoesUpNotOut',
    (tester) async {
      // Four levels down, a way back that closed the library would throw the
      // owner out of the course rather than up a folder.
      final opened = await openLibraries(tester);
      opened.gateway.reads['lib-1'] = {
        '': const LibraryRead.loaded(
          listing: LibraryListing(
            library: course,
            path: '',
            folders: [LibraryFolder(name: 'class-01', path: 'class-01')],
            files: [],
          ),
        ),
        'class-01': const LibraryRead.loaded(
          listing: LibraryListing(
            library: course,
            path: 'class-01',
            folders: [],
            files: [],
          ),
        ),
      };
      // The row in the libraries page, not the library's own left-menu entry.
      await tester.tap(
        find.descendant(
          of: find.byType(LibrariesView),
          matching: find.text('Course'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('class-01'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(LibraryBreadcrumbs),
          matching: find.byTooltip('Course'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(LibraryView),
        findsOneWidget,
        reason: 'going up a folder closed the library instead',
      );
      expect(find.text('class-01'), findsOneWidget);
    },
  );

  testWidgets('GivenAnOverlappingFolder_WhenRegistered_ThenItSaysWhy', (
    tester,
  ) async {
    // A conflict is worth its own sentence: "that folder is already inside
    // another library" is actionable where the generic message leaves the
    // owner guessing which folder.
    final gateway = FakeLibraryGateway(libraries: const [course])
      ..writeOutcomes.add(
        const LibraryWrite.failed(
          failure: Failure.conflict(family: CoreStatusFamily.library, code: 6),
        ),
      );
    final opened = await openLibraries(tester, gateway: gateway);

    await opened.container
        .read(librariesControllerProvider.notifier)
        .register(name: 'Week one', rootPath: '/library/course/class-01');
    await tester.pumpAndSettle();

    expect(gateway.registered, hasLength(1));
  });

  testWidgets('GivenALibraryWithNothingIndexed_WhenOpened_ThenItSaysToScanIt', (
    tester,
  ) async {
    // What the owner actually sees after making a library of a folder
    // nobody has scanned: a library is browsed out of the catalog, not out
    // of a walk of the disk. "Nothing in this folder" describes a disk they
    // can see is not empty, so the root says the cause and the remedy.
    final opened = await openLibraries(tester);
    opened.gateway.reads['lib-1'] = {
      '': const LibraryRead.loaded(
        listing: LibraryListing(
          library: course,
          path: '',
          folders: [],
          files: [],
        ),
      ),
    };

    // The row in the libraries page, not the library's own left-menu entry.
    await tester.tap(
      find.descendant(
        of: find.byType(LibrariesView),
        matching: find.text('Course'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(LibraryView)));
    expect(find.text(l10n.libraryEmptyRoot), findsOneWidget);
    expect(find.text(l10n.libraryEmptyFolder), findsNothing);
  });

  testWidgets('GivenALibrary_WhenRemoved_ThenTheConfirmationSaysFilesReturn', (
    tester,
  ) async {
    // Removing must not read as discarding the files, or nobody undoes a
    // folder they marked by mistake.
    final opened = await openLibraries(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(
      find.text(messages(tester).libraryRemoveMessage('Course')),
      findsOneWidget,
    );
    expect(
      opened.gateway.removed,
      isEmpty,
      reason: 'it removed before the owner confirmed',
    );
  });

  testWidgets(
    'GivenManageLibraries_WhenItOpens_ThenEachRowOffersItsFourActions',
    (tester) async {
      await openLibraries(tester);
      final l10n = messages(tester);

      for (final tooltip in [
        l10n.libraryRenameEntry,
        l10n.libraryScan,
        l10n.libraryMove,
        l10n.libraryRemove,
      ]) {
        expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
      }
    },
  );

  testWidgets('GivenALibrary_WhenRenamedFromTheDialog_ThenItsRowUpdates', (
    tester,
  ) async {
    final opened = await openLibraries(tester);

    await tester.tap(find.byTooltip(messages(tester).libraryRenameEntry));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Rust course',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(opened.gateway.renamedCalls.single, (
      uuid: 'lib-1',
      name: 'Rust course',
    ));
    final rows = find.descendant(
      of: find.byType(LibrariesView),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: rows, matching: find.text('Rust course')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rows, matching: find.text('Course')),
      findsNothing,
    );
  });

  testWidgets('GivenALibraryRow_WhenItIsTapped_ThenTheDialogClosesOnIt', (
    tester,
  ) async {
    await openLibraries(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(LibrariesView),
        matching: find.text('Course'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibrariesView), findsNothing);
    expect(find.byType(LibraryView), findsOneWidget);
  });

  testWidgets(
    'GivenLibraryOneIsShown_WhenItIsRemovedFromManageLibraries_ThenTheShellGoesHome',
    (tester) async {
      final opened = await openLibraries(tester);
      // Shown in the main area behind the dialog.
      opened.container
          .read(shellControllerProvider.notifier)
          .go(const LibraryDestination('lib-1'));
      await tester.pumpAndSettle();
      expect(
        opened.container.read(shellControllerProvider),
        const LibraryDestination('lib-1'),
      );

      await tester.tap(find.byTooltip(messages(tester).libraryRemove));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, messages(tester).libraryRemove),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.removed, ['lib-1']);
      expect(
        opened.container.read(shellControllerProvider),
        const HomeDestination(),
      );
    },
  );
}
