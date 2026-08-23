import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_desktop/features/library_sources/domain/index_run.dart';
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
      final gateway = FakeGateway(active: [runningRun]);
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
    final gateway = FakeGateway(active: [runningRun]);
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

  /// Whether the next [listActiveRuns] call fails instead of answering.
  bool failNext = false;

  /// How many times [listActiveRuns] was called.
  int listCalls = 0;

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
