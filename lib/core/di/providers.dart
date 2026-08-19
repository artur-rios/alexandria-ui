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
import '../../features/auth/application/change_credentials_controller.dart';
import '../../features/auth/application/change_credentials_state.dart';
import '../../features/auth/application/login_controller.dart';
import '../../features/auth/application/login_state.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/application/sign_up_controller.dart';
import '../../features/auth/application/sign_up_state.dart';
import '../../features/auth/data/core_auth_gateway.dart';
import '../../features/auth/domain/auth_gateway.dart';
import '../../features/library_sources/application/library_sources_controller.dart';
import '../../features/library_sources/application/library_sources_state.dart';
import '../../features/library_sources/data/disk_folder_probe.dart';
import '../../features/library_sources/data/native_folder_picker.dart';
import '../../features/library_sources/data/settings_library_source_store.dart';
import '../../features/library_sources/domain/folder_picker.dart';
import '../../features/library_sources/domain/library_source_store.dart';
import '../../features/shell/application/preferences_controller.dart';
import '../../features/shell/application/preferences_state.dart';
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

/// The owner's theme and language, and whether the last change was saved
/// (UC-39).
final preferencesControllerProvider =
    NotifierProvider<PreferencesController, PreferencesState>(
      PreferencesController.new,
    );

/// The theme the owner chose. [ThemeMode.system] until settings have loaded.
///
/// A thin read over [preferencesControllerProvider] rather than its own read
/// of the settings store: the store answers what was saved, and after UC-39
/// what is *applied* can differ from it for a session (AF-02).
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(preferencesControllerProvider).themeMode,
);

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
final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

/// The credential-change form's state (UC-04).
final changeCredentialsControllerProvider =
    NotifierProvider<ChangeCredentialsController, ChangeCredentialsState>(
      ChangeCredentialsController.new,
    );

/// The sign-up form's state (UC-01).
final signUpControllerProvider =
    NotifierProvider<SignUpController, SignUpState>(SignUpController.new);

/// Which screen a session-less owner is shown (FR-AU-01).
final authEntryProvider = NotifierProvider<AuthEntryController, AuthEntry>(
  AuthEntryController.new,
);

/// The language the owner chose, or `null` to follow the system.
final localeProvider = Provider<Locale?>(
  (ref) => ref.watch(preferencesControllerProvider).locale,
);

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

/// The clock (Testing Specification §6.2).
///
/// Bound here so nothing below reaches for `DateTime.now()` directly and a
/// test can register a folder at a time it chose.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The platform's native folder picker (FR-LB-01).
final folderPickerProvider = Provider<FolderPicker>(
  (ref) => const NativeFolderPicker(),
);

/// Whether a folder on disk exists and can be read (FR-LB-02).
final folderProbeProvider = Provider<FolderProbe>(
  (ref) => const DiskFolderProbe(),
);

/// Where the registered library folders are kept (FR-LB-03).
///
/// Reads the settings store the startup sequence loaded, so it is only usable
/// once startup has reached ready — which is when the shell, and so the
/// library-sources screen, is reachable.
final librarySourceStoreProvider = Provider<LibrarySourceStore>((ref) {
  final settings = ref.read(startupControllerProvider.notifier).settings;
  if (settings == null) {
    throw StateError(
      'the library source store was read before settings were loaded',
    );
  }

  return SettingsLibrarySourceStore(settings);
});

/// The registered library folders and the screen that manages them (UC-05).
final librarySourcesControllerProvider =
    NotifierProvider<LibrarySourcesController, LibrarySourcesState>(
      LibrarySourcesController.new,
    );
