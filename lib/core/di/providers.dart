/// The single composition root (IR-07).
///
/// Every outward dependency is bound here and nowhere else, so a test overrides
/// the binding rather than reaching into the widget tree or patching a global.
/// The provider graph is also the one place allowed to see every layer — which
/// is why `lib/core/di/` sits outside the layered tree the analyzer rule
/// polices.
///
/// A use case adds its gateway here and changes nothing else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bindings/core_client.dart';
import '../settings/settings_store.dart';
import '../settings/shared_preferences_settings_store.dart';
import '../startup/core_paths.dart';
import '../startup/startup_controller.dart';
import '../startup/startup_state.dart';

/// Resolves the core library and database paths from the running platform.
final corePathsProvider = Provider<CorePaths>(
  (ref) => CorePaths.fromPlatform(),
);

/// Loads the core over FFI.
///
/// Overridden in tests with a fake that never touches a native library
/// (Testing Specification §2.3).
final coreLoaderProvider = Provider<Future<CoreClient> Function(String)>(
  (ref) => FfiCoreClient.load,
);

/// Loads the owner's local settings.
final settingsLoaderProvider = Provider<Future<SettingsStore> Function()>(
  (ref) => SharedPreferencesSettingsStore.load,
);

/// Runs the startup sequence and holds its state.
///
/// It reads the three providers above in its `build`, so overriding any of them
/// substitutes the whole dependency — which is what a widget test does instead
/// of loading a native library.
final startupControllerProvider =
    NotifierProvider<StartupController, StartupState>(StartupController.new);

/// The theme the owner chose. [ThemeMode.system] until settings have loaded.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final startup = ref.watch(startupControllerProvider);
  if (startup is! StartupReady) return ThemeMode.system;

  return ref.read(startupControllerProvider.notifier).settings?.themeMode ??
      ThemeMode.system;
});

/// The language the owner chose, or `null` to follow the system.
final localeProvider = Provider<Locale?>((ref) {
  final startup = ref.watch(startupControllerProvider);
  if (startup is! StartupReady) return null;

  return ref.read(startupControllerProvider.notifier).settings?.locale;
});
