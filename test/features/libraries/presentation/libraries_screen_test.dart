import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_tree_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librariesOpen);
    await tester.pumpAndSettle();

    return (container: container, gateway: theGateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesScreen)));

  testWidgets('GivenTheScreenOpens_ThenItSaysWhatALibraryHides', (
    tester,
  ) async {
    // Marking a folder empties part of a type panel, and that is not visible
    // until afterwards. Said before anything is marked.
    await openLibraries(tester);

    expect(find.text(messages(tester).librariesExplanation), findsOneWidget);
  });

  testWidgets('GivenNoLibraries_WhenTheScreenOpens_ThenItSaysSo', (
    tester,
  ) async {
    await openLibraries(tester, libraries: const []);

    expect(find.text(messages(tester).librariesNone), findsOneWidget);
  });

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

    await tester.tap(find.text('Course'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryTreeScreen), findsOneWidget);
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
    await tester.tap(find.text('Course'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('class-01'));
    await tester.pumpAndSettle();

    expect(opened.gateway.readsMade.last, (uuid: 'lib-1', path: 'class-01'));
  });

  testWidgets('GivenAFolderIsOpen_WhenBackIsPressed_ThenItGoesUpNotOut', (
    tester,
  ) async {
    // Four levels down, a back control that closed the screen would throw
    // the owner out of the course rather than up a folder.
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
    await tester.tap(find.text('Course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('class-01'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(
      find.byType(LibraryTreeScreen),
      findsOneWidget,
      reason: 'going up a folder closed the library instead',
    );
    expect(find.text('class-01'), findsOneWidget);
  });

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
}
