import 'package:alexandria_desktop/core/bindings/core_client.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/settings/settings_store.dart';
import 'package:alexandria_desktop/core/startup/core_paths.dart';
import 'package:alexandria_desktop/core/startup/startup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_core_client.dart';
import '../../support/in_memory_settings_store.dart';
import '../../support/test_container.dart';

/// IR-07: a single composition root binding every gateway interface to its
/// implementation, overridable wholesale by a test.
void main() {
  test('GivenTheDefaultGraph_WhenItIsBuilt_ThenEveryDependencyIsBound', () {
    final container = buildTestContainer();

    expect(container.read(corePathsProvider), isA<CorePaths>());
    expect(container.read(coreLoaderProvider), isNotNull);
    expect(container.read(settingsLoaderProvider), isNotNull);
    expect(container.read(startupControllerProvider), isA<StartupIdle>());
  });

  test('GivenAFakeCore_WhenTheGraphIsOverridden_ThenNoNativeLibraryIsLoaded',
      () async {
    final fake = FakeCoreClient();
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(core: fake),
    );

    await container.read(startupControllerProvider.notifier).start();

    expect(
      container.read(startupControllerProvider.notifier).core,
      same(fake),
      reason:
          'this substitution is what makes the whole application testable '
          'without a native library present',
    );
  });

  test('GivenAFakeSettingsStore_WhenTheGraphIsOverridden_ThenItIsTheOneUsed',
      () async {
    final settings = InMemorySettingsStore(themeMode: ThemeMode.dark);
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(settings: settings),
    );

    await container.read(startupControllerProvider.notifier).start();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('GivenAStoredLocale_WhenStartupSettles_ThenTheGraphExposesIt', () async {
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(
        settings: InMemorySettingsStore(locale: const Locale('pt', 'BR')),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();

    expect(container.read(localeProvider), const Locale('pt', 'BR'));
  });

  test('GivenStartupHasNotSettled_WhenTheThemeIsRead_ThenItFollowsTheSystem',
      () {
    final container = buildTestContainer();

    expect(
      container.read(themeModeProvider),
      ThemeMode.system,
      reason:
          'the owner has not been asked yet; guessing would flash the wrong '
          'theme on every launch',
    );
    expect(container.read(localeProvider), isNull);
  });

  test('GivenTheGraph_WhenItIsDisposed_ThenTheLoadedCoreIsReleased', () async {
    final fake = FakeCoreClient();
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(core: fake),
    );
    await container.read(startupControllerProvider.notifier).start();

    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(
      fake.disposeCount,
      greaterThanOrEqualTo(1),
      reason: 'a graph that leaks the worker isolate leaks it per test too',
    );
  });

  test('GivenTheLoaderBinding_WhenItIsRead_ThenItsTypeIsTheGatewayInterface',
      () {
    final container = buildTestContainer();

    // The binding is declared in terms of CoreClient, not FfiCoreClient: the
    // future HTTP transport the Technology Stack Document mentions is a
    // substitution here rather than a rewrite everywhere.
    final Future<CoreClient> Function(String) loader = container.read(
      coreLoaderProvider,
    );
    final Future<SettingsStore> Function() settings = container.read(
      settingsLoaderProvider,
    );

    expect(loader, isNotNull);
    expect(settings, isNotNull);
  });
}
