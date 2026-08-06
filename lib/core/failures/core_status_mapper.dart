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
    CoreStatusFamily.auth => _mapAuth(code),
  };
}

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
  _ => Failure.unexpected(family: CoreStatusFamily.auth, code: code),
};
