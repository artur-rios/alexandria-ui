import 'dart:async';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Adding a library and scanning it again (libraries-only design §3).
///
/// On the 0.6.0 core a library is the only way into the catalog: adding one
/// starts its first run, which the screen follows under the new row, and a
/// library is scanned again from its own row.
void main() {
  const folder = '/media/courses/rust';
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: folder);

  Future<
    ({
      ProviderContainer container,
      FakeLibraryGateway gateway,
      FakeIndexGateway index,
    })
  >
  openLibraries(
    WidgetTester tester, {
    String? picked = folder,
    List<LibraryRegistration> registerOutcomes = const [],
    List<Library> libraries = const [],
    FakeIndexGateway? index,
  }) async {
    final gateway = FakeLibraryGateway(libraries: libraries)
      ..registerOutcomes.addAll(registerOutcomes);
    final theIndex =
        index ?? (FakeIndexGateway()..readOutcomes = [runningRun()]);

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      // Off, or the startup re-check races the run this test drives.
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: picked)),
        indexGatewayProvider.overrideWithValue(theIndex),
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

    return (container: container, gateway: gateway, index: theIndex);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesView)));

  /// Presses the button, which opens the picker.
  Future<void> pressAdd(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, messages(tester).libraryAdd),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
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

  group('adding a library', () {
    testWidgets(
      'GivenAPickedFolderAndName_WhenAdded_ThenRegisteredAndItsRunShows',
      (tester) async {
        final opened = await openLibraries(tester);

        await pressAdd(tester);
        await acceptName(tester, name: 'Rust course');

        expect(opened.gateway.registered.single, (
          name: 'Rust course',
          rootPath: folder,
        ));
        expect(find.text('Rust course'), findsOneWidget);
        // The core started the run with the library; this screen only
        // follows it, and starts nothing of its own.
        expect(opened.index.libraryStarts, isEmpty);
        expect(opened.index.reads.single.runId, 'run-1');
        expect(find.text(messages(tester).libraryRunStarting), findsOneWidget);
      },
    );

    testWidgets('GivenAPickedFolder_WhenNamed_ThenTheFolderNameIsSuggested', (
      tester,
    ) async {
      final opened = await openLibraries(tester);

      await pressAdd(tester);
      await acceptName(tester);

      expect(opened.gateway.registered.single.name, 'rust');
    });

    testWidgets(
      'GivenAnOverlappingFolder_WhenAdded_ThenTheRefusalShowsAndNothingIsAdded',
      (tester) async {
        final opened = await openLibraries(
          tester,
          registerOutcomes: const [
            LibraryRegistration.failed(
              failure: Failure.conflict(
                family: CoreStatusFamily.library,
                code: LIBRARY_ERR_CONFLICT,
              ),
            ),
          ],
        );

        await pressAdd(tester);
        await acceptName(tester);

        // `findsWidgets`: the snackbar is drawn by every scaffold registered
        // with the one messenger.
        expect(find.text(messages(tester).libraryOverlaps), findsWidgets);
        expect(opened.gateway.libraries, isEmpty);
        expect(opened.index.reads, isEmpty);
      },
    );

    testWidgets(
      'GivenAFolderTheCoreCannotIndex_WhenAdded_ThenTheReasonIsSaid',
      (tester) async {
        const missing = Failure.invalidInput(
          family: CoreStatusFamily.library,
          code: LIBRARY_ERR_INVALID_INPUT,
        );
        await openLibraries(
          tester,
          registerOutcomes: const [
            LibraryRegistration.failed(failure: missing),
          ],
        );

        await pressAdd(tester);
        await acceptName(tester);

        expect(find.byType(SnackBar), findsWidgets);
        expect(find.text('Course'), findsNothing);
      },
    );

    testWidgets(
      'GivenThePickerIsCancelled_WhenAddIsPressed_ThenNothingIsAsked',
      (tester) async {
        final opened = await openLibraries(tester, picked: null);

        await pressAdd(tester);
        await tester.pumpAndSettle();

        expect(opened.gateway.registered, isEmpty);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('scanning a library again', () {
    Future<void> pressScan(WidgetTester tester) async {
      await tester.tap(find.byTooltip(messages(tester).libraryScan));
      await tester.pumpAndSettle();
    }

    testWidgets('GivenALibrary_WhenScanAgain_ThenALibraryRunStarts', (
      tester,
    ) async {
      final opened = await openLibraries(tester, libraries: [course]);

      await pressScan(tester);

      expect(opened.index.libraryStarts.single.uuid, course.uuid);
      expect(find.text(messages(tester).libraryRunStarting), findsOneWidget);
    });

    testWidgets(
      'GivenAnUnfinishedRun_WhenScanAgainTwice_ThenTheConflictIsSaidAndOneRunStarts',
      (tester) async {
        final opened = await openLibraries(tester, libraries: [course]);

        await pressScan(tester);
        await pressScan(tester);

        expect(opened.index.libraryStarts, hasLength(1));
        expect(find.text(messages(tester).libraryScanConflict), findsWidgets);
      },
    );

    testWidgets(
      'GivenTheCoreAnswersConflict_WhenScanAgain_ThenTheConflictIsSaid',
      (tester) async {
        await openLibraries(
          tester,
          libraries: [course],
          index: FakeIndexGateway()
            ..libraryStartOutcomes.add(
              const IndexStartOutcome.failed(
                failure: Failure.conflict(
                  family: CoreStatusFamily.indexing,
                  code: INDEX_ERR_CONFLICT,
                ),
              ),
            ),
        );

        await pressScan(tester);

        expect(find.text(messages(tester).libraryScanConflict), findsWidgets);
      },
    );

    testWidgets('GivenAFinishedRun_WhenItSettles_ThenItsCountsAreShown', (
      tester,
    ) async {
      await openLibraries(
        tester,
        libraries: [course],
        index: FakeIndexGateway()..readOutcomes = [finishedRun()],
      );

      await pressScan(tester);

      expect(
        find.text(messages(tester).libraryRunComplete(120, 118, 0)),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenAPausedRunFromAnotherSession_WhenTheScreenOpens_ThenItReadsAsResumable',
      (tester) async {
        await openLibraries(
          tester,
          libraries: [course],
          index: FakeIndexGateway()
            ..activeRunsOutcome = const ActiveRunsOutcome.read(
              runs: [
                IndexRun(
                  runId: 'r-old',
                  root: folder,
                  libraryUuid: 'lib-1',
                  status: IndexRunStatus.paused,
                ),
              ],
            ),
        );

        expect(find.text(messages(tester).libraryRunPaused), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(LibrariesView),
            matching: find.byTooltip(messages(tester).libraryRunResume),
          ),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets(
    'GivenTheLibrariesScreen_WhenRefreshAllTapped_ThenARefreshStarts',
    (tester) async {
      final opened = await openLibraries(tester, libraries: [course]);

      await tester.tap(find.text(messages(tester).libraryRefreshAll));
      // Pumped rather than settled: the button spins while the refresh runs.
      await tester.pump();
      await tester.pump();

      expect(opened.index.refreshStarts, hasLength(1));
    },
  );

  group('adding from an empty catalog', () {
    testWidgets(
      'GivenAnEmptyDashboard_WhenAddIsPressedAndAFolderPickedLater_ThenTheLibraryIsAdded',
      (tester) async {
        // The native picker is open for seconds, and pressing the button
        // switches to the Libraries screen meanwhile — so the dashboard that
        // asked is gone by the time the folder comes back.
        final gate = Completer<void>();
        final gateway = FakeLibraryGateway();
        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          settings: InMemorySettingsStore(rechecksAtStartup: false),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
            libraryGatewayProvider.overrideWithValue(gateway),
            folderPickerProvider.overrideWithValue(
              FakeFolderPicker(path: folder, gate: gate),
            ),
            indexGatewayProvider.overrideWithValue(
              FakeIndexGateway()..readOutcomes = [runningRun()],
            ),
            runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
          ],
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellNavigationPanel)),
        );

        await tester.tap(find.widgetWithText(FilledButton, l10n.libraryAdd));
        await tester.pumpAndSettle();
        expect(find.byType(LibrariesView), findsOneWidget);

        gate.complete();
        await tester.pumpAndSettle();
        await acceptName(tester, name: 'Rust course');

        expect(gateway.registered.single, (
          name: 'Rust course',
          rootPath: folder,
        ));
      },
    );
  });
}
