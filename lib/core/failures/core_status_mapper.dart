import '../bindings/alexandria_bindings.dart';
import 'core_rejection.dart';
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
Failure mapCoreStatus(
  CoreStatusFamily family,
  int code, {
  CoreRejection? rejection,
}) {
  if (family.isOk(code)) {
    return Failure.unexpected(family: family, code: code);
  }

  // A rejection the core named wins over the status code's generic meaning:
  // both say the input was refused, and only this one can say which rule it
  // broke. Applied here rather than per family, because the error envelope is
  // the core's, not any one area's.
  if (rejection != null) {
    return Failure.rejected(family: family, code: code, rejection: rejection);
  }

  return switch (family) {
    CoreStatusFamily.indexing => _mapIndex(code),
    CoreStatusFamily.file => _mapFile(code),
    CoreStatusFamily.collection => _mapCollection(code),
    CoreStatusFamily.bookmark => _mapBookmark(code),
    CoreStatusFamily.watchlist => _mapWatchlist(code),
    CoreStatusFamily.readingList => _mapReadingList(code),
    CoreStatusFamily.playlist => _mapPlaylist(code),
    CoreStatusFamily.enrichment => _mapEnrichment(code),
    CoreStatusFamily.library => _mapLibrary(code),
    CoreStatusFamily.auth => _mapAuth(code),
    CoreStatusFamily.playback => _mapPlayback(code),
    CoreStatusFamily.run => _mapRun(code),
    CoreStatusFamily.settings => _mapSettings(code),
  };
}

// The settings read carries only these three failures: it reads a value the
// core process already holds, so there is no input to reject and nothing to
// look up.
Failure _mapSettings(int code) => switch (code) {
  SETTINGS_ERR_UNAUTHORIZED => Failure.unauthorized(
    family: CoreStatusFamily.settings,
    code: code,
  ),
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
  RUN_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  _ => Failure.unexpected(family: CoreStatusFamily.run, code: code),
};

// The index family is the one that predates the others: its "other" is 4, where
// every later family uses 9 and reserves 4 for "not found".
Failure _mapIndex(int code) => switch (code) {
  INDEX_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  INDEX_ERR_UNAUTHORIZED => Failure.unauthorized(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  INDEX_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  INDEX_ERR_OTHER => Failure.unexpected(
    family: CoreStatusFamily.indexing,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.indexing, code: code),
};

Failure _mapPlayback(int code) => switch (code) {
  PLAYBACK_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.playback,
    code: code,
  ),
  PLAYBACK_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  // UC-19 AF-01 and UC-20 AF-01: the record is there and the file is not.
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
  FILE_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  COLLECTION_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  BOOKMARK_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  WATCHLIST_ERR_UNAUTHORIZED => Failure.unauthorized(
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
  READING_LIST_ERR_UNAUTHORIZED => Failure.unauthorized(
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

// The playlist family follows the same five-plus-other shape as the reading
// list and watchlist families beside it — confirmed against alexandria-ffi's
// own `PLAYLIST_ERR_*` constants rather than assumed from the pattern.
Failure _mapPlaylist(int code) => switch (code) {
  PLAYLIST_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.playlist,
    code: code,
  ),
  PLAYLIST_ERR_UNAUTHORIZED => Failure.unauthorized(
    family: CoreStatusFamily.playlist,
    code: code,
  ),
  PLAYLIST_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.playlist,
    code: code,
  ),
  PLAYLIST_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.playlist,
    code: code,
  ),
  PLAYLIST_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.playlist,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.playlist, code: code),
};

// The enrichment family carries one code the others do not:
// ENRICHMENT_ERR_UNAVAILABLE, which is not something the caller did. The
// request was well formed and this installation simply has enrichment
// switched off, or on with no MusicBrainz contact configured. It maps to
// `configuration` rather than `invalidState` so a surface can tell the owner
// their administrator has not set this up, instead of implying they asked
// for something wrong.
Failure _mapEnrichment(int code) => switch (code) {
  ENRICHMENT_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.enrichment,
    code: code,
  ),
  ENRICHMENT_ERR_UNAUTHORIZED => Failure.unauthorized(
    family: CoreStatusFamily.enrichment,
    code: code,
  ),
  ENRICHMENT_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.enrichment,
    code: code,
  ),
  ENRICHMENT_ERR_NOT_FOUND => Failure.notFound(
    family: CoreStatusFamily.enrichment,
    code: code,
  ),
  ENRICHMENT_ERR_UNAVAILABLE => Failure.configuration(
    family: CoreStatusFamily.enrichment,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.enrichment, code: code),
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
  LIBRARY_ERR_UNAUTHORIZED => Failure.unauthorized(
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

// The auth family has no not-found and no disk code, and is the only one with a
// configuration code: local login can fail because the core's own auth
// configuration is unusable.
Failure _mapAuth(int code) => switch (code) {
  AUTH_ERR_INVALID_INPUT => Failure.invalidInput(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_UNAUTHORIZED => Failure.unauthorized(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_NOT_INITIALIZED => Failure.notInitialized(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_INVALID_STATE => Failure.invalidState(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_CONFIG => Failure.configuration(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_CONFLICT => Failure.conflict(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_RATE_LIMITED => Failure.rateLimited(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  AUTH_ERR_SERVICE_UNAVAILABLE => Failure.serviceUnavailable(
    family: CoreStatusFamily.auth,
    code: code,
  ),
  _ => Failure.unexpected(family: CoreStatusFamily.auth, code: code),
};
