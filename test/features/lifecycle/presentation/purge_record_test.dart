import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/auth/application/session_state.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_desktop/features/organization/domain/bookmark.dart';
import 'package:alexandria_desktop/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_lifecycle_gateway.dart';
import '../../../support/shell_harness.dart';

/// Purging a record (UC-35, FR-LC-05, FR-LC-07, FR-LC-09).
void main() {
  final now = DateTime.utc(2026, 8, 20, 12);

  const fileUuid = 'e1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  /// Past its window, which is what UC-35's precondition asks for.
  final elapsed = aFile(
    uuid: fileUuid,
    name: 'Old notes.md',
    type: LibraryType.text,
    isDeleted: true,
    deletedAt: now.subtract(const Duration(days: 31)),
  );

  /// Still inside its window, which is AF-02.
  final recent = aFile(
    uuid: fileUuid,
    name: 'Old notes.md',
    type: LibraryType.text,
    isDeleted: true,
    deletedAt: now.subtract(const Duration(days: 4)),
  );

  /// Listed as deleted but not marked so, which is AF-03.
  final notDeleted = aFile(
    uuid: fileUuid,
    name: 'Old notes.md',
    type: LibraryType.text,
    deletedAt: now.subtract(const Duration(days: 31)),
  );

  final deletedBookmark = Bookmark(
    uuid: 'bm-1',
    url: 'https://example.org/notes',
    title: 'Saved article',
    isDeleted: true,
    deletedAt: now.subtract(const Duration(days: 31)),
  );

  /// Signs in and opens the deleted-items view holding [file].
  Future<({ProviderContainer container, FakeLifecycleGateway lifecycle})>
  openDeleted(
    WidgetTester tester, {
    CatalogFile? file,
    List<Bookmark> bookmarks = const [],
    List<LifecycleWrite> outcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.document: CatalogListing.loaded(files: [aFile()]),
      },
      deleted: {
        if (file != null)
          LibraryType.text: CatalogListing.loaded(files: [file]),
      },
    );

    final lifecycle = FakeLifecycleGateway()..outcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        bookmarkGatewayProvider.overrideWithValue(
          FakeBookmarkGateway()..deletedBookmarks.addAll(bookmarks),
        ),
        lifecycleGatewayProvider.overrideWithValue(lifecycle),
        clockProvider.overrideWithValue(() => now),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.tap(find.text(l10n.deletedItemsOpen));
    await tester.pumpAndSettle();

    return (container: container, lifecycle: lifecycle);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Future<void> askToPurge(WidgetTester tester) async {
    await tester.tap(find.text(messages(tester).purgeRecord).first);
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
    // Steps 1 and 2.
    testWidgets('GivenARecord_WhenAPurgeIsAsked_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openDeleted(tester, file: elapsed);

      await askToPurge(tester);

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).purgeRecordMessage('Old notes.md')),
        findsOneWidget,
      );
      // FR-LC-05: the on-disk promise is stated, not implied.
      expect(find.text(messages(tester).purgeRecordOnDisk), findsOneWidget);
      expect(opened.lifecycle.purged, isEmpty);
    });

    // Steps 3 to 6.
    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDeleted(tester, file: elapsed);

      await askToPurge(tester);
      await confirm(tester);

      expect(opened.lifecycle.purged, [fileUuid]);
    });

    testWidgets('GivenABookmark_WhenItIsPurged_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDeleted(tester, bookmarks: [deletedBookmark]);

      await askToPurge(tester);

      // A bookmark has no file on disk, so the dialog says nothing about one.
      expect(find.text(messages(tester).purgeRecordOnDisk), findsNothing);

      await confirm(tester);

      expect(opened.lifecycle.purged, ['bm-1']);
    });
  });

  // AF-01: the owner cancels.
  group('a purge the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsDeclined_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openDeleted(tester, file: elapsed);

      await askToPurge(tester);
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

  // AF-02: the retention window has not elapsed.
  group('a record still inside its window', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheOwnerIsToldWhen', (
      tester,
    ) async {
      await openDeleted(
        tester,
        file: recent,
        outcomes: const [
          LifecycleWrite.failed(
            failure: Failure.invalidState(
              family: CoreStatusFamily.file,
              code: FILE_ERR_INVALID_STATE,
            ),
          ),
        ],
      );

      await askToPurge(tester);
      await confirm(tester);

      // FR-LC-07: when it becomes possible, not a status code.
      expect(find.text(messages(tester).purgeTooSoon(26)), findsOneWidget);
    });
  });

  // AF-03: the record is not soft-deleted.
  group('a record that is not deleted', () {
    testWidgets(
      'GivenItIsActive_WhenAPurgeIsConfirmed_ThenTheCoreIsNotCalled',
      (tester) async {
        final opened = await openDeleted(tester, file: notDeleted);

        await askToPurge(tester);
        await confirm(tester);

        expect(opened.lifecycle.purged, isEmpty);
        expect(find.text(messages(tester).purgeNotDeleted), findsOneWidget);
      },
    );
  });

  // AF-04: the core reports the record as not found.
  group('a record the core no longer has', () {
    testWidgets('GivenItIsGone_WhenItIsPurged_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openDeleted(
        tester,
        file: elapsed,
        outcomes: const [
          LifecycleWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.file,
              code: FILE_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await askToPurge(tester);
      await confirm(tester);

      expect(find.text(messages(tester).purgeNotFound), findsOneWidget);
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenAPurgeIsSent_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openDeleted(
          tester,
          file: elapsed,
          outcomes: const [
            LifecycleWrite.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: FILE_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );

        await askToPurge(tester);
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
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenAPurgeIsRefused_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openDeleted(
            tester,
            locale: locale,
            file: recent,
            outcomes: const [
              LifecycleWrite.failed(
                failure: Failure.invalidState(
                  family: CoreStatusFamily.file,
                  code: FILE_ERR_INVALID_STATE,
                ),
              ),
            ],
          );

          await askToPurge(tester);
          await confirm(tester);

          expect(
            find.textContaining(RegExp('purge[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
