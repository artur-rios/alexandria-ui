import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/application/active_runs_controller.dart';
import 'package:alexandria_ui/features/library_sources/application/active_runs_state.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_estimate.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/background_activity_strip.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alexandria_ui/features/enrichment/application/artist_portrait_backfill_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// The strip that reports whatever the core is indexing, from anywhere in the
/// application (FR-FC-28 … FR-FC-31).
void main() {
  const discoveringRun = IndexRun(
    runId: 'r1',
    root: '/home/owner/music',
    status: IndexRunStatus.running,
    phase: IndexRunPhase.discovering,
    activeMillis: 4000,
  );

  const processingRun = IndexRun(
    runId: 'r1',
    root: '/home/owner/music',
    status: IndexRunStatus.running,
    phase: IndexRunPhase.processing,
    total: 12264,
    processed: 8412,
    activeMillis: 60000,
  );

  const secondRun = IndexRun(
    runId: 'r2',
    root: '/home/owner/video',
    status: IndexRunStatus.running,
    phase: IndexRunPhase.processing,
    total: 400,
    processed: 100,
    activeMillis: 20000,
  );

  const pausedRun = IndexRun(
    runId: 'r1',
    root: '/home/owner/music',
    status: IndexRunStatus.paused,
    phase: IndexRunPhase.processing,
    total: 12264,
    processed: 8412,
    activeMillis: 60000,
  );

  const completedRun = IndexRun(
    runId: 'r1',
    root: '/home/owner/music',
    status: IndexRunStatus.complete,
  );

  const failedRun = IndexRun(
    runId: 'r1',
    root: '/home/owner/music',
    status: IndexRunStatus.failed,
  );

  // A steady rate over four samples: 10 entries per 1000ms of active time,
  // which is what [estimateRemaining] needs before it will answer at all.
  const steadySamples = <RunSample>[
    RunSample(processed: 8382, activeMillis: 57000),
    RunSample(processed: 8392, activeMillis: 58000),
    RunSample(processed: 8402, activeMillis: 59000),
    RunSample(processed: 8412, activeMillis: 60000),
  ];

  /// Pumps the strip alone, over a controller that answers with [runs].
  ///
  /// The strip on its own rather than the whole shell: every rule here is the
  /// strip's own, and the one thing that needs the shell — that it sits above
  /// the playback bar — has its own test at the bottom of this file.
  Future<RecordingActiveRunsController> pumpStrip(
    WidgetTester tester, {
    List<IndexRun> runs = const [],
    IndexRun? justFinished,
    Map<String, List<RunSample>> samples = const {},
    RecordingActiveRunsController? controller,
    List<Override> extraOverrides = const [],
  }) async {
    final recording =
        controller ??
        RecordingActiveRunsController(
          ActiveRunsState(
            runs: runs,
            justFinished: justFinished,
            samples: samples,
          ),
        );
    recording.seed(
      ActiveRunsState(runs: runs, justFinished: justFinished, samples: samples),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRunsControllerProvider.overrideWith(() => recording),
          ...extraOverrides,
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: SizedBox.expand()),
                BackgroundActivityStrip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    return recording;
  }

  const secondPausedRun = IndexRun(
    runId: 'r2',
    root: '/home/owner/video',
    status: IndexRunStatus.paused,
    phase: IndexRunPhase.processing,
    total: 400,
    processed: 100,
    activeMillis: 20000,
  );

  /// Pumps the strip over the *real* [ActiveRunsController], driven by
  /// [gateway].
  ///
  /// Everywhere else here the state is handed to the strip directly, which is
  /// the right isolation for a rule that is the strip's own. It is the wrong
  /// tool for the seam between the two: a hand-built state can assert a run
  /// ended in a way the controller never produces, and both halves stay green
  /// while the strip is unreachable in the running application. These go
  /// through the controller for that reason.
  Future<ProviderContainer> pumpStripOverCore(
    WidgetTester tester,
    FakeIndexGateway gateway,
  ) async {
    final container = ProviderContainer(
      overrides: [
        indexGatewayProvider.overrideWithValue(gateway),
        // Long enough that no timer fires: the observation is driven by
        // calling refresh directly.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);
    // Turned off before the session is established: this suite sets up its
    // own gateway scenarios for the strip to render, and `establish`'s own
    // unawaited call to `begin()` (FR-LB-21) would otherwise start a refresh
    // of its own against them.
    await container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: SizedBox.expand()),
                BackgroundActivityStrip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    return container;
  }

  group('what the strip shows (FR-FC-28)', () {
    // The shell is unchanged for anyone who is not indexing: the strip is
    // allowed to reflow the content area, but only in answer to a scan.
    testWidgets('GivenNoRuns_WhenBuilt_ThenTheStripTakesNoHeight', (
      tester,
    ) async {
      await pumpStrip(tester, runs: []);

      expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
    });

    // A run still counting what it will have to do has no total, so a
    // percentage would be invented.
    testWidgets(
      'GivenADiscoveringRun_WhenBuilt_ThenThereIsNoPercentageAndNoEstimate',
      (tester) async {
        await pumpStrip(tester, runs: [discoveringRun]);

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, isNull);
        expect(find.textContaining('left'), findsNothing);
      },
    );

    testWidgets('GivenADiscoveringRun_WhenBuilt_ThenItSaysWhatItIsDoing', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [discoveringRun]);

      expect(find.text('Scanning folders…'), findsOneWidget);
    });

    testWidgets('GivenAProcessingRun_WhenBuilt_ThenCountsAreShown', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [processingRun]);

      expect(find.textContaining('8,412'), findsOneWidget);
      expect(find.textContaining('12,264'), findsOneWidget);
    });

    testWidgets('GivenAProcessingRun_WhenBuilt_ThenTheBarIsDeterminate', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [processingRun]);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(8412 / 12264, 0.001));
    });

    // The estimate is the pure function's answer or nothing at all; the strip
    // never substitutes a placeholder for a refusal.
    testWidgets('GivenASteadyRate_WhenBuilt_ThenTheEstimateIsShown', (
      tester,
    ) async {
      await pumpStrip(
        tester,
        runs: [processingRun],
        samples: const {'r1': steadySamples},
      );

      expect(find.textContaining('left'), findsOneWidget);
    });

    testWidgets('GivenTooFewSamples_WhenBuilt_ThenNoEstimateIsShown', (
      tester,
    ) async {
      await pumpStrip(
        tester,
        runs: [processingRun],
        samples: const {
          'r1': [RunSample(processed: 8402, activeMillis: 59000)],
        },
      );

      expect(find.textContaining('left'), findsNothing);
    });
  });

  group('the controls (FR-FC-28 … FR-FC-31)', () {
    testWidgets('GivenAPausedRun_WhenBuilt_ThenResumeIsOffered', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [pausedRun]);

      expect(find.byTooltip('Resume'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsNothing);
    });

    // A paused run at launch is offered a resume by the strip itself. There is
    // no modal anywhere: the row appearing paused *is* the offer.
    testWidgets('GivenAPausedRun_WhenBuilt_ThenTheStripHasHeight', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [pausedRun]);

      expect(
        tester.getSize(find.byType(BackgroundActivityStrip)).height,
        BackgroundActivityStrip.expandedHeight,
      );
    });

    testWidgets('GivenAPausedRun_WhenResumed_ThenThePaceIsLeftAlone', (
      tester,
    ) async {
      // A plain resume must not carry a priority: null asks the core to keep
      // the pace the run already had, and `normal` would silently speed up a
      // scan the owner deliberately throttled.
      final controller = await pumpStrip(tester, runs: [pausedRun]);

      await tester.tap(find.byTooltip('Resume'));
      await tester.pumpAndSettle();

      expect(controller.calls, ['resume:r1:null']);
    });

    testWidgets('GivenARunningRun_WhenPaused_ThenTheRunIsPaused', (
      tester,
    ) async {
      final controller = await pumpStrip(tester, runs: [processingRun]);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();

      expect(controller.calls, ['pause:r1']);
    });

    testWidgets('GivenARunningRun_WhenCancelled_ThenTheRunIsCancelled', (
      tester,
    ) async {
      final controller = await pumpStrip(tester, runs: [processingRun]);

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.calls, ['cancel:r1']);
    });
  });

  group('several runs at once (FR-FC-29)', () {
    testWidgets('GivenTwoRuns_WhenBuilt_ThenOneAggregateRowIsShown', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [processingRun, secondRun]);

      expect(find.textContaining('2 folders'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsNothing);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('GivenTwoRuns_WhenViewIsChosen_ThenTheFoldersScreenOpens', (
      tester,
    ) async {
      await pumpStrip(
        tester,
        runs: [processingRun, secondRun],
        extraOverrides: [
          librarySourceStoreProvider.overrideWithValue(
            InMemoryLibrarySourceStore([]),
          ),
          indexGatewayProvider.overrideWithValue(FakeIndexGateway()),
        ],
      );

      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySourcesScreen), findsOneWidget);
    });

    testWidgets('GivenTwoRuns_WhenBuilt_ThenNoPerRunControlIsOffered', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [processingRun, secondRun]);

      expect(find.byTooltip('Resume'), findsNothing);
      expect(find.byTooltip('Cancel'), findsNothing);
      expect(find.byTooltip('Normal'), findsNothing);
    });

    // Two runs paused at launch is exactly what resuming is designed for, and
    // "Indexing 2 folders" over them asserts work is under way that is not.
    testWidgets('GivenTwoPausedRuns_WhenBuilt_ThenTheyAreNotCalledIndexing', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [pausedRun, secondPausedRun]);

      expect(find.textContaining('2 folders paused'), findsOneWidget);
      expect(find.textContaining('Indexing 2 folders'), findsNothing);
    });

    testWidgets('GivenTwoPausedRunsStillCounting_WhenBuilt_ThenTheBarRests', (
      tester,
    ) async {
      // Nothing is running and there is nothing to divide by, so an animating
      // indeterminate bar would claim work that is not happening.
      await pumpStrip(
        tester,
        runs: [
          pausedRun.copyWith(total: null, phase: IndexRunPhase.discovering),
          secondPausedRun,
        ],
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0);
      expect(find.textContaining('2 folders paused'), findsOneWidget);
    });

    // One paused among runs that are moving is still work under way, so the
    // paused vocabulary must not take over the moment anything stops.
    testWidgets(
      'GivenOnePausedAndOneRunning_WhenBuilt_ThenItStillSaysIndexing',
      (tester) async {
        await pumpStrip(tester, runs: [pausedRun, secondRun]);

        expect(find.textContaining('Indexing 2 folders'), findsOneWidget);
      },
    );

    // One of the two is still counting, so their totals cannot be summed into
    // a figure the core never gave.
    testWidgets('GivenOneOfTwoIsDiscovering_WhenBuilt_ThenNoTotalIsInvented', (
      tester,
    ) async {
      await pumpStrip(tester, runs: [processingRun, discoveringRun]);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
      expect(find.textContaining('12,264'), findsNothing);
    });
  });

  group('how a run ends, through the controller (FR-FC-29)', () {
    // The whole point of the strip, driven the way the application drives it:
    // a scan is running, the core drops it from the active list, and the
    // outcome has to reach the row. Every other test in the group below hands
    // the strip a finished run directly, which cannot see whether the
    // controller can ever produce one.
    testWidgets('GivenARunningRun_WhenItCompletes_ThenTheStripSaysSo', (
      tester,
    ) async {
      final gateway = FakeIndexGateway()
        ..activeRunsOutcome = const ActiveRunsOutcome.read(
          runs: [processingRun],
        )
        ..readOutcomes = [finishedRun(runId: 'r1', root: '/home/owner/music')];
      final container = await pumpStripOverCore(tester, gateway);
      await tester.pump();

      gateway.activeRunsOutcome = const ActiveRunsOutcome.read(runs: []);
      await container.read(activeRunsControllerProvider.notifier).refresh();
      await tester.pump();

      expect(find.text('Finished indexing music'), findsOneWidget);

      // The completion clears itself, and the timer has to be let run out or
      // the binding fails the test for it.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('GivenARunningRun_WhenItFails_ThenTheFailureIsShown', (
      tester,
    ) async {
      final gateway = FakeIndexGateway()
        ..activeRunsOutcome = const ActiveRunsOutcome.read(
          runs: [processingRun],
        )
        ..readOutcomes = [
          finishedRun(
            runId: 'r1',
            root: '/home/owner/music',
            status: IndexRunStatus.failed,
          ),
        ];
      final container = await pumpStripOverCore(tester, gateway);
      await tester.pump();

      gateway.activeRunsOutcome = const ActiveRunsOutcome.read(runs: []);
      await container.read(activeRunsControllerProvider.notifier).refresh();
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Indexing music failed'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('how a run ends (FR-FC-29)', () {
    // A failure that vanishes unseen is worse than a strip that lingers.
    testWidgets('GivenAFailedRun_WhenTimePasses_ThenTheStripStays', (
      tester,
    ) async {
      await pumpStrip(tester, justFinished: failedRun);
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(BackgroundActivityStrip), findsOneWidget);
      expect(find.textContaining('failed'), findsOneWidget);
    });

    testWidgets('GivenAFailedRun_WhenDismissed_ThenTheStripCloses', (
      tester,
    ) async {
      await pumpStrip(tester, justFinished: failedRun);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
    });

    testWidgets(
      'GivenACompletedRun_WhenTimePasses_ThenTheStripDismissesItself',
      (tester) async {
        await pumpStrip(tester, justFinished: completedRun);
        expect(find.textContaining('Finished'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
      },
    );

    // The strip is one row, so an outcome and a run in flight compete for it.
    // A failure has to win: the run is still running and comes back the moment
    // the failure is dismissed, but a failure that loses is overwritten by the
    // next run to finish and is gone for good.
    testWidgets(
      'GivenAFailedRunAndAnotherStillRunning_WhenBuilt_ThenTheFailureIsShown',
      (tester) async {
        await pumpStrip(tester, runs: [secondRun], justFinished: failedRun);

        expect(find.textContaining('failed'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAFailedRunAndTwoStillRunning_WhenBuilt_ThenTheFailureIsShown',
      (tester) async {
        // The aggregate row would otherwise have taken the row first.
        await pumpStrip(
          tester,
          runs: [processingRun, secondRun],
          justFinished: failedRun,
        );

        expect(find.textContaining('failed'), findsOneWidget);
        expect(find.textContaining('2 folders'), findsNothing);
      },
    );

    testWidgets(
      'GivenAFailureOverARunningRun_WhenDismissed_ThenTheRunIsShownAgain',
      (tester) async {
        final controller = RecordingActiveRunsController(
          const ActiveRunsState(runs: [secondRun], justFinished: failedRun),
        );
        await pumpStrip(
          tester,
          runs: [secondRun],
          justFinished: failedRun,
          controller: controller,
        );

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        expect(find.textContaining('failed'), findsNothing);
        expect(find.byTooltip('Pause'), findsOneWidget);
      },
    );

    // A completion is not urgent and clears itself, so it does not get to
    // hide work that is still going.
    testWidgets(
      'GivenACompletedRunAndAnotherStillRunning_WhenBuilt_ThenTheRunIsShown',
      (tester) async {
        await pumpStrip(tester, runs: [secondRun], justFinished: completedRun);

        expect(find.textContaining('Finished'), findsNothing);
        expect(find.byTooltip('Pause'), findsOneWidget);
      },
    );

    // Cancelling is the owner's own doing. Reporting it back is not news, and
    // leaving it in the state would keep the strip open on it.
    testWidgets('GivenACancelledRun_WhenBuilt_ThenItIsClearedWithoutAWord', (
      tester,
    ) async {
      final controller = await pumpStrip(
        tester,
        justFinished: completedRun.copyWith(status: IndexRunStatus.cancelled),
      );

      expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);

      await tester.pumpAndSettle();

      expect(controller.calls, ['dismiss']);
    });

    // The timer belongs to the widget, so it has to die with it.
    testWidgets(
      'GivenACompletedRun_WhenTheStripIsDisposed_ThenNoTimerLingers',
      (tester) async {
        await pumpStrip(tester, justFinished: completedRun);

        await tester.pumpWidget(const SizedBox.shrink());

        // Deliberately without pumping past the four seconds: a timer that was
        // not cancelled is still pending right here, and the binding fails the
        // test for it.
        expect(find.byType(BackgroundActivityStrip), findsNothing);
      },
    );
  });

  group('re-pacing a run (FR-FC-31)', () {
    // Re-pacing a running run means pause then resume, and resume resets the
    // segment — so the bar returns to zero. The strip has to say that, or the
    // reset reads as lost work.
    testWidgets(
      'GivenARunningRun_WhenRePacedToLow_ThenItPausesResumesAndSaysSo',
      (tester) async {
        final controller = RecordingActiveRunsController(
          const ActiveRunsState(runs: [processingRun]),
        );
        await pumpStrip(tester, runs: [processingRun], controller: controller);

        await tester.tap(find.byTooltip('Normal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Low'));
        await tester.pumpAndSettle();

        expect(controller.calls, ['pause:r1', 'resume:r1:low']);
        expect(
          find.textContaining('Re-checking from the start'),
          findsOneWidget,
        );
      },
    );

    // The notice stands until the restarted segment is visibly moving again,
    // which is the moment the reset stops needing an explanation.
    testWidgets(
      'GivenARePacedRun_WhenItIsProcessingAgain_ThenTheNoticeGoesAway',
      (tester) async {
        final controller = RecordingActiveRunsController(
          const ActiveRunsState(runs: [processingRun]),
        );
        await pumpStrip(tester, runs: [processingRun], controller: controller);

        await tester.tap(find.byTooltip('Normal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Low'));
        await tester.pumpAndSettle();

        controller.seed(
          const ActiveRunsState(
            runs: [
              IndexRun(
                runId: 'r1',
                root: '/home/owner/music',
                status: IndexRunStatus.running,
                phase: IndexRunPhase.processing,
                total: 12264,
                processed: 12,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Re-checking from the start'), findsNothing);
      },
    );
  });

  group('where the strip lives (FR-UX-01)', () {
    testWidgets('GivenTheShell_WhenNothingIsIndexing_ThenTheStripIsFlat', (
      tester,
    ) async {
      await tester.pumpShell();

      expect(find.byType(BackgroundActivityStrip), findsOneWidget);
      expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
    });

    testWidgets('GivenTheShell_WhenBuilt_ThenTheStripSitsAboveThePlaybackBar', (
      tester,
    ) async {
      await tester.pumpShell();

      expect(
        tester.getTopLeft(find.byType(BackgroundActivityStrip)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(PlaybackBar)).dy),
      );
    });

    // The offer to pick a scan back up, at launch, is the strip appearing in
    // its paused state. There is no modal anywhere — this is the whole of it.
    testWidgets(
      'GivenAPausedRunAtLaunch_WhenTheShellOpens_ThenResumeIsOffered',
      (tester) async {
        await tester.pumpShell(
          extraOverrides: [
            indexGatewayProvider.overrideWithValue(
              FakeIndexGateway()
                ..activeRunsOutcome = const ActiveRunsOutcome.read(
                  runs: [pausedRun],
                ),
            ),
            runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Resume'), findsOneWidget);
      },
    );
  });

  group('the artist-photograph pass (FR-PL-15)', () {
    testWidgets('GivenThePassIsRunning_WhenTheStripIsShown_ThenItSaysSo', (
      tester,
    ) async {
      // The indication the owner was owed: pictures appearing an hour into a
      // session are inexplicable unless something says a pass is under way —
      // and a pass that never started is indistinguishable from a feature
      // that does not work, which is exactly what it looked like.
      await pumpStrip(
        tester,
        extraOverrides: [
          artistPortraitBackfillProvider.overrideWith(
            () => _FixedPortraits(
              const ArtistPortraitBackfill(
                isRunning: true,
                considered: 12,
                total: 40,
                fetched: 9,
              ),
            ),
          ),
        ],
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackgroundActivityStrip)),
      );
      expect(find.text(l10n.artistPortraitsProgress(12, 40)), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('GivenThePassIsDone_WhenTheStripIsShown_ThenItTakesNoRoom', (
      tester,
    ) async {
      // Nobody is owed a strip they will never see: a finished pass leaves
      // the shell exactly as it was.
      await pumpStrip(
        tester,
        extraOverrides: [
          artistPortraitBackfillProvider.overrideWith(
            () => _FixedPortraits(
              const ArtistPortraitBackfill(considered: 40, total: 40),
            ),
          ),
        ],
      );

      expect(
        tester.getSize(find.byType(BackgroundActivityStrip)).height,
        BackgroundActivityStrip.collapsedHeight,
      );
    });

    testWidgets('GivenAScanIsRunning_WhenThePassIsToo_ThenTheScanIsShown', (
      tester,
    ) async {
      // An index run is work the owner started and is waiting on; the pass is
      // one they never asked for by name. One row, so the scan takes it.
      await pumpStrip(
        tester,
        runs: [processingRun],
        extraOverrides: [
          artistPortraitBackfillProvider.overrideWith(
            () => _FixedPortraits(
              const ArtistPortraitBackfill(
                isRunning: true,
                considered: 1,
                total: 9,
              ),
            ),
          ),
        ],
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackgroundActivityStrip)),
      );
      expect(find.text(l10n.artistPortraitsProgress(1, 9)), findsNothing);
    });
  });
}

/// An [ActiveRunsController] that records the control calls made on it.
///
/// It stands in for the real controller rather than for the gateway beneath
/// it, because what these tests assert is what the strip *asks for* — the
/// gateway's answers are the controller's own tests' subject.
class RecordingActiveRunsController extends ActiveRunsController {
  /// Creates a controller answering with [_initial].
  RecordingActiveRunsController([this._initial = const ActiveRunsState()]);

  ActiveRunsState _initial;
  bool _built = false;

  /// Every control call the strip made, in order.
  final List<String> calls = [];

  /// Replaces what the controller reports, as a fresh read would.
  void seed(ActiveRunsState next) {
    _initial = next;
    if (_built) state = next;
  }

  @override
  ActiveRunsState build() {
    _built = true;

    return _initial;
  }

  // The strip asks for a reading when it is first shown. It is not a control
  // call, so it is not recorded — the assertions here are about pause, resume
  // and cancel.
  @override
  Future<void> refresh() async {}

  @override
  void dismissFinished() {
    calls.add('dismiss');
    super.dismissFinished();
  }

  @override
  Future<void> pause(String runId) async => calls.add('pause:$runId');

  @override
  Future<void> cancel(String runId) async => calls.add('cancel:$runId');

  @override
  Future<void> resume(String runId, {RunPriority? priority}) async =>
      calls.add('resume:$runId:${priority?.name}');
}

/// An [ArtistPortraitBackfillController] holding a fixed state, so the strip
/// can be shown a pass without a library or a network behind it.
class _FixedPortraits extends ArtistPortraitBackfillController {
  _FixedPortraits(this._state);

  final ArtistPortraitBackfill _state;

  @override
  ArtistPortraitBackfill build() => _state;
}
