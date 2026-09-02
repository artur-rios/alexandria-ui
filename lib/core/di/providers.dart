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

import '../failures/failure.dart';
import '../../features/auth/application/auth_entry_controller.dart';
import '../../features/auth/application/change_credentials_controller.dart';
import '../../features/auth/application/change_credentials_state.dart';
import '../../features/auth/application/login_controller.dart';
import '../../features/auth/application/login_state.dart';
import '../../features/auth/application/recovery_codes_controller.dart';
import '../../features/auth/application/recovery_controller.dart';
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
import '../../features/catalog/application/in_progress.dart';
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
import '../../features/catalog/domain/file_type.dart';
import '../../features/catalog/domain/catalog_gateway.dart';
import '../../features/catalog/domain/file_details.dart';
import '../../features/catalog/domain/file_name.dart';
import '../../features/library_sources/application/active_runs_controller.dart';
import '../../features/library_sources/application/active_runs_state.dart';
import '../../features/library_sources/application/index_runs_controller.dart';
import '../../features/library_sources/application/run_failures_controller.dart';
import '../../features/library_sources/application/index_runs_state.dart';
import '../../features/library_sources/application/index_session_activity.dart';
import '../../features/library_sources/data/core_index_gateway.dart';
import '../../features/library_sources/data/disk_folder_probe.dart';
import '../../features/library_sources/data/native_folder_picker.dart';
import '../../features/library_sources/data/settings_library_source_store.dart';
import '../../features/library_sources/domain/folder_picker.dart';
import '../../features/library_sources/domain/index_gateway.dart';
import '../../features/library_sources/domain/index_run.dart';
import '../../features/library_sources/domain/library_source_store.dart';
import '../../features/shell/application/preferences_controller.dart';
import '../../features/shell/application/preferences_state.dart';
import '../../features/shell/application/shell_controller.dart';
import '../../features/shell/data/desktop_window_placement.dart';
import '../../features/editing/application/editing_session_activity.dart';
import '../../features/editing/application/text_editor_controller.dart';
import '../../features/editing/data/core_text_content_gateway.dart';
import '../../features/editing/domain/text_content_gateway.dart';
import '../../features/organization/application/bookmarks_controller.dart';
import '../../features/organization/application/collection_candidates_controller.dart';
import '../../features/organization/application/collection_members_controller.dart';
import '../../features/organization/application/collections_controller.dart';
import '../../features/organization/data/core_bookmark_gateway.dart';
import '../../features/organization/data/core_collection_gateway.dart';
import '../../features/organization/data/url_launcher_browser.dart';
import '../../features/organization/domain/bookmark.dart';
import '../../features/organization/domain/bookmark_gateway.dart';
import '../../features/organization/domain/collection.dart';
import '../../features/organization/domain/collection_gateway.dart';
import '../../features/organization/domain/browser_launcher.dart';
import '../../features/playback/application/album_animation_controller.dart';
import '../../features/playback/application/album_cover_controller.dart';
import '../../features/playback/application/audio_playback_controller.dart';
import '../../features/playback/application/audio_playback_session.dart';
import '../../features/playback/application/music_browse_controller.dart';
import '../../features/playback/application/music_library_controller.dart';
import '../../features/playback/application/playback_session_activity.dart';
import '../../features/playback/application/video_playback_controller.dart';
import '../../features/playback/application/video_playback_session.dart';
import '../../features/playback/data/core_playback_source_gateway.dart';
import '../../features/playback/data/media_kit_player.dart';
import '../../features/playback/data/settings_playback_position_store.dart';
import '../../features/playback/domain/album_cover.dart';
import '../../features/playback/domain/media_player.dart';
import '../../features/playback/domain/playback_position_store.dart';
import '../../features/playback/domain/playback_session.dart';
import '../../features/playback/domain/playback_source.dart';
import '../../features/playlists/application/playlist_detail_controller.dart';
import '../../features/playlists/application/playlists_controller.dart';
import '../../features/enrichment/application/artist_portrait_backfill_controller.dart';
import '../../features/enrichment/application/enrichment_run_controller.dart';
import '../../features/enrichment/application/enrichment_sweep_controller.dart';
import '../../features/enrichment/application/track_enrichment_controller.dart';
import '../../features/enrichment/domain/track_enrichment.dart';
import '../../features/enrichment/data/core_enrichment_gateway.dart';
import '../../features/libraries/application/libraries_controller.dart';
import '../../features/libraries/data/core_library_gateway.dart';
import '../../features/libraries/domain/library.dart';
import '../../features/libraries/domain/library_gateway.dart';
import '../../features/enrichment/domain/enrichment_gateway.dart';
import '../../features/playlists/data/core_playlist_gateway.dart';
import '../../features/playlists/domain/playlist.dart';
import '../../features/playlists/domain/playlist_gateway.dart';
import '../../features/shell/domain/session_activity.dart';
import '../../features/viewers/application/comic_viewer_controller.dart';
import '../../features/viewers/application/document_viewer_controller.dart';
import '../../features/viewers/application/image_viewer_controller.dart';
import '../../features/viewers/application/page_viewer_controller.dart';
import '../../features/viewers/data/disk_page_gateway.dart';
import '../../features/viewers/domain/page_content.dart';
import '../../features/viewers/data/core_comic_gateway.dart';
import '../../features/viewers/data/epub_document_gateway.dart';
import '../../features/viewers/data/settings_reading_position_store.dart';
import '../../features/viewers/domain/comic_gateway.dart';
import '../../features/viewers/domain/document_gateway.dart';
import '../../features/viewers/domain/reading_position_store.dart';
import '../../features/viewers/domain/viewer_registry.dart';
import '../../features/lifecycle/application/deleted_items_controller.dart';
import '../../features/lifecycle/application/deletion_controller.dart';
import '../../features/lifecycle/application/missing_files_controller.dart';
import '../../features/lifecycle/application/purge_controller.dart';
import '../../features/lifecycle/application/open_file_holds.dart';
import '../../features/lifecycle/data/core_lifecycle_gateway.dart';
import '../../features/lifecycle/data/core_retention_gateway.dart';
import '../../features/lifecycle/domain/deleted_record.dart';
import '../../features/lifecycle/domain/file_hold.dart';
import '../../features/lifecycle/domain/lifecycle_gateway.dart';
import '../../features/lifecycle/domain/retention.dart';
import '../../features/playback/application/playback_file_holds.dart';
import '../../features/tracking/application/reading_lists_controller.dart';
import '../../features/tracking/application/reading_progress_editor.dart';
import '../../features/tracking/application/tracked_reading_items_controller.dart';
import '../../features/tracking/application/tracked_videos_controller.dart';
import '../../features/tracking/application/watch_progress_editor.dart';
import '../../features/tracking/application/watchlists_controller.dart';
import '../../features/tracking/data/core_watch_progress_gateway.dart';
import '../../features/tracking/data/core_reading_list_gateway.dart';
import '../../features/tracking/data/core_watchlist_gateway.dart';
import '../../features/tracking/domain/reading_list.dart';
import '../../features/tracking/domain/reading_list_gateway.dart';
import '../../features/tracking/domain/watchlist.dart';
import '../../features/tracking/domain/watchlist_gateway.dart';
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

/// The owner's account and how many recovery codes remain (UC-42).
final accountControllerProvider =
    AsyncNotifierProvider<AccountController, AccountSummary?>(
      AccountController.new,
    );

/// Replacing the whole recovery-code set (UC-42).
final regenerateRecoveryCodesControllerProvider =
    NotifierProvider<RegenerateRecoveryCodesController, RegenerateRefusal?>(
      RegenerateRecoveryCodesController.new,
    );

/// Spending a recovery code on a new password (UC-41).
final recoveryControllerProvider =
    NotifierProvider<RecoveryController, RecoveryState>(RecoveryController.new);

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

/// Where the registered source folders are kept (FR-LB-03).
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

/// The registered source folders and the screen that manages them (UC-05).
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

/// Every run the core still has outstanding, as one list (FR-LB-15 /
/// core FR-FC-35).
///
/// The single source of truth for what is running, read directly from the
/// core's `listActiveRuns` rather than reconstructed from per-folder state.
final activeRunsControllerProvider =
    NotifierProvider<ActiveRunsController, ActiveRunsState>(
      ActiveRunsController.new,
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
    AsyncNotifierProvider<TypeCountsController, Map<FileType, int>>(
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

/// The files one run could not record (UC-06 AF-08 / core FR-FC-42).
///
/// Family-keyed by run id and auto-disposing: this is read when the owner
/// opens one run's failures and is of no use afterwards, so it is not kept
/// alive alongside every other run they ever looked at.
final runFailuresProvider =
    AsyncNotifierProvider.family<
      RunFailuresController,
      List<RunFailure>,
      String
    >(RunFailuresController.new, isAutoDispose: true);

/// The most recently added files, for the dashboard (UC-14).
final recentFilesProvider =
    AsyncNotifierProvider<RecentFilesController, List<FileDetails>>(
      RecentFilesController.new,
    );

/// What the owner is part-way through, for the dashboard (UC-14, FR-CT-11).
final inProgressProvider =
    AsyncNotifierProvider<InProgressController, List<InProgressItem>>(
      InProgressController.new,
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
///
/// One gateway call, listing the audio files: the core's listing now answers
/// each row with the same metadata the single-file call does, so this reads
/// the library whole rather than one file at a time.
final musicLibraryProvider =
    AsyncNotifierProvider<MusicLibraryController, MusicLibrary>(
      MusicLibraryController.new,
    );

/// Where the owner is in the music area (UC-46).
final musicBrowseControllerProvider =
    NotifierProvider<MusicBrowseController, MusicBrowseState>(
      MusicBrowseController.new,
    );

/// The persistent audio player (UC-20).
final audioPlaybackControllerProvider =
    NotifierProvider<AudioPlaybackController, AudioPlaybackState>(
      AudioPlaybackController.new,
    );

/// Whether the album animation owes an insertion, and what medium it would
/// show (UC-21).
final albumAnimationControllerProvider =
    NotifierProvider<AlbumAnimationController, AlbumAnimationState>(
      AlbumAnimationController.new,
    );

/// What the current album's case sleeve shows — its own cover, or the
/// designed jacket (UC-21, FR-PL-07, design section 4).
final albumCoverControllerProvider =
    NotifierProvider<AlbumCoverController, AlbumCover>(
      AlbumCoverController.new,
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

/// The viewers, keyed by the type each presents (UC-22, FR-VW-01).
///
/// A registration rather than a conditional in the detail screen: a type gains
/// a viewer by appearing here, and the screens that offer one do not change
/// for it. The types absent from this map are the ones whose use case has not
/// been built, and FR-VW-08 is what the detail view shows for them.
final viewerRegistryProvider = Provider<ViewerRegistry>(
  (ref) => const ViewerRegistry({
    FileType.document: ViewerKind.document,
    FileType.comic: ViewerKind.comic,
    FileType.image: ViewerKind.image,
    FileType.html: ViewerKind.page,
    // A text file has two ways to open: rendered here (UC-25) and edited in
    // UC-18's editor, which the detail view offers beside this one.
    FileType.text: ViewerKind.page,
  }),
);

/// Reads a saved page at the moment it is opened (UC-25, FR-VW-05, FR-VW-06).
final pageGatewayProvider = Provider<PageGateway>(
  (ref) => const DiskPageGateway(),
);

/// The open page (UC-25).
final pageViewerControllerProvider =
    NotifierProvider<PageViewerController, PageViewerState>(
      PageViewerController.new,
    );

/// Whether a file exists on disk (UC-24 AF-01).
///
/// Bound here so a widget test can say a file is absent without one being
/// absent, and so the check is the same one wherever a viewer needs it.
final fileProbeProvider = Provider<bool Function(String)>((ref) => fileExists);

/// The open image, and the listing it was opened from (UC-24).
final imageViewerControllerProvider =
    NotifierProvider<ImageViewerController, ImageViewerState>(
      ImageViewerController.new,
    );

/// Reads a document at the moment it is opened (UC-22, FR-VW-07).
final documentGatewayProvider = Provider<DocumentGateway>(
  (ref) => const EpubDocumentGateway(),
);

/// Where the owner had read to, per file (FR-VW-02).
final readingPositionsProvider = Provider<ReadingPositionStore>((ref) {
  final settings = ref.read(startupControllerProvider.notifier).settings;
  if (settings == null) {
    throw StateError(
      'the reading positions were read before settings were loaded',
    );
  }

  return SettingsReadingPositionStore(settings);
});

/// Reads a comic-book archive a page at a time (UC-23, FR-VW-03).
final comicGatewayProvider = Provider<ComicGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError('the comic gateway was read before the core was loaded');
  }

  return CoreComicGateway(core);
});

/// The open comic (UC-23).
final comicViewerControllerProvider =
    NotifierProvider<ComicViewerController, ComicViewerState>(
      ComicViewerController.new,
    );

/// The open document (UC-22).
final documentViewerControllerProvider =
    NotifierProvider<DocumentViewerController, DocumentViewerState>(
      DocumentViewerController.new,
    );

/// The core's bookmark operations (UC-28, FR-OG-08 … FR-OG-10).
final bookmarkGatewayProvider = Provider<BookmarkGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the bookmark gateway was read before the core was loaded',
    );
  }

  return CoreBookmarkGateway(core);
});

/// The platform's default browser (UC-28, FR-OG-11).
final browserLauncherProvider = Provider<BrowserLauncher>(
  (ref) => const UrlLauncherBrowser(),
);

/// The owner's bookmarks (UC-28).
final bookmarksControllerProvider =
    AsyncNotifierProvider<BookmarksController, List<Bookmark>>(
      BookmarksController.new,
    );

/// The open bookmark form (UC-28).
final bookmarkFormProvider = NotifierProvider<BookmarkForm, BookmarkFormState>(
  BookmarkForm.new,
);

/// The core's watchlist operations (UC-29, UC-30, FR-TR-01 … FR-TR-07).
final watchlistGatewayProvider = Provider<WatchlistGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the watchlist gateway was read before the core was loaded',
    );
  }

  return CoreWatchlistGateway(core);
});

/// The owner's watchlists (UC-29).
final watchlistsControllerProvider =
    AsyncNotifierProvider<WatchlistsController, List<Watchlist>>(
      WatchlistsController.new,
    );

/// The watchlists screen's own state (UC-29).
final watchlistsFormProvider =
    NotifierProvider<WatchlistsForm, WatchlistsState>(WatchlistsForm.new);

/// The tracked videos' names and markings (UC-30 main flow step 2).
final trackedVideosProvider =
    AsyncNotifierProvider<TrackedVideosController, Map<String, TrackedVideo>>(
      TrackedVideosController.new,
    );

/// The progress entry being edited (UC-30).
final watchProgressEditorProvider =
    NotifierProvider<WatchProgressEditor, WatchProgressEditorState>(
      WatchProgressEditor.new,
    );

/// The core's collection operations (UC-26, UC-27, FR-OG-01 ... FR-OG-06).
final collectionGatewayProvider = Provider<CollectionGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the collection gateway was read before the core was loaded',
    );
  }

  return CoreCollectionGateway(core);
});

/// The owner's collections (UC-26).
final collectionsControllerProvider =
    AsyncNotifierProvider<CollectionsController, List<Collection>>(
      CollectionsController.new,
    );

/// The bookmark collections, for filing and filtering (UC-28).
///
/// A collection of the other kind is never offered: the core would refuse a
/// bookmark filed into a file collection, and not offering one is what keeps
/// the owner from meeting that refusal (UC-28 AF-03).
final bookmarkCollectionsProvider = FutureProvider<List<Collection>>((
  ref,
) async {
  final credential = ref.read(sessionControllerProvider.notifier).credential;
  if (credential == null) return const [];

  final browse = await ref
      .read(collectionGatewayProvider)
      .browse(credential: credential, kind: CollectionKind.bookmark);

  return switch (browse) {
    CollectionBrowseLoaded(:final collections) => collections,
    // A listing that will not load leaves the selector empty rather than
    // failing the screen it sits on: filing is optional, and a bookmark is
    // still creatable without it.
    CollectionBrowseFailed() => const <Collection>[],
  };
});

/// Which collection the bookmarks listing is filtered to (UC-28).
final bookmarkCollectionFilterProvider =
    NotifierProvider<BookmarkCollectionFilter, String?>(
      BookmarkCollectionFilter.new,
    );

/// The collection whose members are open, or `null` when none is (UC-27).
final openCollectionProvider = NotifierProvider<OpenCollection, Collection?>(
  OpenCollection.new,
);

/// The open collection's members (UC-27).
final collectionMembersControllerProvider =
    AsyncNotifierProvider<CollectionMembersController, List<CollectionMember>>(
      CollectionMembersController.new,
    );

/// What the open collection could accept (UC-27 main flow step 3).
final collectionCandidatesControllerProvider =
    AsyncNotifierProvider<
      CollectionCandidatesController,
      List<CollectionMember>
    >(CollectionCandidatesController.new);

/// What became of the last membership change (UC-27).
final collectionMembershipFormProvider =
    NotifierProvider<CollectionMembershipForm, MembershipReport>(
      CollectionMembershipForm.new,
    );

/// The collections screen's own state (UC-26).
final collectionsFormProvider =
    NotifierProvider<CollectionsForm, CollectionsState>(CollectionsForm.new);

/// The core's deletion-lifecycle operations (UC-33, FR-LC-01).
final lifecycleGatewayProvider = Provider<LifecycleGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the lifecycle gateway was read before the core was loaded',
    );
  }

  return CoreLifecycleGateway(core);
});

/// Which viewers and editors currently have a file open (UC-33 AF-04).
final openFileHoldsProvider =
    NotifierProvider<OpenFileHolds, List<OpenFileHold>>(OpenFileHolds.new);

/// Everything that can be holding a file open (UC-33 AF-04).
///
/// The players are always registered; a viewer or an editor joins while it is
/// on screen. The deletion asks this list and nothing else, so neither player
/// nor viewer has to know the deletion exists.
final fileHoldsProvider = Provider<List<FileHold>>(
  (ref) => [
    VideoFileHold(ref),
    AudioFileHold(ref),
    ...ref.watch(openFileHoldsProvider),
  ],
);

/// What a deletion is reporting (UC-33).
final deletionControllerProvider =
    NotifierProvider<DeletionController, DeletionState>(DeletionController.new);

/// The core's settings read (UC-34, FR-LC-03).
final retentionGatewayProvider = Provider<RetentionGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the retention gateway was read before the core was loaded',
    );
  }

  return CoreRetentionGateway(core);
});

/// The retention window the core enforces (UC-34).
final retentionWindowProvider =
    AsyncNotifierProvider<RetentionWindowController, int?>(
      RetentionWindowController.new,
    );

/// Everything the core holds as deleted (UC-34).
final deletedItemsControllerProvider =
    AsyncNotifierProvider<DeletedItemsController, List<DeletedRecord>>(
      DeletedItemsController.new,
    );

/// What a restore is reporting (UC-34).
final restoreControllerProvider =
    NotifierProvider<
      RestoreController,
      ({RestoreNotice notice, Failure? refusal})
    >(RestoreController.new);

/// The files the core reports as missing on disk (UC-37).
final missingFilesControllerProvider =
    AsyncNotifierProvider<MissingFilesController, List<FileDetails>>(
      MissingFilesController.new,
    );

/// What a purge is reporting (UC-35, UC-36).
final purgeControllerProvider = NotifierProvider<PurgeController, PurgeState>(
  PurgeController.new,
);

/// The core's reading-list operations (UC-31, UC-32, FR-TR-08 ... FR-TR-14).
final readingListGatewayProvider = Provider<ReadingListGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the reading list gateway was read before the core was loaded',
    );
  }

  return CoreReadingListGateway(core);
});

/// The owner's reading lists (UC-31).
final readingListsControllerProvider =
    AsyncNotifierProvider<ReadingListsController, List<ReadingList>>(
      ReadingListsController.new,
    );

/// The reading-lists screen's own state (UC-31).
final readingListsFormProvider =
    NotifierProvider<ReadingListsForm, ReadingListsState>(ReadingListsForm.new);

/// The core's playlist operations (playlists design).
final playlistGatewayProvider = Provider<PlaylistGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the playlist gateway was read before the core was loaded',
    );
  }

  return CorePlaylistGateway(core);
});

/// The owner's playlists (playlists design).
final playlistsControllerProvider =
    AsyncNotifierProvider<PlaylistsController, List<Playlist>>(
      PlaylistsController.new,
    );

/// The core's music enrichment operations (music enrichment design).
final enrichmentGatewayProvider = Provider<EnrichmentGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError(
      'the enrichment gateway was read before the core was loaded',
    );
  }

  return CoreEnrichmentGateway(core);
});

/// What enrichment holds for one track, keyed by track and artist (music
/// enrichment design).
///
/// Auto-disposed, which a family is not by default: a player moves through a
/// queue, and without it an entry for every track ever played is held for
/// the life of the container and never read again — so a track enriched
/// after it was first shown would never pick that up.
final trackEnrichmentControllerProvider =
    AsyncNotifierProvider.family<
      TrackEnrichmentController,
      TrackEnrichment,
      TrackEnrichmentKey
    >(TrackEnrichmentController.new, isAutoDispose: true);

/// The startup pass that fetches the photograph of every artist that has
/// none (FR-PL-15).
///
/// Kept alive by the shell rather than by whoever is looking at the artists
/// list: it is a startup job, and an owner who never opens the music area is
/// still an owner whose artists have faces the next time they do.
final artistPortraitBackfillProvider =
    NotifierProvider<ArtistPortraitBackfillController, ArtistPortraitBackfill>(
      ArtistPortraitBackfillController.new,
    );

/// The core's library operations (libraries design).
final libraryGatewayProvider = Provider<LibraryGateway>((ref) {
  final core = ref.read(startupControllerProvider.notifier).core;
  if (core == null) {
    throw StateError('the library gateway was read before the core was loaded');
  }

  return CoreLibraryGateway(core);
});

/// The registered libraries.
final librariesControllerProvider =
    AsyncNotifierProvider<LibrariesController, List<Library>>(
      LibrariesController.new,
    );

/// One level of one library's tree, keyed by library and folder.
///
/// Auto-disposed, which a family is not by default: browsing a course walks
/// through many folders, and an entry for every one ever opened would be
/// held for the life of the container and never read again — so a folder
/// whose contents changed would keep showing what it held the first time.
final libraryTreeControllerProvider =
    AsyncNotifierProvider.family<
      LibraryTreeController,
      LibraryListing?,
      LibraryLocation
    >(LibraryTreeController.new, isAutoDispose: true);

/// A library-wide lookup, walked a batch at a time.
final enrichmentSweepControllerProvider =
    NotifierProvider<EnrichmentSweepController, SweepState>(
      EnrichmentSweepController.new,
    );

/// A lookup the owner asked for, and what it concluded.
final enrichmentRunControllerProvider =
    NotifierProvider<EnrichmentRunController, EnrichmentRunState>(
      EnrichmentRunController.new,
    );

/// The playlists screen's own state.
final playlistsFormProvider = NotifierProvider<PlaylistsForm, PlaylistsState>(
  PlaylistsForm.new,
);

/// One playlist and its tracks, keyed by playlist uuid (playlists design
/// section 3).
///
/// Auto-disposed, which a family is not by default (`isAutoDispose` defaults
/// to `false` in `AsyncNotifierProviderFamilyBuilder.call`). Without it the
/// entry for every playlist ever opened is cached for the life of the
/// container and never read again: reopening a playlist would show whatever
/// it held the first time, so a track added from the music area — where
/// `PlaylistsForm.addEntries` deliberately does not reload this provider —
/// would never appear, and a rename would leave the old title in the app
/// bar. That is also what `PlaylistDetailScreen`'s own doc promises: opened
/// on a uuid, read afresh from the core rather than trusting a copy the
/// caller already had.
final playlistDetailControllerProvider =
    AsyncNotifierProvider.family<
      PlaylistDetailController,
      PlaylistView?,
      String
    >(PlaylistDetailController.new, isAutoDispose: true);

/// The tracked books' and comics' names (UC-32 main flow step 2).
final trackedReadingItemsProvider =
    AsyncNotifierProvider<TrackedReadingItemsController, Map<String, String>>(
      TrackedReadingItemsController.new,
    );

/// The reading-progress entry being edited (UC-32).
final readingProgressEditorProvider =
    NotifierProvider<ReadingProgressEditor, ReadingProgressEditorState>(
      ReadingProgressEditor.new,
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
    // The album animation's own memory of which record it has already shown
    // an insertion for (Finding 4) — a trace of this session, not of the
    // record itself.
    PlaybackSessionActivity(ref),
  ],
);

/// Ends the session on request (UC-03).
final signOutControllerProvider = Provider<SignOutController>(
  SignOutController.new,
);
