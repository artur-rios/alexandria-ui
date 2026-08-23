import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/library_sources/application/active_runs_controller.dart';
import 'package:alexandria_ui/features/library_sources/application/index_runs_state.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';

/// Refreshing the whole catalog (UC-07, FR-LB-06 … FR-LB-08).
void main() {
  const root = '/home/owner/music';
  final now = DateTime.utc(2026, 8, 19, 12);

  /// A finished refresh, in the counts a refresh run reports.
  IndexRunOutcome refreshed({int missing = 0}) => IndexRunOutcome.read(
    run: IndexRun(
      runId: '8c2d0e51-77af-4b93-8a10-2f6c4d9b1e37',
      root: '',
      kind: IndexRunKind.refresh,
      status: IndexRunStatus.complete,
      counts: IndexRunCounts(
        refreshed: 9,
        unchanged: 110,
        markedMissing: missing,
      ),
    ),
  );

  ({ProviderContainer ref, FakeIndexGateway gateway}) build({
    FakeIndexGateway? gateway,
    List<Override> extraOverrides = const [],
  }) {
    // Only when the caller said nothing: overwriting a gateway a test built
    // deliberately is how a test stops testing what it says it does.
    final indexGateway =
        gateway ?? (FakeIndexGateway()..readOutcomes = [refreshed()]);

    final container = ProviderContainer(
      overrides: [
        indexGatewayProvider.overrideWithValue(indexGateway),
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore([
            LibrarySource(
              path: root,
              label: defaultLabelFor(root),
              registeredAt: now,
            ),
          ]),
        ),
        clockProvider.overrideWithValue(() => now),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);

    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, gateway: indexGateway);
  }

  group('the main flow', () {
    test('GivenACatalog_WhenARefreshStarts_ThenTheCoreIsCalled', () async {
      final sut = build();

      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

      expect(
        sut.gateway.refreshStarts.single,
        FakeAuthGateway.defaultSession.credential,
      );
    });

    test('GivenARefreshStarts_WhenItSettles_ThenItsCountsAreShown', () async {
      // FR-LB-08, in a refresh run's own counts.
      final sut = build();

      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

      final run = sut.ref.read(indexRunsControllerProvider).refreshRun!;
      expect(run.kind, IndexRunKind.refresh);
      expect(run.counts?.refreshed, 9);
      expect(run.counts?.unchanged, 110);
    });

    test('GivenARefresh_WhenItRuns_ThenItBelongsToNoFolder', () async {
      // A refresh covers the catalog, so it must not read as a folder's scan —
      // which would also block UC-08 from removing that folder.
      final sut = build(
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );

      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

      expect(sut.ref.read(indexRunsControllerProvider).runFor(root), isNull);
      expect(sut.ref.read(indexRunsControllerProvider).isRefreshing, isTrue);
    });

    // A refresh is catalog-wide and can run for hours, and the strip cannot
    // discover it on its own: its polling only starts once a run is already
    // known. Every other mutation path here tells it; this one did not, so
    // "Re-check library" started work that was invisible everywhere outside
    // this screen.
    test('GivenARefreshStarts_WhenItIsAccepted_ThenTheStripIsTold', () async {
      final activeRuns = _RefreshCountingActiveRunsController();
      final sut = build(
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        extraOverrides: [
          activeRunsControllerProvider.overrideWith(() => activeRuns),
        ],
      );
      sut.ref.read(activeRunsControllerProvider);
      // The controller reads once of its own accord when it is built, and
      // that read is not the one under test — let it happen first, or this
      // passes on it whatever `startRefresh` does.
      await pumpEventQueue();
      final before = activeRuns.refreshCalls;

      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

      expect(activeRuns.refreshCalls, greaterThan(before));
    });

    test('GivenAFinishedRefresh_WhenItIsDismissed_ThenItGoes', () async {
      final sut = build();
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startRefresh();

      controller.dismissRefresh();

      expect(sut.ref.read(indexRunsControllerProvider).refreshRun, isNull);
    });
  });

  group('a refresh is already running (AF-01)', () {
    test('GivenARefreshInFlight_WhenAnotherStarts_ThenItIsRefused', () async {
      final sut = build(
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );
      final controller = sut.ref.read(indexRunsControllerProvider.notifier);
      await controller.startRefresh();

      await controller.startRefresh();

      expect(sut.gateway.refreshStarts, hasLength(1));
      expect(
        sut.ref.read(indexRunsControllerProvider).refreshRefusal,
        RefreshRefusal.alreadyRunning,
      );
    });
  });

  group('the catalog is empty (AF-02)', () {
    test(
      'GivenAnEmptyCatalog_WhenARefreshStarts_ThenTheCoreIsNotCalled',
      () async {
        final sut = build(gateway: FakeIndexGateway()..catalogedFileCount = 0);

        await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

        expect(sut.gateway.refreshStarts, isEmpty);
        expect(
          sut.ref.read(indexRunsControllerProvider).refreshRefusal,
          RefreshRefusal.catalogEmpty,
        );
      },
    );

    test(
      'GivenAnUnknownCount_WhenARefreshStarts_ThenItIsNotTreatedAsEmpty',
      () async {
        // A count the core could not answer is not zero: refusing on it would
        // answer AF-02 on a guess.
        final sut = build(gateway: FakeIndexGateway()..catalogedFileCount = -1);

        await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

        expect(sut.gateway.refreshStarts, hasLength(1));
      },
    );
  });

  group('files are marked missing (AF-03)', () {
    test(
      'GivenFilesGoMissing_WhenTheRefreshFinishes_ThenTheCountIsReported',
      () async {
        // The count is UC-07's own, per FR-LB-08. Only the link to the review is
        // UC-37's.
        final sut = build();
        sut.gateway.readOutcomes = [refreshed(missing: 4)];

        await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

        expect(
          sut.ref
              .read(indexRunsControllerProvider)
              .refreshRun
              ?.counts
              ?.markedMissing,
          4,
        );
      },
    );
  });

  group('the core rejects the session (AF-04)', () {
    test(
      'GivenTheRefreshIsUnauthorized_WhenItSettles_ThenTheOwnerIsSignedOut',
      () async {
        const failure = Failure.unauthorized(
          family: CoreStatusFamily.indexing,
          code: 2,
        );
        final sut = build(
          gateway: FakeIndexGateway()
            ..refreshOutcome = const IndexStartOutcome.failed(failure: failure),
        );

        await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    test('GivenTheCoreRefuses_WhenItSettles_ThenTheReasonIsKept', () async {
      const failure = Failure.invalidInput(
        family: CoreStatusFamily.indexing,
        code: 1,
      );
      final sut = build(
        gateway: FakeIndexGateway()
          ..refreshOutcome = const IndexStartOutcome.failed(failure: failure),
      );

      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

      expect(sut.ref.read(indexRunsControllerProvider).refreshFailure, failure);
      expect(sut.ref.read(sessionControllerProvider), isA<SessionActive>());
    });
  });
}

/// An [ActiveRunsController] that counts calls to [refresh] rather than
/// reaching the gateway.
///
/// The subject here is whether starting a refresh *asks* the active-runs
/// controller to re-read, not what the core would answer if it did — that
/// answer is [ActiveRunsController]'s own tests' subject.
class _RefreshCountingActiveRunsController extends ActiveRunsController {
  /// How many times [refresh] was called, including the one the controller
  /// makes of itself when it is first built.
  int refreshCalls = 0;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}
