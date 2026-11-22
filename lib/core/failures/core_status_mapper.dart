import '../bindings/alexandria_bindings.dart';
import 'core_status.dart';
import 'failure.dart';

/// Translates a status code the core returned into exactly one [Failure]
/// (IR-08).
///
/// [family] is required because the core's codes only mean something within
/// their own set: `4` is `INDEX_ERR_OTHER` but `FILE_ERR_NOT_FOUND`. Passing a
/// success code is a programming error — the caller checks
/// [CoreStatusFamily.isOk] first — and is reported as [UnexpectedFailure]
/// rather than silently producing a failure that reads like a real one.
///
/// Code 2 has no arm in any family: it was `*_ERR_UNAUTHORIZED`, which core
/// 0.7.0 retired with authentication, and it reads as unexpected like any
/// other code this application does not know.
Failure mapCoreStatus(CoreStatusFamily family, int code) {
  if (family.isOk(code)) {
    return Failure.unexpected(family: family, code: code);
  }

  return switch (family) {
    CoreStatusFamily.indexing => _mapIndex(code),
    CoreStatusFamily.file => _mapFile(code),
    CoreStatusFamily.collection => _mapCollection(code),
    CoreStatusFamily.bookmark => _mapBookmark(code),
    CoreStatusFamily.watchlist => _mapWatchlist(code),
    CoreStatusFamily.readingList => _mapReadingList(code),
    CoreStatusFamily.library => _mapLibrary(code),
    CoreStatusFamily.playback => _mapPlayback(code),
    CoreStatusFamily.run => _mapRun(code),
    CoreStatusFamily.settings => _mapSettings(code),
  };
}

// The settings read carries only these two failures: it reads a value the
// core process already holds, so there is no input to reject and nothing to
// look up.
Failure _mapSettings(int code) => switch (code) {
  SETTINGS_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.settings,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.settings, code: code),
};

// The run family reserves 4 for "not found" and 9 for "other", where the index
// family it sits beside uses 4 for "other". Mapping one through the other is
// exactly the misread the separate families exist to prevent.
Failure _mapRun(int code) => switch (code) {
  RUN_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.run,
    code: code,
  ),
  RUN_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.run,
    code: code,
  ),
  RUN_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.run,
    code: code,
  ),
  // Pausing a run that is not running, or resuming one that is not paused.
  // Every other family maps its invalid-state code here; reading this one as
  // unexpected told the owner something broke when the run had only moved on.
  RUN_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.run,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.run, code: code),
};

// The index family is the one that predates the others: its "other" is 4, where
// every later family uses 9 and reserves 4 for "not found".
Failure _mapIndex(int code) => switch (code) {
  INDEX_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  INDEX_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  // A "not now": the run is settling and the same call will be accepted
  // once it has.
  INDEX_ERR_BUSY => Failure.invalidState(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  // A library run (0.6.0): the library is not registered any more.
  INDEX_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  // A library run (0.6.0): the library already has a running or paused run,
  // and only one may be unfinished at a time.
  INDEX_ERR_CONFLICT => Failure.conflict(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  // `INDEX_ERR_OTHER` needs no arm of its own: it maps to the same
  // unexpected failure the default below produces, and spelling it out
  // twice invited the reading that the two differ.
  _ => Failure.unexpected(family: CoreStatusFamily.indexing, code: code),
};

Failure _mapPlayback(int code) => switch (code) {
  PLAYBACK_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  PLAYBACK_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  PLAYBACK_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  PLAYBACK_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  // UC-19 AF-01: the record is there and the file is not.
  PLAYBACK_ERR_DISK => Failure.disk(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.playback, code: code),
};

Failure _mapFile(int code) => switch (code) {
  FILE_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.file,
    code: code,
  ),
  FILE_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.file,
    code: code,
  ),
  FILE_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.file,
    code: code,
  ),
  FILE_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.file,
    code: code,
  ),
  FILE_ERR_DISK => Failure.disk(family: CoreStatusFamily.file, code: code),
  FILE_ERR_INTEGRITY => Failure.integrity(
    family: CoreStatusFamily.file,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.file, code: code),
};

Failure _mapCollection(int code) => switch (code) {
  COLLECTION_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.collection,
    code: code,
  ),
  COLLECTION_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.collection,
    code: code,
  ),
  COLLECTION_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.collection,
    code: code,
  ),
  COLLECTION_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.collection,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.collection, code: code),
};

Failure _mapBookmark(int code) => switch (code) {
  BOOKMARK_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.bookmark,
    code: code,
  ),
  BOOKMARK_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.bookmark,
    code: code,
  ),
  BOOKMARK_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.bookmark,
    code: code,
  ),
  BOOKMARK_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.bookmark,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.bookmark, code: code),
};

Failure _mapWatchlist(int code) => switch (code) {
  WATCHLIST_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.watchlist,
    code: code,
  ),
  WATCHLIST_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.watchlist,
    code: code,
  ),
  WATCHLIST_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.watchlist,
    code: code,
  ),
  WATCHLIST_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.watchlist,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.watchlist, code: code),
};

Failure _mapReadingList(int code) => switch (code) {
  READING_LIST_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.readingList,
    code: code,
  ),
  READING_LIST_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.readingList,
    code: code,
  ),
  READING_LIST_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.readingList,
    code: code,
  ),
  READING_LIST_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.readingList,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.readingList, code: code),
};

// The library family carries one code the others do not:
// LIBRARY_ERR_CONFLICT, for a folder that overlaps a library already
// registered. Mapped to `conflict` rather than `invalidInput` because the
// request was well formed and the folder is a real one — what is wrong is
// the catalog's current state, and a surface that can tell those apart says
// "that folder is already inside Photography" rather than "that is not a
// folder".
Failure _mapLibrary(int code) => switch (code) {
  LIBRARY_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.library,
    code: code,
  ),
  LIBRARY_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.library,
    code: code,
  ),
  LIBRARY_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.library,
    code: code,
  ),
  LIBRARY_ERR_CONFLICT => Failure.conflict(
    family: CoreStatusFamily.library,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.library, code: code),
};
