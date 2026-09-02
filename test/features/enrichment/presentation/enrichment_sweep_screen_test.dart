import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/enrichment/application/artist_portrait_backfill_controller.dart';
import 'package:alexandria_ui/features/enrichment/application/enrichment_sweep_controller.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/enrichment/presentation/enrichment_sweep_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_enrichment_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Looking music info up for the whole library (music enrichment design).
void main() {
  /// A gateway that hands back a fixed number of pending items, counting
  /// down a batch at a time — what a real sweep looks like from here.
  ///
  /// Records every scope it was asked with, which is the assertion for
  /// "batched": one call for the whole library and one call per batch are
  /// indistinguishable from the outside otherwise.
  FakeEnrichmentGateway countingDown(int total) {
    final gateway = _CountingGateway(total);
    return gateway;
  }

  Future<ProviderContainer> openSweep(
    WidgetTester tester, {
    required FakeEnrichmentGateway gateway,
    SettingsStore? settings,
  }) async {
    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      settings: settings,
      extraOverrides: <Override>[
        enrichmentGatewayProvider.overrideWithValue(gateway),
        // The startup pass, held still for these cases.
        //
        // It reaches the same gateway this file counts calls on (FR-PL-15) —
        // in a real session both run, and the core's own rate gate is what
        // keeps them civil — so left alone it would put file-scoped runs
        // into `runs` and spend the counting fake's budget on artists. What
        // is under test here is the sweep's own batching, so the other
        // caller is overridden away rather than filtered out of every
        // assertion.
        artistPortraitBackfillProvider.overrideWith(_NoBackfill.new),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.enrichmentSweepOpen);
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('GivenTheScreenOpens_ThenItSaysWhatItSendsBeforeStarting', (
    tester,
  ) async {
    // The only thing here that talks to anyone else. The owner should be
    // choosing it knowingly rather than finding out afterwards.
    await openSweep(tester, gateway: FakeEnrichmentGateway());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichmentSweepScreen)),
    );

    expect(find.text(l10n.enrichmentSweepExplanation), findsOneWidget);
    expect(find.text(l10n.enrichmentSweepStart), findsOneWidget);
  });

  testWidgets('GivenALibrary_WhenSwept_ThenItIsAskedForABatchAtATime', (
    tester,
  ) async {
    // The whole point of the design. One call for a whole library returns
    // only when it is finished, hours later, with nothing to show meanwhile.
    final gateway = countingDown(12);
    await openSweep(tester, gateway: gateway);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(
      gateway.runs.length,
      greaterThan(1),
      reason: 'the sweep was one long call',
    );
    expect(
      gateway.runs.every(
        (scope) =>
            scope is EnrichmentScopePending &&
            scope.limit == EnrichmentSweepController.batchSize,
      ),
      isTrue,
      reason: 'a batch was asked for without a bound',
    );
  });

  testWidgets('GivenTheLibraryIsDone_WhenTheSweepEnds_ThenItSaysWhatItFound', (
    tester,
  ) async {
    final gateway = countingDown(10);
    final container = await openSweep(tester, gateway: gateway);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    final state = container.read(enrichmentSweepControllerProvider);
    expect(state.stage, SweepStage.finished);
    expect(state.considered, 10);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichmentSweepScreen)),
    );
    expect(
      find.text(l10n.enrichmentSweepFinished(state.found, 10)),
      findsOneWidget,
    );
  });

  testWidgets('GivenNothingIsOutstanding_WhenSwept_ThenItFinishesAtOnce', (
    tester,
  ) async {
    // An already-enriched library, or one of untagged files. Finishing
    // immediately is the truthful answer for both.
    final gateway = countingDown(0);
    final container = await openSweep(tester, gateway: gateway);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(
      container.read(enrichmentSweepControllerProvider).stage,
      SweepStage.finished,
    );
    expect(gateway.runs, hasLength(1));
  });

  testWidgets('GivenEnrichmentIsSwitchedOff_WhenSwept_ThenStartingIsRefused', (
    tester,
  ) async {
    // Not the owner's mistake, and not something pressing again can fix.
    final gateway = FakeEnrichmentGateway()
      ..runOutcome = const EnrichmentRunOutcome.failed(
        failure: Failure.configuration(
          family: CoreStatusFamily.enrichment,
          code: 5,
        ),
      );
    final container = await openSweep(tester, gateway: gateway);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichmentSweepScreen)),
    );

    expect(
      container.read(enrichmentSweepControllerProvider).stage,
      SweepStage.unavailable,
    );
    expect(find.text(l10n.enrichmentUnavailable), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull, reason: 'a dead action stayed pressable');
  });

  testWidgets(
    'GivenTheOwnerSwitchedLookupOff_WhenSweepIsStarted_ThenNothingIsAsked',
    (tester) async {
      // FR-UX-13: off means the application asks for nothing, not that it
      // asks and is refused. The core would refuse it — it is configured
      // from this same preference — but a sweep is a long run of requests,
      // and the first of them must not leave here.
      final gateway = FakeEnrichmentGateway();
      final container = await openSweep(
        tester,
        gateway: gateway,
        settings: InMemorySettingsStore(musicLookupEnabled: false),
      );

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(EnrichmentSweepScreen)),
      );

      expect(gateway.runs, isEmpty);
      expect(
        container.read(enrichmentSweepControllerProvider).stage,
        SweepStage.unavailable,
      );
      expect(find.text(l10n.enrichmentUnavailable), findsOneWidget);
    },
  );

  testWidgets(
    'GivenABatchFails_WhenSwept_ThenItStopsRatherThanRetryingForever',
    (tester) async {
      // A service being down is already absorbed inside a batch — the core
      // records it and carries on. A failure reaching this far is about the
      // call itself, and repeating it a thousand times is a thousand failures.
      final gateway = FakeEnrichmentGateway()
        ..runOutcome = const EnrichmentRunOutcome.failed(
          failure: Failure.unexpected(
            family: CoreStatusFamily.enrichment,
            code: 9,
          ),
        );
      final container = await openSweep(tester, gateway: gateway);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(
        container.read(enrichmentSweepControllerProvider).stage,
        SweepStage.failed,
      );
      expect(gateway.runs, hasLength(1), reason: 'a failing call was retried');
    },
  );

  testWidgets('GivenARunningSweep_WhenItIsStopped_ThenWhatWasDoneIsKept', (
    tester,
  ) async {
    // Stopping must not read as throwing the work away, or nobody stops a
    // job measured in hours.
    final gateway = _CountingGateway(
      1000,
      perBatch: const Duration(milliseconds: 20),
    );
    final container = await openSweep(tester, gateway: gateway);

    await tester.tap(find.text('Start'));
    // Long enough for a batch or two to land, so there is something to keep.
    await tester.pump(const Duration(milliseconds: 60));

    container.read(enrichmentSweepControllerProvider.notifier).stop();
    await tester.pumpAndSettle();

    final state = container.read(enrichmentSweepControllerProvider);
    expect(state.stage, SweepStage.stopped);
    expect(state.considered, greaterThan(0));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichmentSweepScreen)),
    );
    expect(
      find.text(l10n.enrichmentSweepStopped(state.considered)),
      findsOneWidget,
    );
  });
}

/// Hands back `total` pending items, a batch at a time.
/// A startup pass that does nothing at all.
class _NoBackfill extends ArtistPortraitBackfillController {
  @override
  ArtistPortraitBackfill build() => const ArtistPortraitBackfill();
}

class _CountingGateway extends FakeEnrichmentGateway {
  _CountingGateway(this._remaining, {this.perBatch = Duration.zero});

  int _remaining;

  /// How long a batch takes. A real one spends seconds per item at the rate
  /// limit; a test that wants to stop one mid-sweep needs it not to be
  /// instantaneous, or there is never a moment in which to press stop.
  final Duration perBatch;

  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    runs.add(scope);
    if (perBatch > Duration.zero) await Future<void>.delayed(perBatch);

    final limit = scope is EnrichmentScopePending
        ? (scope.limit ?? _remaining)
        : 1;
    final did = limit < _remaining ? limit : _remaining;
    _remaining -= did;

    return EnrichmentRunOutcome.done(
      report: EnrichmentReport(
        considered: did,
        found: did,
        remaining: _remaining,
      ),
    );
  }
}
