import 'package:alexandria_ui/core/di/providers.dart';
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

/// Correcting a library's root after its folder moved (UC-49 AF-04 /
/// core FR-FC-41).
///
/// A move is a correction, not a re-index: what this screen has to get right
/// is that the core is told, and that the folder's own registration follows —
/// a source folder still pointing at where the library used to be is one
/// whose next scan walks a folder that is not there.
void main() {
  const from = '/library/course';
  const to = '/media/courses/rust';
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: from);

  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  LibrarySource marked(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
    libraryName: 'Course',
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
    String? picked = to,
    List<LibrarySource>? registered,
    List<LibraryWrite> writeOutcomes = const [],
  }) async {
    final gateway = FakeLibraryGateway(libraries: const [course])
      ..writeOutcomes.addAll(writeOutcomes);
    final store = InMemoryLibrarySourceStore(registered ?? [marked(from)]);

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        folderPickerProvider.overrideWithValue(
          FakeFolderPicker(path: picked),
        ),
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

  Future<void> pressMove(WidgetTester tester) async {
    await tester.tap(find.byTooltip(messages(tester).libraryMove));
    await tester.pumpAndSettle();
  }

  testWidgets('GivenTheFolderMoved_WhenItIsPicked_ThenTheCoreIsTold', (
    tester,
  ) async {
    final opened = await openLibraries(tester);

    await pressMove(tester);

    expect(opened.gateway.moved, [(uuid: 'lib-1', rootPath: to)]);
  });

  testWidgets('GivenTheFolderMoved_WhenItIsPicked_ThenTheRowShowsWhereItIs', (
    tester,
  ) async {
    await openLibraries(tester);

    await pressMove(tester);

    expect(find.text(to), findsOneWidget);
    expect(
      find.text(from),
      findsNothing,
      reason: 'the listing was not re-read after the move',
    );
  });

  testWidgets('GivenAMovedLibrary_WhenItSettles_ThenItsSourceFolderFollows', (
    tester,
  ) async {
    // Otherwise the registration points at somewhere that is no longer
    // there, and the next scan of it walks a missing folder.
    final opened = await openLibraries(tester);

    await pressMove(tester);

    expect(opened.store.read().single.path, to);
    expect(
      opened.store.read().single.libraryName,
      'Course',
      reason: 'following the move must not unmark the folder',
    );
  });

  testWidgets('GivenThePickerIsCancelled_WhenMoveIsPressed_ThenNothingMoves', (
    tester,
  ) async {
    final opened = await openLibraries(tester, picked: null);

    await pressMove(tester);

    expect(opened.gateway.moved, isEmpty);
    expect(opened.store.read().single.path, from);
  });

  testWidgets('GivenTheCoreRefuses_WhenTheFolderIsPicked_ThenItIsSaidPlainly', (
    tester,
  ) async {
    // The two conflicts a move answers — the destination overlapping another
    // library, or the catalog already holding files there — are one sentence
    // the owner can act on rather than a generic refusal.
    final opened = await openLibraries(
      tester,
      writeOutcomes: const [
        LibraryWrite.failed(
          failure: Failure.conflict(
            family: CoreStatusFamily.library,
            code: 6,
          ),
        ),
      ],
    );

    await pressMove(tester);

    // `findsWidgets`, not `findsOneWidget`: a ScaffoldMessenger renders its
    // snackbar into every Scaffold registered under it, and this screen is a
    // full-screen dialog over the shell — so the message exists twice in the
    // tree and is visible once, on top.
    expect(find.text(messages(tester).libraryMoveConflict), findsWidgets);
    expect(
      opened.store.read().single.path,
      from,
      reason: 'a refused move must not move the source folder either',
    );
  });

  testWidgets(
    'GivenTheDestinationIsAlreadyRegistered_WhenTheLibraryMoves_ThenTheSourcesAreLeftAlone',
    (tester) async {
      // Two registrations collapsing into one would silently drop the
      // other's scope. The library still moves; the folder's record is what
      // stays behind, which is visible and correctable.
      final opened = await openLibraries(
        tester,
        registered: [
          marked(from),
          LibrarySource(
            path: to,
            label: defaultLabelFor(to),
            registeredAt: registeredAt,
          ),
        ],
      );

      await pressMove(tester);

      expect(opened.gateway.moved, hasLength(1));
      expect(
        opened.store.read().map((source) => source.path),
        [from, to],
        reason: 'a registration was overwritten',
      );
    },
  );
}
