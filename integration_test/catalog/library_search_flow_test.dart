import 'dart:async';
import 'dart:io';

import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/startup/core_paths.dart';
import 'package:alexandria_ui/core/startup/startup_state.dart';
import 'package:alexandria_ui/features/catalog/presentation/catalog_search_view.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/temporary_catalog.dart';

/// Finding a library's file by name, through the whole application against the
/// real core (UC-11, FR-CT-06, FR-CT-17).
///
/// The seam every other suite leaves untested: the gateway tests prove the
/// core answers a library's files, and the widget tests prove the row names
/// its library when the index says so. Neither proves the two meet — so this
/// drives the real widget tree over the real core: the shell, the search
/// field, the results list.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const libraryName = 'Rust course';

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

  /// Starts the real application over a throwaway catalog.
  ///
  /// The paths are the only thing substituted, and through the resolver's own
  /// environment variables rather than a seam invented for the test: what
  /// starts here is the application, loading the real core, running the real
  /// startup sequence.
  Future<ProviderContainer> startApp(WidgetTester tester) async {
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
        ],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const AlexandriaApp();
          },
        ),
      ),
    );

    // Started the way `main` starts it — after the first frame, so a failure
    // at step 1 lands on the core-unavailable screen rather than on a blank
    // window. `main` also places the window and opens the log file; neither
    // is part of the seam under test, and neither is what `AlexandriaApp`
    // needs to come up.
    unawaited(container.read(startupControllerProvider.notifier).start());

    // Pumped frame by frame rather than settled: the startup screen shows a
    // progress indicator, and `pumpAndSettle` waits for an animation that
    // runs until the core is up — which is the very thing being waited for.
    for (var attempt = 0; attempt < 200; attempt++) {
      if (container.read(startupControllerProvider) is StartupReady) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      container.read(startupControllerProvider),
      isA<StartupReady>(),
      reason: 'the core never came up',
    );

    return container;
  }

  /// Adds the fixture folder as a library and waits for its first run to
  /// record [expected] files.
  ///
  /// The core starts that run with the library (0.6.0): a library is the
  /// only way anything gets into the catalog.
  Future<void> addLibraryAndSettle(
    WidgetTester tester,
    ProviderContainer container,
    int expected,
  ) async {
    final core = container.read(startupControllerProvider.notifier).core!;

    final registered = await container
        .read(libraryGatewayProvider)
        .register(name: libraryName, rootPath: catalog.libraryDirectory.path);
    expect(registered, isA<LibraryRegistered>());

    for (var attempt = 0; attempt < 300; attempt++) {
      if (await core.indexCountFiles() >= expected) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('the library run never recorded $expected files');
  }

  /// Loads the search index, then types [term] into the shell's search field.
  ///
  /// The index is awaited rather than pumped for: it is a read per type
  /// against a real core, and a search that runs before it lands matches an
  /// empty catalog and reports nothing — which looks exactly like the defect
  /// this test exists to catch.
  Future<void> search(
    WidgetTester tester,
    ProviderContainer container,
    String term,
  ) async {
    container.invalidate(catalogSearchProvider);
    final index = await container.read(catalogSearchProvider.future);
    expect(
      index.files,
      isNotEmpty,
      reason: 'the catalog the search matches against was empty',
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(CatalogSearchField), term);
    await tester.pumpAndSettle();
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  testWidgets(
    'GivenAFileInALibrary_WhenTheOwnerSearchesForIt_ThenItIsFoundAndNamesItsLibrary',
    (tester) async {
      // End to end: a library's file is found by typing its name, and the
      // hit says which library it is in.
      catalog.addFixture('class-01/lecture-notes.md', '# a lecture');
      final container = await startApp(tester);
      expect(find.byType(ShellScreen), findsOneWidget);
      await addLibraryAndSettle(tester, container, 1);

      await search(tester, container, 'lecture');

      // `findsWidgets`: a document row names the file and shows its path
      // underneath, and the path ends in the same name.
      expect(
        find.textContaining('lecture-notes.md'),
        findsWidgets,
        reason: 'a library file could not be found by name',
      );
      expect(
        find.text(messages(tester).searchInLibrary(libraryName)),
        findsOneWidget,
        reason:
            'the hit did not say where it lives, so the owner finds it here '
            'and then cannot find it in the panel for its type',
      );
    },
  );
}
