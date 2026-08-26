import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';

/// Tracking every outstanding run in one place (FR-FC-29).
void main() {
  const pausedRun = IndexRun(
    runId: 'r-paused',
    root: '/home/owner/music',
    status: IndexRunStatus.paused,
  );

  const runningRun = IndexRun(
    runId: 'r-running',
    root: '/home/owner/video',
    status: IndexRunStatus.running,
    total: 100,
    processed: 10,
    activeMillis: 1000,
  );

  const secondRun = IndexRun(
    runId: 'r-second',
    root: '/home/owner/books',
    status: IndexRunStatus.running,
    total: 40,
    processed: 4,
    activeMillis: 1000,
  );

  ProviderContainer harness({required FakeGateway gateway}) {
    final container = ProviderContainer(
      overrides: [
        indexGatewayProvider.overrideWithValue(gateway),
        // Long enough that no timer fires during a test: the observation is
        // driven by calling refresh directly.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);

    // Turned off before the session is established: this suite drives
    // `ActiveRunsController.refresh` explicitly, and `establish`'s own
    // unawaited call to `begin()` (FR-LB-21) would otherwise start a refresh
    // of its own and race it.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return container;
  }

  test('GivenAPausedRunAtLaunch_WhenRefreshed_ThenItIsReported', () async {
    final container = harness(gateway: FakeGateway(active: [pausedRun]));

    await container.read(activeRunsControllerProvider.notifier).refresh();

    expect(
      container.read(activeRunsControllerProvider).runs.single.status,
      IndexRunStatus.paused,
    );
  });

  // The first reading is the controller's own job. Nothing else asks for it —
  // polling cannot bootstrap itself, because it only starts once a running run
  // is known — and leaving it to whichever widget happens to mount first would
  // make the application's first read of core state a question of navigation.
  test(
    'GivenAPausedRunAtLaunch_WhenTheControllerIsBuilt_ThenItReadsUnasked',
    () async {
      final container = harness(gateway: FakeGateway(active: [pausedRun]));

      container.read(activeRunsControllerProvider);
      await pumpEventQueue();

      expect(
        container.read(activeRunsControllerProvider).runs.single.status,
        IndexRunStatus.paused,
      );
    },
  );

  // A paused run makes no progress, so polling it changes nothing. Its state
  // moves only when the owner acts, and the action's own response updates
  // the strip.
  test('GivenOnlyPausedRuns_WhenRefreshed_ThenPollingStops', () async {
    final container = harness(gateway: FakeGateway(active: [pausedRun]));
    final controller = container.read(activeRunsControllerProvider.notifier);

    await controller.refresh();

    expect(controller.debugIsPolling, isFalse);
  });

  test('GivenARunningRun_WhenRefreshed_ThenPollingContinues', () async {
    final container = harness(gateway: FakeGateway(active: [runningRun]));
    final controller = container.read(activeRunsControllerProvider.notifier);

    await controller.refresh();

    expect(controller.debugIsPolling, isTrue);
  });

  // Showing nothing because one read failed would report "no work running"
  // on no evidence.
  test('GivenAFailedPoll_WhenRefreshed_ThenTheKnownRunsAreKept', () async {
    final gateway = FakeGateway(active: [runningRun]);
    final container = harness(gateway: gateway);
    final controller = container.read(activeRunsControllerProvider.notifier);
    await controller.refresh();

    gateway.failNext = true;
    await controller.refresh();

    expect(container.read(activeRunsControllerProvider).runs, hasLength(1));
  });

  test(
    'GivenARunThatDisappeared_WhenRefreshed_ThenItIsHeldAsJustFinished',
    () async {
      final gateway = FakeGateway(active: [runningRun])
        ..terminal[runningRun.runId] = finishedRun(
          runId: runningRun.runId,
          root: runningRun.root,
        );
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      gateway.active = [];
      await controller.refresh();

      expect(
        container.read(activeRunsControllerProvider).justFinished?.runId,
        runningRun.runId,
      );
    },
  );

  // The active list holds only outstanding runs, so the snapshot of a run
  // that has just left it always says `running` or `paused` — never how it
  // actually ended. Holding that snapshot would make a completion and a
  // failure indistinguishable from each other, and unreportable by anything
  // downstream that reads the status.
  test(
    'GivenARunThatCompleted_WhenItLeavesTheActiveList_ThenTheTerminalStatusIsHeld',
    () async {
      final gateway = FakeGateway(active: [runningRun])
        ..terminal[runningRun.runId] = finishedRun(
          runId: runningRun.runId,
          root: runningRun.root,
        );
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      gateway.active = [];
      await controller.refresh();

      expect(
        container.read(activeRunsControllerProvider).justFinished?.status,
        IndexRunStatus.complete,
      );
    },
  );

  // A failure that vanishes unseen is the one outcome the strip exists to
  // prevent, and it can only be told apart from a completion by the status
  // read back after the run left the list.
  test(
    'GivenARunThatFailed_WhenItLeavesTheActiveList_ThenTheFailureIsHeld',
    () async {
      final gateway = FakeGateway(active: [runningRun])
        ..terminal[runningRun.runId] = finishedRun(
          runId: runningRun.runId,
          root: runningRun.root,
          status: IndexRunStatus.failed,
        );
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      gateway.active = [];
      await controller.refresh();

      expect(
        container.read(activeRunsControllerProvider).justFinished?.status,
        IndexRunStatus.failed,
      );
    },
  );

  // A run the core no longer knows cannot be reported on honestly, and
  // guessing at an outcome is worse than saying nothing. What must not happen
  // is the read wedging the controller: the run still leaves the list, and
  // whatever is left is still followed.
  test(
    'GivenATerminalReadThatFails_WhenARunLeavesTheActiveList_ThenNothingIsHeld',
    () async {
      final gateway = FakeGateway(active: [runningRun, pausedRun]);
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      // No terminal answer registered, so the read fails.
      gateway.active = [pausedRun];
      await controller.refresh();

      final state = container.read(activeRunsControllerProvider);
      expect(state.justFinished, isNull);
      expect(state.runs.single.runId, pausedRun.runId);
      expect(state.failure, isNull);
    },
  );

  // Two runs can drop off the same reading, and only one of them can be
  // reported. Deciding by list order would lose the failure half the time.
  test(
    'GivenTwoRunsThatEndTogether_WhenRefreshed_ThenTheFailureIsTheOneHeld',
    () async {
      final gateway = FakeGateway(active: [secondRun, runningRun])
        ..terminal[secondRun.runId] = finishedRun(
          runId: secondRun.runId,
          root: secondRun.root,
        )
        ..terminal[runningRun.runId] = finishedRun(
          runId: runningRun.runId,
          root: runningRun.root,
          status: IndexRunStatus.failed,
        );
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      gateway.active = [];
      await controller.refresh();

      expect(
        container.read(activeRunsControllerProvider).justFinished?.status,
        IndexRunStatus.failed,
      );
    },
  );

  // FR-FC-29: the held outcome is one slot, and a failure standing in it is
  // the thing the owner has not seen yet. A second run finishing thirty
  // seconds later must not push it off before it was read.
  test(
    'GivenAHeldFailure_WhenAnotherRunCompletes_ThenTheFailureStillStands',
    () async {
      final gateway = FakeGateway(active: [runningRun, secondRun])
        ..terminal[runningRun.runId] = finishedRun(
          runId: runningRun.runId,
          root: runningRun.root,
          status: IndexRunStatus.failed,
        )
        ..terminal[secondRun.runId] = finishedRun(
          runId: secondRun.runId,
          root: secondRun.root,
        );
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);
      await controller.refresh();

      gateway.active = [secondRun];
      await controller.refresh();
      gateway.active = [];
      await controller.refresh();

      expect(
        container.read(activeRunsControllerProvider).justFinished?.runId,
        runningRun.runId,
      );
      expect(
        container.read(activeRunsControllerProvider).justFinished?.status,
        IndexRunStatus.failed,
      );
    },
  );

  test(
    'GivenAControlCallRefusedForState_WhenPaused_ThenTheRunsAreRereadNotErrored',
    () async {
      final gateway = FakeGateway(active: [runningRun], pauseFails: true);
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);

      await controller.pause(runningRun.runId);

      expect(container.read(activeRunsControllerProvider).failure, isNull);
      expect(gateway.listCalls, greaterThan(0));
    },
  );

  test('GivenAJustFinishedRun_WhenDismissed_ThenItIsCleared', () async {
    final gateway = FakeGateway(active: [runningRun])
      ..terminal[runningRun.runId] = finishedRun(
        runId: runningRun.runId,
        root: runningRun.root,
      );
    final container = harness(gateway: gateway);
    final controller = container.read(activeRunsControllerProvider.notifier);
    await controller.refresh();
    gateway.active = [];
    await controller.refresh();

    controller.dismissFinished();

    expect(container.read(activeRunsControllerProvider).justFinished, isNull);
  });

  test(
    'GivenManySamples_WhenARunKeepsProgressing_ThenTheWindowIsCapped',
    () async {
      final gateway = FakeGateway(active: [runningRun]);
      final container = harness(gateway: gateway);
      final controller = container.read(activeRunsControllerProvider.notifier);

      for (var i = 0; i < 15; i++) {
        gateway.active = [
          runningRun.copyWith(processed: 10 + i, activeMillis: 1000 + i * 100),
        ];
        await controller.refresh();
      }

      expect(
        container.read(activeRunsControllerProvider).samples[runningRun.runId],
        hasLength(10),
      );
    },
  );
}

/// An [IndexGateway] whose active-run list is driven by the test rather than
/// replayed like [FakeIndexGateway]'s default — this task's tests move the
/// active list around between refreshes, which is easier to express as a
/// field to mutate than as a queue to advance.
class FakeGateway extends FakeIndexGateway {
  FakeGateway({required this.active, bool pauseFails = false}) {
    if (pauseFails) {
      pauseOutcome = const RunControlOutcome.failed(
        failure: Failure.invalidState(
          family: CoreStatusFamily.run,
          code: 5, // RUN_ERR_INVALID_STATE
        ),
      );
    }
  }

  /// The runs the core currently reports as outstanding.
  List<IndexRun> active;

  /// How each run answers a direct read, by run id.
  ///
  /// A run that has left [active] is read individually for the status it
  /// ended on, which the active list can never carry. A run with no entry
  /// here is one the core no longer knows, and its read fails.
  final Map<String, IndexRunOutcome> terminal = {};

  /// Whether the next [listActiveRuns] call fails instead of answering.
  bool failNext = false;

  /// How many times [listActiveRuns] was called.
  int listCalls = 0;

  @override
  Future<IndexRunOutcome> readRun({
    required String runId,
    required String credential,
  }) async {
    reads.add((runId: runId, credential: credential));

    return terminal[runId] ??
        const IndexRunOutcome.failed(
          failure: Failure.notFound(family: CoreStatusFamily.run, code: 4),
        );
  }

  @override
  Future<ActiveRunsOutcome> listActiveRuns({required String credential}) async {
    listCalls++;
    if (failNext) {
      failNext = false;
      return const ActiveRunsOutcome.failed(
        failure: Failure.unexpected(family: CoreStatusFamily.run, code: 99),
      );
    }
    return ActiveRunsOutcome.read(runs: active);
  }
}
