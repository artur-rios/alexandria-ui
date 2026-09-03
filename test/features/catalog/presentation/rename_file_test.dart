import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_name.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/rename_file_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';
import '../../../support/file_row.dart';

/// Renaming a file (UC-17, FR-ME-04, FR-ME-05).
void main() {
  const uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f';

  FileDetails aTrack({bool isDeleted = false}) => FileDetails(
    file: aFile(uuid: uuid, name: 'Kind of Blue.flac'),
    metadata: const {'title': 'So What'},
    isDeleted: isDeleted,
  );

  /// Signs in, opens the audio listing, and opens the rename dialog on the one
  /// file in it.
  Future<(ProviderContainer, FakeCatalogGateway)> openDialog(
    WidgetTester tester, {
    FileDetails? details,
    List<FileRenameOutcome> outcomes = const [],
    HostFileSystem host = HostFileSystem.posix,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final loaded = details ?? aTrack();
    final gateway = FakeCatalogGateway(
      listings: {
        FileType.audio: CatalogListing.loaded(files: [loaded]),
      },
    );
    gateway.details[loaded.file.uuid] = FileDetailsOutcome.read(
      details: loaded,
    );
    gateway.renameOutcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(gateway),
        hostFileSystemProvider.overrideWithValue(host),
      ],
    );

    // Reached from the dashboard's recent list, which names an audio file by
    // its metadata title rather than its file name (FR-CT-13).
    await openDetailsOf(tester, 'So What');
    await tester.pumpAndSettle();

    if (!loaded.isDeleted) {
      // Main flow step 1: renaming is offered from the file's detail view.
      await tester.tap(find.byIcon(Icons.drive_file_rename_outline));
      await tester.pumpAndSettle();
    }

    return (container, gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Future<void> enter(WidgetTester tester, String name) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(RenameFileDialog),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.pump();
  }

  Future<void> rename(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(RenameFileDialog),
        matching: find.widgetWithText(
          FilledButton,
          messages(tester).renameSubmit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    testWidgets('GivenAFile_WhenItsDetailsOpen_ThenRenamingIsOffered', (
      tester,
    ) async {
      await openDialog(tester);

      expect(find.byType(RenameFileDialog), findsOneWidget);
    });

    testWidgets('GivenTheDialogOpens_WhenItIsShown_ThenItHoldsTheCurrentName', (
      tester,
    ) async {
      await openDialog(tester);

      expect(
        find.descendant(
          of: find.byType(RenameFileDialog),
          matching: find.text('Kind of Blue.flac'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('GivenANewName_WhenItIsSubmitted_ThenItGoesToTheCore', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);

      await enter(tester, 'Kind of Blue (1959).flac');
      await rename(tester);

      expect(gateway.renames, hasLength(1));
      expect(gateway.renames.single.name, 'Kind of Blue (1959).flac');
      expect(gateway.renames.single.uuid, uuid);
    });

    testWidgets('GivenTheCoreRenamesIt_WhenItAnswers_ThenTheDialogCloses', (
      tester,
    ) async {
      await openDialog(tester);

      await enter(tester, 'Blue.flac');
      await rename(tester);

      expect(find.byType(RenameFileDialog), findsNothing);
    });

    // FR-ME-05: the listing and the detail view read the core again, so the
    // new name shows up without a manual refresh.
    testWidgets('GivenARename_WhenItIsStored_ThenTheListingIsReadAgain', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);
      final before = gateway.requested.length;

      await enter(tester, 'Blue.flac');
      await rename(tester);

      expect(gateway.requested.length, greaterThan(before));
    });

    // The whitespace is a typing artifact, and on Windows the filesystem would
    // strip it anyway — leaving the catalog and the disk disagreeing.
    testWidgets(
      'GivenSurroundingWhitespace_WhenItIsSubmitted_ThenItIsTrimmed',
      (tester) async {
        final (_, gateway) = await openDialog(tester);

        await enter(tester, '  Blue.flac  ');
        await rename(tester);

        expect(gateway.renames.single.name, 'Blue.flac');
      },
    );

    testWidgets(
      'GivenADeletedRecord_WhenItsDetailsOpen_ThenRenamingIsNotOffered',
      (tester) async {
        await openDialog(tester, details: aTrack(isDeleted: true));

        expect(find.byIcon(Icons.drive_file_rename_outline), findsNothing);
      },
    );
  });

  // AF-01: the name is empty or holds a forbidden character.
  group('a name the dialog refuses', () {
    testWidgets('GivenAnEmptyName_WhenItIsSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);

      await enter(tester, '');
      await rename(tester);

      expect(gateway.renames, isEmpty);
      expect(find.text(messages(tester).renameErrorEmpty), findsOneWidget);
    });

    testWidgets('GivenASeparator_WhenItIsSubmitted_ThenTheFieldIsMarked', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);

      await enter(tester, 'folder/Blue.flac');
      await rename(tester);

      expect(gateway.renames, isEmpty);
      expect(find.text(messages(tester).renameErrorForbidden), findsOneWidget);
    });

    // The rule is the host's, and this one is running as Windows.
    testWidgets('GivenAColonOnWindows_WhenItIsSubmitted_ThenTheFieldIsMarked', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(
        tester,
        host: HostFileSystem.windows,
      );

      await enter(tester, 'Blue: the album.flac');
      await rename(tester);

      expect(gateway.renames, isEmpty);
      expect(find.text(messages(tester).renameErrorForbidden), findsOneWidget);
    });

    testWidgets('GivenAColonOnLinux_WhenItIsSubmitted_ThenItIsSent', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);

      await enter(tester, 'Blue: the album.flac');
      await rename(tester);

      expect(gateway.renames, hasLength(1));
    });

    testWidgets('GivenAMarkedField_WhenItIsEditedAgain_ThenTheMarkIsDropped', (
      tester,
    ) async {
      await openDialog(tester);

      await enter(tester, '');
      await rename(tester);
      await enter(tester, 'Blue.flac');

      expect(find.text(messages(tester).renameErrorEmpty), findsNothing);
    });
  });

  // AF-02: the core reports a disk failure.
  group('a rename the disk refused', () {
    const diskFailure = FileRenameOutcome.failed(
      failure: Failure.disk(family: CoreStatusFamily.file, code: FILE_ERR_DISK),
    );

    testWidgets('GivenADiskFailure_WhenItIsReported_ThenTheDialogStaysOpen', (
      tester,
    ) async {
      await openDialog(tester, outcomes: const [diskFailure]);

      await enter(tester, 'Blue.flac');
      await rename(tester);

      expect(find.byType(RenameFileDialog), findsOneWidget);
    });

    testWidgets(
      'GivenADiskFailure_WhenItIsReported_ThenNothingChangedIsStated',
      (tester) async {
        await openDialog(tester, outcomes: const [diskFailure]);

        await enter(tester, 'Blue.flac');
        await rename(tester);

        expect(
          find.text(messages(tester).renameNothingChanged),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenADiskFailure_WhenTheOwnerRetries_ThenItIsSentAgain', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(
        tester,
        outcomes: const [diskFailure],
      );

      await enter(tester, 'Blue.flac');
      await rename(tester);
      await rename(tester);

      expect(gateway.renames, hasLength(2));
      expect(find.byType(RenameFileDialog), findsNothing);
    });
  });

  // AF-03: the core reports the file as not found.
  group('a file the core no longer has', () {
    const gone = FileRenameOutcome.failed(
      failure: Failure.notFound(
        family: CoreStatusFamily.file,
        code: FILE_ERR_NOT_FOUND,
      ),
    );

    testWidgets('GivenTheRecordIsGone_WhenItIsRenamed_ThenTheDialogCloses', (
      tester,
    ) async {
      await openDialog(tester, outcomes: const [gone]);

      await enter(tester, 'Blue.flac');
      await rename(tester);

      expect(find.byType(RenameFileDialog), findsNothing);
    });

    testWidgets('GivenTheRecordIsGone_WhenItIsRenamed_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openDialog(tester, outcomes: const [gone]);

      await enter(tester, 'Blue.flac');
      await rename(tester);

      expect(find.text(messages(tester).detailsNotFound), findsOneWidget);
    });
  });

  // AF-04: the new name equals the current one.
  group('a name that did not change', () {
    testWidgets('GivenTheSameName_WhenItIsSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, gateway) = await openDialog(tester);

      await rename(tester);

      expect(gateway.renames, isEmpty);
    });

    testWidgets('GivenTheSameName_WhenItIsSubmitted_ThenTheDialogCloses', (
      tester,
    ) async {
      await openDialog(tester);

      await rename(tester);

      expect(find.byType(RenameFileDialog), findsNothing);
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenRenaming_ThenTheOwnerSignsOut',
      (tester) async {
        final (container, _) = await openDialog(
          tester,
          outcomes: const [
            FileRenameOutcome.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: FILE_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );

        await enter(tester, 'Blue.flac');
        await rename(tester);

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheDialogOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openDialog(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(RenameFileDialog))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheDialogOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openDialog(
            tester,
            locale: locale,
            outcomes: const [
              FileRenameOutcome.failed(
                failure: Failure.disk(
                  family: CoreStatusFamily.file,
                  code: FILE_ERR_DISK,
                ),
              ),
            ],
          );

          await enter(tester, 'Blue.flac');
          await rename(tester);

          expect(
            find.textContaining('rename', findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
