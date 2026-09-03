import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/lifecycle/domain/file_hold.dart';
import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/purge_on_disk_section.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_lifecycle_gateway.dart';
import '../../../support/shell_harness.dart';
import '../../../support/file_row.dart';

/// A [FileHold] a test can put on a file (UC-36 AF-05).
class _StubHold implements FileHold {
  _StubHold(this._uuid);

  final String _uuid;

  /// Whether it was let go of.
  bool released = false;

  @override
  bool holds(String uuid) => uuid == _uuid;

  @override
  Future<void> release() async => released = true;
}

/// Purging a file on disk (UC-36, FR-LC-06, FR-LC-09).
void main() {
  const bookUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';
  const path = '/home/owner/books/Solaris.epub';

  final book = aFile(
    uuid: bookUuid,
    name: 'Solaris.epub',
    path: path,
    type: FileType.document,
  );

  /// Signs in and opens the book's detail view (main flow step 1).
  Future<({ProviderContainer container, FakeLifecycleGateway lifecycle})>
  openDetails(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    PurgeOnDiskOutcome? outcome,
    List<FileHold>? holds,
    Locale? locale,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        FileType.document: loadedDetails([book]),
      },
    );
    catalog.details[bookUuid] = FileDetailsOutcome.read(
      details: FileDetails(file: book, metadata: const {}),
    );

    final lifecycle = FakeLifecycleGateway();
    if (outcome != null) lifecycle.purgeOnDiskOutcome = outcome;

    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        lifecycleGatewayProvider.overrideWithValue(lifecycle),
        if (holds != null) fileHoldsProvider.overrideWithValue(holds),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.books.icon),
      ),
    );
    await tester.pumpAndSettle();
    await openDetailsOf(tester, 'Solaris.epub');
    await tester.pumpAndSettle();

    return (container: container, lifecycle: lifecycle);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the folded-away section and presses the action inside it.
  Future<void> reachTheAction(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(PurgeOnDiskSection));
    await tester.tap(find.text(messages(tester).purgeOnDiskTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(messages(tester).purgeOnDiskAction).last);
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    // Step 1 and FR-LC-06: never the default, never one interaction from a
    // listing row.
    testWidgets('GivenTheDetailView_WhenItOpens_ThenTheActionIsFoldedAway', (
      tester,
    ) async {
      await openDetails(tester);

      expect(find.byType(PurgeOnDiskSection), findsOneWidget);
      expect(find.text(messages(tester).purgeOnDiskAction), findsNothing);
    });

    // Step 2: the confirmation names the exact path.
    testWidgets('GivenTheAction_WhenItIsPressed_ThenThePathIsNamed', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await reachTheAction(tester);

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).purgeOnDiskMessage(path)),
        findsOneWidget,
      );
      expect(
        find.text(messages(tester).purgeOnDiskIrreversible),
        findsOneWidget,
      );
      expect(opened.lifecycle.purged, isEmpty);
    });

    // Steps 3 to 6.
    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await reachTheAction(tester);
      await confirm(tester);

      expect(opened.lifecycle.purged, [bookUuid]);
    });
  });

  // AF-01: the owner cancels.
  group('a purge the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsDeclined_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await reachTheAction(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.lifecycle.purged, isEmpty);
    });
  });

  // AF-02: the file was already absent from disk.
  group('a record whose file was already gone', () {
    testWidgets('GivenNoFileOnDisk_WhenItIsPurged_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: const PurgeOnDiskOutcome.purged(diskFilePresent: false),
      );

      await reachTheAction(tester);
      await confirm(tester);

      expect(find.text(messages(tester).purgeNothingOnDisk), findsOneWidget);
    });
  });

  // AF-03: the core reports a disk failure.
  group('a disk that refuses', () {
    testWidgets('GivenTheDiskFails_WhenItIsPurged_ThenNothingWasRemoved', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: const PurgeOnDiskOutcome.failed(
          failure: Failure.disk(
            family: CoreStatusFamily.file,
            code: FILE_ERR_DISK,
          ),
        ),
      );

      await reachTheAction(tester);
      await confirm(tester);

      expect(find.text(messages(tester).purgeDiskFailed), findsOneWidget);
    });
  });

  // AF-04: the core reports the record as not found.
  group('a record the core no longer has', () {
    testWidgets('GivenItIsGone_WhenItIsPurged_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: const PurgeOnDiskOutcome.failed(
          failure: Failure.notFound(
            family: CoreStatusFamily.file,
            code: FILE_ERR_NOT_FOUND,
          ),
        ),
      );

      await reachTheAction(tester);
      await confirm(tester);

      expect(find.text(messages(tester).purgeNotFound), findsOneWidget);
    });
  });

  // AF-05: the file is playing or open.
  group('a file something has open', () {
    testWidgets('GivenItIsOpen_WhenTheActionIsPressed_ThenTheOwnerIsWarned', (
      tester,
    ) async {
      await openDetails(tester, holds: [_StubHold(bookUuid)]);

      await reachTheAction(tester);

      expect(
        find.textContaining(messages(tester).deleteFileInUse),
        findsOneWidget,
      );
    });

    testWidgets('GivenItIsOpen_WhenThePurgeIsConfirmed_ThenItIsLetGoOfFirst', (
      tester,
    ) async {
      final hold = _StubHold(bookUuid);
      final opened = await openDetails(tester, holds: [hold]);

      await reachTheAction(tester);
      await confirm(tester);

      expect(hold.released, isTrue);
      expect(opened.lifecycle.purged, [bookUuid]);
    });
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenAPurgeIsSent_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openDetails(
          tester,
          outcome: const PurgeOnDiskOutcome.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.file,
              code: FILE_ERR_UNAUTHORIZED,
            ),
          ),
        );

        await reachTheAction(tester);
        await confirm(tester);

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('themes and languages', () {
    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenAPurgeFails_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openDetails(
            tester,
            locale: locale,
            outcome: const PurgeOnDiskOutcome.failed(
              failure: Failure.disk(
                family: CoreStatusFamily.file,
                code: FILE_ERR_DISK,
              ),
            ),
            holds: [_StubHold(bookUuid)],
          );

          await reachTheAction(tester);
          await confirm(tester);

          expect(
            find.textContaining(RegExp('purge[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openDetails(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(FileDetailsView).first),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
