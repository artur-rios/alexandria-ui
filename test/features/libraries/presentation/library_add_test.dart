import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_tree_screen.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/presentation/index_scope_dialog.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Making a library from the screen that lists them (libraries design).
///
/// A library is browsed out of what the catalog holds beneath its root, so a
/// folder nobody has indexed makes a library that shows nothing at all — no
/// files, and no folders either. That is what this button did when all it
/// asked the core for was the library, and it is what these tests are mostly
/// about: an unregistered folder is registered and indexed, and an already
/// registered one is only marked.
void main() {
  const folder = '/media/courses/rust';
  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  LibrarySource source(String path, {String? libraryName}) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
    libraryName: libraryName,
  );

  Future<
    ({
      ProviderContainer container,
      FakeLibraryGateway gateway,
      FakeIndexGateway index,
      InMemoryLibrarySourceStore store,
    })
  >
  openLibraries(
    WidgetTester tester, {
    String? picked = folder,
    List<LibrarySource> registered = const [],
    List<LibraryWrite> writeOutcomes = const [],
    List<Library> libraries = const [],
    bool folderExists = true,
  }) async {
    final gateway = FakeLibraryGateway(libraries: libraries)
      ..writeOutcomes.addAll(writeOutcomes);
    final store = InMemoryLibrarySourceStore([...registered]);
    final index = FakeIndexGateway();

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      // Off, or the startup re-check races the run this test drives.
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: picked)),
        folderProbeProvider.overrideWithValue(
          FakeFolderProbe(existing: folderExists, readable: folderExists),
        ),
        librarySourceStoreProvider.overrideWithValue(store),
        indexGatewayProvider.overrideWithValue(index),
        clockProvider.overrideWithValue(() => registeredAt),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.libraries.icon),
      ),
    );
    await tester.pumpAndSettle();

    return (
      container: container,
      gateway: gateway,
      index: index,
      store: store,
    );
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesView)));

  /// Presses the button, which opens the picker.
  ///
  /// Pumped rather than settled: registering keeps a dialog in flight, and
  /// `pumpAndSettle` would wait on an animation doing exactly what it should.
  Future<void> pressAdd(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, messages(tester).libraryAdd),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Answers the scope dialog with what it opens on.
  Future<void> acceptScope(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(IndexScopeDialog)),
    );
    await tester.tap(find.text(l10n.indexScopeConfirm));
    await tester.pumpAndSettle();
  }

  /// Answers the name dialog, keeping the suggestion unless [name] is given.
  Future<void> acceptName(WidgetTester tester, {String? name}) async {
    final l10n = messages(tester);
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    if (name != null) await tester.enterText(field, name);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l10n.libraryAdd),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a folder that is not registered yet', () {
    testWidgets('GivenItIsPicked_ThenTheScopeDialogAsksAsALibrary', (
      tester,
    ) async {
      // One dialog for both questions, and the library half is already
      // answered: the owner pressed "Add a library", so the box is ticked and
      // the name filled in from the folder.
      await openLibraries(tester);

      await pressAdd(tester);

      expect(find.byType(IndexScopeDialog), findsOneWidget);
      expect(find.text('rust'), findsOneWidget);
    });

    testWidgets('GivenTheScopeIsAnswered_ThenTheFolderIsRegisteredAndIndexed', (
      tester,
    ) async {
      // The whole bug this flow was rewritten for: a library over a folder
      // nobody indexed shows nothing at all, because the tree is built from
      // catalog rows rather than from a walk of the disk.
      final opened = await openLibraries(tester);

      await pressAdd(tester);
      await acceptScope(tester);

      expect(opened.store.read().single.path, folder);
      expect(opened.gateway.registered, [(name: 'rust', rootPath: folder)]);
      expect(
        opened.index.starts.map((call) => call.root),
        [folder],
        reason: 'a library over an unindexed folder shows nothing',
      );
    });

    testWidgets('GivenTheLibraryIsRegistered_ThenItIsBeforeTheWalkStarts', (
      tester,
    ) async {
      // Order matters: the core assigns each file to the library it is
      // indexed into, so a library created after the walk would hold nothing
      // until something claimed the files back.
      final opened = await openLibraries(tester);

      await pressAdd(tester);
      await acceptScope(tester);

      expect(opened.gateway.registered, isNotEmpty);
      expect(opened.index.starts, isNotEmpty);
    });

    testWidgets('GivenTheScopeIsCancelled_ThenNothingIsRegistered', (
      tester,
    ) async {
      final opened = await openLibraries(tester);

      await pressAdd(tester);
      await tester.tap(find.text(messages(tester).cancel).last);
      await tester.pumpAndSettle();

      expect(opened.store.read(), isEmpty);
      expect(opened.gateway.registered, isEmpty);
      expect(opened.index.starts, isEmpty);
    });

    testWidgets('GivenTheFolderIsNotThere_ThenTheRefusalIsSaidPlainly', (
      tester,
    ) async {
      // The sources screen renders its refusal notice from the same state,
      // and this screen has nowhere to put one — so a folder that is gone has
      // to be said here, or the button just looks broken.
      final opened = await openLibraries(tester, folderExists: false);

      await pressAdd(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(messages(tester).librarySourcesMissing(folder)),
        findsWidgets,
      );
      expect(opened.store.read(), isEmpty);
    });
  });

  group('a folder that is registered already', () {
    testWidgets('GivenItIsPicked_ThenOnlyTheNameIsAsked', (tester) async {
      // Its files are in the catalog already, so marking it is the whole of
      // the work — no scope to choose and nothing to index.
      final opened = await openLibraries(
        tester,
        registered: [source(folder)],
      );

      await pressAdd(tester);
      await acceptName(tester, name: 'Rust course');

      expect(find.byType(IndexScopeDialog), findsNothing);
      expect(opened.gateway.registered, [
        (name: 'Rust course', rootPath: folder),
      ]);
      expect(opened.index.starts, isEmpty);
    });

    testWidgets('GivenItIsMade_ThenItsSourceFolderIsMarked', (tester) async {
      // Registering with the core and marking the folder are one action:
      // doing only the first leaves the sources screen offering to mark a
      // folder that is already a library.
      final opened = await openLibraries(
        tester,
        registered: [source(folder)],
      );

      await pressAdd(tester);
      await acceptName(tester, name: 'Rust course');

      expect(opened.store.read().single.libraryName, 'Rust course');
    });

    testWidgets('GivenTheCoreRefuses_ThenTheOverlapIsSaidPlainly', (
      tester,
    ) async {
      // "That folder is already inside another library" is something the
      // owner can act on, where a generic refusal is a puzzle.
      final opened = await openLibraries(
        tester,
        registered: [source(folder)],
        writeOutcomes: const [
          LibraryWrite.failed(
            failure: Failure.conflict(
              family: CoreStatusFamily.library,
              code: LIBRARY_ERR_CONFLICT,
            ),
          ),
        ],
      );

      await pressAdd(tester);
      await acceptName(tester, name: 'Rust course');

      // `findsWidgets`: the snackbar is drawn by every scaffold registered
      // with the one messenger.
      expect(find.text(messages(tester).libraryOverlaps), findsWidgets);
      expect(
        opened.store.read().single.libraryName,
        isNull,
        reason: 'a refused registration must not mark the folder',
      );
    });
  });

  group('scanning a library that shows nothing', () {
    testWidgets('GivenARegisteredFolder_WhenScanned_ThenARunStarts', (
      tester,
    ) async {
      // The way out of an empty library, offered where the empty library is
      // seen: a library made before this screen indexed anything holds
      // nothing at all, and the remedy used to be on another screen.
      final opened = await openLibraries(
        tester,
        registered: [source(folder, libraryName: 'Rust course')],
        libraries: const [
          Library(uuid: 'lib-1', name: 'Rust course', rootPath: folder),
        ],
      );

      await tester.tap(find.byTooltip(messages(tester).libraryScan));
      await tester.pumpAndSettle();

      expect(opened.index.starts.map((call) => call.root), [folder]);
    });

    testWidgets('GivenAFolderThatIsNotASourceYet_WhenScanned_ThenItIsRegistered', (
      tester,
    ) async {
      // An index run is refused for a folder the application does not know,
      // so the scan registers it first — asking the scope, and not asking
      // again whether it is a library.
      final opened = await openLibraries(
        tester,
        libraries: const [
          Library(uuid: 'lib-1', name: 'Rust course', rootPath: folder),
        ],
      );

      await tester.tap(find.byTooltip(messages(tester).libraryScan));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await acceptScope(tester);

      expect(opened.store.read().single.path, folder);
      expect(opened.index.starts.map((call) => call.root), [folder]);
      expect(
        opened.gateway.registered,
        isEmpty,
        reason: 'it is already a library — asking again would make it twice',
      );
    });
  });

  testWidgets('GivenAFolderThatIsAlreadyALibrary_WhenPicked_ThenItSaysSo', (
    tester,
  ) async {
    // Nothing to do, and saying so beats a button that appears to do nothing.
    final opened = await openLibraries(
      tester,
      registered: [source(folder, libraryName: 'Rust course')],
    );

    await pressAdd(tester);
    await tester.pumpAndSettle();

    expect(find.text(messages(tester).libraryAlreadyOne), findsWidgets);
    expect(opened.gateway.registered, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('GivenThePickerIsCancelled_WhenAddIsPressed_ThenNothingIsAsked', (
    tester,
  ) async {
    final opened = await openLibraries(tester, picked: null);

    await pressAdd(tester);
    await tester.pumpAndSettle();

    expect(opened.gateway.registered, isEmpty);
    expect(opened.store.read(), isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(IndexScopeDialog), findsNothing);
  });
}
