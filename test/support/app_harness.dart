import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import 'in_memory_settings_store.dart';
import 'test_container.dart';

/// Drives the application through its real root.
///
/// The first screen is reached the way the owner reaches it — startup runs and
/// settles — rather than by pumping a screen on its own. That is what makes
/// these tests cover the wiring in `app.dart` as well as the screen.
extension PumpApp on WidgetTester {
  /// Pumps the application with startup already settled.
  ///
  /// Lands on the shell, which is where a ready startup ends.
  Future<ProviderContainer> pumpApp({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
    SettingsStore? settings,
    List<Override> extraOverrides = const [],
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(
          // A caller-supplied store replaces the default rather than being
          // merged into it: that is how a test asks for one that cannot be
          // written (UC-39 AF-02).
          settings:
              settings ??
              InMemorySettingsStore(themeMode: themeMode, locale: locale),
        ),
        // Appended, so a caller can substitute a feature's own dependencies
        // without restating the whole fake set.
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await pumpAndSettle();

    return container;
  }

  /// Pumps the application with a core that cannot be loaded, so startup ends
  /// in its failure state.
  Future<ProviderContainer> pumpFailedStartup({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      // A path with no file behind it: startup step 1 checks the filesystem
      // before it loads anything.
      overrides: fakeCoreOverrides(
        libraryPath: 'no/such/library.dll',
        settings: InMemorySettingsStore(themeMode: themeMode, locale: locale),
      ),
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await pumpAndSettle();

    return container;
  }
}
