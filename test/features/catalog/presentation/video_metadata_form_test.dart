import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/video_metadata.dart';
import 'package:alexandria_ui/features/catalog/presentation/video_metadata_form.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/keyboard.dart';
import '../../../support/fake_watch_progress_gateway.dart';
import '../../../support/shell_harness.dart';

/// Editing a video file's metadata (UC-16, FR-ME-02, FR-ME-03, FR-ME-05).
void main() {
  const uuid = '9b7c1d20-3a4e-4f51-8c02-7d6e5f4a3b2c';

  /// The details the form opens on: a film with every field filled.
  FileDetails aVideo({
    MediaKind kind = MediaKind.movie,
    bool isDeleted = false,
  }) => FileDetails(
    file: aFile(uuid: uuid, name: 'Stalker.mkv', type: FileType.video),
    metadata: {
      'title': 'Stalker',
      'year': '1979',
      'resolution': '1920x1080',
      'mediaKind': kind.wireName,
    },
    isDeleted: isDeleted,
  );

  /// Signs in, opens the video listing, and opens the metadata form on the one
  /// file in it.
  Future<(ProviderContainer, FakeCatalogGateway)> openForm(
    WidgetTester tester, {
    FileDetails? details,
    List<VideoMetadataEditOutcome> outcomes = const [],
    bool recordsEpisodes = false,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final loaded = details ?? aVideo();
    final gateway = FakeCatalogGateway(
      listings: {
        FileType.video: loadedDetails([loaded.file]),
      },
    );
    gateway.details[loaded.file.uuid] = FileDetailsOutcome.read(
      details: loaded,
    );
    gateway.videoEditOutcomes.addAll(outcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(gateway),
        watchProgressGatewayProvider.overrideWithValue(
          FakeWatchProgressGateway(recordsEpisodes: recordsEpisodes),
        ),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.videos.icon),
      ),
    );
    await tester.pumpAndSettle();

    // Main flow step 1: the form is opened from the file's detail view.
    await tester.tap(find.text('Stalker.mkv').first);
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

  /// The localizations the shell is showing.
  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Presses the form's save action.
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(messages(tester).videoMetadataSave));
    await tester.pumpAndSettle();
  }

  group('reaching the form from the keyboard (FR-UX-11)', () {
    testWidgets('GivenTheForm_WhenItOpens_ThenTheFirstFieldHasFocus', (
      tester,
    ) async {
      await openForm(tester);

      // Scoped to the form: the shell's search field sits behind the dialog.
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(VideoMetadataForm),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.autofocus, isTrue);
    });
  });

  testWidgets(
    'GivenAField_WhenReturnIsPressed_ThenTheFormIsSaved',
    (tester) async {
      // FR-UX-11: Return sends the form from wherever the owner is in it.
      final (_, gateway) = await openForm(tester);
      final l10n = messages(tester);
      await enter(tester, l10n.videoMetadataFieldYear, '1980');

      await tester.pressReturnIn(
        find.ancestor(
          of: find.text(l10n.videoMetadataFieldTitle),
          matching: find.byType(TextField),
        ),
      );

      expect(gateway.videoEdits, hasLength(1));
      expect(gateway.videoEdits.single.metadata.year, 1980);
    },
  );

  group('the main flow', () {
    testWidgets('GivenAVideoFile_WhenItsDetailsOpen_ThenEditingIsOffered', (
      tester,
    ) async {
      await openForm(tester);

      expect(find.text(messages(tester).videoMetadataTitle), findsOneWidget);
    });

    testWidgets('GivenTheFormOpens_WhenItIsShown_ThenItHoldsTheCurrentValues', (
      tester,
    ) async {
      // Step 2: the current values, not an empty form — the owner is
      // correcting a record, not writing one.
      await openForm(tester);

      Finder inForm(String text) => find.descendant(
        of: find.byType(VideoMetadataForm),
        matching: find.text(text),
      );

      expect(inForm('Stalker'), findsOneWidget);
      expect(inForm('1979'), findsOneWidget);
      expect(inForm('1920x1080'), findsOneWidget);
    });

    // FR-ME-02: the marking is part of the form, not something the owner has
    // to go elsewhere for.
    testWidgets('GivenAMovie_WhenTheFormOpens_ThenTheMarkingIsShownAsMovie', (
      tester,
    ) async {
      await openForm(tester);

      final selected = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .map((tile) => tile.value)
          .toList();

      expect(selected, ['movie', 'series']);
      expect(find.text(messages(tester).videoMetadataMovie), findsOneWidget);
    });

    testWidgets('GivenAnEdit_WhenSaved_ThenTheWholeRecordGoesToTheCore', (
      tester,
    ) async {
      // Steps 3 to 5. The whole record is sent rather than the one field that
      // changed, because the core's patch is a full replace.
      final (_, gateway) = await openForm(tester);

      await enter(tester, messages(tester).videoMetadataFieldYear, '1980');
      await save(tester);

      expect(gateway.videoEdits, hasLength(1));
      expect(
        gateway.videoEdits.single.metadata,
        const VideoMetadata(
          title: 'Stalker',
          year: 1980,
          resolution: '1920x1080',
          mediaKind: MediaKind.movie,
        ),
      );
    });

    testWidgets('GivenTheMarkingIsChanged_WhenSaved_ThenItGoesToTheCore', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester);

      await tester.tap(find.text(messages(tester).videoMetadataSeries));
      await tester.pumpAndSettle();
      await save(tester);

      expect(gateway.videoEdits.single.metadata.mediaKind, MediaKind.series);
    });

    testWidgets('GivenASavedEdit_WhenTheCoreAccepts_ThenTheFormCloses', (
      tester,
    ) async {
      await openForm(tester);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Сталкер');
      await save(tester);

      expect(find.byType(VideoMetadataForm), findsNothing);
    });

    // FR-ME-05: the listing and the detail view read the core again, so the
    // edit shows up without the owner refreshing anything.
    testWidgets('GivenASavedEdit_WhenItIsStored_ThenTheListingIsReadAgain', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester);
      final before = gateway.requested.length;

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Сталкер');
      await save(tester);

      expect(gateway.requested.length, greaterThan(before));
    });

    testWidgets('GivenNothingWasChanged_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester);

      await save(tester);

      expect(gateway.videoEdits, isEmpty);
      expect(find.byType(VideoMetadataForm), findsNothing);
    });

    testWidgets(
      'GivenADeletedRecord_WhenItsDetailsOpen_ThenEditingIsNotOffered',
      (tester) async {
        // The core refuses to edit a deleted record until it is restored, so
        // the action is not offered for one.
        final gateway = FakeCatalogGateway(
          listings: {
            FileType.video: loadedDetails([aVideo().file]),
          },
        );
        gateway.details[uuid] = FileDetailsOutcome.read(
          details: aVideo(isDeleted: true),
        );

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(gateway),
          ],
        );
        await tester.tap(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byIcon(ShellDestination.videos.icon),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stalker.mkv').first);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      },
    );
  });

  // AF-01: local validation fails.
  group('a value the form refuses', () {
    testWidgets('GivenAYearThatIsNotANumber_WhenSaved_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester);

      await enter(tester, messages(tester).videoMetadataFieldYear, 'soon');
      await save(tester);

      expect(gateway.videoEdits, isEmpty);
      expect(find.byType(VideoMetadataForm), findsOneWidget);
    });

    testWidgets('GivenAYearThatIsNotANumber_WhenSaved_ThenTheFieldIsMarked', (
      tester,
    ) async {
      await openForm(tester);

      await enter(tester, messages(tester).videoMetadataFieldYear, 'soon');
      await save(tester);

      expect(
        find.text(messages(tester).videoMetadataErrorNotANumber),
        findsOneWidget,
      );
    });

    testWidgets('GivenAMarkedField_WhenItIsEditedAgain_ThenTheMarkIsDropped', (
      tester,
    ) async {
      await openForm(tester);

      await enter(tester, messages(tester).videoMetadataFieldYear, 'soon');
      await save(tester);
      await enter(tester, messages(tester).videoMetadataFieldYear, '1979');

      expect(
        find.text(messages(tester).videoMetadataErrorNotANumber),
        findsNothing,
      );
    });
  });

  // AF-02: the core rejects the change.
  group('a change the core refuses', () {
    const rejection = VideoMetadataEditOutcome.failed(
      failure: Failure.unexpected(
        family: CoreStatusFamily.file,
        code: FILE_ERR_INVALID_INPUT,
      ),
    );

    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheFormStaysOpen', (
      tester,
    ) async {
      await openForm(tester, outcomes: const [rejection]);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Solaris');
      await save(tester);

      expect(find.byType(VideoMetadataForm), findsOneWidget);
    });

    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenWhatWasTypedIsKept', (
      tester,
    ) async {
      await openForm(tester, outcomes: const [rejection]);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Solaris');
      await save(tester);

      expect(
        find.descendant(
          of: find.byType(VideoMetadataForm),
          matching: find.text('Solaris'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('GivenTheCoreRefusesOnce_WhenTheOwnerRetries_ThenItIsSent', (
      tester,
    ) async {
      final (_, gateway) = await openForm(tester, outcomes: const [rejection]);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Solaris');
      await save(tester);
      await save(tester);

      expect(gateway.videoEdits, hasLength(2));
      expect(find.byType(VideoMetadataForm), findsNothing);
    });
  });

  // AF-03: series to movie, with per-episode progress recorded.
  group('turning a series into a movie', () {
    testWidgets(
      'GivenEpisodesAreRecorded_WhenTheMarkingBecomesMovie_ThenTheOwnerIsWarned',
      (tester) async {
        await openForm(
          tester,
          details: aVideo(kind: MediaKind.series),
          recordsEpisodes: true,
        );

        await tester.tap(find.text(messages(tester).videoMetadataMovie));
        await tester.pumpAndSettle();
        await save(tester);

        expect(
          find.text(messages(tester).videoMetadataMarkingWarning),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenTheWarning_WhenItIsShown_ThenTheCoreHasNotBeenCalled', (
      tester,
    ) async {
      final (_, gateway) = await openForm(
        tester,
        details: aVideo(kind: MediaKind.series),
        recordsEpisodes: true,
      );

      await tester.tap(find.text(messages(tester).videoMetadataMovie));
      await tester.pumpAndSettle();
      await save(tester);

      expect(gateway.videoEdits, isEmpty);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerConfirms_ThenTheChangeIsSent', (
      tester,
    ) async {
      final (_, gateway) = await openForm(
        tester,
        details: aVideo(kind: MediaKind.series),
        recordsEpisodes: true,
      );

      await tester.tap(find.text(messages(tester).videoMetadataMovie));
      await tester.pumpAndSettle();
      await save(tester);
      await tester.tap(find.text(messages(tester).videoMetadataMarkingConfirm));
      await tester.pumpAndSettle();

      expect(gateway.videoEdits.single.metadata.mediaKind, MediaKind.movie);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerCancels_ThenNothingIsSent', (
      tester,
    ) async {
      final (_, gateway) = await openForm(
        tester,
        details: aVideo(kind: MediaKind.series),
        recordsEpisodes: true,
      );

      await tester.tap(find.text(messages(tester).videoMetadataMovie));
      await tester.pumpAndSettle();
      await save(tester);
      await tester.tap(find.text(messages(tester).videoMetadataMarkingCancel));
      await tester.pumpAndSettle();

      expect(gateway.videoEdits, isEmpty);
      expect(find.byType(VideoMetadataForm), findsOneWidget);
    });

    // Nothing is lost, so nothing is warned about.
    testWidgets(
      'GivenNoEpisodesAreRecorded_WhenTheMarkingBecomesMovie_ThenItIsSentStraightAway',
      (tester) async {
        final (_, gateway) = await openForm(
          tester,
          details: aVideo(kind: MediaKind.series),
        );

        await tester.tap(find.text(messages(tester).videoMetadataMovie));
        await tester.pumpAndSettle();
        await save(tester);

        expect(gateway.videoEdits, hasLength(1));
      },
    );

    // The warning is about what the change costs, and going the other way
    // costs nothing.
    testWidgets(
      'GivenAMovie_WhenTheMarkingBecomesSeries_ThenNoWarningIsShown',
      (tester) async {
        final (_, gateway) = await openForm(tester, recordsEpisodes: true);

        await tester.tap(find.text(messages(tester).videoMetadataSeries));
        await tester.pumpAndSettle();
        await save(tester);

        expect(gateway.videoEdits, hasLength(1));
      },
    );
  });

  // AF-04: the core reports the file as not found.
  group('a file the core no longer has', () {
    const gone = VideoMetadataEditOutcome.failed(
      failure: Failure.notFound(
        family: CoreStatusFamily.file,
        code: FILE_ERR_NOT_FOUND,
      ),
    );

    testWidgets('GivenTheRecordIsGone_WhenSaved_ThenTheFormCloses', (
      tester,
    ) async {
      await openForm(tester, outcomes: const [gone]);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Solaris');
      await save(tester);

      expect(find.byType(VideoMetadataForm), findsNothing);
    });

    testWidgets('GivenTheRecordIsGone_WhenSaved_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openForm(tester, outcomes: const [gone]);

      await enter(tester, messages(tester).videoMetadataFieldTitle, 'Solaris');
      await save(tester);

      expect(find.text(messages(tester).detailsNotFound), findsOneWidget);
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenSaved_ThenTheOwnerSignsOut',
      (tester) async {
        final (container, _) = await openForm(
          tester,
          outcomes: const [
            VideoMetadataEditOutcome.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: FILE_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );

        await enter(
          tester,
          messages(tester).videoMetadataFieldTitle,
          'Solaris',
        );
        await tester.tap(find.text(messages(tester).videoMetadataSave));
        await tester.pumpAndSettle();

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheFormOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openForm(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(VideoMetadataForm))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheFormOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openForm(
            tester,
            locale: locale,
            details: aVideo(kind: MediaKind.series),
            recordsEpisodes: true,
          );

          await tester.tap(find.text(messages(tester).videoMetadataMovie));
          await tester.pumpAndSettle();
          await save(tester);

          expect(
            find.textContaining('videoMetadata', findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
