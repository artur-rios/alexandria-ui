import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/shell/presentation/background_activity_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// The owner's own experience of FR-LB-21 (UC-07 AF): nobody presses
/// Re-check, and the strip reports one anyway.
///
/// `test/features/library_sources/application/index_session_activity_test.dart`
/// and `.../presentation/refresh_catalog_test.dart` already prove `begin()`
/// reaches the core and that the sources screen shows the outcome with no
/// refusal. Neither proves the half of the feature the owner actually sees
/// without opening any screen: the background activity strip, visible from
/// anywhere in the shell. This is that proof.
void main() {
  testWidgets(
    'GivenACatalogThatFellBehind_WhenTheOwnerSignsIn_ThenTheStripShowsARecheck',
    (tester) async {
      // `begin()` checks what the core already has outstanding
      // (`ActiveRunsController`) before it ever asks `startRefresh` to start
      // one (FR-LB-19), so `listActiveRuns` must answer "nothing outstanding"
      // until the refresh this test is about has genuinely started — or the
      // check itself would refuse to start it. Once it has, determinate, so
      // the bar paints once rather than animating forever and hanging
      // `signIn`'s own `pumpAndSettle`.
      final gateway = FakeIndexGateway()
        ..activeRunsOutcomeOnceRefreshStarts = const ActiveRunsOutcome.read(
          runs: [
            IndexRun(
              runId: '8c2d0e51-77af-4b93-8a10-2f6c4d9b1e37',
              root: '',
              kind: IndexRunKind.refresh,
              status: IndexRunStatus.running,
              phase: IndexRunPhase.processing,
              total: 1000,
              processed: 250,
            ),
          ],
        );

      // The whole feature, from the outside: nobody presses Re-check, and
      // the strip reports one anyway.
      final container = await tester.pumpShell(
        settings: InMemorySettingsStore(rechecksAtStartup: true),
        extraOverrides: [
          indexGatewayProvider.overrideWithValue(gateway),
          runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ],
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackgroundActivityStrip)),
      );

      // `begin()` reached the core unprompted.
      expect(gateway.refreshStarts, isNotEmpty);

      // Not merely present — the strip is in the tree at all times and takes
      // no height when nothing is running. Its actual progress row is what
      // proves a recheck is being reported.
      expect(
        tester.getSize(find.byType(BackgroundActivityStrip)).height,
        BackgroundActivityStrip.expandedHeight,
      );
      expect(
        find.descendant(
          of: find.byType(BackgroundActivityStrip),
          matching: find.text(l10n.activityProgress(250, 1000)),
        ),
        findsOneWidget,
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byType(BackgroundActivityStrip),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.value, closeTo(0.25, 0.001));

      // The run is deliberately still going, so the poller it and the strip
      // schedule is stopped here rather than left pending past the test.
      container.dispose();
    },
  );
}
