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
  String get catalogLockedTitle => 'Confirm your e-mail address';

  @override
  String catalogLockedBody(String email) {
    return 'Alexandria stays locked until the address $email is confirmed.';
  }

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
  String get catalogLockedUndeliverable =>
      'The confirmation message could not be sent, so it is not on its way. Alexandria cannot deliver e-mail yet.';

  @override
  String get failureUnexpected => 'Something went wrong in Alexandria.';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading';

  @override
  String get shellAreaPending => 'Nothing to show here yet.';

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
  String get preferencesUnsaved =>
      'Your choice is applied, but it could not be saved — it will not be remembered the next time Alexandria starts.';

  @override
  String get preferencesClose => 'Done';

  @override
  String get changeCredentialsOpen => 'Change your e-mail and password';

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
  String get dismiss => 'Dismiss';

  @override
  String get librarySourcesIndex => 'Index';

  @override
  String get librarySourcesIndexing => 'Scanning…';

  @override
  String librarySourcesRunComplete(int scanned, int indexed, int skipped) {
    return 'Scanned $scanned files, cataloged $indexed, skipped $skipped.';
  }

  @override
  String librarySourcesRunFailedCount(int failed) {
    return '$failed files could not be read.';
  }

  @override
  String get librarySourcesRunFailed => 'The scan did not finish.';

  @override
  String get librarySourcesRunInterrupted =>
      'The scan did not finish, because Alexandria was closed while it was running.';

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
  String get librarySourcesRefresh => 'Refresh the catalog';

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
  String get librarySourcesMissingReviewPending =>
      'Reviewing missing files arrives with its own use case.';

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
      'This record is deleted. Restoring it arrives with its own use case.';

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
  String get dashboardRecent => 'Recently added';

  @override
  String get dashboardRecentNone => 'Nothing has been added yet.';

  @override
  String get dashboardInProgress => 'In progress';

  @override
  String get dashboardInProgressNone =>
      'Nothing is in progress. Watchlists and reading lists arrive with their own use cases.';

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
}
