import 'dart:io';

import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/startup/core_paths.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Riverpod 3 moved `Override` out of the main export surface; it is the type of
// the list ProviderContainer and ProviderScope already take.
import 'package:riverpod/misc.dart';

import 'fake_auth_gateway.dart';
import 'fake_core_client.dart';
import 'in_memory_settings_store.dart';

/// The overrides that replace every outward dependency with a fake (IR-07,
/// IR-14).
///
/// This is the proof that the composition root is overridable wholesale: a test
/// substitutes the bindings and nothing in the application knows the difference.
List<Override> fakeCoreOverrides({
  CoreClient? core,
  SettingsStore? settings,
  String? libraryPath,
  String? databasePath,
  Future<CoreClient> Function(String)? loadCore,
  Future<SettingsStore> Function()? loadSettings,
}) {
  final directory = Directory.systemTemp.createTempSync('alexandria_test');
  addTearDown(() => directory.deleteSync(recursive: true));

  final resolvedLibrary = libraryPath ?? '${directory.path}/fake_core.dll';

  // A real file on the default path, because startup step 1 checks the
  // filesystem before it loads anything, and faking that check would leave the
  // branch that actually runs in production untested.
  //
  // A caller-supplied path is left alone: that is how a test asks for the
  // library to be *missing*.
  if (libraryPath == null) {
    File(resolvedLibrary).writeAsStringSync('not a real library');
  }

  return [
    corePathsProvider.overrideWithValue(
      CorePaths(
        environment: {
          CorePaths.libraryPathVariable: resolvedLibrary,
          CorePaths.databasePathVariable:
              databasePath ?? '${directory.path}/catalog.db',
        },
      ),
    ),
    coreLoaderProvider.overrideWithValue(
      loadCore ?? (_) async => core ?? FakeCoreClient(),
    ),
    settingsLoaderProvider.overrideWithValue(
      loadSettings ?? () async => settings ?? InMemorySettingsStore(),
    ),
  ];
}

/// A [ProviderContainer] with every outward dependency faked.
///
/// [overrides] replaces the default set rather than adding to it — Riverpod
/// rejects overriding the same provider twice in one container, so a test that
/// wants a different fake passes its own `fakeCoreOverrides(...)`.
ProviderContainer buildTestContainer({List<Override>? overrides}) {
  final container = ProviderContainer(
    overrides: overrides ?? fakeCoreOverrides(),
  );
  addTearDown(container.dispose);
  return container;
}

/// A signed-in [ProviderContainer] with [gateway] as the catalog gateway.
///
/// For an application-level test that only cares about the catalog: no
/// startup sequence and no widget tree, just a session already established so
/// a controller that reads [sessionControllerProvider] for a credential finds
/// one.
ProviderContainer testContainer({required CatalogGateway gateway}) {
  final container = ProviderContainer(
    overrides: [catalogGatewayProvider.overrideWithValue(gateway)],
  );
  addTearDown(container.dispose);

  // No startup ever runs over this container, so it is honest about never
  // having a core to re-check against. `establish`'s own unawaited call to
  // `begin()` (FR-LB-21) does still reach for one that was never loaded — a
  // scenario this helper's callers have nothing to do with — but
  // `SessionController` now catches and logs that rather than letting it
  // become an unhandled zone error, so nothing here needs to pre-empt it.
  container
      .read(sessionControllerProvider.notifier)
      .establish(FakeAuthGateway.defaultSession);

  return container;
}

/// Pumps the whole application with faked dependencies.
///
/// [locale] and [themeMode] let one test assert both languages and both themes,
/// which the Testing Specification treats as test surface rather than review
/// surface (§2.5).
extension PumpAlexandria on WidgetTester {
  /// Builds [AlexandriaApp] inside a scope carrying [overrides].
  ///
  /// [overrides] replaces the default set, as in [buildTestContainer].
  Future<ProviderContainer> pumpAlexandria({
    List<Override>? overrides,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: overrides ?? fakeCoreOverrides(),
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );

    // A single frame, not pumpAndSettle: the idle state shows the progress
    // indicator, whose animation never settles. The caller drives startup and
    // settles once it has reached a state that stops animating.
    await pump();

    return container;
  }
}
