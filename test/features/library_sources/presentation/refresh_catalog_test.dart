import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/missing_files_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// Refreshing the catalog from the library-folders screen (UC-07).
void main() {
  const root = '/home/owner/music';
  final now = DateTime.utc(2026, 8, 19, 12);

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

  Future<ProviderContainer> openScreen(
    WidgetTester tester, {
    required FakeIndexGateway gateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      extraOverrides: <Override>[
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore([
            LibrarySource(
              path: root,
              label: defaultLabelFor(root),
              registeredAt: now,
            ),
          ]),
        ),
        indexGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(() => now),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );

    // Reached from the navigation panel's tools menu (UC-05 main flow step 1),
    // which is where every library-wide screen is reached from.
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librarySourcesOpen);

    return container;
  }

  /// Presses the catalog-wide refresh.
  Future<void> pressRefresh(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    await tester.tap(find.text(l10n.librarySourcesRecheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('GivenTheScreen_WhenItOpens_ThenARefreshIsOffered', (
    tester,
  ) async {
    await openScreen(
      tester,
      gateway: FakeIndexGateway()..readOutcomes = [refreshed()],
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );

    expect(find.text(l10n.librarySourcesRecheck), findsOneWidget);
  });

  testWidgets('GivenARefresh_WhenItFinishes_ThenItsCountsAreShown', (
    tester,
  ) async {
    await openScreen(
      tester,
      gateway: FakeIndexGateway()..readOutcomes = [refreshed()],
    );

    await pressRefresh(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    expect(
      find.textContaining(l10n.librarySourcesRefreshComplete(9, 110, 0)),
      findsOneWidget,
    );
  });

  testWidgets('GivenAnEmptyCatalog_WhenARefreshIsPressed_ThenItSaysWhatToDo', (
    tester,
  ) async {
    // AF-02: registering and indexing a folder is what the owner needs, and
    // both actions are already on this screen.
    await openScreen(
      tester,
      gateway: FakeIndexGateway()
        ..catalogedFileCount = 0
        ..readOutcomes = [refreshed()],
    );

    await pressRefresh(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    expect(find.text(l10n.librarySourcesRefreshEmpty), findsOneWidget);
  });

  testWidgets(
    'GivenARefreshRunning_WhenTheScreenRebuilds_ThenTheActionIsBusy',
    (tester) async {
      final container = await openScreen(
        tester,
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );

      await pressRefresh(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(find.text(l10n.librarySourcesRefreshing), findsOneWidget);

      // The refresh is deliberately still going, so the poller is stopped here.
      container.dispose();
    },
  );

  /// The review link inside the sources screen, and not the dashboard's own
  /// entry behind this full-screen dialog.
  Finder reviewLink(AppLocalizations l10n) => find.descendant(
    of: find.byType(LibrarySourcesScreen),
    matching: find.text(l10n.missingFilesOpen),
  );

  testWidgets(
    'GivenFilesGoMissing_WhenTheRefreshFinishes_ThenTheReviewIsOffered',
    (tester) async {
      // AF-03: "the outcome links to the missing-files review (UC-37)".
      await openScreen(
        tester,
        gateway: FakeIndexGateway()..readOutcomes = [refreshed(missing: 4)],
      );

      await pressRefresh(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(reviewLink(l10n), findsOneWidget);
    },
  );

  testWidgets(
    'GivenFilesGoMissing_WhenTheReviewIsOpened_ThenTheMissingFilesShow',
    (tester) async {
      await openScreen(
        tester,
        gateway: FakeIndexGateway()..readOutcomes = [refreshed(missing: 4)],
      );

      await pressRefresh(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      await tester.tap(reviewLink(l10n));
      await tester.pumpAndSettle();

      expect(find.byType(MissingFilesScreen), findsOneWidget);
    },
  );

  testWidgets('GivenNoFilesGoMissing_WhenItFinishes_ThenNoReviewIsOffered', (
    tester,
  ) async {
    await openScreen(
      tester,
      gateway: FakeIndexGateway()..readOutcomes = [refreshed()],
    );

    await pressRefresh(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    expect(reviewLink(l10n), findsNothing);
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenARefreshFinishes_ThenItIsLocalized', (
      tester,
    ) async {
      await openScreen(
        tester,
        gateway: FakeIndexGateway()..readOutcomes = [refreshed()],
        locale: locale,
      );

      await pressRefresh(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      final outcome = l10n.librarySourcesRefreshComplete(9, 110, 0);
      expect(outcome, isNot(startsWith('librarySources')));
      expect(find.textContaining(outcome), findsOneWidget);
    });
  }
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openScreen(
            tester,
            gateway: FakeIndexGateway(),
            themeMode: mode,
          );

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
