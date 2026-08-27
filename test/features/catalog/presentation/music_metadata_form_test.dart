import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/presentation/music_metadata_form.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Editing an audio file's music metadata (UC-15, FR-ME-01, FR-ME-03).
void main() {
  /// The details the form opens on: a track with every field filled.
  FileDetails aTrack({bool isDeleted = false}) => FileDetails(
    file: aFile(name: 'Kind of Blue.flac'),
    metadata: const {
      'title': 'So What',
      'artist': 'Miles Davis',
      'album': 'Kind of Blue',
      'year': '1959',
      'genre': 'Jazz',
      'track': '1',
    },
    isDeleted: isDeleted,
  );

  /// Signs in, opens the audio listing, and opens the metadata form on the one
  /// file in it.
  Future<(ProviderContainer, FakeCatalogGateway)> openForm(
    WidgetTester tester, {
    FileDetails? details,
    List<MetadataEditOutcome> outcomes = const [],
    ThemeMode themeMode = ThemeMode.light,
    Locale? locale,
  }) async {
    final loaded = details ?? aTrack();
    final gateway = FakeCatalogGateway(
      listings: {
        LibraryType.audio: CatalogListing.loaded(files: [loaded]),
      },
    );
    gateway.details[loaded.file.uuid] = FileDetailsOutcome.read(
      details: loaded,
    );
    gateway.editOutcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(gateway),
      ],
    );
    await tester.pumpAndSettle();

    // Main flow step 1: the form is opened from the file's detail view,
    // reached from the dashboard's recent list, which names an audio file by
    // its metadata title rather than its file name (FR-CT-13).
    await tester.tap(find.text('So What').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    return (container, gateway);
  }

  /// Types [value] into the field labelled [label], replacing what is there.
  Future<void> enter(WidgetTester tester, String label, String value) async {
    await tester.enterText(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      value,
    );
    await tester.pump();
  }

  group('reaching the form from the keyboard (FR-UX-11)', () {
    testWidgets('GivenTheForm_WhenItOpens_ThenTheFirstFieldHasFocus', (
      tester,
    ) async {
      // The rename dialog and the bookmark form both open with their field
      // focused; this one opened with focus nowhere, so correcting a title
      // began with a click or a tab.
      await openForm(tester);

      // Scoped to the form: the shell's search field sits behind the dialog.
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(MusicMetadataForm),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.autofocus, isTrue);
    });
  });

  group('the main flow', () {
    testWidgets('GivenAnAudioFile_WhenItsDetailsOpen_ThenEditingIsOffered', (
      tester,
    ) async {
      await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(find.text(l10n.musicMetadataTitle), findsOneWidget);
    });

    testWidgets('GivenTheFormOpens_WhenItIsShown_ThenItHoldsTheCurrentValues', (
      tester,
    ) async {
      // Step 2: the current values, not an empty form — the owner is
      // correcting a record, not writing one.
      await openForm(tester);

      // Scoped to the form: the detail view it opened over shows the same
      // values, and finding them there would prove nothing about the form.
      Finder inForm(String text) => find.descendant(
        of: find.byType(MusicMetadataForm),
        matching: find.text(text),
      );

      expect(inForm('So What'), findsOneWidget);
      expect(inForm('Miles Davis'), findsOneWidget);
      expect(inForm('1959'), findsOneWidget);
    });

    testWidgets('GivenAnEdit_WhenSaved_ThenTheWholeRecordGoesToTheCore', (
      tester,
    ) async {
      // Steps 3 through 6. The whole record is sent rather than the one field
      // that changed, because the core's patch is a full replace and anything
      // left out would be cleared.
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldArtist, 'Miles Davis Quintet');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits, hasLength(1));
      expect(
        gateway.edits.single.metadata,
        const MusicMetadata(
          title: 'So What',
          artist: 'Miles Davis Quintet',
          album: 'Kind of Blue',
          year: 1959,
          genre: 'Jazz',
          track: 1,
        ),
      );
    });

    testWidgets('GivenASavedEdit_WhenItSettles_ThenTheFormCloses', (
      tester,
    ) async {
      await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldGenre, 'Modal jazz');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(find.byType(MusicMetadataForm), findsNothing);
    });

    testWidgets('GivenASavedEdit_WhenItSettles_ThenTheViewsReadTheCoreAgain', (
      tester,
    ) async {
      // FR-ME-05, step 7: no manual refresh. The detail view is asked for the
      // record again rather than patched in place.
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      final before = gateway.detailsRequested.length;

      await enter(tester, l10n.musicMetadataFieldGenre, 'Modal jazz');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.detailsRequested.length, greaterThan(before));
    });

    testWidgets('GivenAClearedField_WhenSaved_ThenItIsLeftOutOfThePatch', (
      tester,
    ) async {
      // Clearing a field is emptying it: the patch leaves it out, and the core
      // writes NULL for what a full replace does not carry.
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldGenre, '');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits.single.metadata.genre, isNull);
      expect(
        gateway.edits.single.metadata.toPatch().containsKey('genre'),
        isFalse,
      );
    });
  });

  group('the album artist (UC-46)', () {
    /// A track whose performer is not who the record is by: a guest on a
    /// Miles Davis record. The two tags carry different names on purpose, so
    /// nothing here can pass by reading the wrong one.
    FileDetails aGuestTrack() => FileDetails(
      file: aFile(name: 'Kind of Blue.flac'),
      metadata: const {
        'title': 'So What',
        'artist': 'John Coltrane',
        'albumArtist': 'Miles Davis',
        'album': 'Kind of Blue',
        'year': '1959',
        'genre': 'Jazz',
        'track': '1',
      },
    );

    testWidgets('GivenAnAlbumArtist_WhenTheFormOpens_ThenItShowsTheField', (
      tester,
    ) async {
      await openForm(tester, details: aGuestTrack());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      Finder inForm(String text) => find.descendant(
        of: find.byType(MusicMetadataForm),
        matching: find.text(text),
      );

      expect(inForm(l10n.musicMetadataFieldAlbumArtist), findsOneWidget);
      expect(inForm('Miles Davis'), findsOneWidget);
      // The performer is its own field and keeps its own value.
      expect(inForm('John Coltrane'), findsOneWidget);
    });

    testWidgets('GivenAnEditedAlbumArtist_WhenSaved_ThenTheCoreIsSentIt', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester, details: aGuestTrack());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(
        tester,
        l10n.musicMetadataFieldAlbumArtist,
        'Miles Davis Sextet',
      );
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits.single.metadata.albumArtist, 'Miles Davis Sextet');
      expect(
        gateway.edits.single.metadata.toPatch()['albumArtist'],
        'Miles Davis Sextet',
      );
    });

    testWidgets(
      'GivenABlankedAlbumArtist_WhenSaved_ThenItIsLeftOutOfThePatch',
      (tester) async {
        // Clearing it is emptying it, as it is for every other field: the patch
        // leaves it out and the core writes NULL.
        final (_, gateway) = await openForm(tester, details: aGuestTrack());
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        await enter(tester, l10n.musicMetadataFieldAlbumArtist, '');
        await tester.tap(find.text(l10n.musicMetadataSave));
        await tester.pumpAndSettle();

        expect(gateway.edits.single.metadata.albumArtist, isNull);
        expect(
          gateway.edits.single.metadata.toPatch().containsKey('albumArtist'),
          isFalse,
        );
      },
    );

    testWidgets(
      'GivenOnlyTheTitleEdited_WhenSaved_ThenThePatchStillCarriesIt',
      (tester) async {
        // The erasure this field was added to prevent: the patch is a full
        // replace, so an album artist the body omits is written as NULL and the
        // track silently moves to another group in the Artists list. Asserted
        // on the body itself rather than on the record, because the body is
        // what the core is actually sent.
        final (_, gateway) = await openForm(tester, details: aGuestTrack());
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        await enter(tester, l10n.musicMetadataFieldTitle, 'Blue in Green');
        await tester.tap(find.text(l10n.musicMetadataSave));
        await tester.pumpAndSettle();

        final patch = gateway.edits.single.metadata.toPatch();
        expect(patch['title'], 'Blue in Green');
        expect(patch['albumArtist'], 'Miles Davis');
        expect(patch['artist'], 'John Coltrane');
      },
    );
  });

  group('local validation fails (AF-01)', () {
    testWidgets('GivenAYearThatIsNotANumber_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldYear, 'nineteen');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(find.text(l10n.musicMetadataErrorNotANumber), findsOneWidget);
      expect(gateway.edits, isEmpty);
      // The form stays open on what was typed, so it can be corrected.
      expect(find.byType(MusicMetadataForm), findsOneWidget);
    });

    testWidgets('GivenAMarkedField_WhenItIsEditedAgain_ThenTheMarkClears', (
      tester,
    ) async {
      await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldYear, 'nineteen');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();
      expect(find.text(l10n.musicMetadataErrorNotANumber), findsOneWidget);

      // The mark said this value was wrong, and this is no longer that value.
      await enter(tester, l10n.musicMetadataFieldYear, '1959');

      expect(find.text(l10n.musicMetadataErrorNotANumber), findsNothing);
    });
  });

  group('the core rejects the change (AF-02)', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheFormStaysOpen', (
      tester,
    ) async {
      final (_, gateway) = await openForm(
        tester,
        outcomes: const [
          MetadataEditOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.file,
              code: FILE_ERR_INVALID_INPUT,
            ),
          ),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldTitle, 'So What?');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      // The core's reason is final, the form is still open with what was
      // typed, and nothing else was sent.
      expect(find.byType(MusicMetadataForm), findsOneWidget);
      expect(find.text(l10n.failureInvalidInput), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MusicMetadataForm),
          matching: find.text('So What?'),
        ),
        findsOneWidget,
      );
      expect(gateway.edits, hasLength(1));
    });

    testWidgets('GivenARefusal_WhenTheOwnerCorrectsIt_ThenTheRetryIsSent', (
      tester,
    ) async {
      final (_, gateway) = await openForm(
        tester,
        outcomes: const [
          MetadataEditOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.file,
              code: FILE_ERR_INVALID_INPUT,
            ),
          ),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldTitle, 'So What?');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      // Corrected to something else, not back to what the file held: putting
      // the original back would be AF-04 and would rightly send nothing.
      await enter(tester, l10n.musicMetadataFieldTitle, 'So What (take 1)');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits, hasLength(2));
      expect(find.byType(MusicMetadataForm), findsNothing);
    });
  });

  group('the file is gone (AF-03)', () {
    testWidgets('GivenTheCoreHasNoSuchFile_WhenSaved_ThenTheFormCloses', (
      tester,
    ) async {
      await openForm(
        tester,
        outcomes: const [
          MetadataEditOutcome.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.file,
              code: FILE_ERR_NOT_FOUND,
            ),
          ),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldTitle, 'So What?');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(find.byType(MusicMetadataForm), findsNothing);
      expect(find.text(l10n.detailsNotFound), findsOneWidget);
    });
  });

  group('nothing changed (AF-04)', () {
    testWidgets('GivenNoEdit_WhenSaved_ThenTheCoreIsNotCalled', (tester) async {
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits, isEmpty);
      expect(find.byType(MusicMetadataForm), findsNothing);
    });

    testWidgets('GivenAnEditUndone_WhenSaved_ThenTheCoreIsStillNotCalled', (
      tester,
    ) async {
      // Typing into a field and putting it back is not a change. The
      // comparison is against what the file held, not against whether a key
      // was touched.
      final (_, gateway) = await openForm(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      await enter(tester, l10n.musicMetadataFieldTitle, 'So What?');
      await enter(tester, l10n.musicMetadataFieldTitle, 'So What');
      await tester.tap(find.text(l10n.musicMetadataSave));
      await tester.pumpAndSettle();

      expect(gateway.edits, isEmpty);
    });
  });

  group('the session is rejected (AF-05)', () {
    testWidgets(
      'GivenAnUnauthorizedCall_WhenSaved_ThenTheOwnerReturnsToLogin',
      (tester) async {
        final (container, _) = await openForm(
          tester,
          outcomes: const [
            MetadataEditOutcome.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: FILE_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        await enter(tester, l10n.musicMetadataFieldTitle, 'So What?');
        await tester.tap(find.text(l10n.musicMetadataSave));
        await tester.pumpAndSettle();

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('the form is offered only where it applies', () {
    testWidgets(
      'GivenADeletedRecord_WhenItsDetailsOpen_ThenEditingIsNotOffered',
      (tester) async {
        // The core refuses to edit a soft-deleted record until it is restored,
        // so the action is not offered rather than offered and refused.
        final deleted = aTrack(isDeleted: true);
        final gateway = FakeCatalogGateway(
          listings: {
            LibraryType.audio: CatalogListing.loaded(files: [deleted]),
          },
        );
        gateway.details[deleted.file.uuid] = FileDetailsOutcome.read(
          details: deleted,
        );

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(gateway),
          ],
        );
        await tester.pumpAndSettle();
        // Named by its metadata title on the dashboard, not its file name
        // (FR-CT-13).
        await tester.tap(find.text('So What').first);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
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
          await openForm(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(MusicMetadataForm).first),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
  // Testing Specification 7.1: both languages, asserting that no key renders
  // as its identifier. Matched on the catalog's key prefixes, the way the
  // other suites do it — a bare lowercase word is a legitimate metadata value
  // ("title" is one of this form's own).
  group('both languages', () {
    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheFormOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openForm(tester, locale: locale);

          expect(
            find.textContaining(
              RegExp('(musicMetadata|metadata|details)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
