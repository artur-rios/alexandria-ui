import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/failures/failure_messages.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Removing a library (core 0.6.0), which deletes its catalog records: the
/// confirmation has to say so plainly, and a paused scan goes with it.
void main() {
  const course = Library(
    uuid: 'lib-1',
    name: 'Course',
    rootPath: '/media/courses',
  );

  Future<FakeLibraryGateway> openLibraries(
    WidgetTester tester, {
    List<IndexRun> active = const [],
    List<LibraryWrite> writeOutcomes = const [],
  }) async {
    final gateway = FakeLibraryGateway(libraries: [course])
      ..writeOutcomes.addAll(writeOutcomes);

    await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(gateway),
        indexGatewayProvider.overrideWithValue(
          FakeIndexGateway()
            ..activeRunsOutcome = ActiveRunsOutcome.read(runs: active),
        ),
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

    return gateway;
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrariesView)));

  Future<void> askToRemove(WidgetTester tester) async {
    await tester.tap(find.byTooltip(messages(tester).libraryRemove));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, messages(tester).libraryRemove),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenALibrary_WhenRemoveIsAsked_ThenTheMessageSaysItsRecordsAreDeleted',
    (tester) async {
      await openLibraries(tester);

      await askToRemove(tester);

      final l10n = messages(tester);
      expect(find.text(l10n.libraryRemoveMessage('Course')), findsOneWidget);
      expect(l10n.libraryRemoveMessage('Course'), contains('deleted'));
      expect(l10n.libraryRemoveMessage('Course'), contains('Nothing on disk'));
      expect(l10n.libraryRemoveMessage('Course'), isNot(contains('go back')));
    },
  );

  testWidgets(
    'GivenAPausedRun_WhenRemoveIsAsked_ThenTheMessageSaysThePausedScanIsDiscarded',
    (tester) async {
      await openLibraries(
        tester,
        active: const [
          IndexRun(
            runId: 'r1',
            root: '/media/courses',
            libraryUuid: 'lib-1',
            status: IndexRunStatus.paused,
          ),
        ],
      );

      await askToRemove(tester);

      final l10n = messages(tester);
      expect(
        find.text(
          '${l10n.libraryRemoveMessage('Course')} ${l10n.libraryRemovePausedNote}',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('GivenAConfirmedRemoval_WhenItIsDone_ThenTheLibraryGoes', (
    tester,
  ) async {
    final gateway = await openLibraries(tester);

    await askToRemove(tester);
    await confirm(tester);

    expect(gateway.removed, ['lib-1']);
  });

  testWidgets('GivenARunningRun_WhenRemoved_ThenTheRefusalIsSaid', (
    tester,
  ) async {
    const conflict = Failure.conflict(
      family: CoreStatusFamily.library,
      code: LIBRARY_ERR_CONFLICT,
    );
    await openLibraries(
      tester,
      writeOutcomes: const [LibraryWrite.failed(failure: conflict)],
    );

    await askToRemove(tester);
    await confirm(tester);

    expect(
      find.text(conflict.localizedMessage(messages(tester))),
      findsWidgets,
    );
    expect(find.text('Course'), findsOneWidget);
  });
}
