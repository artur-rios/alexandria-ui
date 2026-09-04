// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Alexandria';

  @override
  String get retry => 'Try again';

  @override
  String get coreUnavailableTitle => 'Alexandria\'s core is not available';

  @override
  String get loginTitle => 'Sign in to Alexandria';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginEmailMissing => 'Enter your e-mail address.';

  @override
  String get loginEmailMalformed =>
      'That does not look like an e-mail address.';

  @override
  String get loginPasswordMissing => 'Enter your password.';

  @override
  String get loginRejected =>
      'That e-mail and password do not match an account.';

  @override
  String get loginNoAccount =>
      'No account has been set up on this computer yet.';

  @override
  String get signUpTitle => 'Create your Alexandria account';

  @override
  String get signUpIntro =>
      'This is the only account. Its password cannot be recovered, so choose one you will not lose.';

  @override
  String get signUpPasswordConfirmationLabel => 'Repeat password';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get signUpPasswordConfirmationMissing => 'Repeat your password.';

  @override
  String get signUpPasswordMismatch => 'The two passwords do not match.';

  @override
  String get signUpRejected =>
      'Alexandria did not accept those credentials. Try a longer, less predictable password that is not your e-mail address.';

  @override
  String get signUpAccountExists =>
      'An account already exists on this computer. Sign in instead.';

  @override
  String get signUpGoToLogin => 'Go to sign in';

  @override
  String get loginGoToSignUp => 'Create an account';

  @override
  String get loginSessionEndedTitle => 'You were signed out';

  @override
  String failureCoreLibraryNotLoaded(String path) {
    return 'The Alexandria core could not be loaded from $path.';
  }

  @override
  String failureApplicationDirectoryUnavailable(String path) {
    return 'The application folder $path could not be created.';
  }

  @override
  String get failureCoreInitializationFailed =>
      'The Alexandria core could not open the catalog.';

  @override
  String get failureCoreUnhealthy =>
      'The Alexandria core reported that it is not healthy.';

  @override
  String failureCoreVersionUnsupported(String found, String required) {
    return 'This version of Alexandria needs a core matching $required, but found $found.';
  }

  @override
  String get failurePreferencesUnreadable =>
      'Your preferences could not be read, so the system theme and language are being used.';

  @override
  String get failureInvalidInput => 'Alexandria rejected that as invalid.';

  @override
  String get failureUnauthorized =>
      'Your session has ended. Please sign in again.';

  @override
  String get failureNotInitialized =>
      'Alexandria is not ready yet. Please restart the application.';

  @override
  String get failureNotFound => 'That item no longer exists.';

  @override
  String get failureInvalidState =>
      'That cannot be done to this item right now.';

  @override
  String get failureDisk =>
      'The file could not be read or written on disk. Nothing was changed.';

  @override
  String get failureIntegrity =>
      'The file on disk no longer matches what Alexandria recorded.';

  @override
  String get failureConfiguration =>
      'Alexandria\'s configuration could not be read.';

  @override
  String get failureConflict => 'That already exists in Alexandria.';

  @override
  String get failureRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get failureServiceUnavailable =>
      'Alexandria could not reach a service it needs, so that step did not happen.';

  @override
  String rejectionPasswordTooShort(String min) {
    return 'Use at least $min characters.';
  }

  @override
  String rejectionPasswordTooLong(String max) {
    return 'Use at most $max characters.';
  }

  @override
  String get rejectionPasswordWhitespace => 'A password cannot be only spaces.';

  @override
  String get rejectionPasswordRepeatedCharacter =>
      'A password cannot be one character repeated.';

  @override
  String get rejectionPasswordTooCommon =>
      'That password is too common. Choose something less predictable.';

  @override
  String get rejectionPasswordContainsEmail =>
      'A password cannot contain your e-mail address.';

  @override
  String get rejectionEmailUntrimmed =>
      'Remove the spaces around your e-mail address.';

  @override
  String get failureUnexpected => 'Something went wrong in Alexandria.';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading';

  @override
  String get playbackBarLabel => 'Playback';

  @override
  String get playbackNothingPlaying => 'Nothing is playing';

  @override
  String get destinationHome => 'Home';

  @override
  String get destinationMusic => 'Music';

  @override
  String get destinationBooks => 'Books';

  @override
  String get destinationComicBooks => 'Comic books';

  @override
  String get destinationNotes => 'Notes';

  @override
  String get destinationPages => 'Pages';

  @override
  String get destinationImages => 'Images';

  @override
  String get destinationBookmarks => 'Bookmarks';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get preferencesOpen => 'Open preferences';

  @override
  String get preferencesLabel => 'Preferences';

  @override
  String get settingsMenuLabel => 'Settings';

  @override
  String get settingsMenuOpen => 'Open settings';

  @override
  String get preferencesThemeLabel => 'Theme';

  @override
  String get preferencesThemeSystem => 'Match the system';

  @override
  String get preferencesThemeLight => 'Light';

  @override
  String get preferencesThemeDark => 'Dark';

  @override
  String get preferencesLanguageLabel => 'Language';

  @override
  String get preferencesLanguageSystem => 'Match the system';

  @override
  String get playerAutoOpenLabel => 'Open the player when a track starts';

  @override
  String get playerAutoOpenDescription =>
      'The full player opens by itself whenever something new begins playing.';

  @override
  String get startupRecheckLabel => 'Re-check the library at startup';

  @override
  String get startupRecheckDescription =>
      'Looks for files added, changed, or removed while Alexandria was closed.';

  @override
  String get preferencesUnsaved =>
      'Your choice is applied, but it could not be saved — it will not be remembered the next time Alexandria starts.';

  @override
  String get preferencesClose => 'Done';

  @override
  String get changeCredentialsOpen => 'Change credentials…';

  @override
  String get changeCredentialsTitle => 'Change credentials';

  @override
  String get changeCredentialsIntro =>
      'Both are replaced together. You stay signed in.';

  @override
  String get changeCredentialsEmailLabel => 'New e-mail';

  @override
  String get changeCredentialsPasswordLabel => 'New password';

  @override
  String get changeCredentialsConfirmationLabel => 'Repeat the new password';

  @override
  String get changeCredentialsSubmit => 'Change';

  @override
  String get changeCredentialsDone =>
      'Your e-mail and password have been changed.';

  @override
  String get changeCredentialsRejected =>
      'The change was refused, and your e-mail and password are unchanged.';

  @override
  String get librarySourcesOpen => 'Library folders';

  @override
  String get librarySourcesTitle => 'Library folders';

  @override
  String get librarySourcesEmptyTitle => 'No library folders yet';

  @override
  String get librarySourcesEmptyBody =>
      'Add a folder from your disk and Alexandria will catalog what is inside it. Nothing is moved, copied, or changed.';

  @override
  String get librarySourcesClose => 'Close the library folders';

  @override
  String get librarySourcesAdd => 'Add a folder';

  @override
  String librarySourcesMissing(String path) {
    return 'There is no folder at $path. Nothing was added.';
  }

  @override
  String librarySourcesUnreadable(String path) {
    return 'The folder at $path cannot be read. Nothing was added.';
  }

  @override
  String get librarySourcesAlreadyRegistered =>
      'That folder is already in your library.';

  @override
  String get librarySourcesOverlapTitle => 'These folders overlap';

  @override
  String librarySourcesOverlapBody(String path, String existing) {
    return '$path overlaps $existing, which is already in your library. Files inside both will be cataloged once for each folder.';
  }

  @override
  String get librarySourcesOverlapConfirm => 'Add it anyway';

  @override
  String get indexScopeTitle => 'What is in this folder?';

  @override
  String get indexScopeBody =>
      'Alexandria will catalog only the kinds of file you choose here. A music folder scoped to music keeps its cover art out of your images.';

  @override
  String get indexScopeAll => 'All supported files';

  @override
  String get indexScopeConfirm => 'Add the folder';

  @override
  String get indexScopeEmpty =>
      'Choose at least one kind of file, or all of them.';

  @override
  String get librarySourcesScopeUnreadable =>
      'Covers file types this version does not recognize';

  @override
  String get librarySourcesStartUnreadableScope =>
      'This folder is set to cover file types this version does not recognize, so it was not scanned. Remove it and add it again to choose what it covers.';

  @override
  String get librarySourcesStartNotRegistered =>
      'This folder is no longer in your library, so it was not scanned.';

  @override
  String get librarySourcesScopeAll => 'All supported files';

  @override
  String librarySourcesScopeOnly(String types) {
    return 'Only $types';
  }

  @override
  String get fileTypeAudio => 'Music';

  @override
  String get fileTypeVideo => 'Video';

  @override
  String get fileTypeDocument => 'Books';

  @override
  String get fileTypeComic => 'Comic books';

  @override
  String get fileTypeText => 'Notes';

  @override
  String get fileTypeHtml => 'Saved pages';

  @override
  String get fileTypeImage => 'Images';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get librarySourcesRescan => 'Rescan';

  @override
  String get librarySourcesIndexing => 'Scanning…';

  @override
  String librarySourcesRunComplete(int scanned, int indexed, int skipped) {
    return 'Scanned $scanned files, cataloged $indexed, skipped $skipped.';
  }

  @override
  String librarySourcesRunFailedCount(int failed) {
    return '$failed files could not be read, and are not in your library. Re-scanning tries them again.';
  }

  @override
  String get librarySourcesRunFailed => 'The scan did not finish.';

  @override
  String get librarySourcesRunCancelled => 'The scan was cancelled.';

  @override
  String get librarySourcesRunPaused =>
      'The scan is paused. It can be resumed from where it left off.';

  @override
  String get librarySourcesRunRefused =>
      'A scan of this folder is already running.';

  @override
  String get librarySourcesStartFailed => 'This folder could not be scanned.';

  @override
  String get librarySourcesUnregister => 'Remove';

  @override
  String librarySourcesUnregisterTitle(String label) {
    return 'Remove $label from your library folders?';
  }

  @override
  String get librarySourcesUnregisterBody =>
      'Alexandria will stop scanning this folder. Everything already cataloged from it stays in your library, and nothing on disk is touched.';

  @override
  String get librarySourcesUnregisterConfirm => 'Remove the folder';

  @override
  String get librarySourcesUnregisterRefused =>
      'This folder is being scanned. It can be removed once the scan finishes.';

  @override
  String get librarySourcesRecheck => 'Re-check library';

  @override
  String get librarySourcesPause => 'Pause';

  @override
  String get librarySourcesResume => 'Resume';

  @override
  String get librarySourcesCancelRun => 'Cancel';

  @override
  String get librarySourcesCancelRunTitle => 'Cancel this scan?';

  @override
  String get librarySourcesCancelRunConfirm =>
      'This scan cannot be resumed once cancelled. Everything it has already cataloged stays in your library.';

  @override
  String get librarySourcesCancelRunAction => 'Cancel the scan';

  @override
  String get librarySourcesRefreshing => 'Re-checking the catalog…';

  @override
  String librarySourcesRefreshComplete(
    int refreshed,
    int unchanged,
    int missing,
  ) {
    return '$refreshed files updated, $unchanged unchanged, $missing now missing.';
  }

  @override
  String get librarySourcesRefreshRunning =>
      'The catalog is already being re-checked.';

  @override
  String get librarySourcesRefreshEmpty =>
      'There is nothing cataloged yet. Add a folder and index it first.';

  @override
  String get librarySourcesRefreshFailed =>
      'The catalog could not be re-checked.';

  @override
  String get destinationVideos => 'Videos';

  @override
  String get catalogEmptyTitle => 'Nothing of this type yet';

  @override
  String get catalogEmptyFirstRun =>
      'Your library is empty. Add a folder and index it, and what is inside will appear here.';

  @override
  String get catalogEmptyAddFolder => 'Library folders';

  @override
  String get catalogFileMissing => 'Missing from disk';

  @override
  String catalogCount(int count) {
    return '$count';
  }

  @override
  String get layoutList => 'List';

  @override
  String get layoutDetailedList => 'List with details';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutLabel => 'Layout';

  @override
  String get layoutSubstituted =>
      'The window is too narrow for that layout, so the list is shown instead.';

  @override
  String get layoutUnsaved =>
      'The layout changed, but the choice could not be saved — it will not be remembered next time.';

  @override
  String get searchLabel => 'Search the library';

  @override
  String get searchClear => 'Clear the search';

  @override
  String searchNoResults(String term) {
    return 'Nothing matches “$term”.';
  }

  @override
  String get searchPartial =>
      'Some of the library could not be read, so more results may exist.';

  @override
  String searchResultsFor(String term) {
    return 'Results for “$term”';
  }

  @override
  String get filtersLabel => 'Filters and order';

  @override
  String get filterLifecycle => 'Show';

  @override
  String get filterLifecycleActive => 'In the library';

  @override
  String get filterLifecycleDeleted => 'Deleted';

  @override
  String get filterLifecycleAll => 'Everything';

  @override
  String get sortLabel => 'Order by';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByIndexed => 'Date added';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get filtersClear => 'Clear the filters';

  @override
  String get filtersEmpty => 'Nothing matches the filters you have set.';

  @override
  String get filtersRejected =>
      'That filter was refused, so the previous one is back.';

  @override
  String get detailsTitle => 'Details';

  @override
  String get detailsPath => 'Where it is';

  @override
  String get detailsMetadata => 'About it';

  @override
  String get detailsState => 'State';

  @override
  String get detailsStateActive => 'In the library';

  @override
  String get detailsStateDeleted => 'Deleted';

  @override
  String get detailsStateMissing => 'Missing from disk';

  @override
  String get detailsOpen => 'Open';

  @override
  String get detailsNoViewer => 'Nothing can open this kind of file yet.';

  @override
  String get detailsMissingHint =>
      'Alexandria could not find this file where the catalog says it is. Re-check the catalog to find out whether it has come back.';

  @override
  String get detailsRescan => 'Re-check the catalog';

  @override
  String get detailsDeletedHint =>
      'This record is deleted. Restore it to edit or open it again.';

  @override
  String get detailsNotFound => 'That file is no longer in the catalog.';

  @override
  String get detailsMetadataNone =>
      'The core reports nothing else about this file.';

  @override
  String get detailsWidth => 'Width';

  @override
  String get detailsHeight => 'Height';

  @override
  String get detailsPages => 'Pages';

  @override
  String get detailsDuration => 'Duration';

  @override
  String get detailsFileSection => 'The file';

  @override
  String get detailsFileName => 'File name';

  @override
  String get detailsFileSize => 'Size on disk';

  @override
  String get detailsFileFormat => 'Format';

  @override
  String get detailsFileModified => 'Last modified';

  @override
  String get dashboardRecent => 'Recently added';

  @override
  String get dashboardRecentNone => 'Nothing has been added yet.';

  @override
  String get dashboardInProgress => 'In progress';

  @override
  String get dashboardInProgressNone => 'Nothing is in progress.';

  @override
  String dashboardInProgressIn(String list) {
    return 'In $list';
  }

  @override
  String dashboardInProgressInAt(String list, String progress) {
    return 'In $list — $progress';
  }

  @override
  String get dashboardCounts => 'What is in the library';

  @override
  String get dashboardLastRun => 'The last scan';

  @override
  String get dashboardLastRunNone =>
      'Nothing has been scanned in this session.';

  @override
  String get dashboardLastRunRunning => 'A scan is running now.';

  @override
  String get dashboardLastRunComplete => 'The last scan finished.';

  @override
  String get dashboardLastRunFailed => 'The last scan did not finish.';

  @override
  String get dashboardLastRunInterrupted =>
      'The last scan was interrupted when Alexandria closed.';

  @override
  String get detailsEditMetadata => 'Edit metadata';

  @override
  String get musicMetadataTitle => 'Music metadata';

  @override
  String get musicMetadataFieldTitle => 'Title';

  @override
  String get musicMetadataFieldArtist => 'Artist';

  @override
  String get musicMetadataFieldAlbumArtist => 'Album artist';

  @override
  String get musicMetadataFieldAlbum => 'Album';

  @override
  String get musicMetadataFieldYear => 'Year';

  @override
  String get musicMetadataFieldGenre => 'Genre';

  @override
  String get musicMetadataFieldTrack => 'Track number';

  @override
  String get musicMetadataSave => 'Save';

  @override
  String get musicMetadataCancel => 'Cancel';

  @override
  String get musicMetadataErrorNotANumber => 'Enter a whole number.';

  @override
  String get musicMetadataErrorYear => 'Enter a four-digit year.';

  @override
  String get musicMetadataErrorTrack => 'A track number starts at 1.';

  @override
  String musicMetadataErrorTooLong(int max) {
    return 'Keep this under $max characters.';
  }

  @override
  String get musicViewArtists => 'Artists';

  @override
  String get musicViewAlbums => 'Albums';

  @override
  String get musicViewSongs => 'Songs';

  @override
  String get musicBreadcrumbRoot => 'Music library';

  @override
  String get musicUnknownTitle => 'Unknown title';

  @override
  String get musicUnknownArtist => 'Unknown artist';

  @override
  String get musicUnknownAlbum => 'Unknown album';

  @override
  String get musicRowActions => 'Actions for this track';

  @override
  String get musicEmpty => 'No audio files are catalogued yet.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutUnsavedTitle => 'Unsaved changes';

  @override
  String get signOutUnsavedMessage =>
      'Signing out now discards the changes you have not saved. Cancel to go back and save them first.';

  @override
  String get signOutUnsavedConfirm => 'Sign out and discard';

  @override
  String get signOutIndexRunContinues =>
      'You signed out while a scan was still running. It continues in the core, and how it ended is shown the next time you sign in.';

  @override
  String get videoMetadataTitle => 'Edit video metadata';

  @override
  String get videoMetadataFieldTitle => 'Title';

  @override
  String get videoMetadataFieldYear => 'Year';

  @override
  String get videoMetadataFieldResolution => 'Resolution';

  @override
  String get videoMetadataFieldMediaKind => 'Kind';

  @override
  String get videoMetadataMovie => 'Movie';

  @override
  String get videoMetadataSeries => 'Series';

  @override
  String get videoMetadataSave => 'Save';

  @override
  String get videoMetadataCancel => 'Cancel';

  @override
  String get videoMetadataMarkingWarning =>
      'This video is tracked per episode. Marking it as a movie replaces that with progress for the item as a whole.';

  @override
  String get videoMetadataMarkingConfirm => 'Mark as a movie';

  @override
  String get videoMetadataErrorNotANumber => 'Enter a whole number.';

  @override
  String get videoMetadataErrorYear => 'Enter a four-digit year.';

  @override
  String videoMetadataErrorTooLong(int max) {
    return 'Keep this under $max characters.';
  }

  @override
  String get videoMetadataMarkingCancel => 'Keep it as a series';

  @override
  String get renameOpen => 'Rename';

  @override
  String get renameTitle => 'Rename file';

  @override
  String get renameFieldLabel => 'File name';

  @override
  String get renameSubmit => 'Rename';

  @override
  String get renameNothingChanged =>
      'Neither the catalog nor the file on disk was changed.';

  @override
  String get renameErrorEmpty => 'Enter a file name.';

  @override
  String get renameErrorForbidden =>
      'This name uses a character the file system does not allow.';

  @override
  String get renameErrorReserved =>
      'This name is reserved by the operating system.';

  @override
  String get renameErrorTrailingDot => 'A file name cannot end in a dot.';

  @override
  String renameErrorTooLong(int max) {
    return 'Keep the name under $max characters.';
  }

  @override
  String get editorOpen => 'Edit';

  @override
  String get editorClose => 'Close the editor';

  @override
  String get editorSave => 'Save';

  @override
  String get editorUnsaved => 'Unsaved changes';

  @override
  String get editorDismiss => 'Dismiss';

  @override
  String get editorDiscard => 'Discard';

  @override
  String get editorReload => 'Reload from disk';

  @override
  String get editorOverwrite => 'Save anyway';

  @override
  String get editorSignInAgain => 'Sign in again';

  @override
  String get editorNothingToSave =>
      'The content has not changed, so nothing was written.';

  @override
  String get editorLeaveUnsaved =>
      'You have changes that are not saved. Save them, discard them, or stay in the editor.';

  @override
  String get editorChangedOnDisk =>
      'This file changed on disk since you opened it. Reload to see the new version, or save anyway to replace it.';

  @override
  String get editorRecordGone =>
      'This file is no longer in the catalog. What you have written is still here, and is not saved.';

  @override
  String get editorSessionRejected =>
      'Your session ended, so this could not be saved. Signing in again will lose what is on screen.';

  @override
  String get editorCouldNotRead => 'This file could not be read.';

  @override
  String get editorSaveAndClose => 'Save and close';

  @override
  String get videoPlay => 'Play';

  @override
  String get videoPause => 'Pause';

  @override
  String get videoClose => 'Close the player';

  @override
  String get videoSeekBackward => 'Back ten seconds';

  @override
  String get videoSeekForward => 'Forward ten seconds';

  @override
  String get videoFullScreen => 'Full screen';

  @override
  String get videoSubtitles => 'Subtitles';

  @override
  String get videoSubtitlesOff => 'Off';

  @override
  String get videoNoSubtitles => 'This file carries no subtitles';

  @override
  String get videoAudioTracks => 'Audio tracks';

  @override
  String get videoNoAudioTracks => 'This file carries one audio track';

  @override
  String get videoResume => 'Resume';

  @override
  String get videoStartOver => 'Start over';

  @override
  String get videoFileMissing =>
      'This file is not where the catalog says it is.';

  @override
  String get videoCannotDecode => 'This file cannot be played.';

  @override
  String videoResumePrompt(String position) {
    return 'You stopped watching at $position.';
  }

  @override
  String videoTrackUnnamed(String id) {
    return 'Track $id';
  }

  @override
  String get audioPlay => 'Play';

  @override
  String get audioShuffleAlbum => 'Shuffle album';

  @override
  String get audioShuffleArtist => 'Shuffle artist';

  @override
  String get audioShuffleAll => 'Shuffle everything';

  @override
  String get audioShuffleAllLabel => 'Shuffled library';

  @override
  String get audioShufflePlaylist => 'Shuffle playlist';

  @override
  String get audioPlayAlbum => 'Play album';

  @override
  String get audioPlayArtist => 'Play artist';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioNext => 'Next track';

  @override
  String get audioPrevious => 'Previous track';

  @override
  String get audioStop => 'Stop';

  @override
  String get audioNothingPlayable =>
      'Nothing in this selection could be played.';

  @override
  String audioSkipped(String name) {
    return 'Skipped $name — it could not be played.';
  }

  @override
  String audioResumePrompt(String position) {
    return 'You stopped this track at $position.';
  }

  @override
  String get audioPlayer => 'Player';

  @override
  String get audioOpenPlayer => 'Open the player';

  @override
  String get audioClosePlayer => 'Close the player';

  @override
  String get albumMediumVinyl => 'A record turning on a turntable';

  @override
  String get albumMediumTape => 'A cassette turning in a tape deck';

  @override
  String get albumMediumDisc => 'A disc turning in a player';

  @override
  String get viewerOpen => 'Open';

  @override
  String get viewerClose => 'Close the viewer';

  @override
  String get viewerNext => 'Next chapter';

  @override
  String get viewerPrevious => 'Previous chapter';

  @override
  String get viewerFileMissing =>
      'This file is not where the catalog says it is.';

  @override
  String get viewerUnreadable =>
      'This file could not be read. It may be damaged, or not the format its name claims.';

  @override
  String get viewerEncrypted =>
      'This document is protected by a password, which this application does not ask for or store.';

  @override
  String get viewerNone =>
      'There is no viewer for this kind of file yet. Its other actions are still available.';

  @override
  String viewerUnsupportedFormat(String name) {
    return '$name is in a format no bundled decoder can open.';
  }

  @override
  String viewerChapterOf(int position, int total) {
    return 'Chapter $position of $total';
  }

  @override
  String get comicFitPage => 'Fit the page';

  @override
  String get comicFitWidth => 'Fit the width';

  @override
  String get comicNextPage => 'Next page';

  @override
  String get comicPreviousPage => 'Previous page';

  @override
  String comicPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String comicPagesSkipped(String pages) {
    return 'These pages could not be read: $pages';
  }

  @override
  String get imageFit => 'Fit to the window';

  @override
  String get imageNext => 'Next image';

  @override
  String get imagePrevious => 'Previous image';

  @override
  String imageOf(int position, int total) {
    return '$position of $total';
  }

  @override
  String get pageScriptsNotRun =>
      'This page is shown as content. Any script it contains is not run.';

  @override
  String get pageMalformed =>
      'This page\'s markup is incomplete, so some of it may be missing.';

  @override
  String pageMissingAssets(String assets) {
    return 'These files the page refers to are not on disk: $assets';
  }

  @override
  String get bookmarkAdd => 'Add a bookmark';

  @override
  String get bookmarkEdit => 'Edit this bookmark';

  @override
  String get bookmarkCreate => 'Create';

  @override
  String get bookmarkSave => 'Save';

  @override
  String get bookmarkTitleLabel => 'Title';

  @override
  String get bookmarkUrlLabel => 'Address';

  @override
  String get bookmarksNone => 'You have not saved any bookmarks yet.';

  @override
  String get bookmarkFieldEmpty => 'This cannot be empty.';

  @override
  String get bookmarkUrlMalformed => 'This is not an address.';

  @override
  String get bookmarkUrlUnopenable =>
      'Enter a web address starting with http:// or https://.';

  @override
  String get bookmarkNoBrowser =>
      'No browser could be opened for this bookmark.';

  @override
  String get bookmarkCopyUrl => 'Copy the address';

  @override
  String get watchlistsTitle => 'Watchlists';

  @override
  String get watchlistsOpen => 'Watchlists';

  @override
  String get watchlistsNone => 'You have not made a watchlist yet.';

  @override
  String get watchlistNameLabel => 'Watchlist name';

  @override
  String get watchlistCreate => 'Create';

  @override
  String get watchlistNameEmpty => 'Give the watchlist a name.';

  @override
  String get watchlistDelete => 'Delete this watchlist';

  @override
  String get watchlistEmpty => 'Nothing is tracked in this watchlist yet.';

  @override
  String get watchlistAddTo => 'Add to a watchlist';

  @override
  String get watchlistRemoveVideo => 'Stop tracking this video';

  @override
  String get watchlistAlreadyTracked =>
      'That video is already in that watchlist.';

  @override
  String get watchlistNotFound => 'That watchlist or video is no longer there.';

  @override
  String get watchStatePending => 'Not started';

  @override
  String get watchStateWatching => 'Watching';

  @override
  String get watchStateWatched => 'Watched';

  @override
  String watchlistDeleteMessage(String name) {
    return 'Delete $name? The videos in it are kept — only the tracking is removed.';
  }

  @override
  String watchlistAlreadyIn(String name) {
    return '$name — already there';
  }

  @override
  String watchlistItemCount(int count) {
    return '$count tracked';
  }

  @override
  String get watchProgressSave => 'Save progress';

  @override
  String get watchCurrentEpisodeLabel => 'Episode';

  @override
  String get watchTotalEpisodesLabel => 'of how many';

  @override
  String get watchEpisodeNotANumber => 'Enter a whole number.';

  @override
  String get watchEpisodeNotPositive => 'Episodes are counted from 1.';

  @override
  String get watchEpisodeBeyondTotal => 'That is past the total you gave.';

  @override
  String watchEpisode(int episode) {
    return 'episode $episode';
  }

  @override
  String watchEpisodeOf(int episode, int total) {
    return 'episode $episode of $total';
  }

  @override
  String get readingListsTitle => 'Reading lists';

  @override
  String get readingListsOpen => 'Reading lists';

  @override
  String get readingListsNone => 'You have not made a reading list yet.';

  @override
  String get readingListNameLabel => 'Reading list name';

  @override
  String get readingListCreate => 'Create';

  @override
  String get readingListNameEmpty => 'Give the reading list a name.';

  @override
  String get readingListDelete => 'Delete this reading list';

  @override
  String get readingListEmpty => 'Nothing is tracked in this reading list yet.';

  @override
  String get readingListAddTo => 'Add to a reading list';

  @override
  String get readingListRemoveItem => 'Stop tracking this item';

  @override
  String get readingListAlreadyTracked =>
      'That item is already in that reading list.';

  @override
  String get readingListNotFound =>
      'That reading list or item is no longer there.';

  @override
  String get readStatePending => 'Not started';

  @override
  String get readStateReading => 'Reading';

  @override
  String get readStateRead => 'Read';

  @override
  String readingListDeleteMessage(String name) {
    return 'Delete $name? The books and comics in it are kept — only the tracking is removed.';
  }

  @override
  String readingListAlreadyIn(String name) {
    return '$name — already there';
  }

  @override
  String readingListItemCount(int count) {
    return '$count tracked';
  }

  @override
  String get playlistsTitle => 'Playlists';

  @override
  String get playlistsOpen => 'Playlists';

  @override
  String get playlistsNone => 'You have not made a playlist yet.';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get playlistRenameLabel => 'New name';

  @override
  String get playlistCreate => 'Create';

  @override
  String get playlistRenameSave => 'Rename';

  @override
  String get playlistRename => 'Rename this playlist';

  @override
  String get playlistDelete => 'Delete this playlist';

  @override
  String get playlistNameEmpty => 'Give the playlist a name.';

  @override
  String get playlistNotFound => 'That playlist is no longer there.';

  @override
  String playlistDeleteMessage(String name) {
    return 'Delete $name? The tracks in it are kept — only the playlist is removed.';
  }

  @override
  String get playlistDetailEmpty => 'This playlist has no tracks yet.';

  @override
  String get playlistRemoveTrack => 'Remove from playlist';

  @override
  String get indexScopeAsLibrary => 'Keep this folder together as a library';

  @override
  String get indexScopeAsLibraryBody =>
      'Its files are browsed in their folders here instead of appearing in the type panels. Search still finds them.';

  @override
  String librarySourcesIsLibrary(String name) {
    return 'Library: $name';
  }

  @override
  String get librarySourcesMarkAsLibrary => 'Mark as a library';

  @override
  String get libraryMove => 'The folder moved';

  @override
  String get libraryMoveConflict =>
      'That folder cannot hold this library: it overlaps another one, or the catalog already has files there.';

  @override
  String searchInLibrary(String name) {
    return 'In $name';
  }

  @override
  String get searchInALibrary => 'In a library';

  @override
  String get runFailuresTitle => 'Files that could not be read';

  @override
  String get runFailuresExplanation =>
      'A scan could not read these files, so they are not in your library. Nothing was changed or deleted — scanning the folder again tries them.';

  @override
  String get runFailuresNone => 'This scan read every file it found.';

  @override
  String runFailuresTruncated(int shown, int total) {
    return 'Naming the first $shown of $total. A scan records only so many paths; the count is the whole tally.';
  }

  @override
  String get runFailuresOpen => 'Show which files';

  @override
  String get librariesTitle => 'Libraries';

  @override
  String get librariesNone =>
      'You have not made a library yet. Add one with the button above — a folder becomes a library, and its files are shown there instead of in the type panels.';

  @override
  String get librariesExplanation =>
      'A library keeps a folder\'s files together and in their folders — a course, with each class\'s recording and handouts side by side. Its files are shown here instead of in the type panels, so they do not bury everything else. Search still finds them.';

  @override
  String get libraryNameLabel => 'Library name';

  @override
  String get libraryAdd => 'Add a library';

  @override
  String get libraryScan => 'Scan this folder';

  @override
  String get libraryRemove => 'Remove this library';

  @override
  String libraryRemoveMessage(String name) {
    return 'Remove $name? Its files go back to the type panels — nothing on disk is touched and nothing is deleted.';
  }

  @override
  String get libraryEmptyRoot =>
      'Nothing under this folder has been indexed yet. Scan it from the libraries list, and what it holds will appear here.';

  @override
  String get libraryEmptyFolder => 'Nothing in this folder.';

  @override
  String get libraryUp => 'Up one folder';

  @override
  String get libraryOverlaps =>
      'That folder is already inside another library.';

  @override
  String get enrichmentSweepOpen => 'Find music info';

  @override
  String get enrichmentSweepTitle => 'Find music info';

  @override
  String get enrichmentSweepExplanation =>
      'Looks up artist photography and lyrics for your music from MusicBrainz, Wikimedia Commons and LRCLIB. Nothing about you is sent — only an artist name, a track title, an album name and a duration. It is slow on purpose: those services allow one request a second, so a large library takes hours. You can stop at any time and pick up where you left off.';

  @override
  String get enrichmentSweepStart => 'Start';

  @override
  String get enrichmentSweepStop => 'Stop';

  @override
  String enrichmentSweepProgress(int considered, int remaining) {
    return '$considered looked up, $remaining to go';
  }

  @override
  String enrichmentSweepFinished(int found, int considered) {
    return 'Finished. Found something for $found of $considered.';
  }

  @override
  String enrichmentSweepStopped(int considered) {
    return 'Stopped. $considered looked up so far — starting again picks up from here.';
  }

  @override
  String get enrichmentSweepFailed => 'The lookup could not continue.';

  @override
  String get enrichmentLyricsTitle => 'Lyrics';

  @override
  String enrichmentLyricsSource(String source) {
    return 'Lyrics from $source';
  }

  @override
  String enrichmentImageCredit(String source) {
    return 'Photograph: $source';
  }

  @override
  String get enrichmentFindForTrack => 'Find lyrics and artwork';

  @override
  String get enrichmentLookingUp => 'Looking up…';

  @override
  String get enrichmentNothingFound => 'Nothing found for this track.';

  @override
  String get enrichmentUnavailable =>
      'Music lookup is switched off. You can turn it on in Preferences.';

  @override
  String get playlistPlay => 'Play this playlist';

  @override
  String get playlistAddTo => 'Add to a playlist';

  @override
  String get playlistAddAlbumTo => 'Add album to a playlist';

  @override
  String get playlistAddArtistTo => 'Add artist to a playlist';

  @override
  String get playlistAddCreateOne => 'Make a playlist first';

  @override
  String get readCurrentIssueLabel => 'Current issue';

  @override
  String get readTotalIssuesLabel => 'Total issues';

  @override
  String get readIssueNotANumber => 'Use a whole number.';

  @override
  String get readIssueNotPositive => 'Issues are counted from one.';

  @override
  String get readIssueBeyondTotal => 'That is past the total you gave.';

  @override
  String get readProgressSave => 'Save progress';

  @override
  String readIssue(int current) {
    return 'issue $current';
  }

  @override
  String readIssueOf(int current, int total) {
    return 'issue $current of $total';
  }

  @override
  String get deleteFile => 'Delete this file';

  @override
  String get deleteFileOnDisk => 'The file on disk is not affected.';

  @override
  String get deleteFileInUse =>
      'It is playing or open right now — confirming stops it.';

  @override
  String get deleteBookmark => 'Delete this bookmark';

  @override
  String get deleteAlreadyDeleted => 'That record was already deleted.';

  @override
  String get deleteNotFound => 'That record is no longer there.';

  @override
  String deleteFileMessage(String name) {
    return 'Hide $name from the library? It stays restorable.';
  }

  @override
  String deleteBookmarkMessage(String title) {
    return 'Hide $title from your bookmarks? It stays restorable.';
  }

  @override
  String get deletedItemsTitle => 'Deleted items';

  @override
  String get deletedItemsOpen => 'Deleted items';

  @override
  String get deletedItemsNone => 'Nothing has been deleted.';

  @override
  String get restoreRecord => 'Restore';

  @override
  String get restoreNotFound =>
      'That record cannot be restored — it is gone, or its window has passed.';

  @override
  String get retentionElapsed =>
      'No longer restorable — it can only be purged.';

  @override
  String get retentionUnknown => 'Restorable';

  @override
  String retentionRemaining(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Restorable for $days more days',
      one: 'Restorable for 1 more day',
    );
    return '$_temp0';
  }

  @override
  String get purgeRecord => 'Purge';

  @override
  String get purgeRecordOnDisk => 'The file on disk is not removed.';

  @override
  String get purgeNotDeleted =>
      'Delete that record first — only a deleted record can be purged.';

  @override
  String get purgeNotFound => 'That record is no longer there.';

  @override
  String get purgeNothingOnDisk =>
      'The record was removed, and no file was found on disk.';

  @override
  String get purgeDiskFailed =>
      'Nothing was removed — neither the file nor the record.';

  @override
  String purgeRecordMessage(String name) {
    return 'Remove $name from the catalog permanently? This cannot be undone.';
  }

  @override
  String purgeTooSoon(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'That record can be purged in $days days.',
      one: 'That record can be purged in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get purgeOnDiskTitle => 'Remove from disk';

  @override
  String get purgeOnDiskAction => 'Delete the file from disk';

  @override
  String get purgeOnDiskExplanation =>
      'This is the only action here that removes your data from disk. Everything else keeps the file and changes only the catalog.';

  @override
  String get purgeOnDiskIrreversible => 'This cannot be undone.';

  @override
  String purgeOnDiskMessage(String path) {
    return 'Delete $path from disk and remove its record?';
  }

  @override
  String get missingFilesTitle => 'Missing files';

  @override
  String get missingFilesOpen => 'Missing files';

  @override
  String get missingFilesNone => 'Every cataloged file was found on disk.';

  @override
  String get missingFilesExplanation =>
      'These records are still in the catalog — nothing is removed because a file is absent. Re-scan to check whether they came back, or open a record to decide what to do about it.';

  @override
  String get missingFilesRescan => 'Re-scan the library';

  @override
  String get missingFilesOpenDetails => 'Open';

  @override
  String get missingFilesUnregisteredFolder =>
      'From a folder that is no longer registered.';

  @override
  String get recoveryCodesTitle => 'Save your recovery codes';

  @override
  String get recoveryCodesExplanation =>
      'This is the only time these are shown. Each one replaces a forgotten password exactly once — without them, a forgotten password means a lost library.';

  @override
  String get recoveryCodesCopy => 'Copy the codes';

  @override
  String get recoveryCodesCopied => 'Copied to the clipboard.';

  @override
  String get recoveryCodesAcknowledge => 'I have stored them';

  @override
  String get recoveryCodesNone =>
      'Your account was created, but no recovery codes came with it. Generate a set from preferences before you need one.';

  @override
  String get recoveryTitle => 'Recover access';

  @override
  String get recoveryOpen => 'I cannot sign in';

  @override
  String get recoveryExplanation =>
      'Enter one of the recovery codes you saved when the account was created, and choose a new password. The code is spent once used, and every open session is signed out.';

  @override
  String get recoveryCodeLabel => 'Recovery code';

  @override
  String get recoveryNewPassword => 'New password';

  @override
  String get recoveryConfirmPassword => 'Repeat the new password';

  @override
  String get recoveryCodeMissing => 'Enter a recovery code.';

  @override
  String get recoveryPasswordMissing => 'Enter a new password.';

  @override
  String get recoverySubmit => 'Replace the password';

  @override
  String get recoveryCodeUnknown =>
      'That is not one of this account\'s recovery codes. Check it and try again.';

  @override
  String get recoveryCodeUsed =>
      'That recovery code has already been used. Each one works once — try another from your list.';

  @override
  String get recoveryRefused =>
      'The password could not be replaced. Check the code and try again.';

  @override
  String get recoveryDone => 'Your password was replaced';

  @override
  String get recoveryDoneExplanation =>
      'The code you used is spent, and every open session was signed out. Sign in with the new password.';

  @override
  String get recoveryBackToLogin => 'Back to sign in';

  @override
  String get recoveryCodesRegenerate => 'Generate new recovery codes';

  @override
  String get recoveryCodesRegenerateMessage =>
      'Every code you have now stops working, and ten new ones take their place. They are shown once.';

  @override
  String get recoveryCodesNoneLeft =>
      'No recovery codes are left. Generate a set while you still know your password.';

  @override
  String recoveryCodesRemaining(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recovery codes left',
      one: '1 recovery code left',
    );
    return '$_temp0';
  }

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsOpen => 'Collections';

  @override
  String get collectionsNone => 'You have not made a collection yet.';

  @override
  String get collectionNameLabel => 'Collection name';

  @override
  String get collectionRenameLabel => 'New name';

  @override
  String get collectionCreate => 'Create';

  @override
  String get collectionRenameSave => 'Rename';

  @override
  String get collectionRename => 'Rename this collection';

  @override
  String get collectionDelete => 'Delete this collection';

  @override
  String get collectionNameEmpty => 'Give the collection a name.';

  @override
  String get collectionNotFound => 'That collection is no longer there.';

  @override
  String get collectionKindFile => 'Files';

  @override
  String get collectionKindBookmark => 'Bookmarks';

  @override
  String collectionDeleteMessage(String name) {
    return 'Delete $name? The items in it are kept — only the grouping is removed.';
  }

  @override
  String collectionItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String get collectionAddItems => 'Add items';

  @override
  String get collectionAddChosen => 'Add';

  @override
  String get collectionRemoveItem => 'Remove from this collection';

  @override
  String get collectionEmpty => 'This collection is empty.';

  @override
  String get collectionNoCandidates =>
      'There is nothing of this collection\'s kind to add.';

  @override
  String collectionItemsAdded(String names) {
    return 'Added: $names';
  }

  @override
  String collectionItemsAlreadyPresent(String names) {
    return 'Already in this collection: $names';
  }

  @override
  String collectionItemNotAdded(String name, String reason) {
    return '$name was not added — $reason';
  }

  @override
  String get bookmarkCollectionLabel => 'Collection';

  @override
  String get bookmarkCollectionNone => 'Not in a collection';

  @override
  String get bookmarkFilterLabel => 'Show';

  @override
  String get bookmarkFilterAll => 'All bookmarks';

  @override
  String get collectionItemWrongKind => 'it is not this collection\'s kind';

  @override
  String get collectionItemGone => 'it no longer exists';

  @override
  String get libraryToolsOpen => 'Library tools';

  @override
  String get libraryToolsLabel => 'Library';

  @override
  String get libraryToolsGroupLibrary => 'Library';

  @override
  String get libraryToolsGroupTracking => 'Tracking';

  @override
  String get libraryToolsGroupReview => 'Review';

  @override
  String artistPortraitsProgress(int done, int total) {
    return 'Finding artist photographs — $done of $total';
  }

  @override
  String get activityBarLabel => 'Background indexing';

  @override
  String get activityDiscovering => 'Scanning folders…';

  @override
  String activityProgress(int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$processedString of $totalString';
  }

  @override
  String activityRemaining(String duration) {
    return 'about $duration left';
  }

  @override
  String activityDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
      zero: 'less than a minute',
    );
    return '$_temp0';
  }

  @override
  String activityDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String activityPaused(int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Paused — $processedString of $totalString';
  }

  @override
  String activityAggregate(int count, int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Indexing $count folders — $processedString of $totalString';
  }

  @override
  String activityAggregateDiscovering(int count) {
    return 'Indexing $count folders';
  }

  @override
  String activityAggregatePaused(int count, int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$count folders paused — $processedString of $totalString';
  }

  @override
  String activityAggregatePausedDiscovering(int count) {
    return '$count folders paused';
  }

  @override
  String activityComplete(String folder) {
    return 'Finished indexing $folder';
  }

  @override
  String activityFailed(String folder) {
    return 'Indexing $folder failed';
  }

  @override
  String get activityCatalog => 'the catalog';

  @override
  String get activityRepacing => 'Re-checking from the start at low speed';

  @override
  String get activityRepacingNormal =>
      'Re-checking from the start at normal speed';

  @override
  String get activityPause => 'Pause';

  @override
  String get activityResume => 'Resume';

  @override
  String get activityCancel => 'Cancel';

  @override
  String get activityViewAll => 'View';

  @override
  String get activityPriorityLow => 'Low';

  @override
  String get activityPriorityNormal => 'Normal';

  @override
  String get activityDismiss => 'Dismiss';

  @override
  String get musicLookupLabel => 'Look up music info online';

  @override
  String get musicLookupDescription =>
      'Lets Alexandria fetch lyrics and artist photography from MusicBrainz, Wikimedia Commons and LRCLIB. This is the only part of Alexandria that reaches the internet, and it only does so when you ask for a lookup. Nothing about you is sent — only an artist name, a track title, an album name and a duration.';

  @override
  String get musicLookupContactLabel => 'Contact for the lookup services';

  @override
  String get musicLookupContactHelp =>
      'MusicBrainz requires a way to reach whoever is making the requests. Leave it as it is to use the application\'s own address, or put your own here.';

  @override
  String get preferencesMusicLookupLabel => 'Music info';

  @override
  String get lyricsOpen => 'Lyrics';

  @override
  String get lyricsClose => 'Hide lyrics';

  @override
  String get lyricsNone => 'No lyrics were found for this track.';

  @override
  String get lyricsSwitchedOff =>
      'Music info lookup is switched off. Turn it on in Preferences to fetch lyrics.';

  @override
  String get audioSoundBarsLabel => 'Sound levels';

  @override
  String get audioTransportSemantics => 'Player controls';

  @override
  String get albumCoverLabel => 'Album cover';

  @override
  String get enrichmentLookupFailed =>
      'The lookup could not be completed. The services may be unreachable — try again later.';

  @override
  String get enrichmentUntagged =>
      'This track has no artist or title tag to look anything up with.';

  @override
  String get musicStatsOpen => 'Music stats';

  @override
  String get musicStatsTitle => 'Music stats';

  @override
  String get musicStatsNone =>
      'Nothing has been counted yet. A track counts once you have heard half of it, or four minutes of it — whichever comes first.';

  @override
  String musicStatsSummary(num plays, num tracks) {
    String _temp0 = intl.Intl.pluralLogic(
      plays,
      locale: localeName,
      other: '$plays plays',
      one: '1 play',
    );
    String _temp1 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracks tracks',
      one: '1 track',
    );
    return '$_temp0 across $_temp1';
  }

  @override
  String musicStatsPeriod(String first, String last) {
    return 'Counted from $first to $last';
  }

  @override
  String get musicStatsRefresh => 'Read again';

  @override
  String get musicStatsTopTracks => 'Most played tracks';

  @override
  String get musicStatsTopArtists => 'Most played artists';

  @override
  String get musicStatsTopAlbums => 'Most played albums';

  @override
  String get musicStatsTopGenres => 'Most played genres';

  @override
  String musicStatsPlays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String musicStatsArtistTracks(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get musicStatsUntaggedNote =>
      'Tracks with no tags are counted in the totals, and can only be listed by name.';

  @override
  String get destinationLibraries => 'Libraries';

  @override
  String get libraryAlreadyOne => 'That folder is already a library.';
}
