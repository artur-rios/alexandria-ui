import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/library_sources/presentation/run_failures_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// Naming the files a run could not record (UC-06 AF-08 / core FR-FC-42).
///
/// The count on the folder's row says how many; this says which. Without it
/// the owner is told a number about files that are on disk, in no listing, in
/// no search, and named nowhere they can reach.
void main() {
  const root = '/home/owner/music';
  const runId = 'a-recorded-run';
  final registeredAt = DateTime.utc(2026, 8, 31, 9);

  IndexRunOutcome finishedWith(int failed) => IndexRunOutcome.read(
    run: IndexRun(
      runId: runId,
      root: root,
      kind: IndexRunKind.scan,
      status: IndexRunStatus.complete,
      counts: IndexRunCounts(scanned: 40, indexed: 40 - failed, failed: failed),
    ),
  );

  Future<FakeIndexGateway> openScreen(
    WidgetTester tester, {
    int failed = 2,
    RunFailuresOutcome? failures,
  }) async {
    final gateway = FakeIndexGateway()..readOutcomes = [finishedWith(failed)];
    if (failures != null) gateway.failures[runId] = failures;

    await tester.pumpShell(
      extraOverrides: <Override>[
        indexGatewayProvider.overrideWithValue(gateway),
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore([
            LibrarySource(
              path: root,
              label: 'music',
              registeredAt: registeredAt,
              lastRunId: runId,
            ),
          ]),
        ),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );

    final shell = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(shell.librarySourcesOpen);
    await tester.pumpAndSettle();

    return gateway;
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LibrarySourcesScreen)));

  testWidgets(
    'GivenARunDroppedFiles_WhenTheReportIsRead_ThenTheListIsOffered',
    (tester) async {
      await openScreen(tester);

      expect(find.text(messages(tester).runFailuresOpen), findsOneWidget);
    },
  );

  testWidgets(
    'GivenARunDroppedNothing_WhenTheReportIsRead_ThenNoListIsOffered',
    (tester) async {
      // The half that makes the test above mean something: a clean run has no
      // list worth opening.
      await openScreen(tester, failed: 0);

      expect(find.text(messages(tester).runFailuresOpen), findsNothing);
    },
  );

  testWidgets(
    'GivenTheListIsOpened_WhenItLoads_ThenEachFileIsNamedWithItsReason',
    (tester) async {
      // The whole point: a path the owner can go and look at, and the reason
      // in the core's own words.
      await openScreen(
        tester,
        failures: const RunFailuresOutcome.read(
          failures: [
            RunFailure(
              path: '/home/owner/music/locked.mp3',
              reason: 'permission denied',
            ),
            RunFailure(
              path: '/home/owner/music/odd.mp3',
              reason: 'database is locked',
            ),
          ],
        ),
      );

      await tester.tap(find.text(messages(tester).runFailuresOpen));
      await tester.pumpAndSettle();

      expect(find.byType(RunFailuresScreen), findsOneWidget);
      expect(find.text('/home/owner/music/locked.mp3'), findsOneWidget);
      expect(find.text('permission denied'), findsOneWidget);
      expect(find.text('/home/owner/music/odd.mp3'), findsOneWidget);
    },
  );

  testWidgets('GivenTheListIsOpened_WhenItIsAskedFor_ThenItIsThatRunsList', (
    tester,
  ) async {
    // Keyed by run: a list read for the wrong run would send the owner to
    // files that are perfectly fine.
    final gateway = await openScreen(
      tester,
      failures: const RunFailuresOutcome.read(failures: []),
    );

    await tester.tap(find.text(messages(tester).runFailuresOpen));
    await tester.pumpAndSettle();

    expect(gateway.failuresRequested, [runId]);
  });

  testWidgets(
    'GivenTheCoreRecordedFewerThanItCounted_WhenTheListIsOpened_ThenTheGapIsNamed',
    (tester) async {
      // The core bounds how many paths one run records and keeps counting past
      // the bound, so the list is allowed to be shorter than the tally. Said
      // out loud, or the owner reads a report of four dropped files, counts two
      // in the list, and has no way to tell a limit from a lost file.
      await openScreen(
        tester,
        failed: 4,
        failures: const RunFailuresOutcome.read(
          failures: [
            RunFailure(
              path: '/home/owner/music/one.mp3',
              reason: 'permission denied',
            ),
            RunFailure(
              path: '/home/owner/music/two.mp3',
              reason: 'permission denied',
            ),
          ],
        ),
      );

      await tester.tap(find.text(messages(tester).runFailuresOpen));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RunFailuresScreen)),
      );
      expect(find.text(l10n.runFailuresTruncated(2, 4)), findsOneWidget);
    },
  );

  testWidgets(
    'GivenEveryDroppedFileIsNamed_WhenTheListIsOpened_ThenNoGapIsClaimed',
    (tester) async {
      // The half that makes the test above mean something. Saying "the first 2
      // of 2" on a complete list would train the owner to skip the line on the
      // one occasion it matters.
      await openScreen(
        tester,
        failed: 2,
        failures: const RunFailuresOutcome.read(
          failures: [
            RunFailure(
              path: '/home/owner/music/one.mp3',
              reason: 'permission denied',
            ),
            RunFailure(
              path: '/home/owner/music/two.mp3',
              reason: 'permission denied',
            ),
          ],
        ),
      );

      await tester.tap(find.text(messages(tester).runFailuresOpen));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RunFailuresScreen)),
      );
      expect(find.text(l10n.runFailuresTruncated(2, 2)), findsNothing);
    },
  );

  testWidgets(
    'GivenTheCoreCannotAnswer_WhenTheListIsOpened_ThenItSaysSoNotEmpty',
    (tester) async {
      // "Could not ask" and "nothing to show" are answers the owner would act
      // on differently — an empty list here would say the scan was clean.
      await openScreen(
        tester,
        failures: const RunFailuresOutcome.failed(
          failure: Failure.unexpected(family: CoreStatusFamily.run, code: 9),
        ),
      );

      await tester.tap(find.text(messages(tester).runFailuresOpen));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RunFailuresScreen)),
      );
      expect(find.text(l10n.runFailuresNone), findsNothing);
      expect(find.text(l10n.retry), findsOneWidget);
    },
  );
}
