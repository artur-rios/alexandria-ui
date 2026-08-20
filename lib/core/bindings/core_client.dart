import 'core_isolate.dart';

/// The application's view of the Alexandria core.
///
/// Every gateway is built on this, and nothing above the data layer touches
/// `dart:ffi` — the analyzer rule in `tools/alexandria_lints` enforces that
/// (IR-02). Only the operations the foundation itself needs are declared here;
/// each use case adds its own gateway over the same [CoreIsolate], rather than
/// this class growing a method per call.
abstract interface class CoreClient {
  /// The core's version string, e.g. `0.1.0`.
  Future<String?> version();

  /// The core's health status code. `200` when healthy — see
  /// `coreHealthyStatusCode`.
  Future<int> healthStatus();

  /// Initializes the core against [databasePath], creating and migrating the
  /// database on demand. Returns the core's status code.
  Future<int> initialize(String databasePath);

  /// Authenticates through `alexandria_auth_local_login` (FR-AU-04).
  ///
  /// [jsonBody] is the body the core's matching HTTP route takes —
  /// `{"email":…,"password":…}`. It carries the plaintext password, so it is
  /// built for this call and never logged or retained (FR-AU-11).
  ///
  /// Returns the core's status code and, on success, the `LocalLoginResult`
  /// JSON. The string is freed on the worker before this returns, including
  /// when the call fails (NFR-13).
  Future<CoreJsonResponse> authLocalLogin(String jsonBody);

  /// Creates the owner's account through `alexandria_auth_local_register`
  /// (FR-AU-02).
  ///
  /// [jsonBody] is the body the core's matching HTTP route takes —
  /// `{"email":…,"password":…,"passwordConfirmation":…}`. It carries both
  /// plaintext entries, so it is built for this call and never logged or
  /// retained (FR-AU-11).
  ///
  /// Takes no session credential: there is nothing to authenticate with before
  /// an account exists. Succeeds only once — a second call answers
  /// `AUTH_ERR_CONFLICT`.
  Future<CoreJsonResponse> authLocalRegister(String jsonBody);

  /// Reads the owner's account through `alexandria_auth_local_account`
  /// (FR-AU-14, UC-42).
  ///
  /// Answers the address and how many recovery codes remain unconsumed.
  /// [token] is the active session's credential, never logged or retained
  /// (FR-AU-11).
  Future<CoreJsonResponse> authLocalAccount(String token);

  /// Replaces the whole recovery-code set through
  /// `alexandria_auth_local_regenerate_recovery_codes` (FR-AU-17, UC-42).
  ///
  /// Answers the ten new codes, once. Every code from the previous set stops
  /// working. [token] is the active session's credential.
  Future<CoreJsonResponse> authLocalRegenerateRecoveryCodes(String token);

  /// Replaces a forgotten password with a recovery code through
  /// `alexandria_auth_local_redeem_recovery_code` (FR-AU-15, UC-41).
  ///
  /// [jsonBody] is the body the core's matching HTTP route takes —
  /// `{"code":…,"newPassword":…,"passwordConfirmation":…}` — built for this
  /// call and never logged or retained: it carries both a plaintext password
  /// and a code that is itself a credential (FR-AU-11).
  ///
  /// Takes no session credential, and that is the point of it: this is the
  /// call for an owner who cannot sign in. Consuming the code invalidates
  /// every existing session.
  Future<CoreJsonResponse> authLocalRedeemRecoveryCode(String jsonBody);

  /// Replaces the stored credentials through
  /// `alexandria_auth_local_set_credentials` (FR-AU-10, UC-04).
  ///
  /// [jsonBody] is the body the core's matching HTTP route takes —
  /// `{"email":…,"password":…}` — and [token] is the active session's
  /// credential, which this call requires: it changes credentials that already
  /// exist, where registration creates the first ones.
  ///
  /// Both strings are built for this call and never logged or retained: one
  /// carries the new plaintext password and the other the session credential
  /// (FR-AU-11).
  Future<CoreJsonResponse> authLocalSetCredentials(
    String jsonBody,
    String token,
  );

  /// Starts an index scan of [root] through `alexandria_index_start`
  /// (FR-LB-05, UC-06).
  ///
  /// The scan runs in the background on the core's own runtime; this returns
  /// as soon as it has been started. [token] is the active session's
  /// credential.
  ///
  /// The run id comes back in a fixed-size array inside the result struct
  /// rather than as an allocation, so there is nothing to free on this path.
  Future<CoreRunStart> indexStart(String root, String token);

  /// Reads a run's status and outcome through
  /// `alexandria_index_run_status_json` (FR-LB-07, FR-LB-08, UC-06).
  ///
  /// The status codes are the `RUN_*` family, not `INDEX_*`: they overlap
  /// numerically and disagree on what `4` means.
  Future<CoreJsonResponse> indexRunStatus(String runId, String token);

  /// Starts a refresh run over everything already cataloged through
  /// `alexandria_index_refresh_start` (FR-LB-06, UC-07).
  ///
  /// Takes no root: a refresh covers the whole catalog rather than one folder,
  /// which is the difference between it and [indexStart].
  Future<CoreRunStart> indexRefreshStart(String token);

  /// How many files the catalog holds, through
  /// `alexandria_index_count_files` (UC-07 AF-02).
  ///
  /// Answers the one question the refresh needs before it starts: there is
  /// nothing to re-check in an empty catalog.
  Future<int> indexCountFiles();

  /// Lists files matching [jsonFilters] through `alexandria_files_list`
  /// (FR-CT-02, UC-09).
  ///
  /// [jsonFilters] is the body the core's matching HTTP route takes —
  /// `{"type":"audio","state":"active"}`.
  Future<CoreJsonResponse> filesList(String jsonFilters, String token);

  /// Reads one file by its UUID through `alexandria_file_get_by_uuid`
  /// (FR-CT-05, UC-13).
  ///
  /// Answers the `FileView` body: the record a listing would show, plus
  /// the type-specific metadata and the values the core extracted from the
  /// file — none of which a listing carries.
  Future<CoreJsonResponse> fileByUuid(String uuid, String token);

  /// Replaces the type-specific metadata of the file [uuid] identifies
  /// (FR-ME-01, UC-15).
  ///
  /// [jsonPatch] is the whole metadata object, tagged by type. The core
  /// replaces the editable columns with it rather than merging: a field the
  /// body omits is written as NULL, which is how a field is cleared.
  Future<CoreJsonResponse> fileEditMetadata(
    String uuid,
    String jsonPatch,
    String token,
  );

  /// Resolves the file [uuid] identifies to something a local player can open,
  /// through `alexandria_file_playback_source` (FR-PL-01, FR-PL-05).
  ///
  /// Answers `{uuid, path, mimeType, sizeBytes}`. No bytes cross the boundary:
  /// the player opens the path directly, which is what playing without
  /// transcoding needs.
  Future<CoreJsonResponse> filePlaybackSource(String uuid, String token);

  /// Reads one page of a comic-book archive through `alexandria_comic_page`
  /// (FR-VW-03, UC-23).
  ///
  /// Answers `{uuid, page, pageCount, mimeType, bytesBase64}`. The bytes do
  /// cross the boundary here, unlike playback's: a page has no path of its own
  /// because it lives inside the archive, and it is bounded — which is what
  /// lets the archive be read without being extracted to disk.
  Future<CoreJsonResponse> comicPage(String uuid, int page, String token);

  /// Reads a text file's content from disk through
  /// `alexandria_file_read_content` (FR-ME-06, UC-18).
  ///
  /// Answers the `FileContent` body: the uuid and the content as a string.
  Future<CoreJsonResponse> fileReadContent(String uuid, String token);

  /// Writes edited content back to a text file through
  /// `alexandria_file_edit_content` (FR-ME-08, UC-18).
  ///
  /// [jsonBody] carries the content. Answers the `File` record the core
  /// refreshed, whose content hash is what the next save compares against.
  Future<CoreJsonResponse> fileEditContent(
    String uuid,
    String jsonBody,
    String token,
  );

  /// Renames the file [uuid] identifies, on disk and in the catalog, through
  /// `alexandria_file_rename` (FR-ME-04, UC-17).
  ///
  /// Answers the `File` body the core echoed. A disk failure comes back as
  /// `FILE_ERR_DISK` and leaves the catalog untouched.
  Future<CoreJsonResponse> fileRename(String uuid, String name, String token);

  /// Soft-deletes the file [uuid] identifies through
  /// `alexandria_file_soft_delete` (FR-LC-01, UC-33).
  ///
  /// Answers the `File` the core echoed, now marked deleted. The file on disk
  /// is untouched: only the catalog row changes.
  Future<CoreJsonResponse> fileSoftDelete(String uuid, String token);

  /// Restores the file [uuid] identifies through `alexandria_file_restore`
  /// (FR-LC-04, UC-34).
  ///
  /// The core enforces the retention window: a record past it comes back as
  /// `FILE_ERR_NOT_FOUND`.
  Future<CoreJsonResponse> fileRestore(String uuid, String token);

  /// Purges the file [uuid] identifies through `alexandria_file_purge`
  /// (FR-LC-05, UC-35).
  ///
  /// The catalog row only; the file on disk is untouched. The core enforces
  /// the retention window and answers `FILE_ERR_INVALID_STATE` for a record
  /// still inside it, or one that is not deleted at all.
  Future<CoreJsonResponse> filePurge(String uuid, String token);

  /// Purges the file [uuid] identifies from disk as well as from the catalog,
  /// through `alexandria_file_purge_on_disk` (FR-LC-06, UC-36).
  ///
  /// Answers a `PurgeOnDiskOutcome`, whose `diskFilePresent` says whether
  /// there was a file to remove. A disk failure comes back as `FILE_ERR_DISK`
  /// and leaves both the file and the record alone.
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid, String token);

  /// Creates a browser bookmark through `alexandria_bookmark_create`
  /// (FR-OG-08, UC-28).
  Future<CoreJsonResponse> bookmarkCreate(String jsonBody, String token);

  /// Updates a bookmark through `alexandria_bookmark_update` (FR-OG-09).
  Future<CoreJsonResponse> bookmarkUpdate(
    String uuid,
    String jsonBody,
    String token,
  );

  /// Browses bookmarks through `alexandria_bookmarks_list` (FR-OG-10).
  ///
  /// [jsonFilters] optionally carries a containing collection; an empty
  /// string is every bookmark.
  Future<CoreJsonResponse> bookmarksList(String jsonFilters, String token);

  /// Soft-deletes the bookmark [uuid] identifies through
  /// `alexandria_bookmark_soft_delete` (FR-LC-01, UC-33).
  Future<CoreJsonResponse> bookmarkSoftDelete(String uuid, String token);

  /// Restores the bookmark [uuid] identifies through
  /// `alexandria_bookmark_restore` (FR-LC-04, UC-34).
  Future<CoreJsonResponse> bookmarkRestore(String uuid, String token);

  /// Purges the bookmark [uuid] identifies through
  /// `alexandria_bookmark_purge` (FR-LC-05, UC-35).
  Future<CoreJsonResponse> bookmarkPurge(String uuid, String token);

  /// Creates a watchlist through `alexandria_watchlist_create` (FR-TR-01).
  Future<CoreJsonResponse> watchlistCreate(String jsonBody, String token);

  /// Deletes one through `alexandria_watchlist_delete` (FR-TR-02).
  Future<CoreJsonResponse> watchlistDelete(String uuid, String token);

  /// Adds a video through `alexandria_watchlist_add_video` (FR-TR-03).
  Future<CoreJsonResponse> watchlistAddVideo(
    String uuid,
    String jsonBody,
    String token,
  );

  /// Removes one through `alexandria_watchlist_remove_video` (FR-TR-04).
  Future<CoreJsonResponse> watchlistRemoveVideo(
    String uuid,
    String videoUuid,
    String token,
  );

  /// Records progress through `alexandria_watchlist_update_progress`
  /// (FR-TR-05 … FR-TR-07).
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
    String token,
  );

  /// Creates a reading list through `alexandria_reading_list_create`
  /// (FR-TR-08).
  Future<CoreJsonResponse> readingListCreate(String jsonBody, String token);

  /// Deletes one through `alexandria_reading_list_delete` (FR-TR-09).
  Future<CoreJsonResponse> readingListDelete(String uuid, String token);

  /// Adds an item through `alexandria_reading_list_add_item` (FR-TR-10).
  Future<CoreJsonResponse> readingListAddItem(
    String uuid,
    String jsonBody,
    String token,
  );

  /// Removes one through `alexandria_reading_list_remove_item` (FR-TR-11).
  Future<CoreJsonResponse> readingListRemoveItem(
    String uuid,
    String itemUuid,
    String token,
  );

  /// Records progress through `alexandria_reading_list_update_progress`
  /// (FR-TR-12 … FR-TR-14).
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
    String token,
  );

  /// Browses reading lists through `alexandria_reading_lists_list`
  /// (FR-TR-11).
  Future<CoreJsonResponse> readingListsList(String jsonFilters, String token);

  /// Browses watchlists and the watch progress of everything they track
  /// through `alexandria_watchlists_list` (FR-WL-08).
  ///
  /// [jsonFilters] is the filter body; an empty string means every watchlist.
  /// UC-16 reads it to answer one question — is this video's progress counted
  /// per episode — and UC-29 and UC-30 are what present it.
  Future<CoreJsonResponse> watchlistsList(String jsonFilters, String token);

  /// Releases the worker isolate and the shared library.
  Future<void> dispose();
}

/// What starting a run answered: the core's status code and, on success, the
/// run's identifier.
typedef CoreRunStart = ({int status, String runId});

/// A core call's status code and its JSON payload, if it returned one.
///
/// The payload is already a Dart string: the pointer the core allocated was
/// read and freed on the worker isolate, so nothing above this line owns
/// native memory (IR-09, NFR-13).
typedef CoreJsonResponse = ({int status, String? json});

/// The [CoreClient] backed by the real core over FFI.
class FfiCoreClient implements CoreClient {
  /// Wraps an already-spawned worker.
  const FfiCoreClient(this._isolate);

  /// Spawns the worker and loads the shared library at [libraryPath].
  static Future<FfiCoreClient> load(String libraryPath) async =>
      FfiCoreClient(await CoreIsolate.spawn(libraryPath));

  final CoreIsolate _isolate;

  /// The shared library this client loaded, for the failure message that names
  /// the path attempted.
  String get libraryPath => _isolate.libraryPath;

  @override
  Future<String?> version() async => await _isolate.call('version') as String?;

  @override
  Future<int> healthStatus() async =>
      await _isolate.call('healthStatus') as int;

  @override
  Future<int> initialize(String databasePath) async =>
      await _isolate.call('init', [databasePath]) as int;

  @override
  Future<CoreJsonResponse> authLocalLogin(String jsonBody) async =>
      await _isolate.call('authLocalLogin', [jsonBody]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> authLocalRegister(String jsonBody) async =>
      await _isolate.call('authLocalRegister', [jsonBody]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> authLocalAccount(String token) async =>
      await _isolate.call('authLocalAccount', [token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> authLocalRegenerateRecoveryCodes(
    String token,
  ) async =>
      await _isolate.call('authLocalRegenerateRecoveryCodes', [token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> authLocalRedeemRecoveryCode(String jsonBody) async =>
      await _isolate.call('authLocalRedeemRecoveryCode', [jsonBody])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> authLocalSetCredentials(
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('authLocalSetCredentials', [jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreRunStart> indexStart(String root, String token) async =>
      await _isolate.call('indexStart', [root, token]) as CoreRunStart;

  @override
  Future<CoreJsonResponse> indexRunStatus(String runId, String token) async =>
      await _isolate.call('indexRunStatus', [runId, token]) as CoreJsonResponse;

  @override
  Future<CoreRunStart> indexRefreshStart(String token) async =>
      await _isolate.call('indexRefreshStart', [token]) as CoreRunStart;

  @override
  Future<int> indexCountFiles() async =>
      await _isolate.call('countFiles') as int;

  @override
  Future<CoreJsonResponse> filesList(String jsonFilters, String token) async =>
      await _isolate.call('filesList', [jsonFilters, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileByUuid(String uuid, String token) async =>
      await _isolate.call('fileByUuid', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileEditMetadata(
    String uuid,
    String jsonPatch,
    String token,
  ) async =>
      await _isolate.call('fileEditMetadata', [uuid, jsonPatch, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> filePlaybackSource(
    String uuid,
    String token,
  ) async =>
      await _isolate.call('filePlaybackSource', [uuid, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> comicPage(
    String uuid,
    int page,
    String token,
  ) async =>
      await _isolate.call('comicPage', [uuid, page, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileReadContent(String uuid, String token) async =>
      await _isolate.call('fileReadContent', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileEditContent(
    String uuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('fileEditContent', [uuid, jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileRename(
    String uuid,
    String name,
    String token,
  ) async =>
      await _isolate.call('fileRename', [uuid, name, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileSoftDelete(String uuid, String token) async =>
      await _isolate.call('fileSoftDelete', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarkSoftDelete(
    String uuid,
    String token,
  ) async =>
      await _isolate.call('bookmarkSoftDelete', [uuid, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> fileRestore(String uuid, String token) async =>
      await _isolate.call('fileRestore', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarkRestore(String uuid, String token) async =>
      await _isolate.call('bookmarkRestore', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> filePurge(String uuid, String token) async =>
      await _isolate.call('filePurge', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid, String token) async =>
      await _isolate.call('filePurgeOnDisk', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarkPurge(String uuid, String token) async =>
      await _isolate.call('bookmarkPurge', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarkCreate(
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('bookmarkCreate', [jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarkUpdate(
    String uuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('bookmarkUpdate', [uuid, jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> bookmarksList(
    String jsonFilters,
    String token,
  ) async =>
      await _isolate.call('bookmarksList', [jsonFilters, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListCreate(
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('readingListCreate', [jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListDelete(String uuid, String token) async =>
      await _isolate.call('readingListDelete', [uuid, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListAddItem(
    String uuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('readingListAddItem', [uuid, jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListRemoveItem(
    String uuid,
    String itemUuid,
    String token,
  ) async =>
      await _isolate.call('readingListRemoveItem', [uuid, itemUuid, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('readingListUpdateProgress', [
            uuid,
            itemUuid,
            jsonBody,
            token,
          ])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> readingListsList(
    String jsonFilters,
    String token,
  ) async =>
      await _isolate.call('readingListsList', [jsonFilters, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistCreate(
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('watchlistCreate', [jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistDelete(String uuid, String token) async =>
      await _isolate.call('watchlistDelete', [uuid, token]) as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistAddVideo(
    String uuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('watchlistAddVideo', [uuid, jsonBody, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistRemoveVideo(
    String uuid,
    String videoUuid,
    String token,
  ) async =>
      await _isolate.call('watchlistRemoveVideo', [uuid, videoUuid, token])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
    String token,
  ) async =>
      await _isolate.call('watchlistUpdateProgress', [
            uuid,
            videoUuid,
            jsonBody,
            token,
          ])
          as CoreJsonResponse;

  @override
  Future<CoreJsonResponse> watchlistsList(
    String jsonFilters,
    String token,
  ) async =>
      await _isolate.call('watchlistsList', [jsonFilters, token])
          as CoreJsonResponse;

  @override
  Future<void> dispose() => _isolate.dispose();
}
