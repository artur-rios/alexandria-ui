import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/data/core_index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Named for readability at the call site — the RUN_ family's own vocabulary
/// for "the run exists, but not in the state this call needs".
const runErrInvalidState = RUN_ERR_INVALID_STATE;

/// [CoreIndexGateway] over the generated bindings (IR-03, UC-06, FR-FC-28,
/// FR-FC-31).
void main() {
  group('pauseRun', () {
    test(
      'GivenARunThatIsNotRunning_WhenPaused_ThenItFailsWithInvalidState',
      () async {
        final gateway = CoreIndexGateway(
          FakeCoreClient(pauseStatus: runErrInvalidState),
        );

        final outcome = await gateway.pauseRun(runId: 'r1', credential: 't');

        expect(outcome, isA<RunControlFailed>());
      },
    );

    test('GivenARunningRun_WhenPaused_ThenItSucceeds', () async {
      final gateway = CoreIndexGateway(FakeCoreClient());

      final outcome = await gateway.pauseRun(runId: 'r1', credential: 't');

      expect(outcome, isA<RunControlOk>());
    });

    test('GivenACallThatThrows_WhenPaused_ThenItFailsAsUnexpected', () async {
      final fake = FakeCoreClient()..failOnIndexPause = true;
      final gateway = CoreIndexGateway(fake);

      final outcome = await gateway.pauseRun(runId: 'r1', credential: 't');

      expect(outcome, isA<RunControlFailed>());
    });
  });

  group('cancelRun', () {
    test('GivenARunningRun_WhenCancelled_ThenItSucceeds', () async {
      final gateway = CoreIndexGateway(FakeCoreClient());

      final outcome = await gateway.cancelRun(runId: 'r1', credential: 't');

      expect(outcome, isA<RunControlOk>());
    });

    test(
      'GivenACallThatThrows_WhenCancelled_ThenItFailsAsUnexpected',
      () async {
        final fake = FakeCoreClient()..failOnIndexCancel = true;
        final gateway = CoreIndexGateway(fake);

        final outcome = await gateway.cancelRun(runId: 'r1', credential: 't');

        expect(outcome, isA<RunControlFailed>());
      },
    );
  });

  group('resumeRun', () {
    test('GivenAResume_WhenTheCoreAnswers_ThenTheSameRunIdComesBack', () async {
      final gateway = CoreIndexGateway(FakeCoreClient(resumeRunId: 'r1'));

      final outcome = await gateway.resumeRun(runId: 'r1', credential: 't');

      expect((outcome as IndexStarted).runId, 'r1');
    });

    test('GivenAPriority_WhenResumed_ThenItIsForwardedToTheCore', () async {
      final fake = FakeCoreClient(resumeRunId: 'r1');
      final gateway = CoreIndexGateway(fake);

      await gateway.resumeRun(
        runId: 'r1',
        priority: RunPriority.low,
        credential: 't',
      );

      expect(fake.indexResumes.single.priority, 'low');
    });

    // Carried forward from Task 3's review: nothing pinned that a null
    // priority stays null at the wire rather than becoming "normal". A
    // plain resume must not silently re-pace a scan the owner throttled.
    test(
      'GivenNoPriority_WhenResumed_ThenNullReachesTheCoreNotNormal',
      () async {
        final fake = FakeCoreClient(resumeRunId: 'r1');
        final gateway = CoreIndexGateway(fake);

        await gateway.resumeRun(runId: 'r1', credential: 't');

        expect(fake.indexResumes.single.priority, isNull);
      },
    );
  });

  group('startIndex carries the scope of the folder (UC-05)', () {
    test('GivenAScope_WhenAnIndexStarts_ThenTheWireNamesAreSent', () async {
      final fake = FakeCoreClient();
      final gateway = CoreIndexGateway(fake);

      await gateway.startIndex(
        root: 'D:/Music',
        types: const [FileType.audio, FileType.image],
        credential: 't',
      );

      // The core's own words, comma-separated — not a second vocabulary
      // mapped onto them (BR-02).
      expect(fake.indexStarts.single.types, 'audio,image');
    });

    test(
      'GivenNoScope_WhenAnIndexStarts_ThenNullReachesTheCoreNotAnEmptyString',
      () async {
        // The core documents NULL and "" as the same absence today, but the
        // two are still different arguments: an absent scope is built as
        // absent, not as an empty list of names that happens to parse the
        // same way.
        final fake = FakeCoreClient();
        final gateway = CoreIndexGateway(fake);

        await gateway.startIndex(root: 'D:/Music', credential: 't');

        expect(fake.indexStarts.single.types, isNull);
        expect(fake.indexStarts.single.types, isNot(''));
      },
    );

    test('GivenARefresh_WhenItStarts_ThenNoScopeIsSent', () async {
      // UC-07 walks the catalog rather than the disk, so it revisits what is
      // already recorded and cannot pull in an excluded type. It reaches the
      // core through `alexandria_index_refresh_start`, which takes no scope
      // at all — so the assertion that matters is that a re-check never
      // reaches the scoped call, where it would have to send *some* scope.
      final fake = FakeCoreClient();
      final gateway = CoreIndexGateway(fake);

      await gateway.startRefresh(credential: 't');

      expect(fake.indexRefreshStarts, hasLength(1));
      expect(
        fake.indexStarts,
        isEmpty,
        reason:
            'a re-check must not go through the scoped index-start call, '
            'which would carry a scope — absent or empty — of its own',
      );
    });
  });

  group('listActiveRuns', () {
    test(
      'GivenOutstandingRuns_WhenListed_ThenEachIsParsedWithItsProgress',
      () async {
        final gateway = CoreIndexGateway(
          FakeCoreClient(
            activeRunsJson: '''
    [{"runId":"r1","kind":"index","status":"running","root":"D:/Music",
      "phase":"processing","total":12264,"processed":8412,"activeMillis":90000}]
  ''',
          ),
        );

        final outcome = await gateway.listActiveRuns(credential: 't');

        final runs = (outcome as ActiveRunsRead).runs;
        expect(runs.single.processed, 8412);
        expect(runs.single.phase, IndexRunPhase.processing);
      },
    );

    test('GivenNoOutstandingRuns_WhenListed_ThenTheListIsEmpty', () async {
      final gateway = CoreIndexGateway(FakeCoreClient(activeRunsJson: '[]'));

      final outcome = await gateway.listActiveRuns(credential: 't');

      expect((outcome as ActiveRunsRead).runs, isEmpty);
    });

    test('GivenACallThatThrows_WhenListed_ThenItFailsAsUnexpected', () async {
      final fake = FakeCoreClient()..failOnIndexRunsActive = true;
      final gateway = CoreIndexGateway(fake);

      final outcome = await gateway.listActiveRuns(credential: 't');

      expect(outcome, isA<ActiveRunsFailed>());
    });
  });

  group('priority on start', () {
    test(
      'GivenAPriority_WhenIndexStarted_ThenItIsForwardedToTheCore',
      () async {
        final fake = FakeCoreClient();
        final gateway = CoreIndexGateway(fake);

        await gateway.startIndex(
          root: 'D:/Music',
          priority: RunPriority.low,
          credential: 't',
        );

        expect(fake.indexStarts.single.priority, 'low');
      },
    );

    test(
      'GivenAPriority_WhenRefreshStarted_ThenItIsForwardedToTheCore',
      () async {
        final fake = FakeCoreClient();
        final gateway = CoreIndexGateway(fake);

        await gateway.startRefresh(priority: RunPriority.low, credential: 't');

        expect(fake.indexRefreshStarts.single.priority, 'low');
      },
    );
  });

  group('_runFrom progress fields', () {
    test('GivenAPausedRun_WhenReadBackViaReadRun_ThenPausedAtParses', () async {
      final fake = FakeCoreClient(
        indexRunStatusResult: (
          status: 0,
          json:
              '{"runId":"r1","kind":"index","status":"paused",'
              '"root":"D:/Music","phase":"processing","total":100,'
              '"processed":40,"activeMillis":5000,'
              '"pausedAt":"2026-08-20T12:00:00Z"}',
        ),
      );
      final gateway = CoreIndexGateway(fake);

      final outcome = await gateway.readRun(runId: 'r1', credential: 't');

      final run = (outcome as IndexRunRead).run;
      expect(run.total, 100);
      expect(run.processed, 40);
      expect(run.activeMillis, 5000);
      expect(run.pausedAt, DateTime.parse('2026-08-20T12:00:00Z'));
    });

    test(
      'GivenAlreadyCatalogedCount_WhenReadBackViaReadRun_ThenCountsArePresent',
      () async {
        final fake = FakeCoreClient(
          indexRunStatusResult: (
            status: 0,
            json:
                '{"runId":"r1","kind":"index","status":"running",'
                '"root":"D:/Music","alreadyCataloged":7}',
          ),
        );
        final gateway = CoreIndexGateway(fake);

        final outcome = await gateway.readRun(runId: 'r1', credential: 't');

        final run = (outcome as IndexRunRead).run;
        expect(run.counts?.alreadyCataloged, 7);
      },
    );
  });
}
