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

  /// `alexandria_playlist_*` and `alexandria_playlists_*` — see `PLAYLIST_*`.
  playlist,

  /// `alexandria_play_record` and `alexandria_music_stats` — see `PLAY_*`.
  ///
  /// Its own family rather than [CoreStatusFamily.playlist]'s, on the
  /// header's own convention: a playlist is something the owner curates and
  /// a play is something that happened, and the two calls fail for different
  /// reasons. The family carries no invalid-state code — there is no state
  /// for a play to be in.
  play,

  /// `alexandria_enrichment_*` — see `ENRICHMENT_*` in the core's header.
  enrichment,

  /// `alexandria_library_*` and `alexandria_libraries_*` — see `LIBRARY_*`.
  library,

  /// `alexandria_auth_local_*` — see `AUTH_*`.
  auth,

  /// `alexandria_settings_json` — see `SETTINGS_*`.
  settings,

  /// `alexandria_file_playback_source`, `alexandria_file_thumbnail`, and
  /// `alexandria_comic_page` — see `PLAYBACK_*`.
  ///
  /// Its own family rather than the file one, on the header's own convention:
  /// the codes agree today, and a family is what makes a future divergence a
  /// compile-time question rather than a silent misread (IR-08).
  playback,

  /// `alexandria_index_run_status_json` — see `RUN_*`.
  ///
  /// Its own family rather than [CoreStatusFamily.indexing]'s, on the header's
  /// own instruction that the two "grow independently". They already differ
  /// where it matters: `4` is `RUN_ERR_NOT_FOUND` here and `INDEX_ERR_OTHER`
  /// there, so reading a run's status through the index family would report a
  /// run that does not exist as an unexpected failure.
  run;

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
    CoreStatusFamily.playlist => PLAYLIST_OK,
    CoreStatusFamily.play => PLAY_OK,
    CoreStatusFamily.enrichment => ENRICHMENT_OK,
    CoreStatusFamily.library => LIBRARY_OK,
    CoreStatusFamily.auth => AUTH_OK,
    CoreStatusFamily.settings => SETTINGS_OK,
    CoreStatusFamily.playback => PLAYBACK_OK,
    CoreStatusFamily.run => RUN_OK,
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
