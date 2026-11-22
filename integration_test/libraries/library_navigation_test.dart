import 'dart:async';
import 'dart:io';

import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/startup/core_paths.dart';
import 'package:alexandria_ui/core/startup/startup_state.dart';
import 'package:alexandria_ui/features/catalog/presentation/home_dashboard.dart';
import 'package:alexandria_ui/features/indexing/domain/folder_picker.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_view.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../support/temporary_catalog.dart';

/// A [FolderPicker] answering the folder a test chose: the native dialog is
/// the one thing that cannot be driven, and everything after it is real.
class _ChosenFolder implements FolderPicker {
  String? path;

  @override
  Future<String?> pickFolder() async => path;
}

/// Living with libraries, through the whole application against the real core
/// (library navigation design).
///
/// Adds two libraries from the Library menu, then pins, favorites, renames
/// and opens one from the left menu, and reads the totals on home. Every step
/// is driven through the widget tree and asserted on what is drawn, because
/// the unit tests of each piece run against a fake the application also wrote
/// and cannot tell whether the pieces meet.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TemporaryCatalog catalog;
  late String libraryPath;

  setUpAll(() {
    expect(
      Platform.isWindows || Platform.isLinux,
      isTrue,
      reason: 'IR-01 configures no other target',
    );

    final resolved = resolveRealCoreLibrary();
    expect(resolved, isNotNull, reason: missingCoreReason);
    libraryPath = resolved!;
  });

  setUp(() => catalog = TemporaryCatalog.create());
  tearDown(() => catalog.dispose());

  /// Pumps until [finder] matches, so a read against the real core has landed.
  Future<void> until(WidgetTester tester, Finder finder, String what) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('never saw $what');
  }

  /// Pumps until [finder] matches nothing.
  Future<void> untilGone(
    WidgetTester tester,
    Finder finder,
    String what,
  ) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (finder.evaluate().isEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('$what never went away');
  }

  /// A few frames, for an animation or a menu opening to finish.
  Future<void> frames(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Finder panel() => find.byType(ShellNavigationPanel);
  Finder entry(String label) =>
      find.descendant(of: panel(), matching: find.text(label));
  Finder home() => find.byType(HomeDashboard);

  Future<ProviderContainer> startApp(
    WidgetTester tester,
    FolderPicker picker,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corePathsProvider.overrideWithValue(
            CorePaths(
              environment: {
                CorePaths.libraryPathVariable: libraryPath,
                CorePaths.databasePathVariable: catalog.databasePath,
              },
            ),
          ),
          folderPickerProvider.overrideWithValue(picker),
        ],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const AlexandriaApp();
          },
        ),
      ),
    );

    // Started the way `main` starts it, after the first frame.
    unawaited(container.read(startupControllerProvider.notifier).start());
    for (var attempt = 0; attempt < 200; attempt++) {
      if (container.read(startupControllerProvider) is StartupReady) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      container.read(startupControllerProvider),
      isA<StartupReady>(),
      reason: 'the core never came up',
    );
    await until(tester, find.byType(ShellScreen), 'the shell');

    return container;
  }

  /// Adds [folder] from the Library menu, naming it [name].
  Future<void> addFromMenu(
    WidgetTester tester,
    _ChosenFolder picker, {
    required String folder,
    required String name,
  }) async {
    picker.path = folder;
    final l10n = messages(tester);

    await tester.tap(find.byType(LibraryMenu));
    await frames(tester);
    await tester.tap(find.text(l10n.libraryMenuAdd));
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await until(tester, field, 'the name dialog');

    await tester.enterText(field, name);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l10n.libraryAdd),
      ),
    );
    await until(tester, entry(name), 'the new library in the left menu');
  }

  Future<void> openContextMenu(WidgetTester tester, String label) async {
    await tester.tap(entry(label), buttons: kSecondaryButton);
    await frames(tester);
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets(
    'GivenALibrary_WhenPinnedFavoritedRenamedAndOpened_ThenTheMenuHomeAndViewAgree',
    (tester) async {
      // The folder the owner adds: a subfolder with two notes, and a track at
      // the top, so home's totals are known exactly.
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      catalog.addFixture('class-01/handout.md', '# a handout');
      File(
        'integration_test/fixtures/tagged.flac',
      ).copySync(p.join(catalog.libraryDirectory.path, 'tagged.flac'));
      final other = Directory(
        p.join(catalog.libraryDirectory.parent.path, 'other'),
      )..createSync();

      // 1. The shell shows, and there is no login.
      final picker = _ChosenFolder();
      final container = await startApp(tester, picker);
      expect(find.byType(ShellScreen), findsOneWidget);
      expect(find.textContaining('Sign in'), findsNothing);
      expect(find.textContaining('password'), findsNothing);
      final l10n = messages(tester);

      // 2. Add the folder as a library and wait for its run.
      await addFromMenu(
        tester,
        picker,
        folder: catalog.libraryDirectory.path,
        name: 'Course',
      );
      final core = container.read(startupControllerProvider.notifier).core!;
      for (var attempt = 0; attempt < 300; attempt++) {
        if (await core.indexCountFiles() >= 3) break;
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(await core.indexCountFiles(), 3, reason: 'the run did not finish');

      // A second one, alphabetically first, so that pinning has an order to
      // change.
      await addFromMenu(tester, picker, folder: other.path, name: 'Alpha');

      // 3. Both are in the left menu, the others A-Z.
      expect(entry('Course'), findsOneWidget);
      expect(
        top(tester, entry('Alpha')),
        lessThan(top(tester, entry('Course'))),
        reason: 'unpinned libraries were not listed A-Z',
      );

      // 4. Pin it: it is first among the libraries.
      await openContextMenu(tester, 'Course');
      await tester.tap(find.text(l10n.libraryPin));
      await frames(tester);
      expect(
        top(tester, entry('Course')),
        lessThan(top(tester, entry('Alpha'))),
        reason: 'the pinned library was not listed first',
      );
      expect(
        find.descendant(of: panel(), matching: find.byType(Divider)),
        findsOneWidget,
        reason: 'no divider between the pinned and the other libraries',
      );

      // 5. Favorite it: home lists it, and only it.
      await openContextMenu(tester, 'Course');
      await tester.tap(find.text(l10n.libraryFavoriteAdd));
      await frames(tester);
      await tester.tap(entry(l10n.destinationHome));
      await frames(tester);
      await until(
        tester,
        find.descendant(of: home(), matching: find.text('Course')),
        'the favorite on home',
      );
      expect(
        find.descendant(of: home(), matching: find.text('Alpha')),
        findsNothing,
        reason: 'a library that is not a favorite was listed on home',
      );

      // 6. Rename it: the menu and home show the new name.
      await openContextMenu(tester, 'Course');
      await tester.tap(find.text(l10n.libraryRenameEntry));
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await until(tester, field, 'the rename dialog');
      await tester.enterText(field, 'Lectures');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, l10n.renameSubmit));
      await until(tester, entry('Lectures'), 'the new name in the menu');
      await untilGone(tester, find.byType(AlertDialog), 'the rename dialog');
      expect(entry('Course'), findsNothing);
      await until(
        tester,
        find.descendant(of: home(), matching: find.text('Lectures')),
        'the new name on home',
      );
      expect(
        find.descendant(of: home(), matching: find.text('Course')),
        findsNothing,
      );

      // 7. Open it: its folders show, under its name.
      await tester.tap(entry('Lectures'));
      await until(
        tester,
        find.descendant(
          of: find.byType(LibraryView),
          matching: find.text('class-01'),
        ),
        'the library\'s folder',
      );
      expect(
        find.descendant(
          of: find.byType(LibraryView),
          matching: find.text('Lectures'),
        ),
        findsOneWidget,
        reason: 'the header did not carry the new name',
      );

      // 8. Home's statistics count its files.
      await tester.tap(entry(l10n.destinationHome));
      await until(
        tester,
        find.text(l10n.homeLibraryCount(2)),
        'the library count',
      );
      Finder count(String wireName, String value) => find.descendant(
        of: find.byKey(ValueKey('home-stat-$wireName')),
        matching: find.text(value),
      );
      await until(tester, count('text', '2'), 'two notes in the totals');
      expect(count('audio', '1'), findsOneWidget);
      for (final none in ['video', 'document', 'comic', 'html', 'image']) {
        expect(count(none, '0'), findsOneWidget, reason: 'totals of $none');
      }
    },
  );
}
