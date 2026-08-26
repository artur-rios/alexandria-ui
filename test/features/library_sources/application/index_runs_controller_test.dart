import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';

/// Starting an index run and watching it finish
/// (UC-06, FR-LB-05, FR-LB-07 … FR-LB-09).
void main() {
  const root = '/home/owner/music';
  final now = DateTime.utc(2026, 8, 19, 11);

  LibrarySource source(String path, {String? lastRunId}) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: now,
    lastRunId: lastRunId,
  );

  ({
    ProviderContainer ref,
    FakeIndexGateway gateway,
    InMemoryLibrarySourceStore store,
  })
  build({FakeIndexGateway? gateway, List<LibrarySource>? registered}) {
    final indexGateway = gateway ?? FakeIndexGateway();
    final store = InMemoryLibrarySourceStore(registered ?? [source(root)]);

    final container = ProviderContainer(
      overrides: [
        indexGatewayProvider.overrideWithValue(indexGateway),
        librarySourceStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
        // Long enough that no timer fires during a test: the observation is
        // driven by calling refresh directly.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);

    // Turned off before the session is established: this suite exercises
    // `startRefresh` through explicit calls, and `establish`'s own unawaited
    // call to `begin()` (FR-LB-21) would otherwise start one of its own and
    // race the one each test drives.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, gateway: indexGateway, store: store);
  }

  group('the main flow', () {
    test(
      'GivenARegisteredFolder_WhenAScanStarts_ThenTheCoreIsCalled',
      () async {
        final sut = build();

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(sut.gateway.starts.single.root, root);
        expect(
          sut.gateway.starts.single.credential,
          FakeAuthGateway.defaultSession.credential,
        );
      },
    );

    test(
      'GivenAScanStarts_WhenTheCoreAnswers_ThenTheRunIdIsRetained',
      () async {
        // FR-LB-05.
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(
          sut.ref.read(indexRunsControllerProvider).runFor(root)?.runId,
          sut.gateway.runId,
        );
      },
    );

    test(
      'GivenAScanStarts_WhenItIsRecorded_ThenTheFolderRemembersTheRun',
      () async {
        // AF-05 depends on this: the run must be findable after a restart.
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(sut.store.read().single.lastRunId, sut.gateway.runId);
      },
    );

    test('GivenARunInFlight_WhenItFinishes_ThenItsCountsAreShown', () async {
      // FR-LB-08.
      final sut = build(
        gateway: FakeIndexGateway()
          ..readOutcomes = [runningRun(), finishedRun()],
      );
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startIndex(root);

      await controller.refresh();

      final run = sut.ref.read(indexRunsControllerProvider).runFor(root)!;
      expect(run.status, IndexRunStatus.complete);
      expect(run.counts?.indexed, 118);
      expect(run.counts?.scanned, 120);
    });

    test('GivenAFinishedRun_WhenItSettles_ThenTheOutcomeIsRecorded', () async {
      final sut = build();

      await sut.ref.read(indexRunsControllerProvider.notifier).startIndex(root);

      final stored = sut.store.read().single;
      expect(stored.lastRunOutcome, 'complete');
      expect(stored.lastRunAt, now);
    });

    test(
      'GivenAFinishedRun_WhenItIsNotDismissed_ThenItStaysOnScreen',
      () async {
        // FR-LB-08: visible until the owner dismisses it.
        final sut = build();
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startIndex(root);

        await controller.refresh();

        expect(
          sut.ref.read(indexRunsControllerProvider).runFor(root),
          isNotNull,
        );
      },
    );

    test('GivenAFinishedRun_WhenItIsDismissed_ThenItGoes', () async {
      final sut = build();
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startIndex(root);

      controller.dismiss(root);

      expect(sut.ref.read(indexRunsControllerProvider).runFor(root), isNull);
    });
  });

  group('a second run is refused (AF-01, FR-LB-09)', () {
    test(
      'GivenARunInFlight_WhenAnotherIsStarted_ThenTheCoreIsNotCalledAgain',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startIndex(root);

        await controller.startIndex(root);

        expect(sut.gateway.starts, hasLength(1));
      },
    );

    test(
      'GivenARunInFlight_WhenAnotherIsStarted_ThenTheRefusalNamesTheFolder',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startIndex(root);

        await controller.startIndex(root);

        expect(
          sut.ref.read(indexRunsControllerProvider).refusedSecondRunFor,
          root,
        );
      },
    );

    test('GivenAFinishedRun_WhenAnotherIsStarted_ThenItRuns', () async {
      // The refusal is about a run in flight, not about ever having run.
      final sut = build();
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startIndex(root);

      await controller.startIndex(root);

      expect(sut.gateway.starts, hasLength(2));
    });
  });

  group('a refresh started without asking (FR-LB-21)', () {
    test(
      'GivenARefusalIsNotReported_WhenARefreshIsRefused_ThenNoMessageIsLeft',
      () async {
        // A re-check nobody asked for must not leave an explanation on the
        // Sources screen for a question the owner never asked. The refusal
        // still stops the run; it simply is not announced.
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startRefresh();
        expect(sut.gateway.refreshStarts, hasLength(1));

        await controller.startRefresh(reportRefusals: false);

        expect(sut.gateway.refreshStarts, hasLength(1));
        expect(
          sut.ref.read(indexRunsControllerProvider).refreshRefusal,
          isNull,
        );
      },
    );
  });

  group('the core refuses the start (AF-02, AF-03)', () {
    test(
      'GivenTheCoreRejectsTheStart_WhenItIsSent_ThenTheReasonIsKept',
      () async {
        const failure = Failure.invalidInput(
          family: CoreStatusFamily.indexing,
          code: 1,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..startOutcome = const IndexStartOutcome.failed(failure: failure),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(
          sut.ref.read(indexRunsControllerProvider).failureFor(root),
          failure,
        );
      },
    );

    test('GivenTheStartIsRefused_WhenItSettles_ThenNoRunIsRecorded', () async {
      final sut = build(
        gateway: FakeIndexGateway()
          ..startOutcome = const IndexStartOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.indexing,
              code: 1,
            ),
          ),
      );

      await sut.ref.read(indexRunsControllerProvider.notifier).startIndex(root);

      expect(sut.ref.read(indexRunsControllerProvider).runFor(root), isNull);
      expect(sut.store.read().single.lastRunId, isNull);
    });
  });

  group('the core rejects the session (AF-06)', () {
    test(
      'GivenTheStartIsUnauthorized_WhenItSettles_ThenTheOwnerIsSignedOut',
      () async {
        const failure = Failure.unauthorized(
          family: CoreStatusFamily.indexing,
          code: 2,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..startOutcome = const IndexStartOutcome.failed(failure: failure),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(
          sut.ref.read(sessionControllerProvider),
          const SessionState.absent(endedBecause: failure),
        );
      },
    );

    test(
      'GivenAReadIsUnauthorized_WhenItSettles_ThenTheOwnerIsSignedOut',
      () async {
        const failure = Failure.unauthorized(
          family: CoreStatusFamily.run,
          code: 2,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [const IndexRunOutcome.failed(failure: failure)],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(root);

        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('a run outlives the application (AF-05)', () {
    test(
      'GivenARecordedRun_WhenTheApplicationStarts_ThenItsOutcomeIsRead',
      () async {
        // The run belongs to the core, so its outcome is waiting rather than
        // lost.
        final sut = build(
          registered: [source(root, lastRunId: 'a-recorded-run')],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .resumeRecordedRuns();

        expect(sut.gateway.reads.single.runId, 'a-recorded-run');
        expect(
          sut.ref.read(indexRunsControllerProvider).runFor(root)?.status,
          IndexRunStatus.complete,
        );
      },
    );

    test(
      'GivenARunStillGoing_WhenTheApplicationStarts_ThenItIsFollowed',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
          registered: [source(root, lastRunId: 'a-recorded-run')],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .resumeRecordedRuns();

        expect(
          sut.ref.read(indexRunsControllerProvider).hasRunInFlight,
          isTrue,
        );
      },
    );

    test(
      'GivenNoRecordedRun_WhenTheApplicationStarts_ThenNothingIsRead',
      () async {
        final sut = build();

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .resumeRecordedRuns();

        expect(sut.gateway.reads, isEmpty);
      },
    );
  });

  group('one run ending never stops the others being followed', () {
    const other = '/home/owner/films';
    const unreadable = Failure.invalidInput(
      family: CoreStatusFamily.indexing,
      code: 1,
    );

    test(
      'GivenARefreshIsRunning_WhenAFolderScanFinishes_ThenTheRefreshIsStillPolled',
      () async {
        // The refresh is catalog-wide and can run for hours, while a folder
        // scan beside it finishes in minutes. Weighing only the folder scans
        // stopped the timer on the shorter one and froze the refresh on its
        // last reading, with nothing left to restart it.
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [
              runningRun(), // the folder scan, just started
              runningRun(), // the refresh, just started
              finishedRun(), // the folder scan, now complete
              runningRun(), // the refresh, still going
            ],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);

        await controller.startIndex(root);
        await controller.startRefresh();
        await controller.refresh();

        expect(sut.ref.read(indexRunsControllerProvider).isRefreshing, isTrue);
        expect(controller.debugIsPolling, isTrue);
      },
    );

    test(
      'GivenTwoFoldersScanning_WhenOneStatusIsUnreadable_ThenTheOtherIsStillPolled',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [
              runningRun(), // first folder, just started
              runningRun(), // second folder, just started
              const IndexRunOutcome.failed(failure: unreadable),
              runningRun(), // second folder, still going
            ],
          registered: [source(root), source(other)],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);

        await controller.startIndex(root);
        await controller.startIndex(other);
        await controller.refresh();

        final state = sut.ref.read(indexRunsControllerProvider);
        // The folder that could not be read drops out of the rotation rather
        // than spinning on the same error, and takes nothing else with it.
        expect(state.failureFor(root), unreadable);
        expect(state.pollableRoots, [other]);
        expect(controller.debugIsPolling, isTrue);
      },
    );

    test(
      'GivenAFolderIsScanning_WhenTheRefreshStatusIsUnreadable_ThenTheFolderIsStillPolled',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [
              runningRun(), // the folder scan, just started
              runningRun(), // the refresh, just started
              runningRun(), // the folder scan, still going
              const IndexRunOutcome.failed(failure: unreadable),
            ],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);

        await controller.startIndex(root);
        await controller.startRefresh();
        await controller.refresh();

        final state = sut.ref.read(indexRunsControllerProvider);
        expect(state.refreshFailure, unreadable);
        expect(state.pollableRoots, [root]);
        expect(controller.debugIsPolling, isTrue);
      },
    );
  });
}
