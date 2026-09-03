import 'dart:async';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/tracking/domain/watchlist.dart';
import 'package:alexandria_ui/features/tracking/domain/watchlist_gateway.dart';
import 'package:alexandria_ui/features/tracking/presentation/watchlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_watchlist_gateway.dart';
import '../../../support/shell_harness.dart';
import '../../../support/file_row.dart';

/// Managing watchlists (UC-29, FR-TR-01 … FR-TR-04).
void main() {
  const videoUuid = 'v1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  const evenings = Watchlist(uuid: 'wl-1', name: 'Evenings');

  final video = aFile(
    uuid: videoUuid,
    name: 'Stalker.mkv',
    type: FileType.video,
  );

  /// Signs in, opens the videos area, and opens the watchlists screen.
  Future<({ProviderContainer container, FakeWatchlistGateway gateway})>
  openWatchlists(
    WidgetTester tester, {
    List<Watchlist> watchlists = const [evenings],
    WatchlistBrowse? browse,
    List<WatchlistWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openScreen = true,
    bool reachArea = true,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        FileType.video: loadedDetails([video]),
      },
    );
    catalog.details[videoUuid] = FileDetailsOutcome.read(
      details: FileDetails(file: video, metadata: const {}),
    );

    final gateway = FakeWatchlistGateway(watchlists: watchlists)
      ..browseOutcome = browse
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        watchlistGatewayProvider.overrideWithValue(gateway),
      ],
    );

    // A rejected session has already returned the owner to login by now, so
    // there is no panel to navigate — the sign-out is the outcome under test.
    if (reachArea) {
      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.videos.icon),
        ),
      );
      await tester.pumpAndSettle();
    }

    if (openScreen) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.watchlistsOpen));
      await tester.pumpAndSettle();
    }

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(messages(tester).watchlistNameLabel),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.pump();
  }

  group('the main flow', () {
    // Step 1.
    testWidgets('GivenTheVideosArea_WhenItIsShown_ThenWatchlistsAreReachable', (
      tester,
    ) async {
      await openWatchlists(tester, openScreen: false);

      expect(find.text(messages(tester).watchlistsOpen), findsOneWidget);
    });

    testWidgets('GivenWatchlists_WhenTheScreenOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openWatchlists(tester);

      expect(find.text('Evenings'), findsOneWidget);
    });

    testWidgets('GivenNoWatchlists_WhenTheScreenOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openWatchlists(tester, watchlists: const []);

      expect(find.text(messages(tester).watchlistsNone), findsOneWidget);
    });

    // Step 2.
    testWidgets('GivenAName_WhenACreateIsAsked_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openWatchlists(tester, watchlists: const []);

      await typeName(tester, 'Weekends');
      await tester.tap(find.text(messages(tester).watchlistCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, ['Weekends']);
      expect(find.text('Weekends'), findsOneWidget);
    });

    // Steps 3 and 4, from the video's detail view.
    testWidgets('GivenAVideo_WhenItIsAddedToAWatchlist_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openWatchlists(tester, openScreen: false);

      await openDetailsOf(tester, 'Stalker.mkv');
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).watchlistAddTo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evenings').last);
      await tester.pumpAndSettle();

      expect(opened.gateway.added, [(watchlist: 'wl-1', video: videoUuid)]);
    });

    // AF-02 needs nothing of its own: the action is offered for a video and
    // for nothing else.
    testWidgets(
      'GivenAnAudioFile_WhenItsDetailsOpen_ThenTrackingIsNotOffered',
      (tester) async {
        // Filed under audio, matching the fixture's own type: UC-46 gave
        // audio its own browsing area whose rows play on tap rather than
        // opening this dialog, so the dialog is opened directly the same
        // way the application's own `FileDetailsView.show` is called.
        final catalog = FakeCatalogGateway(
          listings: {
            FileType.audio: loadedDetails([aFile()]),
          },
        );

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
            watchlistGatewayProvider.overrideWithValue(FakeWatchlistGateway()),
          ],
        );
        final element = tester.element(find.byType(ShellScreen));
        unawaited(
          FileDetailsView.show(element, element as WidgetRef, aFile().uuid),
        );
        await tester.pumpAndSettle();

        expect(find.text(messages(tester).watchlistAddTo), findsNothing);
      },
    );

    // Step 5.
    testWidgets('GivenATrackedVideo_WhenItIsRemoved_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openWatchlists(
        tester,
        watchlists: const [
          Watchlist(
            uuid: 'wl-1',
            name: 'Evenings',
            items: [
              WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: videoUuid,
                state: WatchState.pending,
              ),
            ],
          ),
        ],
      );

      await tester.tap(find.text('Evenings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(opened.gateway.removed, [(watchlist: 'wl-1', video: videoUuid)]);
    });

    // Step 6: the confirmation says the videos are kept.
    testWidgets('GivenAWatchlist_WhenItIsDeleted_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openWatchlists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).watchlistDeleteMessage('Evenings')),
        findsOneWidget,
      );
      expect(opened.gateway.deleted, isEmpty);
    });

    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenItIsDeleted', (
      tester,
    ) async {
      final opened = await openWatchlists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, ['wl-1']);
      expect(find.text('Evenings'), findsNothing);
    });
  });

  // AF-01: the name is blank after trimming.
  group('a name the screen refuses', () {
    testWidgets('GivenABlankName_WhenCreateIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openWatchlists(tester, watchlists: const []);

      await typeName(tester, '   ');
      await tester.tap(find.text(messages(tester).watchlistCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, isEmpty);
      expect(find.text(messages(tester).watchlistNameEmpty), findsOneWidget);
    });

    testWidgets('GivenAMarkedName_WhenItIsTypedAgain_ThenTheMarkIsDropped', (
      tester,
    ) async {
      await openWatchlists(tester, watchlists: const []);

      await typeName(tester, '');
      await tester.tap(find.text(messages(tester).watchlistCreate));
      await tester.pumpAndSettle();
      await typeName(tester, 'Weekends');

      expect(find.text(messages(tester).watchlistNameEmpty), findsNothing);
    });
  });

  // AF-03: the video is already in that watchlist.
  group('a video already tracked', () {
    const alreadyTracking = Watchlist(
      uuid: 'wl-1',
      name: 'Evenings',
      items: [
        WatchProgress(
          watchlistUuid: 'wl-1',
          videoUuid: videoUuid,
          state: WatchState.watching,
        ),
      ],
    );

    testWidgets('GivenItIsAlreadyTracked_WhenAddedAgain_ThenNothingIsSent', (
      tester,
    ) async {
      final opened = await openWatchlists(
        tester,
        watchlists: const [alreadyTracking],
        openScreen: false,
      );

      await openDetailsOf(tester, 'Stalker.mkv');
      await tester.tap(find.text(messages(tester).watchlistAddTo));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(messages(tester).watchlistAlreadyIn('Evenings')),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.added, isEmpty);
    });

    // The menu says so rather than dropping the entry, which would leave the
    // owner wondering where the watchlist went.
    testWidgets('GivenItIsAlreadyTracked_WhenTheMenuOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openWatchlists(
        tester,
        watchlists: const [alreadyTracking],
        openScreen: false,
      );

      await openDetailsOf(tester, 'Stalker.mkv');
      await tester.tap(find.text(messages(tester).watchlistAddTo));
      await tester.pumpAndSettle();

      expect(
        find.text(messages(tester).watchlistAlreadyIn('Evenings')),
        findsOneWidget,
      );
    });
  });

  // AF-04: the core reports the watchlist or video as not found.
  group('a watchlist the core no longer has', () {
    testWidgets('GivenTheWatchlistIsGone_WhenItIsDeleted_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openWatchlists(
        tester,
        writeOutcomes: const [
          WatchlistWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.watchlist,
              code: WATCHLIST_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).watchlistNotFound), findsOneWidget);
    });
  });

  // AF-05: the owner cancels a deletion.
  group('a deletion the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsCancelled_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openWatchlists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, isEmpty);
      expect(find.text('Evenings'), findsOneWidget);
    });
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenBrowsing_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openWatchlists(
          tester,
          browse: const WatchlistBrowse.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.watchlist,
              code: WATCHLIST_ERR_UNAUTHORIZED,
            ),
          ),
          openScreen: false,
          reachArea: false,
        );

        // Read rather than opened: the watchlists load lazily, so this is the
        // browse the screen would have triggered.
        await opened.container.read(watchlistsControllerProvider.future);

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
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openWatchlists(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(WatchlistsScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openWatchlists(tester, locale: locale, watchlists: const []);

          await typeName(tester, '  ');
          await tester.tap(find.text(messages(tester).watchlistCreate));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              RegExp('watch(list|State)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
