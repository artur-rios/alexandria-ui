import 'dart:async';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/lifecycle/domain/file_hold.dart';
import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_lifecycle_gateway.dart';
import '../../../support/shell_harness.dart';

/// A [FileHold] a test can put on a file (UC-33 AF-04).
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

/// Deleting an item (UC-33, FR-LC-01, FR-LC-02, FR-LC-09).
void main() {
  const bookUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  final book = aFile(
    uuid: bookUuid,
    name: 'Solaris.epub',
    type: LibraryType.document,
  );

  const bookmark = Bookmark(
    uuid: 'bm-1',
    url: 'https://example.org/notes',
    title: 'Notes',
  );

  /// Signs in and opens the book's detail view (main flow step 1).
  Future<({ProviderContainer container, FakeLifecycleGateway lifecycle})>
  openDetails(
    WidgetTester tester, {
    List<LifecycleWrite> outcomes = const [],
    List<FileHold>? holds,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.document: loadedDetails([book]),
      },
    );
    catalog.details[bookUuid] = FileDetailsOutcome.read(
      details: FileDetails(file: book, metadata: const {}),
    );

    final lifecycle = FakeLifecycleGateway()..outcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
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
    await tester.tap(find.text('Solaris.epub').first);
    await tester.pumpAndSettle();

    return (container: container, lifecycle: lifecycle);
  }

  /// Signs in and opens the bookmarks area.
  Future<({ProviderContainer container, FakeLifecycleGateway lifecycle})>
  openBookmarks(WidgetTester tester) async {
    final lifecycle = FakeLifecycleGateway();

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        bookmarkGatewayProvider.overrideWithValue(
          FakeBookmarkGateway(bookmarks: const [bookmark]),
        ),
        lifecycleGatewayProvider.overrideWithValue(lifecycle),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.bookmarks.icon),
      ),
    );
    await tester.pumpAndSettle();

    return (container: container, lifecycle: lifecycle);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

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
    testWidgets('GivenAFile_WhenADeleteIsAsked_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).deleteFileMessage('Solaris.epub')),
        findsOneWidget,
      );
      // FR-LC-01: the on-disk promise is stated, not implied.
      expect(find.text(messages(tester).deleteFileOnDisk), findsOneWidget);
      expect(opened.lifecycle.deletedFiles, isEmpty);
    });

    // Steps 3 to 6.
    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(opened.lifecycle.deletedFiles, [bookUuid]);
    });

    testWidgets('GivenABookmark_WhenItIsDeleted_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(
        find.text(messages(tester).deleteBookmarkMessage('Notes')),
        findsOneWidget,
      );
      // A bookmark has no file on disk, so the dialog says nothing about one.
      expect(find.text(messages(tester).deleteFileOnDisk), findsNothing);

      await confirm(tester);

      expect(opened.lifecycle.deletedBookmarks, ['bm-1']);
    });
  });

  group('deleting an audio file (FR-CT-13)', () {
    testWidgets(
      'GivenAnAudioFile_WhenADeleteIsAsked_ThenTheConfirmationNamesItByItsMetadata',
      (tester) async {
        const audioUuid = 'a1a2a3a4-5d6e-4f70-8912-a3b4c5d6e7f8';
        final track = aFile(
          uuid: audioUuid,
          name: 'track-07.flac',
          type: LibraryType.audio,
        );
        final row = FileDetails(
          file: track,
          metadata: const {'title': 'So What'},
        );
        final gateway = FakeCatalogGateway(
          listings: {
            LibraryType.audio: CatalogListing.loaded(files: [row]),
          },
        )..details[audioUuid] = FileDetailsOutcome.read(details: row);

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(gateway),
          ],
        );

        // Reached the same way `audio_player_test.dart` reaches the details
        // dialog for an audio file: UC-46 gave audio its own browsing area
        // whose rows do not open this dialog on tap, so this calls the same
        // static `show` the application does rather than a listing row.
        final element = tester.element(find.byType(ShellScreen));
        unawaited(
          FileDetailsView.show(element, element as WidgetRef, audioUuid),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(messages(tester).deleteFile).last);
        await tester.pumpAndSettle();

        expect(
          find.text(messages(tester).deleteFileMessage('So What')),
          findsOneWidget,
        );
        expect(
          find.text(messages(tester).deleteFileMessage('track-07.flac')),
          findsNothing,
        );
      },
    );
  });

  // AF-01: the owner cancels.
  group('a deletion the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsDeclined_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openDetails(tester);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.lifecycle.deletedFiles, isEmpty);
    });
  });

  // AF-02 and AF-03: the core has it deleted already, or not at all.
  group('a record the core will not delete', () {
    for (final (label, failure, message) in [
      (
        'AlreadyDeleted',
        const Failure.invalidState(
          family: CoreStatusFamily.file,
          code: FILE_ERR_INVALID_STATE,
        ),
        'deleteAlreadyDeleted',
      ),
      (
        'Gone',
        const Failure.notFound(
          family: CoreStatusFamily.file,
          code: FILE_ERR_NOT_FOUND,
        ),
        'deleteNotFound',
      ),
    ]) {
      testWidgets('GivenItIs${label}_WhenItIsDeleted_ThenTheOwnerIsTold', (
        tester,
      ) async {
        await openDetails(
          tester,
          outcomes: [LifecycleWrite.failed(failure: failure)],
        );

        await tester.tap(find.text(messages(tester).deleteFile).last);
        await tester.pumpAndSettle();
        await confirm(tester);

        expect(
          find.text(switch (message) {
            'deleteAlreadyDeleted' => messages(tester).deleteAlreadyDeleted,
            _ => messages(tester).deleteNotFound,
          }),
          findsOneWidget,
        );
      });
    }
  });

  // AF-04: something has the file open.
  group('a file something has open', () {
    testWidgets('GivenItIsOpen_WhenADeleteIsAsked_ThenTheOwnerIsWarned', (
      tester,
    ) async {
      await openDetails(tester, holds: [_StubHold(bookUuid)]);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(messages(tester).deleteFileInUse),
        findsOneWidget,
      );
    });

    testWidgets('GivenItIsOpen_WhenTheDeleteIsConfirmed_ThenItIsLetGoOf', (
      tester,
    ) async {
      final hold = _StubHold(bookUuid);
      final opened = await openDetails(tester, holds: [hold]);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(hold.released, isTrue);
      expect(opened.lifecycle.deletedFiles, [bookUuid]);
    });

    testWidgets('GivenNothingHasIt_WhenADeleteIsAsked_ThenNoWarningIsShown', (
      tester,
    ) async {
      await openDetails(tester, holds: [_StubHold('another-uuid')]);

      await tester.tap(find.text(messages(tester).deleteFile).last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(messages(tester).deleteFileInUse),
        findsNothing,
      );
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenADeleteIsSent_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openDetails(
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

        await tester.tap(find.text(messages(tester).deleteFile).last);
        await tester.pumpAndSettle();
        await confirm(tester);

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
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheConfirmationOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openDetails(tester, themeMode: themeMode);

          await tester.tap(find.text(messages(tester).deleteFile).last);
          await tester.pumpAndSettle();

          expect(
            Theme.of(
              tester.element(find.byType(ConfirmationDialog)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenADeleteFails_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openDetails(
            tester,
            locale: locale,
            outcomes: const [
              LifecycleWrite.failed(
                failure: Failure.notFound(
                  family: CoreStatusFamily.file,
                  code: FILE_ERR_NOT_FOUND,
                ),
              ),
            ],
            holds: [_StubHold(bookUuid)],
          );

          await tester.tap(find.text(messages(tester).deleteFile).last);
          await tester.pumpAndSettle();
          await confirm(tester);

          expect(
            find.textContaining(RegExp('delete[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
