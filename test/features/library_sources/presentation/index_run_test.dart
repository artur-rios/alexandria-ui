import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/auth/presentation/login_screen.dart';
import 'package:alexandria_desktop/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_desktop/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_desktop/features/library_sources/domain/index_run.dart';
import 'package:alexandria_desktop/features/library_sources/domain/library_source.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// Starting an index run from the library-folders screen
/// (UC-06, FR-LB-05, FR-LB-07 … FR-LB-09).
void main() {
  const root = '/home/owner/music';
  final registeredAt = DateTime.utc(2026, 8, 19, 10, 30);

  LibrarySource source({String? lastRunId}) => LibrarySource(
    path: root,
    label: defaultLabelFor(root),
    registeredAt: registeredAt,
    lastRunId: lastRunId,
  );

  /// Opens the library-folders screen with [gateway] bound and one folder
  /// already registered.
  Future<({InMemoryLibrarySourceStore store, ProviderContainer ref})>
  openScreen(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    FakeIndexGateway? gateway,
    List<LibrarySource>? registered,
    Locale? locale,
  }) async {
    final store = InMemoryLibrarySourceStore(registered ?? [source()]);

    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      extraOverrides: <Override>[
        librarySourceStoreProvider.overrideWithValue(store),
        indexGatewayProvider.overrideWithValue(gateway ?? FakeIndexGateway()),
        clockProvider.overrideWithValue(() => registeredAt),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );

    // Reached from the navigation panel's tools menu (UC-05 main flow step 1),
    // which is where every library-wide screen is reached from.
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librarySourcesOpen);

    return (store: store, ref: container);
  }

  /// Presses a folder's index action.
  Future<void> startIndex(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    await tester.tap(find.text(l10n.librarySourcesIndex));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('the main flow', () {
    testWidgets(
      'GivenARegisteredFolder_WhenTheScreenOpens_ThenIndexIsOffered',
      (tester) async {
        await openScreen(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        expect(find.text(l10n.librarySourcesIndex), findsOneWidget);
      },
    );

    testWidgets('GivenAScanIsStarted_WhenItIsRunning_ThenTheScreenSaysSo', (
      tester,
    ) async {
      // FR-LB-07: the run is visible and the interface stays usable.
      final opened = await openScreen(
        tester,
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );

      await startIndex(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(find.text(l10n.librarySourcesIndexing), findsOneWidget);

      // Disposed here rather than at teardown: a run still in flight is still
      // being polled, and the widget tree is torn down before the provider
      // container is, so the poller would outlive the test.
      opened.ref.dispose();
    });

    testWidgets('GivenAScanFinishes_WhenItSettles_ThenItsCountsAreShown', (
      tester,
    ) async {
      // FR-LB-08.
      await openScreen(tester);

      await startIndex(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(
        find.text(l10n.librarySourcesRunComplete(120, 118, 2)),
        findsOneWidget,
      );
    });

    testWidgets('GivenAnOutcome_WhenItIsDismissed_ThenItGoes', (tester) async {
      await openScreen(tester);
      await startIndex(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.byTooltip(l10n.dismiss));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.librarySourcesRunComplete(120, 118, 2)),
        findsNothing,
      );
    });
  });

  group('a second run is refused (AF-01)', () {
    testWidgets('GivenARunInFlight_WhenIndexIsPressedAgain_ThenItIsRefused', (
      tester,
    ) async {
      final gateway = FakeIndexGateway()..readOutcomes = [runningRun()];
      final opened = await openScreen(tester, gateway: gateway);
      await startIndex(tester);

      // The action is replaced by the running indicator, so the second
      // attempt goes through the controller the way a stale frame would.
      await opened.ref
          .read(indexRunsControllerProvider.notifier)
          .startIndex(root);
      // Pumped, not settled: the running indicator is an animation that is
      // supposed to keep going.
      await tester.pump();

      expect(gateway.starts, hasLength(1));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(find.text(l10n.librarySourcesRunRefused), findsOneWidget);

      // As above: the run is deliberately still going.
      opened.ref.dispose();
    });
  });

  group('the core refuses the start (AF-02, AF-03)', () {
    testWidgets('GivenTheCoreRefuses_WhenAScanIsStarted_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openScreen(
        tester,
        gateway: FakeIndexGateway()
          ..startOutcome = const IndexStartOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.indexing,
              code: 1,
            ),
          ),
      );

      await startIndex(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(
        find.textContaining(l10n.librarySourcesStartFailed),
        findsOneWidget,
      );
    });
  });

  group('the core rejects the session (AF-06)', () {
    testWidgets('GivenTheStartIsUnauthorized_WhenItSettles_ThenLoginReturns', (
      tester,
    ) async {
      await openScreen(
        tester,
        gateway: FakeIndexGateway()
          ..startOutcome = const IndexStartOutcome.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.indexing,
              code: 2,
            ),
          ),
      );

      await startIndex(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('a run outlives the application (AF-05)', () {
    testWidgets(
      'GivenARecordedRun_WhenTheScreenOpens_ThenItsOutcomeIsPresented',
      (tester) async {
        await openScreen(
          tester,
          registered: [source(lastRunId: 'a-recorded-run')],
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );
        expect(
          find.text(l10n.librarySourcesRunComplete(120, 118, 2)),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenAPausedRun_WhenTheScreenOpens_ThenItReadsAsInterrupted', (
      tester,
    ) async {
      // Not a failure: the owner closed the application, and saying it
      // failed would report a problem that did not happen.
      await openScreen(
        tester,
        gateway: FakeIndexGateway()
          ..readOutcomes = [
            finishedRun(
              status: IndexRunStatus.paused,
              counts: const IndexRunCounts(scanned: 40, indexed: 12),
            ),
          ],
        registered: [source(lastRunId: 'a-recorded-run')],
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(find.text(l10n.librarySourcesRunInterrupted), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenARunFinishes_ThenItsStringsAreLocalized', (
      tester,
    ) async {
      await openScreen(tester, locale: locale);

      await startIndex(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      final outcome = l10n.librarySourcesRunComplete(120, 118, 2);
      expect(outcome, isNot(startsWith('librarySources')));
      expect(find.text(outcome), findsOneWidget);
    });
  }
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openScreen(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(LibrarySourcesScreen).first),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
