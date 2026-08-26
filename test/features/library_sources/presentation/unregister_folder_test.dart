import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Unregistering a library folder from the screen (UC-08, FR-LB-10), and the
/// offer UC-06 AF-03 makes once there is an action behind it.
void main() {
  const music = '/home/owner/music';
  final registeredAt = DateTime.utc(2026, 8, 19, 11);

  LibrarySource source(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
  );

  Future<({InMemoryLibrarySourceStore store, ProviderContainer ref})>
  openScreen(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    FakeIndexGateway? gateway,
    List<LibrarySource>? registered,
    Locale? locale,
  }) async {
    final store = InMemoryLibrarySourceStore(registered ?? [source(music)]);

    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      // Off, so `establish`'s own unawaited call to `begin()` (FR-LB-21)
      // does not itself start a refresh through a gateway a test here
      // configured for its own scenario, racing the scan the test drives.
      settings: InMemorySettingsStore(
        themeMode: themeMode,
        locale: locale,
        rechecksAtStartup: false,
      ),
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

  /// Presses a folder's remove action and waits for the confirmation.
  Future<void> pressRemove(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    await tester.tap(find.text(l10n.librarySourcesUnregister).first);
    await tester.pumpAndSettle();
  }

  group('the confirmation (main flow step 2)', () {
    testWidgets('GivenAFolder_WhenRemoveIsPressed_ThenAConfirmationAppears', (
      tester,
    ) async {
      await openScreen(tester);

      await pressRemove(tester);

      expect(find.byType(ConfirmationDialog), findsOneWidget);
    });

    testWidgets('GivenTheConfirmation_WhenItIsShown_ThenItNamesTheFolder', (
      tester,
    ) async {
      await openScreen(tester);

      await pressRemove(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );
      expect(
        find.text(l10n.librarySourcesUnregisterTitle('music')),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenTheConfirmation_WhenItIsShown_ThenItSaysNothingElseIsTouched',
      (tester) async {
        // FR-LB-10 requires the confirmation state that catalog records and
        // on-disk files are left untouched (BR-12).
        await openScreen(tester);

        await pressRemove(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ConfirmationDialog)),
        );
        expect(find.text(l10n.librarySourcesUnregisterBody), findsOneWidget);
      },
    );
  });

  group('the owner confirms or cancels', () {
    testWidgets('GivenTheConfirmation_WhenTheOwnerConfirms_ThenTheFolderGoes', (
      tester,
    ) async {
      final opened = await openScreen(tester);
      await pressRemove(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );

      await tester.tap(find.text(l10n.librarySourcesUnregisterConfirm));
      await tester.pumpAndSettle();

      expect(opened.store.read(), isEmpty);
      expect(find.text('music'), findsNothing);
    });

    testWidgets('GivenTheConfirmation_WhenTheOwnerCancels_ThenNothingChanges', (
      tester,
    ) async {
      // AF-01.
      final opened = await openScreen(tester);
      await pressRemove(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(opened.store.read(), hasLength(1));
      expect(find.text('music'), findsOneWidget);
    });
  });

  group('the last folder (AF-03)', () {
    testWidgets('GivenTheOnlyFolder_WhenItIsRemoved_ThenGuidanceReturns', (
      tester,
    ) async {
      await openScreen(tester);
      await pressRemove(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );

      await tester.tap(find.text(l10n.librarySourcesUnregisterConfirm));
      await tester.pumpAndSettle();

      expect(find.text(l10n.librarySourcesEmptyTitle), findsOneWidget);
    });
  });

  group('UC-06 AF-03, now that there is an action behind it', () {
    testWidgets(
      'GivenTheCoreCouldNotScanIt_WhenTheFailureShows_ThenRemoveIsOffered',
      (tester) async {
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
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        await tester.tap(find.text(l10n.librarySourcesRescan));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // One in the row, one in the failure notice: the offer is the second.
        expect(find.text(l10n.librarySourcesUnregister), findsNWidgets(2));
      },
    );

    testWidgets('GivenAFinishedRun_WhenTheOutcomeShows_ThenNoRemoveIsOffered', (
      tester,
    ) async {
      // A run that worked says nothing about whether the folder should stay.
      await openScreen(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.text(l10n.librarySourcesRescan));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.librarySourcesUnregister), findsOneWidget);
    });
  });

  group('a run is in flight (AF-02)', () {
    testWidgets(
      'GivenAFolderBeingScanned_WhenRemoveIsPressed_ThenItIsRefused',
      (tester) async {
        final opened = await openScreen(
          tester,
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );
        await tester.tap(find.text(l10n.librarySourcesRescan));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text(l10n.librarySourcesUnregister).first);
        await tester.pump();

        // No confirmation at all: the refusal comes before the question.
        expect(find.byType(ConfirmationDialog), findsNothing);
        expect(find.text(l10n.librarySourcesUnregisterRefused), findsOneWidget);
        expect(opened.store.read(), hasLength(1));

        // The run is deliberately still going, so the poller is stopped here.
        opened.ref.dispose();
      },
    );
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheConfirmationShows_ThenItIsLocalized', (
      tester,
    ) async {
      await openScreen(tester, locale: locale);

      await pressRemove(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );
      for (final label in [
        l10n.librarySourcesUnregisterBody,
        l10n.librarySourcesUnregisterConfirm,
      ]) {
        expect(label, isNot(startsWith('librarySources')));
        expect(find.text(label), findsOneWidget);
      }
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
