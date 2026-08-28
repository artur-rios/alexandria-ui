import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlists_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_playlist_gateway.dart';
import '../../../support/shell_harness.dart';

/// Managing playlists from the Library menu (playlists design).
void main() {
  const jazz = Playlist(uuid: 'p-1', name: 'Jazz');

  /// Signs in and opens the playlists screen.
  Future<({ProviderContainer container, FakePlaylistGateway gateway})>
  openPlaylists(
    WidgetTester tester, {
    List<Playlist> playlists = const [jazz],
    PlaylistBrowse? browse,
    List<PlaylistWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openScreen = true,
  }) async {
    final gateway = FakePlaylistGateway(playlists: playlists)
      ..browseOutcome = browse
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        playlistGatewayProvider.overrideWithValue(gateway),
      ],
    );

    if (openScreen) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.openLibraryTool(l10n.playlistsOpen);
      await tester.pumpAndSettle();
    }

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// The screen's own name field.
  ///
  /// Scoped: the shell behind the dialog has a search field of its own, and it
  /// comes first in the tree.
  Finder nameField() => find.descendant(
    of: find.byType(PlaylistsScreen),
    matching: find.byType(TextField),
  );

  /// [finder], but only inside the screen.
  Finder inScreen(Finder finder) =>
      find.descendant(of: find.byType(PlaylistsScreen), matching: finder);

  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(nameField(), name);
    await tester.pump();
  }

  group('the main flow', () {
    testWidgets(
      'GivenTheShell_WhenTheToolsAreOpened_ThenPlaylistsAreReachable',
      (tester) async {
        await openPlaylists(tester, openScreen: false);

        await tester.tap(find.byType(LibraryMenu));
        await tester.pumpAndSettle();

        expect(find.text(messages(tester).playlistsOpen), findsOneWidget);
      },
    );

    testWidgets('GivenPlaylists_WhenTheScreenOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openPlaylists(tester);

      expect(find.text('Jazz'), findsOneWidget);
    });

    // The empty state invites making one rather than showing a bare list.
    testWidgets('GivenNoPlaylists_WhenTheScreenOpens_ThenItInvitesCreatingOne', (
      tester,
    ) async {
      await openPlaylists(tester, playlists: const []);

      expect(find.text(messages(tester).playlistsNone), findsOneWidget);
    });

    // Creating one adds it to the list without a manual refresh.
    testWidgets('GivenAName_WhenCreateIsAsked_ThenItAppearsAtOnce', (
      tester,
    ) async {
      final opened = await openPlaylists(tester, playlists: const []);

      await typeName(tester, 'Chill');
      await tester.tap(find.text(messages(tester).playlistCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, ['Chill']);
      expect(find.text('Chill'), findsOneWidget);
    });

    // Renaming shows the new name.
    testWidgets('GivenAPlaylist_WhenRenamed_ThenTheNewNameShows', (
      tester,
    ) async {
      final opened = await openPlaylists(tester);

      await tester.tap(inScreen(find.byIcon(Icons.edit_outlined)));
      await tester.pumpAndSettle();
      await typeName(tester, 'Bebop');
      await tester.tap(find.text(messages(tester).playlistRenameSave));
      await tester.pumpAndSettle();

      expect(opened.gateway.renamed, [(uuid: 'p-1', name: 'Bebop')]);
      expect(find.text('Bebop'), findsOneWidget);
      expect(find.text('Jazz'), findsNothing);
    });

    // Deleting asks first, and says the tracks themselves are untouched.
    testWidgets('GivenAPlaylist_WhenItIsDeleted_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openPlaylists(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).playlistDeleteMessage('Jazz')),
        findsOneWidget,
      );
      expect(opened.gateway.deleted, isEmpty);
    });

    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenItIsDeleted', (
      tester,
    ) async {
      final opened = await openPlaylists(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, ['p-1']);
      expect(find.text('Jazz'), findsNothing);
    });
  });

  // A blank name never reaches the core.
  group('a name the screen refuses', () {
    testWidgets('GivenABlankName_WhenCreateIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openPlaylists(tester, playlists: const []);

      await typeName(tester, '   ');
      await tester.tap(find.text(messages(tester).playlistCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, isEmpty);
      expect(find.text(messages(tester).playlistNameEmpty), findsOneWidget);
    });

    testWidgets('GivenABlankRename_WhenSaveIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openPlaylists(tester);

      await tester.tap(inScreen(find.byIcon(Icons.edit_outlined)));
      await tester.pumpAndSettle();
      await typeName(tester, '  ');
      await tester.tap(find.text(messages(tester).playlistRenameSave));
      await tester.pumpAndSettle();

      expect(opened.gateway.renamed, isEmpty);
      expect(find.text(messages(tester).playlistNameEmpty), findsOneWidget);
    });
  });

  group('a deletion the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsCancelled_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openPlaylists(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, isEmpty);
      expect(find.text('Jazz'), findsOneWidget);
    });
  });

  group('a playlist the core no longer has', () {
    testWidgets('GivenItIsGone_WhenItIsDeleted_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openPlaylists(
        tester,
        writeOutcomes: const [
          PlaylistWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.playlist,
              code: PLAYLIST_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).playlistNotFound), findsOneWidget);
    });
  });

  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenBrowsing_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openPlaylists(
          tester,
          browse: const PlaylistBrowse.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.playlist,
              code: PLAYLIST_ERR_UNAUTHORIZED,
            ),
          ),
          openScreen: false,
        );

        // Read rather than opened: the playlists load lazily, so this is the
        // browse the screen would have triggered.
        await opened.container.read(playlistsControllerProvider.future);

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('a rejected write does not freeze the form', () {
    testWidgets(
      'GivenTheCoreRejectsAWrite_WhenTheOwnerSignsBackIn_ThenTheFormStillWorks',
      (tester) async {
        // `playlistsFormProvider` is not auto-disposed, so `isWriting`
        // outlives the dialog and the session. Left set, `create` returns at
        // its own `state.isWriting` guard and every later create, rename and
        // delete silently does nothing for the rest of the run — the field
        // stays disabled and the core is never called again.
        final opened = await openPlaylists(
          tester,
          writeOutcomes: const [
            PlaylistWrite.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.playlist,
                code: PLAYLIST_ERR_UNAUTHORIZED,
              ),
            ),
          ],
          openScreen: false,
        );
        final form = opened.container.read(playlistsFormProvider.notifier);

        form.editName('Road Trip');
        await form.create();
        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
        expect(
          opened.container.read(playlistsFormProvider).isWriting,
          isFalse,
          reason: 'the form would stay disabled with nothing in flight',
        );

        // The owner signs back in and tries again.
        opened.container
            .read(sessionControllerProvider.notifier)
            .establish(FakeAuthGateway.defaultSession);
        form.editName('Second Try');
        await form.create();

        expect(
          opened.gateway.created,
          ['Road Trip', 'Second Try'],
          reason: 'the second attempt never reached the core',
        );
      },
    );
  });

  group('opening a playlist', () {
    testWidgets(
      'GivenAPlaylist_WhenItsRowIsTapped_ThenItsTracksOpen',
      (tester) async {
        // The row is the only way into the detail screen, so without this the
        // tracks, their order and the play action are all unreachable however
        // well they work.
        final opened = await openPlaylists(tester);
        opened.gateway.reads[jazz.uuid] = const PlaylistRead.loaded(
          view: PlaylistView(playlist: jazz, entries: []),
        );

        await tester.tap(find.text(jazz.name));
        await tester.pumpAndSettle();

        expect(find.byType(PlaylistDetailScreen), findsOneWidget);
        expect(opened.gateway.readsMade, contains(jazz.uuid));
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openPlaylists(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(PlaylistsScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openPlaylists(tester, locale: locale, playlists: const []);

          await typeName(tester, '  ');
          await tester.tap(find.text(messages(tester).playlistCreate));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(RegExp('playlists?[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
