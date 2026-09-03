import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_tree_screen.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// Making a library from the screen that lists them (libraries design).
///
/// Making one used to be reachable only while a folder was being registered,
/// or from that folder's own row on the sources screen — neither of which is
/// where an owner looking at their libraries goes to add one.
void main() {
  const folder = '/media/courses/rust';
  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  LibrarySource unmarked(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
  );

  Future<
    ({
      ProviderContainer container,
      FakeLibraryGateway gateway,
      InMemoryLibrarySourceStore store,
    })
  >
  openLibraries(
    WidgetTester tester, {
    String? picked = folder,
    List<LibrarySource>? registered,
    List<LibraryWrite> writeOutcomes = const [],
  }) async {
    final gateway = FakeLibraryGateway(libraries: const <Library>[])
      ..writeOutcomes.addAll(writeOutcomes);
    final store = InMemoryLibrarySourceStore(registered ?? [unmarked(folder)]);

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: picked)),
        librarySourceStoreProvider.overrideWithValue(store),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librariesOpen);
    await tester.pumpAndSettle();

    return (container: container, gateway: gateway, store: store);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesScreen)));

  /// Presses the button and answers the name dialog, keeping the suggested
  /// name unless [name] is given.
  Future<void> addLibrary(WidgetTester tester, {String? name}) async {
    final l10n = messages(tester);
    await tester.tap(find.widgetWithText(FilledButton, l10n.libraryAdd));
    await tester.pumpAndSettle();

    // Scoped to the dialog: the shell's own catalog search is a text field
    // too, and an unscoped finder types the library's name into it.
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    if (name != null) {
      await tester.enterText(field, name);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l10n.libraryAdd),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('GivenAPickedFolder_WhenNamed_ThenTheCoreIsToldToRegisterIt', (
    tester,
  ) async {
    final opened = await openLibraries(tester);

    await addLibrary(tester, name: 'Rust course');

    expect(opened.gateway.registered, [
      (name: 'Rust course', rootPath: folder),
    ]);
  });

  testWidgets('GivenTheNameDialog_WhenItOpens_ThenTheFolderNameIsSuggested', (
    tester,
  ) async {
    // A directory called `2024-final-v2` is a path, not a title — so the
    // suggestion is editable, and it is the folder's own name rather than
    // its whole path.
    final opened = await openLibraries(tester);

    await addLibrary(tester);

    expect(opened.gateway.registered, [(name: 'rust', rootPath: folder)]);
  });

  testWidgets('GivenANewLibrary_WhenItIsMade_ThenItsSourceFolderIsMarked', (
    tester,
  ) async {
    // Registering with the core and marking the folder are one action:
    // doing only the first leaves the sources screen offering to mark a
    // folder that is already a library.
    final opened = await openLibraries(tester);

    await addLibrary(tester, name: 'Rust course');

    expect(opened.store.read().single.libraryName, 'Rust course');
  });

  testWidgets('GivenAFolderThatIsNotRegistered_WhenMade_ThenItStillWorks', (
    tester,
  ) async {
    // A library can be made of a folder that is not a source: nothing marks,
    // and the registration still happens.
    final opened = await openLibraries(tester, registered: const []);

    await addLibrary(tester, name: 'Rust course');

    expect(opened.gateway.registered, [
      (name: 'Rust course', rootPath: folder),
    ]);
    expect(opened.store.read(), isEmpty);
  });

  testWidgets('GivenThePickerIsCancelled_WhenAddIsPressed_ThenNothingIsAsked', (
    tester,
  ) async {
    final opened = await openLibraries(tester, picked: null);

    await tester.tap(
      find.widgetWithText(FilledButton, messages(tester).libraryAdd),
    );
    await tester.pumpAndSettle();

    expect(opened.gateway.registered, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('GivenAnOverlappingFolder_WhenMade_ThenTheRefusalIsSaidPlainly', (
    tester,
  ) async {
    // "That folder is already inside another library" is something the owner
    // can act on, where a generic refusal is a puzzle.
    final opened = await openLibraries(
      tester,
      writeOutcomes: const [
        LibraryWrite.failed(
          failure: Failure.conflict(
            family: CoreStatusFamily.library,
            code: LIBRARY_ERR_CONFLICT,
          ),
        ),
      ],
    );

    await addLibrary(tester, name: 'Rust course');

    // `findsWidgets`, not `findsOneWidget`: the screen is a full-screen
    // dialog over the shell, so both scaffolds are registered with the one
    // messenger and each draws the snackbar — as they already do for the
    // refusals `_move` reports.
    expect(find.text(messages(tester).libraryOverlaps), findsWidgets);
    expect(
      opened.store.read().single.libraryName,
      isNull,
      reason: 'a refused registration must not mark the folder',
    );
  });
}
