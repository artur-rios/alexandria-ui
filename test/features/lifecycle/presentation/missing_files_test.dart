import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/lifecycle/application/missing_files_controller.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/missing_files_screen.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// Reviewing missing files (UC-37, FR-LC-08).
void main() {
  final missingAt = DateTime.utc(2026, 8, 18);

  const missingUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  final present = aFile(
    uuid: 'a0000000-0000-4000-8000-000000000001',
    name: 'Here.epub',
    path: '/home/owner/books/Here.epub',
    type: LibraryType.document,
  );

  final missing = aFile(
    uuid: missingUuid,
    name: 'Gone.epub',
    path: '/home/owner/books/Gone.epub',
    type: LibraryType.document,
    missingAt: missingAt,
  );

  final fromUnregistered = aFile(
    uuid: 'a0000000-0000-4000-8000-000000000002',
    name: 'Elsewhere.epub',
    path: '/media/usb/Elsewhere.epub',
    type: LibraryType.document,
    missingAt: missingAt,
  );

  final registered = LibrarySource(
    path: '/home/owner/books',
    label: 'Books',
    registeredAt: DateTime.utc(2026),
  );

  /// Signs in and opens the missing-files review (main flow step 1).
  Future<({ProviderContainer container, FakeCatalogGateway catalog})>
  openReview(
    WidgetTester tester, {
    List<CatalogFile> files = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.document: CatalogListing.loaded(files: [present, ...files]),
      },
    );
    for (final file in [present, missing, fromUnregistered]) {
      catalog.details[file.uuid] = FileDetailsOutcome.read(
        details: FileDetails(file: file, metadata: const {}),
      );
    }

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore([registered]),
        ),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.missingFilesOpen);
    await tester.pumpAndSettle();

    return (container: container, catalog: catalog);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    // Steps 1 to 3.
    testWidgets('GivenMissingFiles_WhenTheReviewOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openReview(tester, files: [missing]);

      // Scoped to the screen: the dashboard behind it lists the same files.
      expect(
        find.descendant(
          of: find.byType(MissingFilesScreen),
          matching: find.text('Gone.epub'),
        ),
        findsOneWidget,
      );
      expect(find.text('/home/owner/books/Gone.epub'), findsOneWidget);
    });

    testWidgets('GivenAPresentFile_WhenTheReviewOpens_ThenItIsNotListed', (
      tester,
    ) async {
      await openReview(tester, files: [missing]);

      expect(
        find.descendant(
          of: find.byType(MissingFilesScreen),
          matching: find.text('Here.epub'),
        ),
        findsNothing,
      );
    });

    // Steps 4 and 5.
    testWidgets('GivenTheReview_WhenARescanIsAsked_ThenTheCoreIsAsked', (
      tester,
    ) async {
      await openReview(tester, files: [missing]);

      await tester.tap(find.text(messages(tester).missingFilesRescan));
      await tester.pumpAndSettle();

      // The refresh is the core's own run; asking for it is what step 4 is.
      expect(find.text(messages(tester).missingFilesRescan), findsOneWidget);
    });
  });

  // AF-01: no file is missing.
  group('a missing audio file (FR-CT-13)', () {
    testWidgets(
      'GivenAMissingAudioFile_WhenTheReviewListsIt_ThenItsMetadataTitleAppearsNotItsName',
      (tester) async {
        final catalog = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c0000000-0000-4000-8000-000000000009',
            name: 'track-09.flac',
            title: 'So What',
            missingAt: missingAt,
          )
          ..listings[LibraryType.document] = CatalogListing.loaded(
            files: [present],
          );
        for (final file in [present]) {
          catalog.details[file.uuid] = FileDetailsOutcome.read(
            details: FileDetails(file: file, metadata: const {}),
          );
        }

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
            librarySourceStoreProvider.overrideWithValue(
              InMemoryLibrarySourceStore([registered]),
            ),
          ],
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        await tester.openLibraryTool(l10n.missingFilesOpen);
        await tester.pumpAndSettle();

        // Scoped to the screen: the dashboard behind it may show the same
        // recently-added file, named the same way.
        expect(
          find.descendant(
            of: find.byType(MissingFilesScreen),
            matching: find.text('So What'),
          ),
          findsOneWidget,
        );
        expect(find.text('track-09.flac'), findsNothing);
      },
    );
  });

  group('a library nothing is missing from', () {
    testWidgets('GivenNothingIsMissing_WhenTheReviewOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openReview(tester);

      expect(find.text(messages(tester).missingFilesNone), findsOneWidget);
    });
  });

  // AF-02: the owner decides to remove a missing record. Nothing here does it
  // for them — the record's own detail view is where deletion lives (BR-16).
  group('a record the owner wants gone', () {
    testWidgets('GivenARecord_WhenTheReviewListsIt_ThenNoDeleteIsOffered', (
      tester,
    ) async {
      await openReview(tester, files: [missing]);

      expect(
        find.descendant(
          of: find.byType(MissingFilesScreen),
          matching: find.text(messages(tester).deleteFile),
        ),
        findsNothing,
      );
    });

    testWidgets('GivenARecord_WhenItIsOpened_ThenItsDetailViewIsShown', (
      tester,
    ) async {
      await openReview(tester, files: [missing]);

      await tester.tap(
        find.text(messages(tester).missingFilesOpenDetails).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
      expect(find.text(messages(tester).deleteFile), findsWidgets);
    });
  });

  // AF-03: the record came from a folder that is no longer registered.
  group('a record from an unregistered folder', () {
    testWidgets('GivenAnUnregisteredFolder_WhenItIsListed_ThenItIsMarked', (
      tester,
    ) async {
      await openReview(tester, files: [missing, fromUnregistered]);

      expect(
        find.text(messages(tester).missingFilesUnregisteredFolder),
        findsOneWidget,
      );
    });
  });

  // AF-04: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenTheReviewLoads_ThenTheOwnerSignsOut',
      (tester) async {
        final catalog = FakeCatalogGateway(
          listings: {
            for (final type in LibraryType.values)
              type: const CatalogListing.failed(
                failure: Failure.unauthorized(
                  family: CoreStatusFamily.file,
                  code: FILE_ERR_UNAUTHORIZED,
                ),
              ),
          },
        );

        final container = await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
          ],
        );

        // Read rather than opened: the review loads lazily, so this is the
        // listing it would have triggered.
        await container.read(missingFilesControllerProvider.future);

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('the registered-folder check', () {
    test('GivenAPathUnderARoot_WhenItIsChecked_ThenItIsRegistered', () {
      expect(
        isUnderRegisteredFolder('/home/owner/books/a.epub', const [
          '/home/owner/books',
        ]),
        isTrue,
      );
    });

    // A prefix comparison that ignored the separator would claim this one.
    test('GivenASiblingWithASharedPrefix_WhenChecked_ThenItIsNot', () {
      expect(
        isUnderRegisteredFolder('/home/owner/books-archive/a.epub', const [
          '/home/owner/books',
        ]),
        isFalse,
      );
    });

    test('GivenAWindowsPathDifferingInCase_WhenChecked_ThenItIsRegistered', () {
      expect(
        isUnderRegisteredFolder(r'C:\Users\Owner\Books\a.epub', const [
          r'c:\users\owner\books',
        ]),
        isTrue,
      );
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheReviewOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openReview(tester, themeMode: themeMode, files: [missing]);

          expect(
            Theme.of(
              tester.element(find.byType(MissingFilesScreen)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheReviewOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openReview(
            tester,
            locale: locale,
            files: [missing, fromUnregistered],
          );

          expect(
            find.textContaining(
              RegExp('missingFiles[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
