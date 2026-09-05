import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/library_sources/application/active_runs_controller.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/presentation/index_scope_dialog.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/in_memory_settings_store.dart';
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
      // Off, so `establish`'s own unawaited call to `begin()` (FR-LB-21)
      // does not itself start a refresh through a gateway a test here
      // configured for its own scenario, racing the scan the test drives.
      settings: InMemorySettingsStore(
        themeMode: themeMode,
        locale: locale,
        rechecksAtStartup: false,
      ),
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

  /// Answers the scope dialog with what it opens on — every supported file
  /// (UC-05). Registering does not complete until this is answered.
  Future<void> acceptScope(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(IndexScopeDialog)),
    );
    await tester.tap(find.text(l10n.indexScopeConfirm));
    await tester.pumpAndSettle();
  }

  /// Opens the screen with one registered folder per entry in [runs], each
  /// carrying the given status.
  ///
  /// Seeded through AF-05's own recorded-run pickup rather than a new
  /// controller seam: a folder whose entry carries a status gets a
  /// `lastRunId`, and the gateway is told what reading that id answers, so
  /// `resumeRecordedRuns` (already exercised by the AF-05 tests) is what puts
  /// the row in the state under test. A folder with no entry at all is still
  /// registered, with no run — "no run" is a real row state, not an absence
  /// of one.
  Future<ProviderContainer> pumpSourcesScreen(
    WidgetTester tester, {
    FakeIndexGateway? gateway,
    Map<String, IndexRunStatus> runs = const {},
  }) async {
    const defaultRoot = 'D:/Music';
    final roots = runs.keys.isEmpty ? [defaultRoot] : runs.keys.toList();
    final fakeGateway = gateway ?? FakeIndexGateway();

    final sources = [
      for (final root in roots)
        LibrarySource(
          path: root,
          label: defaultLabelFor(root),
          registeredAt: registeredAt,
          lastRunId: runs.containsKey(root) ? '$root-run' : null,
        ),
    ];

    if (runs.isNotEmpty) {
      fakeGateway.readOutcomes = [
        for (final entry in runs.entries)
          IndexRunOutcome.read(
            run: IndexRun(
              runId: '${entry.key}-run',
              root: entry.key,
              status: entry.value,
            ),
          ),
      ];
    }

    final container = await tester.pumpShell(
      // Off, for the same reason as `openScreen` above.
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        librarySourceStoreProvider.overrideWithValue(
          InMemoryLibrarySourceStore(sources),
        ),
        indexGatewayProvider.overrideWithValue(fakeGateway),
        clockProvider.overrideWithValue(() => registeredAt),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.openLibraryTool(l10n.librarySourcesOpen);
    await tester.pumpAndSettle();

    return container;
  }

  group(
    'a row offers only what its own state affords (FR-FC-28 … FR-FC-30)',
    () {
      testWidgets(
        'GivenARowWithARunningRun_WhenBuilt_ThenPauseAndCancelAreOffered',
        (tester) async {
          final container = await pumpSourcesScreen(
            tester,
            runs: {'D:/Music': IndexRunStatus.running},
          );

          expect(find.byTooltip('Pause'), findsOneWidget);
          expect(find.byTooltip('Cancel'), findsOneWidget);
          expect(find.text('Rescan'), findsNothing);

          // The run is deliberately still going, so the poller is stopped here.
          container.dispose();
        },
      );

      testWidgets('GivenARowWithAPausedRun_WhenBuilt_ThenResumeIsOffered', (
        tester,
      ) async {
        await pumpSourcesScreen(
          tester,
          runs: {'D:/Music': IndexRunStatus.paused},
        );

        expect(find.byTooltip('Resume'), findsOneWidget);
      });

      testWidgets('GivenARowWithNoRun_WhenBuilt_ThenRescanIsOffered', (
        tester,
      ) async {
        await pumpSourcesScreen(tester, runs: {});

        expect(find.text('Rescan'), findsOneWidget);
      });

      // The row-affordance rule's whole point is that a state must never
      // offer a control it cannot support — running and paused each have
      // their own test above, but a terminal run had none. The
      // implementation falls through to Rescan for anything that is not
      // running or paused, and this is what would catch a reordering of
      // those branches that let Resume, Pause or Cancel leak onto a run
      // that is over for good.
      for (final (name, status) in [
        ('Complete', IndexRunStatus.complete),
        ('Failed', IndexRunStatus.failed),
        ('Cancelled', IndexRunStatus.cancelled),
      ]) {
        testWidgets(
          'GivenARowWithA${name}Run_WhenBuilt_ThenOnlyRescanIsOffered',
          (tester) async {
            await pumpSourcesScreen(tester, runs: {'D:/Music': status});

            expect(find.text('Rescan'), findsOneWidget);
            expect(find.byTooltip('Resume'), findsNothing);
            expect(find.byTooltip('Pause'), findsNothing);
            expect(find.byTooltip('Cancel'), findsNothing);
          },
        );
      }

      // Cancel is terminal and not resumable, so it asks first — this is what
      // catches a naive implementation that wires the button straight to the
      // gateway.
      testWidgets('GivenARunningRun_WhenCancelIsTapped_ThenItConfirmsFirst', (
        tester,
      ) async {
        final gateway = FakeIndexGateway();
        final container = await pumpSourcesScreen(
          tester,
          gateway: gateway,
          runs: {'D:/Music': IndexRunStatus.running},
        );

        await tester.tap(find.byTooltip('Cancel'));
        await tester.pumpAndSettle();

        expect(gateway.cancels, isEmpty);
        expect(find.byType(AlertDialog), findsOneWidget);

        // The run is deliberately still going, so the poller is stopped here.
        container.dispose();
      });
    },
  );

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
      await acceptScope(tester);

      expect(find.text('music'), findsOneWidget);
      expect(find.text('/home/owner/music'), findsOneWidget);
    });

    testWidgets('GivenAFolderIsAdded_WhenItSettles_ThenItIsPersisted', (
      tester,
    ) async {
      final opened = await openScreen(tester);

      await addFolder(tester);
      await acceptScope(tester);

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
      // Pumped rather than settled, for the reason `addFolder` is: the
      // attempt is still in flight — the scope is asked next — and the add
      // action's spinner keeps animating until it is answered.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await acceptScope(tester);

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
        await acceptScope(tester);

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
        await acceptScope(tester);

        expect(activeRuns.refreshCalls, greaterThan(before));
      },
    );
  });

  group('what each folder covers is on its row (UC-05)', () {
    LibrarySource scoped(String path, List<FileType> types) => LibrarySource(
      path: path,
      label: defaultLabelFor(path),
      registeredAt: registeredAt,
      scope: [for (final type in types) type.wireName],
    );

    testWidgets('GivenAScopedFolder_WhenTheListIsRead_ThenItsScopeIsNamed', (
      tester,
    ) async {
      await openScreen(
        tester,
        registered: [
          scoped('/home/owner/music', const [FileType.audio]),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      expect(
        find.text(l10n.librarySourcesScopeOnly(l10n.fileTypeAudio)),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenAnUnscopedFolder_WhenTheListIsRead_ThenItCoversEverything',
      (tester) async {
        // The absent scope reads as every supported file, not as nothing —
        // which is what a folder registered before this existed still covers.
        await openScreen(tester, registered: [source('/home/owner/music')]);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        expect(find.text(l10n.librarySourcesScopeAll), findsOneWidget);
      },
    );

    testWidgets('GivenAScopedFolder_WhenItIsRescanned_ThenItIsNotAskedAgain', (
      tester,
    ) async {
      // The scope belongs to the folder: a later index of it uses the answer
      // already given rather than interrupting to ask for it a second time.
      final gateway = FakeIndexGateway();
      await openScreen(
        tester,
        gateway: gateway,
        registered: [
          scoped('/home/owner/music', const [FileType.audio]),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.text(l10n.librarySourcesRescan));
      await tester.pumpAndSettle();

      expect(find.byType(IndexScopeDialog), findsNothing);
      expect(gateway.starts.single.types, [FileType.audio]);
    });
  });

  group('a scope this version cannot read (UC-05, UC-06)', () {
    LibrarySource unreadable(String path) => LibrarySource(
      path: path,
      label: defaultLabelFor(path),
      registeredAt: registeredAt,
      scope: const ['podcast'],
    );

    testWidgets(
      'GivenAnUnreadableScope_WhenTheListIsRead_ThenItDoesNotSayAll',
      (tester) async {
        // Reading as "All supported files" would state the opposite of what
        // the owner chose, on the row that is the only place they could catch
        // it.
        await openScreen(tester, registered: [unreadable('/home/owner/music')]);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        expect(find.text(l10n.librarySourcesScopeUnreadable), findsOneWidget);
        expect(find.text(l10n.librarySourcesScopeAll), findsNothing);
      },
    );

    testWidgets('GivenAnUnreadableScope_WhenItIsRescanned_ThenTheOwnerIsTold', (
      tester,
    ) async {
      final gateway = FakeIndexGateway();
      await openScreen(
        tester,
        gateway: gateway,
        registered: [unreadable('/home/owner/music')],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.text(l10n.librarySourcesRescan));
      await tester.pumpAndSettle();

      // Refused visibly and before the core: a folder that silently never
      // scans is its own defect.
      expect(gateway.starts, isEmpty);
      expect(
        find.text(l10n.librarySourcesStartUnreadableScope),
        findsOneWidget,
      );
    });
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

      // The empty screen above can never reach a folder's own strings, so
      // the scope lines went unrendered in either language — the gap that
      // lets a missing pt translation ship as a key. A registered folder is
      // what puts them on screen.
      testWidgets(
        'Given${name}_WhenFoldersAreListed_ThenTheirScopesRenderTranslated',
        (tester) async {
          await openScreen(
            tester,
            locale: locale,
            registered: [
              source('/home/owner/books'),
              LibrarySource(
                path: '/home/owner/music',
                label: 'music',
                registeredAt: registeredAt,
                scope: const ['audio'],
              ),
              LibrarySource(
                path: '/home/owner/podcasts',
                label: 'podcasts',
                registeredAt: registeredAt,
                scope: const ['podcast'],
              ),
            ],
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(LibrarySourcesScreen)),
          );

          for (final label in [
            l10n.librarySourcesScopeAll,
            l10n.librarySourcesScopeOnly(l10n.fileTypeAudio),
            l10n.librarySourcesScopeUnreadable,
          ]) {
            expect(label, isNotEmpty);
            expect(label, isNot(startsWith('librarySources')));
            expect(label, isNot(contains('fileType')));
            expect(find.text(label), findsWidgets);
          }
        },
      );
    }
  });

  group('a folder that is a library', () {
    /// A source folder already marked as [name].
    LibrarySource marked(String path, String name) => LibrarySource(
      path: path,
      label: defaultLabelFor(path),
      registeredAt: registeredAt,
      libraryName: name,
    );

    testWidgets('GivenAMarkedFolder_WhenItIsListed_ThenItsRowSaysSo', (
      tester,
    ) async {
      // Marking is invisible from anywhere else on this screen: the row looks
      // the same, and the files it removed from the type panels are missing
      // without explanation. This badge is the explanation.
      await openScreen(
        tester,
        registered: [marked('/home/owner/courses/rust', 'Rust course')],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      expect(
        find.text(l10n.librarySourcesIsLibrary('Rust course')),
        findsOneWidget,
      );
      expect(
        find.byTooltip(l10n.librarySourcesMarkAsLibrary),
        findsNothing,
        reason: 'a folder that is already a library cannot be marked again',
      );
    });

    /// Marks the first row's folder as [name], through the row's own action.
    Future<void> mark(WidgetTester tester, String name) async {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LibrarySourcesScreen)),
      );

      await tester.tap(find.byTooltip(l10n.librarySourcesMarkAsLibrary));
      await tester.pumpAndSettle();
      // Scoped to the dialog: the shell behind it has a search field, and an
      // unscoped finder matches both.
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        name,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text(l10n.libraryAdd),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('GivenAMarkedFolder_WhenItIsMarked_ThenItIsIndexed', (
      tester,
    ) async {
      // Registered is not the same as indexed: a folder registered before the
      // first index happened on its own, or one whose run was cancelled, is a
      // source with nothing of it in the catalog — and a library made of it
      // shows nothing at all. Marking asks for the contents, so the walk goes
      // with the mark rather than waiting for the Rescan button beside it.
      final gateway = FakeIndexGateway();
      await openScreen(
        tester,
        registered: [source('/home/owner/courses/rust')],
        gateway: gateway,
        extraOverrides: [
          libraryGatewayProvider.overrideWithValue(FakeLibraryGateway()),
        ],
      );

      await mark(tester, 'Rust course');

      expect(gateway.starts.map((call) => call.root), [
        '/home/owner/courses/rust',
      ]);
    });

    testWidgets('GivenTheCoreRefusesTheLibrary_ThenNothingIsIndexed', (
      tester,
    ) async {
      // The folder never became a library, so there is nothing to fill.
      final gateway = FakeIndexGateway();
      await openScreen(
        tester,
        registered: [source('/home/owner/courses/rust')],
        gateway: gateway,
        extraOverrides: [
          libraryGatewayProvider.overrideWithValue(
            FakeLibraryGateway()
              ..writeOutcomes.add(
                const LibraryWrite.failed(
                  failure: Failure.conflict(
                    family: CoreStatusFamily.library,
                    code: LIBRARY_ERR_CONFLICT,
                  ),
                ),
              ),
          ),
        ],
      );

      await mark(tester, 'Rust course');

      expect(gateway.starts, isEmpty);
    });

    testWidgets(
      'GivenAnUnmarkedFolder_WhenItIsMarked_ThenTheCoreIsToldAndTheRowSaysSo',
      (tester) async {
        // The way in for a folder registered before the question existed.
        final libraries = FakeLibraryGateway();
        await openScreen(
          tester,
          registered: [source('/home/owner/courses/rust')],
          extraOverrides: [libraryGatewayProvider.overrideWithValue(libraries)],
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(LibrarySourcesScreen)),
        );

        await tester.tap(find.byTooltip(l10n.librarySourcesMarkAsLibrary));
        await tester.pumpAndSettle();
        // Scoped to the dialog: the shell behind it has a search field, and
        // an unscoped finder matches both.
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Rust course',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.text(l10n.libraryAdd),
          ),
        );
        await tester.pumpAndSettle();

        expect(libraries.registered, [
          (name: 'Rust course', rootPath: '/home/owner/courses/rust'),
        ]);
        expect(
          find.text(l10n.librarySourcesIsLibrary('Rust course')),
          findsOneWidget,
        );
      },
    );
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
