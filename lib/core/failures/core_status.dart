import '../bindings/alexandria_bindings.dart';

/// The families of status code the Alexandria core returns.
///
/// The core deliberately keeps a separate set per area so each can grow without
/// colliding, which means the numbers overlap: `4` is [CoreStatusFamily.indexing]'s
/// *other* but [CoreStatusFamily.file]'s *not found*. A status code is therefore
/// only meaningful together with the family that produced it, and every call
/// site names its family (IR-08).
enum CoreStatusFamily {
  /// `alexandria_index_*` — see `INDEX_*` in the core's header.
  indexing,

  /// `alexandria_file_*` and `alexandria_files_*` — see `FILE_*`.
  file,

  /// `alexandria_collection_*` — see `COLLECTION_*`.
  collection,

  /// `alexandria_bookmark_*` and `alexandria_bookmarks_*` — see `BOOKMARK_*`.
  bookmark,

  /// `alexandria_watchlist_*` and `alexandria_watchlists_*` — see `WATCHLIST_*`.
  watchlist,

  /// `alexandria_reading_list_*` — see `READING_LIST_*`.
  readingList,

  /// `alexandria_auth_local_*` — see `AUTH_*`.
  auth;

  /// The success code for this family.
  ///
  /// Every family agrees on zero by the core's own convention, but naming it
  /// per family keeps a future divergence from becoming a silent misread.
  int get okCode => switch (this) {
    CoreStatusFamily.indexing => INDEX_OK,
    CoreStatusFamily.file => FILE_OK,
    CoreStatusFamily.collection => COLLECTION_OK,
    CoreStatusFamily.bookmark => BOOKMARK_OK,
    CoreStatusFamily.watchlist => WATCHLIST_OK,
    CoreStatusFamily.readingList => READING_LIST_OK,
    CoreStatusFamily.auth => AUTH_OK,
  };

  /// Whether [code] means the operation succeeded.
  bool isOk(int code) => code == okCode;
}

/// The status code `alexandria_health_status_code` returns when the core is
/// healthy.
///
/// It is HTTP-shaped rather than zero — the core reports `200` — which is why
/// this is named here rather than assumed to follow the `*_OK` convention
/// (Operations & Infrastructure Document §5.2).
const int coreHealthyStatusCode = 200;
