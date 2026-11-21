import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_folder_picker.dart';
import '../../../support/shell_harness.dart';

/// Correcting a library's root after its folder moved (UC-49 AF-04 /
/// core FR-FC-41).
///
/// A move is a correction, not a re-index: what this screen has to get right
/// is that the core is told, and that its refusal — the folder overlaps
/// another library, or the library has an unfinished run — is said.
void main() {
  const from = '/library/course';
  const to = '/media/courses/rust';
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: from);

  Future<({ProviderContainer container, FakeLibraryGateway gateway})>
  openLibraries(
    WidgetTester tester, {
    String? picked = to,
    List<LibraryWrite> writeOutcomes = const [],
  }) async {
    final gateway = FakeLibraryGateway(libraries: const [course])
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: picked)),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.libraries.icon),
      ),
    );
    await tester.pumpAndSettle();

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesView)));

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

  testWidgets('GivenThePickerIsCancelled_WhenMoveIsPressed_ThenNothingMoves', (
    tester,
  ) async {
    final opened = await openLibraries(tester, picked: null);

    await pressMove(tester);

    expect(opened.gateway.moved, isEmpty);
    expect(opened.gateway.libraries.single.rootPath, from);
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
          failure: Failure.conflict(family: CoreStatusFamily.library, code: 6),
        ),
      ],
    );

    await pressMove(tester);

    // `findsWidgets`, not `findsOneWidget`: a ScaffoldMessenger renders its
    // snackbar into every Scaffold registered under it, and this screen is a
    // full-screen dialog over the shell — so the message exists twice in the
    // tree and is visible once, on top.
    expect(find.text(messages(tester).libraryMoveConflict), findsWidgets);
    expect(opened.gateway.libraries.single.rootPath, from);
  });
}
