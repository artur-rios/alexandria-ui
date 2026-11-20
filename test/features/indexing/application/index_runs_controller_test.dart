import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';

/// Starting a library's index run and watching it finish (UC-06, FR-LB-05,
/// FR-LB-07 … FR-LB-09, core 0.6.0).
void main() {
  const library = 'lib-1';
  const other = 'lib-2';

  ({ProviderContainer ref, FakeIndexGateway gateway}) build({
    FakeIndexGateway? gateway,
  }) {
    final indexGateway = gateway ?? FakeIndexGateway();

    final container = ProviderContainer(
      overrides: [
        indexGatewayProvider.overrideWithValue(indexGateway),
        // Long enough that no timer fires during a test: the observation is
        // driven by calling refresh directly.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);

    // Turned off before the session is established: `establish`'s own
    // unawaited call to `begin()` (FR-LB-21) would otherwise start a refresh
    // of its own and race the one a test drives.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, gateway: indexGateway);
  }

  group('a library run', () {
    test(
      'GivenALibrary_WhenStartLibraryIndex_ThenTheRunIsFollowedUnderItsUuid',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );

        final refused = await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startLibraryIndex(library);

        expect(refused, isNull);
        expect(sut.gateway.libraryStarts.single.uuid, library);
        expect(
          sut.gateway.libraryStarts.single.credential,
          FakeAuthGateway.defaultSession.credential,
        );
        final run = sut.ref.read(indexRunsControllerProvider).runFor(library);
        expect(run?.status, IndexRunStatus.running);
        expect(run?.libraryUuid, library);
      },
    );

    test(
      'GivenAnUnfinishedRun_WhenStartLibraryIndexAgain_ThenTheConflictIsAnsweredAndOneRunIsFollowed',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startLibraryIndex(library);

        final refused = await controller.startLibraryIndex(library);

        expect(refused, isA<ConflictFailure>());
        expect(sut.gateway.libraryStarts, hasLength(1));
        expect(sut.ref.read(indexRunsControllerProvider).runs, hasLength(1));
      },
    );

    test(
      'GivenTheCoreAnswersConflict_WhenStartLibraryIndex_ThenItIsAnsweredAndNothingIsFollowed',
      () async {
        // A paused run another session started: this one does not follow it,
        // so only the core knows, and its answer is passed on.
        const conflict = Failure.conflict(
          family: CoreStatusFamily.indexing,
          code: INDEX_ERR_CONFLICT,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..libraryStartOutcomes.add(
              const IndexStartOutcome.failed(failure: conflict),
            ),
        );

        final refused = await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startLibraryIndex(library);

        expect(refused, conflict);
        final state = sut.ref.read(indexRunsControllerProvider);
        expect(state.runFor(library), isNull);
        expect(state.isStarting(library), isFalse);
      },
    );

    test('GivenAFollowedRun_WhenItCompletes_ThenItsOutcomeIsKept', () async {
      final sut = build(
        gateway: FakeIndexGateway()
          ..readOutcomes = [runningRun(), finishedRun()],
      );
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startLibraryIndex(library);

      await controller.refresh();

      final run = sut.ref.read(indexRunsControllerProvider).runFor(library);
      expect(run?.status, IndexRunStatus.complete);
      expect(run?.counts?.indexed, 118);
      expect(controller.debugIsPolling, isFalse);
    });

    test('GivenAFinishedRun_WhenAnotherIsStarted_ThenItRuns', () async {
      final sut = build(
        gateway: FakeIndexGateway()..readOutcomes = [finishedRun()],
      );
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startLibraryIndex(library);

      final refused = await controller.startLibraryIndex(library);

      expect(refused, isNull);
      expect(sut.gateway.libraryStarts, hasLength(2));
    });

    test('GivenAPausedRun_WhenRefreshed_ThenItIsStillFollowed', () async {
      // Resumed from the strip or the row, it would otherwise read paused
      // here long after it finished.
      final sut = build(
        gateway: FakeIndexGateway()
          ..readOutcomes = [
            finishedRun(status: IndexRunStatus.paused),
            finishedRun(),
          ],
      );
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startLibraryIndex(library);
      expect(sut.ref.read(indexRunsControllerProvider).pollable, [library]);

      await controller.refresh();

      expect(
        sut.ref.read(indexRunsControllerProvider).runFor(library)?.status,
        IndexRunStatus.complete,
      );
    });

    test(
      'GivenARunTheCoreStartedForANewLibrary_WhenFollowed_ThenItIsPolled',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .follow(library, 'run-9');

        expect(sut.gateway.reads.single.runId, 'run-9');
        expect(sut.gateway.libraryStarts, isEmpty);
        expect(
          sut.ref.read(indexRunsControllerProvider).runFor(library)?.isInFlight,
          isTrue,
        );
      },
    );

    test(
      'GivenARemovedLibrary_WhenDismissed_ThenItsRunIsNoLongerFollowed',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);
        await controller.startLibraryIndex(library);

        controller.dismiss(library);

        final state = sut.ref.read(indexRunsControllerProvider);
        expect(state.runFor(library), isNull);
        expect(state.pollable, isEmpty);
      },
    );
  });

  group('the core rejects the session (AF-06)', () {
    test(
      'GivenTheStartIsUnauthorized_WhenItSettles_ThenTheSessionEnds',
      () async {
        const unauthorized = Failure.unauthorized(
          family: CoreStatusFamily.indexing,
          code: INDEX_ERR_UNAUTHORIZED,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..libraryStartOutcomes.add(
              const IndexStartOutcome.failed(failure: unauthorized),
            ),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startLibraryIndex(library);

        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
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

    test(
      'GivenARefusalIsNotReported_WhenTheCoreRefusesTheStart_ThenNoFailureIsLeft',
      () async {
        // The core's own refusal of the start itself — not AF-01's "already
        // running" — must be just as silent for a re-check nobody asked for.
        // Left on screen, it would explain a failure to an owner who never
        // pressed anything.
        const failure = Failure.invalidInput(
          family: CoreStatusFamily.indexing,
          code: 1,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..refreshOutcome = const IndexStartOutcome.failed(failure: failure),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startRefresh(reportRefusals: false);

        expect(
          sut.ref.read(indexRunsControllerProvider).refreshFailure,
          isNull,
        );
      },
    );
  });

  group('one run ending never stops the others being followed', () {
    const unreadable = Failure.invalidInput(
      family: CoreStatusFamily.indexing,
      code: 1,
    );

    test(
      'GivenARefreshIsRunning_WhenALibraryRunFinishes_ThenTheRefreshIsStillPolled',
      () async {
        // The refresh re-checks every library and can run for hours, while a
        // library's run beside it finishes in minutes. Weighing only the
        // library runs stopped the timer on the shorter one and froze the
        // refresh on its last reading.
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [
              runningRun(), // the library run, just started
              runningRun(), // the refresh, just started
              finishedRun(), // the library run, now complete
              runningRun(), // the refresh, still going
            ],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);

        await controller.startLibraryIndex(library);
        await controller.startRefresh();
        await controller.refresh();

        expect(sut.ref.read(indexRunsControllerProvider).isRefreshing, isTrue);
        expect(controller.debugIsPolling, isTrue);
      },
    );

    test(
      'GivenTwoLibrariesScanning_WhenOneStatusIsUnreadable_ThenTheOtherIsStillPolled',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()
            ..readOutcomes = [
              runningRun(), // first library, just started
              runningRun(), // second library, just started
              const IndexRunOutcome.failed(failure: unreadable),
              runningRun(), // second library, still going
            ],
        );
        final controller = sut.ref.read(indexRunsControllerProvider.notifier);

        await controller.startLibraryIndex(library);
        await controller.startLibraryIndex(other);
        await controller.refresh();

        final state = sut.ref.read(indexRunsControllerProvider);
        // The library that could not be read drops out of the rotation
        // rather than spinning on the same error, and takes nothing else
        // with it.
        expect(state.failureFor(library), unreadable);
        expect(state.pollable, [other]);
        expect(controller.debugIsPolling, isTrue);
      },
    );
  });
}
