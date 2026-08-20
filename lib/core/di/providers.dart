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
import '../../features/auth/application/sign_out_controller.dart';
import '../../features/auth/application/sign_up_controller.dart';
import '../../features/auth/application/sign_up_state.dart';
import '../../features/auth/data/core_auth_gateway.dart';
import '../../features/auth/domain/auth_gateway.dart';
import '../../features/library_sources/application/library_sources_controller.dart';
import '../../features/library_sources/application/library_sources_state.dart';
import '../../features/catalog/application/dashboard_controller.dart';
import '../../features/catalog/application/file_details_controller.dart';
import '../../features/catalog/application/music_metadata_editor.dart';
import '../../features/catalog/application/video_metadata_editor.dart';
import '../../features/catalog/application/layout_controller.dart';
import '../../features/catalog/application/listing_controller.dart';
import '../../features/catalog/application/listing_view_controller.dart';
import '../../features/catalog/application/search_controller.dart';
import '../../features/catalog/application/catalog_session_activity.dart';
import '../../features/catalog/data/core_catalog_gateway.dart';
import '../../features/catalog/domain/catalog_file.dart';
import '../../features/catalog/domain/library_type.dart';
import '../../features/catalog/domain/catalog_gateway.dart';
import '../../features/catalog/domain/file_details.dart';
import '../../features/library_sources/application/index_runs_controller.dart';
import '../../features/library_sources/application/index_runs_state.dart';
import '../../features/library_sources/application/index_session_activity.dart';
import '../../features/library_sources/data/core_index_gateway.dart';
import '../../features/library_sources/data/disk_folder_probe.dart';
import '../../features/library_sources/data/native_folder_picker.dart';
import '../../features/library_sources/data/settings_library_source_store.dart';
import '../../features/library_sources/domain/folder_picker.dart';
import '../../features/library_sources/domain/index_gateway.dart';
import '../../features/library_sources/domain/library_source_store.dart';
import '../../features/shell/application/preferences_controller.dart';
import '../../features/shell/application/preferences_state.dart';
import '../../features/shell/application/shell_controller.dart';
import '../../features/shell/data/desktop_window_placement.dart';
import '../../features/shell/domain/session_activity.dart';
import '../../features/tracking/data/core_watch_progress_gateway.dart';
import '../../features/tracking/domain/watch_progress_gateway.dart';
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

/// The core's indexing operations (UC-06).
final indexGatewayProvider = Provider<IndexGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError('the index gateway was read before the core was loaded');
  }

  return CoreIndexGateway(core);
});

/// How often an in-flight run's status is read (FR-LB-07).
///
/// The core publishes a status query and no callback, so the run is followed
/// by asking. Injected so a test drives the observation directly instead of
/// waiting on a clock.
final runPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// The index runs the application is following (UC-06).
final indexRunsControllerProvider =
    NotifierProvider<IndexRunsController, IndexRunsState>(
      IndexRunsController.new,
    );

/// The core's catalog queries (UC-09).
final catalogGatewayProvider = Provider<CatalogGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError('the catalog gateway was read before the core was loaded');
  }

  return CoreCatalogGateway(core);
});

/// The selected type's files (UC-09).
final listingControllerProvider =
    AsyncNotifierProvider<ListingController, List<CatalogFile>>(
      ListingController.new,
    );

/// Every type's item count, for the navigation panel (FR-CT-01).
final typeCountsControllerProvider =
    AsyncNotifierProvider<TypeCountsController, Map<LibraryType, int>>(
      TypeCountsController.new,
    );

/// The layout each file type is drawn in (UC-10).
final layoutControllerProvider =
    NotifierProvider<LayoutController, LayoutState>(LayoutController.new);

/// What the owner has typed into the search (UC-11).
final searchTermProvider = NotifierProvider<SearchTermController, String>(
  SearchTermController.new,
);

/// The catalog the search matches against (UC-11).
final catalogSearchProvider =
    AsyncNotifierProvider<CatalogSearchController, CatalogSearchIndex>(
      CatalogSearchController.new,
    );

/// How each file type's listing is filtered and ordered (UC-12).
final listingViewControllerProvider =
    NotifierProvider<ListingViewController, ListingViewState>(
      ListingViewController.new,
    );

/// Which file's details are open, or `null` for none (UC-13).
final openFileProvider = NotifierProvider<OpenFileController, String?>(
  OpenFileController.new,
);

/// The open file's details (UC-13).
final fileDetailsControllerProvider =
    AsyncNotifierProvider<FileDetailsController, FileDetails?>(
      FileDetailsController.new,
    );

/// The most recently added files, for the dashboard (UC-14).
final recentFilesProvider =
    AsyncNotifierProvider<RecentFilesController, List<CatalogFile>>(
      RecentFilesController.new,
    );

/// The open metadata form (UC-15).
final musicMetadataEditorProvider =
    NotifierProvider<MusicMetadataEditor, MusicEditorState>(
      MusicMetadataEditor.new,
    );

/// The core's watch-progress read (UC-16 AF-03).
///
/// Bound here for the one question UC-16 asks of it; UC-29 and UC-30 grow it
/// into the watchlists they present.
final watchProgressGatewayProvider = Provider<WatchProgressGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the watch progress gateway was read before the core was loaded',
    );
  }

  return CoreWatchProgressGateway(core);
});

/// The open video metadata form (UC-16).
final videoMetadataEditorProvider =
    NotifierProvider<VideoMetadataEditor, VideoEditorState>(
      VideoMetadataEditor.new,
    );

/// Everything that runs for the length of a session (UC-03, FR-AU-09).
///
/// The list is the registration point sign-out reads: a use case that opens
/// something belonging to the session — a player, an editor — adds its
/// activity here and changes nothing in the authentication layer.
final sessionActivitiesProvider = Provider<List<SessionActivity>>(
  (ref) => [CatalogSessionActivity(ref), IndexSessionActivity(ref)],
);

/// Ends the session on request (UC-03).
final signOutControllerProvider = Provider<SignOutController>(
  SignOutController.new,
);
