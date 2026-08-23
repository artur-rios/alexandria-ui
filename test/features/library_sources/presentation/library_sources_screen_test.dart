import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/library_sources/application/active_runs_controller.dart';
import 'package:alexandria_desktop/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_desktop/features/library_sources/domain/library_source.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_desktop/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/shell_harness.dart';

/// The library-sources screen (UC-05, FR-LB-01 … FR-LB-04, FR-LB-11).
void main() {
  final registeredAt = DateTime.utc(2026, 8, 19, 10, 30);

  LibrarySource source(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
  );

  /// Signs in, opens preferences, and opens the library-folders screen.
  Future<({FakeFolderPicker picker, InMemoryLibrarySourceStore store})>
  openScreen(
    WidgetTester tester, {
    String? picked = '/home/owner/music',
    bool exists = true,
    bool readable = true,
    List<LibrarySource>? registered,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    FakeIndexGateway? gateway,
    List<Override> extraOverrides = const [],
  }) async {
    final picker = FakeFolderPicker(path: picked);
    final store = InMemoryLibrarySourceStore(registered);

    await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      extraOverrides: <Override>[
        folderPickerProvider.overrideWithValue(picker),
        folderProbeProvider.overrideWithValue(
          FakeFolderProbe(existing: exists, readable: readable),
        ),
        librarySourceStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => registeredAt),
        if (gateway != null) indexGatewayProvider.overrideWithValue(gateway),
        // Long enough that no timer fires during a test: a running index run
        // is observed by calling refresh directly, not by waiting on a poll.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ...extraOverrides,
      ],
    );

    // Reached from the navigation panel's tools menu (UC-05 main flow step 1),
    // which is where every library-wide screen is reached from.
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librarySourcesOpen);

    return (picker: picker, store: store);
  }

  /// The folder rows on this screen.
  ///
  /// Scoped deliberately: the preferences dialog is still in the tree behind
  /// the full-screen one, and its radio options are ListTiles too.
  Finder sourceRows() => find.descendant(
    of: find.byType(LibrarySourcesScreen),
    matching: find.byType(ListTile),
  );

  /// Presses the screen's add-a-folder action.
  ///
  /// Pumped rather than settled: while the attempt is in flight the action
  /// shows a spinner, and an overlap warning keeps it in flight until the
  /// owner answers — so `pumpAndSettle` would wait for an animation that is
  /// doing exactly what it should.
  Future<void> addFolder(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibrarySourcesScreen)),
    );
    await tester.tap(find.text(l10n.librarySourcesAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('reachability', () {
    testWidgets(
      'GivenASignedInOwner_WhenPreferencesOpen_ThenLibraryFoldersCanBeOpened',
      (tester) async {
        await openScreen(tester);

        expect(find.byType(LibrarySourcesScreen), findsOneWidget);
      },
    );
  });

  group('first-run guidance (FR-LB-11)', () {
    testWidgets(
      'GivenNoRegisteredFolders_WhenTheScreenOpens_ThenGuidanceIsShown',
      (tester) async {
        await openScreen(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        expect(find.text(l10n.librarySourcesEmptyTitle), findsOneWidget);
        expect(sourceRows(), findsNothing);
      },
    );

    testWidgets(
      'GivenARegisteredFolder_WhenTheScreenOpens_ThenGuidanceIsNotShown',
      (tester) async {
        await openScreen(tester, registered: [source('/home/owner/books')]);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        expect(find.text(l10n.librarySourcesEmptyTitle), findsNothing);
        expect(find.text('books'), findsOneWidget);
      },
    );
  });

  group('the main flow', () {
    testWidgets('GivenAFolderIsChosen_WhenItIsAdded_ThenItIsListed', (
      tester,
    ) async {
      await openScreen(tester);

      await addFolder(tester);

      expect(find.text('music'), findsOneWidget);
      expect(find.text('/home/owner/music'), findsOneWidget);
    });

    testWidgets('GivenAFolderIsAdded_WhenItSettles_ThenItIsPersisted', (
      tester,
    ) async {
      final opened = await openScreen(tester);

      await addFolder(tester);

      expect(opened.store.read().single.path, '/home/owner/music');
    });
  });

  group('the owner cancels the picker (AF-01)', () {
    testWidgets('GivenTheOwnerCancels_WhenTheyAdd_ThenTheScreenIsUnchanged', (
      tester,
    ) async {
      final opened = await openScreen(tester, picked: null);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await addFolder(tester);

      expect(find.text(l10n.librarySourcesEmptyTitle), findsOneWidget);
      expect(opened.store.writeCount, 0);
      expect(opened.picker.openCount, 1);
    });
  });

  group('the folder is refused (AF-02, AF-03)', () {
    testWidgets('GivenAMissingFolder_WhenItIsAdded_ThenTheOwnerIsToldWhich', (
      tester,
    ) async {
      await openScreen(tester, exists: false);

      await addFolder(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(
        find.text(l10n.librarySourcesMissing('/home/owner/music')),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenAnUnreadableFolder_WhenItIsAdded_ThenTheOwnerIsToldWhich',
      (tester) async {
        // FR-LB-02: the two conditions read differently.
        await openScreen(tester, readable: false);

        await addFolder(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );
        expect(
          find.text(l10n.librarySourcesUnreadable('/home/owner/music')),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenADuplicate_WhenItIsAdded_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openScreen(tester, registered: [source('/home/owner/music')]);

      await addFolder(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );
      expect(find.text(l10n.librarySourcesAlreadyRegistered), findsOneWidget);
      expect(sourceRows(), findsOneWidget);
    });

    testWidgets('GivenARefusal_WhenItIsDismissed_ThenTheNoticeGoes', (
      tester,
    ) async {
      await openScreen(tester, exists: false);
      await addFolder(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.byTooltip(l10n.dismiss));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.librarySourcesMissing('/home/owner/music')),
        findsNothing,
      );
    });
  });

  group('the folders overlap (AF-04)', () {
    testWidgets('GivenAnOverlap_WhenItIsAdded_ThenTheOwnerIsWarnedFirst', (
      tester,
    ) async {
      await openScreen(tester, registered: [source('/home/owner')]);

      await addFolder(tester);

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );
      expect(find.text(l10n.librarySourcesOverlapTitle), findsOneWidget);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerConfirms_ThenItIsRegistered', (
      tester,
    ) async {
      final opened = await openScreen(
        tester,
        registered: [source('/home/owner')],
      );
      await addFolder(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );

      await tester.tap(find.text(l10n.librarySourcesOverlapConfirm));
      await tester.pumpAndSettle();

      expect(opened.store.read(), hasLength(2));
      expect(find.text('music'), findsOneWidget);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerCancels_ThenNothingIsRegistered', (
      tester,
    ) async {
      final opened = await openScreen(
        tester,
        registered: [source('/home/owner')],
      );
      await addFolder(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ConfirmationDialog)),
      );

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(opened.store.writeCount, 0);
      expect(sourceRows(), findsOneWidget);
    });
  });

  group('a registered folder is indexed without a second click (UC-06)', () {
    testWidgets(
      'GivenAFolderIsRegistered_WhenAdded_ThenItIsIndexedWithoutASecondClick',
      (tester) async {
        final gateway = FakeIndexGateway();

        await openScreen(tester, gateway: gateway);
        await addFolder(tester);

        expect(gateway.starts.single.root, '/home/owner/music');
      },
    );

    // The negative is what catches a naive implementation: chaining on the
    // call rather than on its result would index a folder the controller
    // refused.
    testWidgets('GivenARefusedFolder_WhenAdded_ThenNothingIsIndexed', (
      tester,
    ) async {
      final gateway = FakeIndexGateway();

      await openScreen(tester, gateway: gateway, exists: false);
      await addFolder(tester);

      expect(gateway.starts, isEmpty);
    });

    testWidgets('GivenThePickerIsCancelled_WhenAdded_ThenNothingIsIndexed', (
      tester,
    ) async {
      final gateway = FakeIndexGateway();

      await openScreen(tester, gateway: gateway, picked: null);
      await addFolder(tester);

      expect(gateway.starts, isEmpty);
    });

    // Task 6's review traced this gap end to end: `ActiveRunsController`
    // only learns what is running from its own build-time read and from
    // polling that starts once a running run is already known. Nothing told
    // it a run had just started here, so the strip would not show a scan
    // that began by registering a folder until something else happened to
    // remount or re-read the provider.
    testWidgets(
      'GivenAFolderIsRegistered_WhenAdded_ThenActiveRunsAreRefreshed',
      (tester) async {
        final gateway = FakeIndexGateway();
        final activeRuns = _RefreshCountingActiveRunsController();

        await openScreen(
          tester,
          gateway: gateway,
          extraOverrides: [
            activeRunsControllerProvider.overrideWith(() => activeRuns),
          ],
        );
        final before = activeRuns.refreshCalls;

        await addFolder(tester);

        expect(activeRuns.refreshCalls, greaterThan(before));
      },
    );
  });

  group('themes, languages, and the keyboard', () {
    testWidgets('GivenTheScreen_WhenItOpens_ThenItsPrimaryActionIsFocused', (
      tester,
    ) async {
      // FR-UX-11.
      await openScreen(tester);

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.byIcon(Icons.create_new_folder_outlined),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.autofocus, isTrue);
    });

    for (final (name, mode) in [
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ]) {
      testWidgets(
        'GivenThe${name}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openScreen(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(LibrarySourcesScreen)),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final (name, locale) in [
      ('English', const Locale('en')),
      ('Portuguese', const Locale('pt', 'BR')),
    ]) {
      testWidgets(
        'Given${name}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openScreen(tester, locale: locale);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(LibrarySourcesScreen)),
          );

          for (final label in [
            l10n.librarySourcesTitle,
            l10n.librarySourcesEmptyTitle,
            l10n.librarySourcesEmptyBody,
            l10n.librarySourcesAdd,
          ]) {
            expect(label, isNotEmpty);
            expect(label, isNot(startsWith('librarySources')));
            expect(find.text(label), findsWidgets);
          }
        },
      );
    }
  });
}

/// An [ActiveRunsController] that counts calls to [refresh] rather than
/// reaching the gateway.
///
/// It stands in for the real controller because the thing under test here is
/// whether registering a folder *asks* the active-runs controller to
/// re-read, not what the core would answer if it did — that answer is
/// [ActiveRunsController]'s own tests' subject.
class _RefreshCountingActiveRunsController extends ActiveRunsController {
  /// How many times [refresh] was called, including the one the controller
  /// makes of itself when it is first built.
  int refreshCalls = 0;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}
