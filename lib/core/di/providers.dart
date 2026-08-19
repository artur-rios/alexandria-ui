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

import '../../features/auth/application/auth_entry_controller.dart';
import '../../features/auth/application/login_controller.dart';
import '../../features/auth/application/login_state.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/application/sign_up_controller.dart';
import '../../features/auth/application/sign_up_state.dart';
import '../../features/auth/data/core_auth_gateway.dart';
import '../../features/auth/domain/auth_gateway.dart';
import '../../features/shell/application/shell_controller.dart';
import '../../features/shell/data/desktop_window_placement.dart';
import '../../features/shell/domain/shell_destination.dart';
import '../../features/shell/domain/window_placement.dart';
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

/// The core's authentication operations (UC-02).
///
/// Reads the loaded core from the startup controller, so it is only usable
/// once startup has reached [StartupReady] — which is exactly when the login
/// screen is presented. A test overrides this with a fake gateway and never
/// reaches the FFI boundary at all (Testing Specification §2.3).
final authGatewayProvider = Provider<AuthGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the authentication gateway was read before the core was loaded',
    );
  }

  return CoreAuthGateway(core);
});

/// The owner's session, held in memory for the run (FR-AU-05).
final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// The login form's state (UC-02).
final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);

/// The sign-up form's state (UC-01).
final signUpControllerProvider =
    NotifierProvider<SignUpController, SignUpState>(SignUpController.new);

/// Which screen a session-less owner is shown (FR-AU-01).
final authEntryProvider =
    NotifierProvider<AuthEntryController, AuthEntry>(AuthEntryController.new);

/// The language the owner chose, or `null` to follow the system.
final localeProvider = Provider<Locale?>((ref) {
  final startup = ref.watch(startupControllerProvider);
  if (startup is! StartupReady) return null;

  return ref.read(startupControllerProvider.notifier).settings?.locale;
});

/// Which area of the shell the owner is in (UC-38).
final shellControllerProvider =
    NotifierProvider<ShellController, ShellDestination>(ShellController.new);

/// The running window (FR-UX-03).
///
/// Bound here so a test substitutes a fake placement and the shell's restore
/// rule is exercised without a desktop window; the application binds the
/// implementation over `window_manager`.
final windowPlacementProvider = Provider<WindowPlacement>(
  (ref) => const DesktopWindowPlacement(),
);
