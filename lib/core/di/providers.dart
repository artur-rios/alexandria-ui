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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
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
import '../../features/catalog/application/file_rename_controller.dart';
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
import '../../features/catalog/domain/file_name.dart';
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
import '../../features/editing/application/editing_session_activity.dart';
import '../../features/editing/application/text_editor_controller.dart';
import '../../features/editing/data/core_text_content_gateway.dart';
import '../../features/editing/domain/text_content_gateway.dart';
import '../../features/playback/application/audio_playback_controller.dart';
import '../../features/playback/application/audio_playback_session.dart';
import '../../features/playback/application/music_library_controller.dart';
import '../../features/playback/application/video_playback_controller.dart';
import '../../features/playback/application/video_playback_session.dart';
import '../../features/playback/data/core_playback_source_gateway.dart';
import '../../features/playback/data/media_kit_player.dart';
import '../../features/playback/data/settings_playback_position_store.dart';
import '../../features/playback/domain/media_player.dart';
import '../../features/playback/domain/playback_position_store.dart';
import '../../features/playback/domain/music_grouping.dart';
import '../../features/playback/domain/playback_session.dart';
import '../../features/playback/domain/playback_source.dart';
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

/// Where the core says a file is, for a player to open (UC-19, FR-PL-01).
final playbackSourceGatewayProvider = Provider<PlaybackSourceGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the playback source gateway was read before the core was loaded',
    );
  }

  return CorePlaybackSourceGateway(core);
});

/// The video playback engine (UC-19).
///
/// Bound here because it is a native library: a widget test substitutes a fake
/// and exercises every flow around it without libmpv (Testing Specification
/// §2.3).
final videoPlayerProvider = Provider<MediaPlayer>((ref) {
  final player = MediaKitPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

/// The widget that draws the decoded frames (UC-19, FR-PL-01).
///
/// The engine owns the surface, so this follows the engine's binding: the
/// application draws media_kit's, and a test draws a placeholder.
final videoSurfaceProvider = Provider<WidgetBuilder>((ref) {
  final player = ref.read(videoPlayerProvider);
  if (player is! MediaKitPlayer) return (context) => const SizedBox.expand();

  return (context) => mkv.Video(controller: player.videoController);
});

/// The resume positions (UC-19, FR-PL-09, System Requirements §4.10).
final playbackPositionsProvider = Provider<PlaybackPositionStore>((ref) {
  final settings = ref.read(startupControllerProvider.notifier).settings;
  if (settings == null) {
    throw StateError(
      'the playback positions were read before settings were loaded',
    );
  }

  return SettingsPlaybackPositionStore(settings);
});

/// The audio playback engine (UC-20).
///
/// Its own engine rather than the video player's: FR-PL-08 stops one when the
/// other starts, and sharing an engine would make that rule a matter of who
/// called `open` last rather than something the application decides.
final audioPlayerProvider = Provider<MediaPlayer>((ref) {
  final player = MediaKitPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

/// Every audio file with the metadata a queue is grouped by (UC-20, FR-PL-06).
final musicLibraryProvider =
    AsyncNotifierProvider<MusicLibraryController, List<MusicEntry>>(
      MusicLibraryController.new,
    );

/// The persistent audio player (UC-20).
final audioPlaybackControllerProvider =
    NotifierProvider<AudioPlaybackController, AudioPlaybackState>(
      AudioPlaybackController.new,
    );

/// The video player (UC-19).
final videoPlaybackControllerProvider =
    NotifierProvider<VideoPlaybackController, VideoPlaybackState>(
      VideoPlaybackController.new,
    );

/// The players, of which at most one runs at a time (FR-PL-08).
///
/// The registry UC-19 AF-05 and UC-20 AF-05 are both read from: a player added
/// here is stopped by every other one starting, and neither controller has to
/// know the other exists.
final playbackSessionsProvider = Provider<List<PlaybackSession>>(
  (ref) => [VideoPlaybackSession(ref), AudioPlaybackSession(ref)],
);

/// The core's text content operations (UC-18, FR-ME-06, FR-ME-08).
final textContentGatewayProvider = Provider<TextContentGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the text content gateway was read before the core was loaded',
    );
  }

  return CoreTextContentGateway(core);
});

/// The open text editor (UC-18).
final textEditorControllerProvider =
    NotifierProvider<TextEditorController, TextEditorState>(
      TextEditorController.new,
    );

/// The filesystem the application is running on (UC-17 main flow step 2).
///
/// Bound here rather than read from `Platform` where it is needed, so a test
/// can hold a name up against both hosts' rules — the Windows ones are not
/// reachable from a Linux CI runner otherwise, and they are half of what
/// FR-ME-04 asks for.
final hostFileSystemProvider = Provider<HostFileSystem>(
  (ref) => Platform.isWindows ? HostFileSystem.windows : HostFileSystem.posix,
);

/// The open rename dialog (UC-17).
final fileRenameControllerProvider =
    NotifierProvider<FileRenameController, RenameState>(
      FileRenameController.new,
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
  (ref) => [
    CatalogSessionActivity(ref),
    IndexSessionActivity(ref),
    // UC-18's editor, which is the first thing in the application that can
    // hold something the owner has not saved (UC-03 AF-01).
    EditingSessionActivity(ref),
  ],
);

/// Ends the session on request (UC-03).
final signOutControllerProvider = Provider<SignOutController>(
  SignOutController.new,
);
