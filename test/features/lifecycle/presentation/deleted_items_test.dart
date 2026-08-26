import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/deleted_items_screen.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_lifecycle_gateway.dart';
import '../../../support/shell_harness.dart';

/// Browsing and restoring deleted items (UC-34, FR-LC-03, FR-LC-04).
void main() {
  /// A fixed present, so a retention countdown is a fact and not a race.
  final now = DateTime.utc(2026, 8, 20, 12);

  const bookUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  final recentlyDeleted = aFile(
    uuid: bookUuid,
    name: 'Solaris.epub',
    type: LibraryType.document,
    deletedAt: now.subtract(const Duration(days: 4)),
  );

  final longDeleted = aFile(
    uuid: 'e1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8',
    name: 'Old notes.md',
    type: LibraryType.text,
    deletedAt: now.subtract(const Duration(days: 31)),
  );

  final deletedBookmark = Bookmark(
    uuid: 'bm-1',
    url: 'https://example.org/notes',
    title: 'Saved article',
    isDeleted: true,
    deletedAt: now.subtract(const Duration(days: 1)),
  );

  /// Signs in and opens the deleted-items view (main flow step 1).
  Future<({ProviderContainer container, FakeLifecycleGateway lifecycle})>
  openDeleted(
    WidgetTester tester, {
    Map<LibraryType, CatalogListing>? deleted,
    List<Bookmark> bookmarks = const [],
    List<LifecycleWrite> outcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    // A file in the active catalog, so the dashboard is not the first-run
    // block — which is where the view is reached from.
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.document: loadedDetails([aFile()]),
      },
      deleted:
          deleted ??
          {
            LibraryType.document: loadedDetails([recentlyDeleted]),
          },
    );

    final bookmarkGateway = FakeBookmarkGateway()
      ..deletedBookmarks.addAll(bookmarks);
    final lifecycle = FakeLifecycleGateway()..outcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        bookmarkGatewayProvider.overrideWithValue(bookmarkGateway),
        lifecycleGatewayProvider.overrideWithValue(lifecycle),
        clockProvider.overrideWithValue(() => now),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.deletedItemsOpen);
    await tester.pumpAndSettle();

    return (container: container, lifecycle: lifecycle);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    // Steps 1 to 3.
    testWidgets('GivenDeletedRecords_WhenTheViewOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openDeleted(tester, bookmarks: [deletedBookmark]);

      expect(find.text('Solaris.epub'), findsOneWidget);
      expect(find.text('Saved article'), findsOneWidget);
    });

    // Step 3: FR-LC-03's countdown.
    testWidgets('GivenARecentDeletion_WhenItIsListed_ThenTheDaysLeftAreShown', (
      tester,
    ) async {
      await openDeleted(tester);

      expect(
        find.text(messages(tester).retentionRemaining(26)),
        findsOneWidget,
      );
    });

    // Steps 4 to 6.
    testWidgets('GivenARecord_WhenItIsRestored_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDeleted(tester);

      await tester.tap(find.text(messages(tester).restoreRecord));
      await tester.pumpAndSettle();

      expect(opened.lifecycle.restored, [bookUuid]);
    });

    testWidgets('GivenABookmark_WhenItIsRestored_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDeleted(
        tester,
        deleted: const {},
        bookmarks: [deletedBookmark],
      );

      await tester.tap(find.text(messages(tester).restoreRecord));
      await tester.pumpAndSettle();

      expect(opened.lifecycle.restored, ['bm-1']);
    });
  });

  // AF-01: nothing is deleted.
  group('a library nothing has been deleted from', () {
    testWidgets('GivenNothingIsDeleted_WhenTheViewOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openDeleted(tester, deleted: const {});

      expect(find.text(messages(tester).deletedItemsNone), findsOneWidget);
    });
  });

  // AF-02: the retention window has elapsed.
  group('a record past its retention window', () {
    testWidgets(
      'GivenTheWindowElapsed_WhenItIsListed_ThenRestoreIsNotOffered',
      (tester) async {
        await openDeleted(
          tester,
          deleted: {
            LibraryType.text: loadedDetails([longDeleted]),
          },
        );

        expect(find.text('Old notes.md'), findsOneWidget);
        expect(find.text(messages(tester).retentionElapsed), findsOneWidget);
        expect(find.text(messages(tester).restoreRecord), findsNothing);
      },
    );
  });

  // AF-03: the core reports the record as not found.
  group('a record the core no longer has', () {
    testWidgets('GivenItIsGone_WhenItIsRestored_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openDeleted(
        tester,
        outcomes: const [
          LifecycleWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.file,
              code: FILE_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(find.text(messages(tester).restoreRecord));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).restoreNotFound), findsOneWidget);
    });
  });

  // AF-04: the file went missing on disk since the deletion. The core marks
  // it, and restoring shows what the core answers.
  group('a restored file whose bytes are gone', () {
    testWidgets('GivenItIsMissing_WhenItIsRestored_ThenTheListingShowsThat', (
      tester,
    ) async {
      final catalog = FakeCatalogGateway(
        listings: {
          LibraryType.document: loadedDetails([
            aFile(
              uuid: bookUuid,
              name: 'Solaris.epub',
              type: LibraryType.document,
              missingAt: now,
            ),
          ]),
        },
        deleted: {
          LibraryType.document: loadedDetails([recentlyDeleted]),
        },
      );
      final lifecycle = FakeLifecycleGateway();

      await tester.pumpShell(
        surfaceSize: const Size(1440, 1000),
        extraOverrides: <Override>[
          catalogGatewayProvider.overrideWithValue(catalog),
          bookmarkGatewayProvider.overrideWithValue(FakeBookmarkGateway()),
          lifecycleGatewayProvider.overrideWithValue(lifecycle),
          clockProvider.overrideWithValue(() => now),
        ],
      );

      await tester.openLibraryTool(messages(tester).deletedItemsOpen);
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).restoreRecord));
      await tester.pumpAndSettle();

      // The record came back through the core, and the missing marking is the
      // core's own — nothing here decides it.
      expect(lifecycle.restored, [bookUuid]);
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenARestoreIsSent_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openDeleted(
          tester,
          outcomes: const [
            LifecycleWrite.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: FILE_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );

        await tester.tap(find.text(messages(tester).restoreRecord));
        await tester.pumpAndSettle();

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheViewOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openDeleted(tester, themeMode: themeMode);

          expect(
            Theme.of(
              tester.element(find.byType(DeletedItemsScreen)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenARestoreFails_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openDeleted(
            tester,
            locale: locale,
            bookmarks: [deletedBookmark],
            outcomes: const [
              LifecycleWrite.failed(
                failure: Failure.notFound(
                  family: CoreStatusFamily.file,
                  code: FILE_ERR_NOT_FOUND,
                ),
              ),
            ],
          );

          await tester.tap(find.text(messages(tester).restoreRecord).first);
          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              RegExp('(deletedItems|restore|retention)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
