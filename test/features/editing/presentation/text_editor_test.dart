import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/editing/domain/text_content_gateway.dart';
import 'package:alexandria_ui/features/editing/presentation/text_editor_screen.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_text_content_gateway.dart';
import '../../../support/shell_harness.dart';

/// Editing a Markdown or text file (UC-18, FR-ME-06 … FR-ME-10).
void main() {
  const uuid = '4c2b9e10-7d3a-4b62-8e15-2f6a9c0d3b41';
  const originalContent = '# Notes\n\nSomething.';

  // No content hash, which is what indexing leaves on a file nobody has
  // edited: what says whether it changed on disk is its size and mtime.
  FileDetails aNote({int sizeBytes = 120, bool isDeleted = false}) =>
      FileDetails(
        file: aFile(
          uuid: uuid,
          name: 'Notes.md',
          type: LibraryType.text,
          contentHash: '',
          sizeBytes: sizeBytes,
          mtime: DateTime.utc(2026, 8, 23, 9),
        ),
        metadata: const {},
        isDeleted: isDeleted,
      );

  /// Signs in, opens the notes listing, and opens the editor on the one file
  /// in it.
  Future<(ProviderContainer, FakeTextContentGateway, FakeCatalogGateway)>
  openEditor(
    WidgetTester tester, {
    FileDetails? details,
    List<TextContentWrite> writeOutcomes = const [],
    List<TextContentRead> readOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1440, 1000),
    bool openIt = true,
  }) async {
    final loaded = details ?? aNote();
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.text: CatalogListing.loaded(files: [loaded.file]),
      },
    );
    catalog.details[uuid] = FileDetailsOutcome.read(details: loaded);

    final content = FakeTextContentGateway()
      ..writeOutcomes.addAll(writeOutcomes)
      ..readOutcomes.addAll(readOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: surfaceSize,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        textContentGatewayProvider.overrideWithValue(content),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.notes.icon),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes.md').first);
    await tester.pumpAndSettle();

    if (openIt && !loaded.isDeleted) {
      await tester.tap(find.byIcon(Icons.edit_note_outlined));
      await tester.pumpAndSettle();
    }

    return (container, content, catalog);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// The editor's own field. Scoped, because the shell behind the full-screen
  /// dialog still holds the catalog search.
  final editorField = find.descendant(
    of: find.byType(TextEditorScreen),
    matching: find.byType(TextField),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(TextEditorScreen),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, messages(tester).editorSave).first,
    );
    await tester.pumpAndSettle();
  }

  group('saving from the keyboard (FR-UX-11)', () {
    testWidgets('GivenEditedContent_WhenControlSIsPressed_ThenItIsWritten', (
      tester,
    ) async {
      // Save is the editor's primary action, and the owner's hands are on the
      // keyboard: reaching it meant tabbing out of the field they were typing
      // in.
      final (_, content, _) = await openEditor(tester);
      await type(tester, 'edited');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(content.writes.map((write) => write.content), ['edited']);
    });

    testWidgets(
      'GivenUnchangedContent_WhenControlSIsPressed_ThenNothingIsWritten',
      (tester) async {
        // AF-01 holds for the shortcut exactly as it holds for the button.
        final (_, content, _) = await openEditor(tester);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(content.writes, isEmpty);
      },
    );
  });

  group('the main flow', () {
    testWidgets('GivenATextFile_WhenItsDetailsOpen_ThenEditingIsOffered', (
      tester,
    ) async {
      await openEditor(tester, openIt: false);

      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    });

    testWidgets('GivenAnAudioFile_WhenItsDetailsOpen_ThenEditingIsNotOffered', (
      tester,
    ) async {
      // BR-06 and BR-09: this application writes text content, not media.
      // Filed under video rather than music: UC-46 gave audio its own
      // browsing area with no path to the details dialog, but the file
      // itself is still typed audio, which is what this test needs.
      final catalog = FakeCatalogGateway(
        listings: {
          LibraryType.video: CatalogListing.loaded(files: [aFile()]),
        },
      );

      await tester.pumpShell(
        surfaceSize: const Size(1440, 1000),
        extraOverrides: <Override>[
          catalogGatewayProvider.overrideWithValue(catalog),
        ],
      );
      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.videos.icon),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kind of Blue.flac').first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note_outlined), findsNothing);
    });

    // Step 2: the content comes through the core (FR-ME-06).
    testWidgets(
      'GivenTheEditorOpens_WhenItLoads_ThenTheContentIsReadThroughTheCore',
      (tester) async {
        final (_, content, _) = await openEditor(tester);

        expect(content.reads, [uuid]);
        expect(
          find.descendant(
            of: find.byType(TextEditorScreen),
            matching: find.text(originalContent),
          ),
          findsWidgets,
        );
      },
    );

    // Step 3: the source alongside a rendered preview (FR-ME-07).
    testWidgets(
      'GivenTheEditorIsOpen_WhenItIsShown_ThenThePreviewIsBesideTheSource',
      (tester) async {
        await openEditor(tester);

        expect(editorField, findsOneWidget);
        expect(find.byType(Markdown), findsOneWidget);
      },
    );

    // Step 4: the preview follows as they type.
    testWidgets(
      'GivenTheOwnerTypes_WhenTheContentChanges_ThenThePreviewFollows',
      (tester) async {
        await openEditor(tester);

        await type(tester, '# Changed');

        expect(
          tester.widget<Markdown>(find.byType(Markdown)).data,
          '# Changed',
        );
      },
    );

    testWidgets('GivenAnEdit_WhenItIsSaved_ThenItGoesThroughTheCore', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(tester);

      await type(tester, '# Changed');
      await save(tester);

      expect(content.writes, hasLength(1));
      expect(content.writes.single.content, '# Changed');
      expect(content.writes.single.uuid, uuid);
    });

    testWidgets('GivenASavedEdit_WhenTheCoreWritesIt_ThenNothingIsUnsaved', (
      tester,
    ) async {
      final (container, _, _) = await openEditor(tester);

      await type(tester, '# Changed');
      await save(tester);

      expect(container.read(textEditorControllerProvider).isDirty, isFalse);
      expect(find.text(messages(tester).editorUnsaved), findsNothing);
    });

    testWidgets('GivenAnEdit_WhenItIsUnsaved_ThenTheEditorSaysSo', (
      tester,
    ) async {
      await openEditor(tester);

      await type(tester, '# Changed');

      expect(find.text(messages(tester).editorUnsaved), findsOneWidget);
    });

    testWidgets('GivenACleanEditor_WhenItIsClosed_ThenItClosesWithoutAsking', (
      tester,
    ) async {
      await openEditor(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(TextEditorScreen), findsNothing);
    });
  });

  // AF-01: the content is unchanged.
  group('nothing to save', () {
    testWidgets('GivenUnchangedContent_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(tester);

      await save(tester);

      expect(content.writes, isEmpty);
    });

    testWidgets('GivenUnchangedContent_WhenSaved_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openEditor(tester);

      await save(tester);

      expect(find.text(messages(tester).editorNothingToSave), findsOneWidget);
    });

    // Typing and undoing is not a change either.
    testWidgets('GivenAnEditThatWasUndone_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(tester);

      await type(tester, '# Changed');
      await type(tester, originalContent);
      await save(tester);

      expect(content.writes, isEmpty);
    });
  });

  // AF-02: leaving with unsaved changes.
  group('leaving with unsaved changes', () {
    testWidgets('GivenUnsavedChanges_WhenTheEditorIsClosed_ThenItAsksFirst', (
      tester,
    ) async {
      await openEditor(tester);

      await type(tester, '# Changed');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(TextEditorScreen), findsOneWidget);
      expect(find.text(messages(tester).editorLeaveUnsaved), findsOneWidget);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerCancels_ThenTheEditorStaysOpen', (
      tester,
    ) async {
      await openEditor(tester);

      await type(tester, '# Changed');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).cancel));
      await tester.pumpAndSettle();

      expect(find.byType(TextEditorScreen), findsOneWidget);
      expect(find.text(messages(tester).editorLeaveUnsaved), findsNothing);
    });

    testWidgets(
      'GivenTheWarning_WhenTheOwnerDiscards_ThenTheEditorClosesUnsaved',
      (tester) async {
        final (_, content, _) = await openEditor(tester);

        await type(tester, '# Changed');
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        await tester.tap(find.text(messages(tester).editorDiscard));
        await tester.pumpAndSettle();

        expect(find.byType(TextEditorScreen), findsNothing);
        expect(content.writes, isEmpty);
      },
    );

    testWidgets('GivenTheWarning_WhenTheOwnerSaves_ThenItIsWrittenAndClosed', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(tester);

      await type(tester, '# Changed');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).editorSaveAndClose));
      await tester.pumpAndSettle();

      expect(content.writes.single.content, '# Changed');
      expect(find.byType(TextEditorScreen), findsNothing);
    });
  });

  // AF-03 and FR-ME-10: a disk failure on write.
  group('a write the disk refused', () {
    const diskFailure = TextContentWrite.failed(
      failure: Failure.disk(family: CoreStatusFamily.file, code: FILE_ERR_DISK),
    );

    testWidgets(
      'GivenADiskFailure_WhenItIsReported_ThenTheContentIsUntouched',
      (tester) async {
        final (container, _, _) = await openEditor(
          tester,
          writeOutcomes: const [diskFailure],
        );

        await type(tester, '# Changed');
        await save(tester);

        expect(
          container.read(textEditorControllerProvider).content,
          '# Changed',
        );
        expect(
          tester.widget<Markdown>(find.byType(Markdown)).data,
          '# Changed',
        );
      },
    );

    testWidgets('GivenADiskFailure_WhenItIsReported_ThenItIsStillUnsaved', (
      tester,
    ) async {
      final (container, _, _) = await openEditor(
        tester,
        writeOutcomes: const [diskFailure],
      );

      await type(tester, '# Changed');
      await save(tester);

      expect(container.read(textEditorControllerProvider).isDirty, isTrue);
      expect(find.text(messages(tester).editorUnsaved), findsOneWidget);
    });

    testWidgets('GivenADiskFailure_WhenTheOwnerRetries_ThenItIsWritten', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(
        tester,
        writeOutcomes: const [diskFailure],
      );

      await type(tester, '# Changed');
      await save(tester);
      await save(tester);

      expect(content.writes, hasLength(2));
    });
  });

  // AF-04: the core reports the file as not found.
  group('a record the core no longer has', () {
    const gone = TextContentWrite.failed(
      failure: Failure.notFound(
        family: CoreStatusFamily.file,
        code: FILE_ERR_NOT_FOUND,
      ),
    );

    testWidgets('GivenTheRecordIsGone_WhenSaving_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openEditor(tester, writeOutcomes: const [gone]);

      await type(tester, '# Changed');
      await save(tester);

      expect(find.text(messages(tester).editorRecordGone), findsOneWidget);
    });

    // Nothing typed is lost silently.
    testWidgets('GivenTheRecordIsGone_WhenSaving_ThenTheContentStaysOnScreen', (
      tester,
    ) async {
      final (container, _, _) = await openEditor(
        tester,
        writeOutcomes: const [gone],
      );

      await type(tester, '# Changed');
      await save(tester);

      expect(find.byType(TextEditorScreen), findsOneWidget);
      expect(container.read(textEditorControllerProvider).content, '# Changed');
    });

    testWidgets(
      'GivenTheMessage_WhenItIsDismissed_ThenTheContentIsStillThere',
      (tester) async {
        final (container, _, _) = await openEditor(
          tester,
          writeOutcomes: const [gone],
        );

        await type(tester, '# Changed');
        await save(tester);
        await tester.tap(find.text(messages(tester).editorDismiss));
        await tester.pumpAndSettle();

        expect(
          container.read(textEditorControllerProvider).content,
          '# Changed',
        );
        expect(find.byType(TextEditorScreen), findsOneWidget);
      },
    );
  });

  // AF-05: the file changed on disk since it was loaded.
  group('a file that changed underneath', () {
    /// Opens the editor, then has the catalog report a different size — which
    /// is what somebody else writing the file looks like from here.
    Future<(ProviderContainer, FakeTextContentGateway)> withDiskChange(
      WidgetTester tester,
    ) async {
      final (container, content, catalog) = await openEditor(tester);

      catalog.details[uuid] = FileDetailsOutcome.read(
        details: aNote(sizeBytes: 340),
      );

      return (container, content);
    }

    testWidgets('GivenTheFileChangedOnDisk_WhenSaving_ThenTheOwnerIsWarned', (
      tester,
    ) async {
      await withDiskChange(tester);

      await type(tester, '# Mine');
      await save(tester);

      expect(find.text(messages(tester).editorChangedOnDisk), findsOneWidget);
    });

    testWidgets('GivenTheWarning_WhenItIsShown_ThenNothingWasWritten', (
      tester,
    ) async {
      final (_, content) = await withDiskChange(tester);

      await type(tester, '# Mine');
      await save(tester);

      expect(content.writes, isEmpty);
    });

    testWidgets(
      'GivenTheWarning_WhenTheOwnerOverwrites_ThenTheirContentIsWritten',
      (tester) async {
        final (_, content) = await withDiskChange(tester);

        await type(tester, '# Mine');
        await save(tester);
        await tester.tap(find.text(messages(tester).editorOverwrite));
        await tester.pumpAndSettle();

        expect(content.writes.single.content, '# Mine');
      },
    );

    testWidgets(
      'GivenTheWarning_WhenTheOwnerReloads_ThenTheDisksContentIsShown',
      (tester) async {
        final (container, content) = await withDiskChange(tester);
        content.content = '# Theirs';

        await type(tester, '# Mine');
        await save(tester);
        await tester.tap(find.text(messages(tester).editorReload));
        await tester.pumpAndSettle();

        expect(
          container.read(textEditorControllerProvider).content,
          '# Theirs',
        );
        expect(container.read(textEditorControllerProvider).isDirty, isFalse);
      },
    );

    // An unchanged stamp is not a conflict, so nothing stands in the way.
    testWidgets('GivenTheFileIsUntouched_WhenSaving_ThenNoWarningIsShown', (
      tester,
    ) async {
      final (_, content, _) = await openEditor(tester);

      await type(tester, '# Mine');
      await save(tester);

      expect(content.writes, hasLength(1));
    });
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    const rejected = TextContentWrite.failed(
      failure: Failure.unauthorized(
        family: CoreStatusFamily.file,
        code: FILE_ERR_UNAUTHORIZED,
      ),
    );

    testWidgets(
      'GivenTheSessionIsRejected_WhenSaving_ThenTheOwnerIsWarnedFirst',
      (tester) async {
        final (container, _, _) = await openEditor(
          tester,
          writeOutcomes: const [rejected],
        );

        await type(tester, '# Changed');
        await save(tester);

        expect(
          find.text(messages(tester).editorSessionRejected),
          findsOneWidget,
        );
        // Still signed in: the warning comes before the session goes.
        expect(container.read(sessionControllerProvider), isA<SessionActive>());
      },
    );

    testWidgets(
      'GivenTheWarning_WhenItIsAcknowledged_ThenTheOwnerReturnsToLogin',
      (tester) async {
        final (container, _, _) = await openEditor(
          tester,
          writeOutcomes: const [rejected],
        );

        await type(tester, '# Changed');
        await save(tester);
        await tester.tap(find.text(messages(tester).editorSignInAgain));
        await tester.pumpAndSettle();

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  // The editor is what UC-03's registry was built for.
  group('signing out with the editor open', () {
    testWidgets('GivenUnsavedChanges_WhenSigningOut_ThenTheyAreReported', (
      tester,
    ) async {
      final (container, _, _) = await openEditor(tester);

      await type(tester, '# Changed');

      expect(
        container.read(signOutControllerProvider).holdsUnsavedChanges,
        isTrue,
      );
    });

    testWidgets('GivenACleanEditor_WhenSigningOut_ThenNothingIsReported', (
      tester,
    ) async {
      final (container, _, _) = await openEditor(tester);

      expect(
        container.read(signOutControllerProvider).holdsUnsavedChanges,
        isFalse,
      );
    });
  });

  group('the content could not be read', () {
    testWidgets('GivenTheCoreRefusesTheRead_WhenTheEditorOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openEditor(
        tester,
        readOutcomes: const [
          TextContentRead.failed(
            failure: Failure.disk(
              family: CoreStatusFamily.file,
              code: FILE_ERR_DISK,
            ),
          ),
        ],
      );

      expect(find.text(messages(tester).editorCouldNotRead), findsOneWidget);
      expect(editorField, findsNothing);
    });
  });

  group('breakpoints, themes, and languages', () {
    // FR-UX-02: the preview is not dropped at the narrow tier, it moves below.
    testWidgets('GivenACompactWindow_WhenTheEditorOpens_ThenBothPanesRemain', (
      tester,
    ) async {
      await openEditor(tester, surfaceSize: const Size(700, 800));

      expect(editorField, findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);
    });

    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheEditorOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openEditor(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(TextEditorScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheEditorOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openEditor(tester, locale: locale);

          await type(tester, '# Changed');
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();

          // A key renders as its own camelCase name; an English sentence
          // that happens to contain the word "editor" does not.
          expect(
            find.textContaining(RegExp('editor[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
