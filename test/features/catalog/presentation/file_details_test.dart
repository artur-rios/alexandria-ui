import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/auth/presentation/login_screen.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/file_details.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// One file's details (UC-13, FR-CT-05).
void main() {
  const uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f';

  /// Signs in, opens the music listing, and taps the file.
  Future<ProviderContainer> openDetails(
    WidgetTester tester, {
    FileDetailsOutcome? outcome,
    Locale? locale,
    bool tapRow = true,
  }) async {
    final gateway = FakeCatalogGateway(
      listings: {
        LibraryType.audio: CatalogListing.loaded(files: [aFile(uuid: uuid)]),
      },
    );
    if (outcome != null) gateway.details[uuid] = outcome;

    final container = await tester.pumpShell(
      locale: locale,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(gateway),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.music.icon),
      ),
    );
    await tester.pumpAndSettle();

    if (tapRow) {
      await tester.tap(find.text('Kind of Blue.flac'));
      await tester.pumpAndSettle();
    }

    return container;
  }

  group('the main flow', () {
    testWidgets('GivenAListing_WhenARowIsTapped_ThenTheDetailsOpen',
        (tester) async {
      await openDetails(tester);

      expect(find.byType(FileDetailsView), findsOneWidget);
    });

    testWidgets('GivenTheDetails_WhenTheyOpen_ThenTheCoreIsAskedByUuid',
        (tester) async {
      final container = await openDetails(tester);

      // Asked afresh rather than shown from the listing's copy: the record the
      // owner clicked is not necessarily what the core holds now.
      expect(container.read(openFileProvider), uuid);
    });

    testWidgets('GivenTheDetails_WhenTheyOpen_ThenPathStateAndMetadataShow',
        (tester) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid),
            metadata: const {'artist': 'Miles Davis'},
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsPath), findsOneWidget);
      expect(find.text(l10n.detailsState), findsOneWidget);
      expect(find.text('Miles Davis'), findsOneWidget);
      expect(find.text(l10n.detailsStateActive), findsOneWidget);
    });

    testWidgets('GivenExtractedValues_WhenTheyExist_ThenTheyAreShown',
        (tester) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(file: aFile(uuid: uuid), durationSeconds: 545),
        ),
      );

      // 9 minutes 5 seconds, read the same way in both languages.
      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('GivenNoMetadata_WhenTheDetailsOpen_ThenItSaysSo',
        (tester) async {
      // Text and HTML files have none, and a file whose metadata has not been
      // written has none either.
      await openDetails(tester);

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsMetadataNone), findsOneWidget);
    });
  });

  group('no viewer is registered (AF-04)', () {
    testWidgets('GivenNoViewer_WhenTheDetailsOpen_ThenTheDetailsStillShow',
        (tester) async {
      // True of every type today: the viewers are M-07's. The details are
      // presented and the limitation is stated rather than an action offered
      // that would do nothing.
      await openDetails(tester);

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsNoViewer), findsOneWidget);
      expect(find.text(l10n.detailsPath), findsOneWidget);
    });
  });

  group('the record is deleted (AF-02)', () {
    testWidgets('GivenADeletedRecord_WhenTheDetailsOpen_ThenItShowsAsDeleted',
        (tester) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(file: aFile(uuid: uuid), isDeleted: true),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsStateDeleted), findsOneWidget);
      expect(find.text(l10n.detailsDeletedHint), findsOneWidget);
    });
  });

  group('the file is missing on disk (AF-03)', () {
    testWidgets('GivenAMissingFile_WhenTheDetailsOpen_ThenARescanIsOffered',
        (tester) async {
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, missingAt: DateTime.utc(2026, 8, 19)),
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsStateMissing), findsOneWidget);
      // The re-scan is UC-07's refresh, which does exist.
      expect(find.text(l10n.detailsRescan), findsOneWidget);
    });

    testWidgets('GivenADeletedRecord_WhenItIsAlsoMissing_ThenDeletedWins',
        (tester) async {
      // Both are true of a record deleted after its file vanished; the owner
      // needs the one that explains why it is not in the library.
      await openDetails(
        tester,
        outcome: FileDetailsOutcome.read(
          details: FileDetails(
            file: aFile(uuid: uuid, missingAt: DateTime.utc(2026, 8, 19)),
            isDeleted: true,
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.detailsStateDeleted), findsOneWidget);
      expect(find.text(l10n.detailsRescan), findsNothing);
    });
  });

  group('the core cannot answer', () {
    testWidgets('GivenTheCoreFails_WhenTheDetailsOpen_ThenAMessageAndRetry',
        (tester) async {
      // AF-01 arrives as this failure; the message and retry are the shell's.
      await openDetails(
        tester,
        outcome: const FileDetailsOutcome.failed(
          failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
        ),
      );

      expect(find.byType(ShellFailureView), findsOneWidget);
    });

    testWidgets('GivenTheCoreRejectsTheSession_WhenTheyOpen_ThenLoginReturns',
        (tester) async {
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
    testWidgets('Given${name}_WhenTheDetailsOpen_ThenTheyAreLocalized',
        (tester) async {
      await openDetails(tester, locale: locale);

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
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
}
