import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_lifecycle_gateway.dart';
import '../../../support/shell_harness.dart';

/// One file's details (UC-13, FR-CT-05).
void main() {
  const uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f';

  /// Signs in, opens a listing, and taps the file.
  Future<ProviderContainer> openDetails(
    WidgetTester tester, {
    FileDetailsOutcome? outcome,
    Locale? locale,
    bool tapRow = true,
    FakeLifecycleGateway? lifecycle,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    // Filed under video rather than music: UC-46 gave audio its own browsing
    // area, and this suite is about the details dialog in general, reached
    // the way every other type reaches it — through the generic listing.
    // `aFile()` defaults to audio and nothing in this file depends on that;
    // typed explicitly as video so the fixture matches the listing it sits
    // in.
    final gateway = FakeCatalogGateway(
      listings: {
        FileType.video: loadedDetails([
          aFile(uuid: uuid, type: FileType.video),
        ]),
      },
    );
    if (outcome != null) gateway.details[uuid] = outcome;

    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(gateway),
        if (lifecycle != null)
          lifecycleGatewayProvider.overrideWithValue(lifecycle),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.videos.icon),
      ),
    );
    await tester.pumpAndSettle();

    if (tapRow) {
      await tester.tap(find.text('Kind of Blue.flac'));
      await tester.pumpAndSettle();
    }

    return container;
  }

  /// Opens the details for a fixture file carrying [name], [sizeBytes] and
  /// [mtime], for the tests about the file's own facts rather than about the
  /// flow.
  Future<void> openDetailsFor(
    WidgetTester tester, {
    required String name,
    int? sizeBytes,
    DateTime? mtime,
  }) => openDetails(
    tester,
    outcome: FileDetailsOutcome.read(
      details: FileDetails(
        file: aFile(
          uuid: uuid,
          type: FileType.video,
          name: name,
          sizeBytes: sizeBytes,
          mtime: mtime,
        ),
      ),
    ),
  );

  /// The localizations the dialog itself reads from.
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    testWidgets('GivenAListing_WhenARowIsTapped_ThenTheDetailsOpen', (
      tester,
    ) async {
      await openDetails(tester);

      expect(find.byType(FileDetailsView), findsOneWidget);
    });

    testWidgets('GivenTheDetails_WhenTheyOpen_ThenTheCoreIsAskedByUuid', (
      tester,
    ) async {
      final container = await openDetails(tester);

      // Asked afresh rather than shown from the listing's copy: the record the
      // owner clicked is not necessarily what the core holds now.
      expect(container.read(openFileProvider), uuid);
    });

    testWidgets('GivenTheDetails_WhenTheyOpen_ThenPathStateAndMetadataShow', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
            metadata: const {'artist': 'Miles Davis'},
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsPath), findsOneWidget);
      expect(find.text(l10n.detailsState), findsOneWidget);
      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text(l10n.detailsStateActive), findsOneWidget);
    });

    testWidgets('GivenExtractedValues_WhenTheyExist_ThenTheyAreShown', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
            durationSeconds: 545,
          ),
        ),
      );

      // 9 minutes 5 seconds, read the same way in both languages.
      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('GivenNoMetadata_WhenTheDetailsOpen_ThenItSaysSo', (
      tester,
    ) async {
      // Text and HTML files have none, and a file whose metadata has not been
      // written has none either.
      await openDetails(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsMetadataNone), findsOneWidget);
    });
  });

  group('no viewer is registered (AF-04)', () {
    testWidgets('GivenNoViewer_WhenTheDetailsOpen_ThenTheDetailsStillShow', (
      tester,
    ) async {
      // True of every type today: the viewers are M-07's. The details are
      // presented and the limitation is stated rather than an action offered
      // that would do nothing.
      await openDetails(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsNoViewer), findsOneWidget);
      expect(find.text(l10n.detailsPath), findsOneWidget);
    });
  });

  group('the record is deleted (AF-02)', () {
    testWidgets('GivenADeletedRecord_WhenTheDetailsOpen_ThenItShowsAsDeleted', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
            isDeleted: true,
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsStateDeleted), findsOneWidget);
      expect(find.text(l10n.detailsDeletedHint), findsOneWidget);
    });

    testWidgets('GivenADeletedRecord_WhenTheDetailsOpen_ThenRestoreIsOffered', (
      tester,
    ) async {
      // AF-02: "offers restore (UC-34) instead of editing" — the offer is the
      // action, not a sentence about one.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
            isDeleted: true,
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.restoreRecord), findsOneWidget);
    });

    testWidgets(
      'GivenADeletedRecord_WhenRestoreIsTaken_ThenTheCoreRestoresIt',
      (tester) async {
        final lifecycle = FakeLifecycleGateway();
        await openDetails(
          tester,
          outcome: FileDetailsOutcome.read(
            details: FileDetails(
              file: aFile(uuid: uuid, type: FileType.video),
              isDeleted: true,
            ),
          ),
          lifecycle: lifecycle,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        await tester.tap(find.text(l10n.restoreRecord));
        await tester.pumpAndSettle();

        expect(lifecycle.restored, [uuid]);
      },
    );

    testWidgets(
      'GivenADeletedRecord_WhenTheDetailsOpen_ThenEditingIsNotOffered',
      (tester) async {
        // AF-02 again: restore is offered *instead of* editing.
        await openDetails(
          tester,
          outcome: FileDetailsOutcome.read(
            details: FileDetails(
              file: aFile(uuid: uuid, type: FileType.video),
              isDeleted: true,
            ),
          ),
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(find.text(l10n.renameOpen), findsNothing);
        expect(find.text(l10n.detailsEditMetadata), findsNothing);
      },
    );
  });

  group('how the actions are laid out', () {
    testWidgets('GivenSeveralActions_WhenTheDetailsOpen_ThenTheyShareRows', (
      tester,
    ) async {
      // They were one full-width button per row inside a 520-wide dialog, so
      // a video's actions ran well past the bottom of it and the owner
      // scrolled a column of buttons to reach Play.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      final play = tester.getCenter(find.text(l10n.videoPlay));
      final metadata = tester.getCenter(find.text(l10n.detailsEditMetadata));

      // Side by side on the first row of the group rather than one per row.
      expect(play.dy, equals(metadata.dy));
      expect(metadata.dx, greaterThan(play.dx));
    });

    testWidgets('GivenAnyFile_WhenTheDetailsOpen_ThenPurgeStaysBelowTheRest', (
      tester,
    ) async {
      // FR-LC-06: never a default action, never one interaction from a row.
      // Grouping the ordinary actions must not pull it up among them.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.video),
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      final rename = tester.getCenter(find.text(l10n.renameOpen));
      final purge = tester.getCenter(find.text(l10n.purgeOnDiskTitle));

      expect(purge.dy, greaterThan(rename.dy));
    });
  });

  group('the actions a missing file cannot support (AF-03)', () {
    /// The details of a missing video, which is the type with the most
    /// file-reading actions on it.
    Future<void> openMissingVideo(WidgetTester tester) => openDetails(
      tester,
      outcome: FileDetailsOutcome.read(
        details: FileDetails(
          file: aFile(
            uuid: uuid,
            type: FileType.video,
            missingAt: DateTime.utc(2026, 8, 19),
          ),
        ),
      ),
    );

    /// Whether the button labelled [label] is enabled.
    ///
    /// A predicate rather than `find.byType`, because the `.icon` constructors
    /// build private subclasses and `byType` matches the exact runtime type.
    bool isEnabled(WidgetTester tester, String label) {
      final button =
          tester
                  .widgetList<Widget>(
                    find.ancestor(
                      of: find.text(label),
                      matching: find.byWidgetPredicate(
                        (w) => w is ButtonStyleButton,
                      ),
                    ),
                  )
                  .first
              as ButtonStyleButton;

      return button.onPressed != null;
    }

    testWidgets('GivenAMissingVideo_WhenTheDetailsOpen_ThenPlayIsDisabled', (
      tester,
    ) async {
      // AF-03: "disables the actions that need the file". Playing needs it.
      await openMissingVideo(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(isEnabled(tester, l10n.videoPlay), isFalse);
    });

    testWidgets('GivenAMissingFile_WhenTheDetailsOpen_ThenRenameIsDisabled', (
      tester,
    ) async {
      // UC-17 renames the file on disk, so it needs the file.
      await openMissingVideo(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(isEnabled(tester, l10n.renameOpen), isFalse);
    });

    testWidgets('GivenAPresentFile_WhenTheDetailsOpen_ThenRenameIsEnabled', (
      tester,
    ) async {
      // The other half of the rule: nothing is disabled for a file that is
      // where the catalog says it is.
      await openDetails(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(isEnabled(tester, l10n.renameOpen), isTrue);
    });
  });

  group('the file is missing on disk (AF-03)', () {
    testWidgets('GivenAMissingFile_WhenTheDetailsOpen_ThenARescanIsOffered', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(
              uuid: uuid,
              type: FileType.video,
              missingAt: DateTime.utc(2026, 8, 19),
            ),
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsStateMissing), findsOneWidget);
      // The re-scan is UC-07's refresh, which does exist.
      expect(find.text(l10n.detailsRescan), findsOneWidget);
    });

    testWidgets('GivenADeletedRecord_WhenItIsAlsoMissing_ThenDeletedWins', (
      tester,
    ) async {
      // Both are true of a record deleted after its file vanished; the owner
      // needs the one that explains why it is not in the library.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(
              uuid: uuid,
              type: FileType.video,
              missingAt: DateTime.utc(2026, 8, 19),
            ),
            isDeleted: true,
          ),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.detailsStateDeleted), findsOneWidget);
      expect(find.text(l10n.detailsRescan), findsNothing);
    });
  });

  group('the core cannot answer', () {
    testWidgets('GivenTheCoreFails_WhenTheDetailsOpen_ThenAMessageAndRetry', (
      tester,
    ) async {
      // AF-01 arrives as this failure; the message and retry are the shell's.
      await openDetails(
        tester,
        outcome: const FileDetailsOutcome.failed(
          failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
        ),
      );

      expect(find.byType(ShellFailureView), findsOneWidget);
    });

    testWidgets('GivenTheCoreRejectsTheSession_WhenTheyOpen_ThenLoginReturns', (
      tester,
    ) async {
      // AF-05.
      await openDetails(
        tester,
        outcome: const FileDetailsOutcome.failed(
          failure: Failure.unauthorized(family: CoreStatusFamily.file, code: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheDetailsOpen_ThenTheyAreLocalized', (
      tester,
    ) async {
      await openDetails(tester, locale: locale);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      for (final label in [
        l10n.detailsTitle,
        l10n.detailsPath,
        l10n.detailsState,
      ]) {
        expect(label, isNot(startsWith('details')));
        expect(find.text(label), findsWidgets);
      }
    });
  }
  group('the file itself (FR-CT-05)', () {
    testWidgets(
      'GivenAFile_WhenItsDetailsOpen_ThenItsNameSizeAndFormatAreShown',
      (tester) async {
        // The one place the name on disk belongs, under a label saying that is
        // what it is — FR-CT-13 keeps it out of the music area, not out of the
        // record of what the file is.
        await openDetailsFor(
          tester,
          name: 'DISKNAME-01.flac',
          sizeBytes: 4922880,
        );
        final l10n = localizations(tester);

        expect(find.text(l10n.detailsFileName), findsOneWidget);
        // Once, under its label — not also as an unlabelled heading above
        // it, which the labelled row made a duplicate of.
        expect(find.text('DISKNAME-01.flac'), findsOneWidget);
        expect(find.text('4.7 MB'), findsOneWidget);
        expect(find.text('FLAC'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAFileWithNoRecordedSize_WhenItsDetailsOpen_ThenNoSizeRowIsShown',
      (tester) async {
        // A core that answered without a size has not told us the file is
        // empty, and a row reading "0 B" would say it had.
        await openDetailsFor(tester, name: 'DISKNAME-01.flac', sizeBytes: null);
        final l10n = localizations(tester);

        expect(find.text(l10n.detailsFileSize), findsNothing);
      },
    );

    testWidgets(
      'GivenAFileWithNoRecordedModificationTime_WhenItsDetailsOpen_ThenNoModifiedRowIsShown',
      (tester) async {
        // The same rule as the size row: a core that answered without an
        // mtime has not told us when the file changed, and showing an epoch
        // date would say it had.
        await openDetailsFor(tester, name: 'DISKNAME-01.flac', mtime: null);
        final l10n = localizations(tester);

        expect(find.text(l10n.detailsFileModified), findsNothing);
      },
    );
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
  group('adding a track to a playlist', () {
    // The music area is a type panel, so it lists no library's audio. Without
    // this control a track inside a library could reach a playlist only by
    // being played first — while a video or a book in the same folder can be
    // tracked from this very view.
    testWidgets('GivenAnAudioFile_WhenItsDetailsOpen_ThenItCanJoinAPlaylist', (
      tester,
    ) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.audio),
            libraryUuid: 'lib-1',
          ),
        ),
      );

      expect(
        find.byTooltip(localizations(tester).playlistAddTo),
        findsOneWidget,
      );
    });

    testWidgets('GivenAVideo_WhenItsDetailsOpen_ThenNoPlaylistActionIsOffered', (
      tester,
    ) async {
      // Offered for its own type and nothing else, like the two tracking
      // controls beside it: a playlist holds audio.
      //
      // The outcome is spelled out because the fake gateway answers
      // `aFile(uuid)` when a test does not, and that helper defaults to
      // audio — so `openDetails(tester)` alone would show an audio dialog
      // and pass this for the wrong reason.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(file: aFile(uuid: uuid, type: FileType.video)),
        ),
      );

      expect(find.byTooltip(localizations(tester).playlistAddTo), findsNothing);
    });

    testWidgets('GivenADeletedTrack_WhenItsDetailsOpen_ThenItCannotJoinOne', (
      tester,
    ) async {
      // A deleted record is not a track to queue; the same rule the tracking
      // controls and the delete action already follow.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, type: FileType.audio, isDeleted: true),
            isDeleted: true,
          ),
        ),
      );

      expect(find.byTooltip(localizations(tester).playlistAddTo), findsNothing);
    });
  });

}
