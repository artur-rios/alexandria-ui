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
  String get failureConflict => 'That already exists in Alexandria.';

  @override
  String get failureUnexpected => 'Something went wrong in Alexandria.';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading';

  @override
  String get destinationHome => 'Home';

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
  String get dismiss => 'Dismiss';

  @override
  String get libraryRunStarting => 'Scanning…';

  @override
  String libraryRunComplete(int scanned, int indexed, int skipped) {
    return 'Scanned $scanned files, cataloged $indexed, skipped $skipped.';
  }

  @override
  String libraryRunFailedCount(int failed) {
    return '$failed files could not be read, and are not in your library. Re-scanning tries them again.';
  }

  @override
  String get libraryRunFailed => 'The scan did not finish.';

  @override
  String get libraryRunCancelled => 'The scan was cancelled.';

  @override
  String get libraryRunPaused =>
      'The scan is paused. It can be resumed from where it left off.';

  @override
  String get libraryRefreshAll => 'Re-check all libraries';

  @override
  String get libraryRunPause => 'Pause';

  @override
  String get libraryRunResume => 'Resume';

  @override
  String get libraryRunCancel => 'Cancel';

  @override
  String get libraryRunCancelTitle => 'Cancel this scan?';

  @override
  String get libraryRunCancelConfirm =>
      'This scan cannot be resumed once cancelled. Everything it has already cataloged stays in your library.';

  @override
  String get libraryRunCancelAction => 'Cancel the scan';

  @override
  String get libraryRefreshing => 'Re-checking the catalog…';

  @override
  String libraryRefreshComplete(int refreshed, int unchanged, int missing) {
    return '$refreshed files updated, $unchanged unchanged, $missing now missing.';
  }

  @override
  String get libraryRefreshRunning =>
      'The catalog is already being re-checked.';

  @override
  String get libraryRefreshEmpty =>
      'There is nothing cataloged yet. Add a library first.';

  @override
  String get libraryRefreshFailed => 'The catalog could not be re-checked.';

  @override
  String get destinationVideos => 'Videos';

  @override
  String get destinationMusic => 'Music';

  @override
  String get catalogEmptyTitle => 'Nothing of this type yet';

  @override
  String get catalogEmptyFirstRun =>
      'Nothing is in Alexandria yet. Add a folder as a library, and what is inside appears here as soon as it is indexed.';

  @override
  String get catalogFileMissing => 'Missing from disk';

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
  String get sortByAlbum => 'Album';

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
  String get pageEngineSandboxUnavailable =>
      'This page is drawn without its browser engine: Chromium\'s sandbox is not available on this computer, and the engine does not run without it.';

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
  String get librariesNone =>
      'You have no libraries yet. Add a folder as a library with the button above, and Alexandria indexes it.';

  @override
  String get librariesExplanation =>
      'A library is a folder Alexandria indexes, with its folders kept as they are. Adding one is how files get into Alexandria: everything you browse, play, or read comes from your libraries.';

  @override
  String get libraryNameLabel => 'Library name';

  @override
  String get libraryAdd => 'Add a library';

  @override
  String get libraryScan => 'Scan again';

  @override
  String get libraryRemove => 'Remove this library';

  @override
  String libraryRemoveMessage(String name) {
    return 'Remove $name? It is deleted from the catalog with its files, their reading and watching positions, and their place in collections. Nothing on disk is touched.';
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
  String get libraryToolsLabel => 'Library';

  @override
  String get libraryToolsGroupLibrary => 'Library';

  @override
  String get libraryToolsGroupTracking => 'Tracking';

  @override
  String get libraryToolsGroupReview => 'Review';

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
  String get destinationLibraries => 'Libraries';

  @override
  String get libraryRemovePausedNote => 'Its paused scan is discarded too.';

  @override
  String get libraryScanConflict =>
      'This library already has an unfinished scan. Resume or cancel it first.';

  @override
  String get libraryScanFailed => 'This library could not be scanned.';

  @override
  String libraryRunProgress(int processed, int total) {
    return 'Scanning… $processed of $total';
  }

  @override
  String get libraryMenuLibraries => 'Libraries';

  @override
  String get libraryMenuAdd => 'Add library…';

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
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next track';

  @override
  String get playerPrevious => 'Previous track';

  @override
  String get playerClose => 'Stop and close';

  @override
  String get playerNothingPlayable =>
      'None of the remaining tracks could be opened.';

  @override
  String get playerRescan => 'Re-check libraries';

  @override
  String playerSkipped(String name) {
    return 'Skipped $name: it could not be opened.';
  }

  @override
  String get libraryRemoveRunning =>
      'This library is being scanned. Pause or cancel the scan, then remove it.';

  @override
  String updateAvailableTitle(String version) {
    return 'Alexandria $version is available';
  }

  @override
  String updateYouHave(String current) {
    return 'You have $current.';
  }

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateSkip => 'Skip this version';

  @override
  String get updateOpenPage => 'Open release page';

  @override
  String get updateClose => 'Close';

  @override
  String get updateCancel => 'Cancel';

  @override
  String updateDownloading(String received, String total) {
    return 'Downloading… $received of $total';
  }

  @override
  String get updateDownloadFailed => 'The update could not be downloaded.';

  @override
  String get updateVerifyFailed =>
      'The download could not be verified, so it was not installed.';

  @override
  String get updateInstallFailed =>
      'The update could not be started, so this version is still the one running.';

  @override
  String get updateInstalling => 'Closing Alexandria to install the update…';

  @override
  String updatePreviousFailed(String to) {
    return 'The update to $to did not complete.';
  }

  @override
  String get updateManual =>
      'This copy of Alexandria can\'t update itself. Download the new version from the release page.';

  @override
  String get updatesCheckLabel => 'Check for updates at startup';

  @override
  String get updatesCheckDescription =>
      'Asks GitHub for the latest release. Nothing else is sent.';

  @override
  String get updatesCheckNow => 'Check now';

  @override
  String get updatesUpToDate => 'You\'re up to date.';

  @override
  String get updatesCheckFailed => 'Couldn\'t check for updates.';

  @override
  String get updateUnsavedTitle => 'Unsaved changes';

  @override
  String get updateUnsavedMessage =>
      'Updating closes Alexandria and discards the changes you have not saved. Cancel to go back and save them first.';

  @override
  String get updateUnsavedConfirm => 'Update and discard';

  @override
  String get updateScanTitle => 'A scan is running';

  @override
  String get updateScanMessage =>
      'It will pause, and you can resume it after the update.';

  @override
  String get updateScanConfirm => 'Update anyway';
}
