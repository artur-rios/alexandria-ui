// This file was excluded from analysis entirely until the FFI signature
// change of 2026-08-27, when a whole directory of hand-written code turned
// out to be unlinted and an arity error against the core survived a clean
// `flutter analyze`. The exclusion is now the generated bindings only, and
// this file is analysed like any other — including
// `cast_nullable_to_non_nullable`, which was written for exactly this
// boundary and so is the last rule that should be switched off here. Every
// reply the protocol guarantees goes through [_reply] instead.

import 'core_isolate.dart';

/// The application's view of the Alexandria core.
///
/// Every gateway is built on this, and nothing above the data layer touches
/// `dart:ffi` — the analyzer rule in `tools/alexandria_lints` enforces that
/// (IR-02). Only the operations the foundation itself needs are declared here;
/// each use case adds its own gateway over the same [CoreIsolate], rather than
/// this class growing a method per call.
abstract interface class CoreClient {
  /// The core's version string, e.g. `0.7.0`.
  Future<String?> version();

  /// The core's health status code. `200` when healthy — see
  /// `coreHealthyStatusCode`.
  Future<int> healthStatus();

  /// Initializes the core against [databasePath], creating and migrating the
  /// database on demand. Returns the core's status code.
  Future<int> initialize(String databasePath);

  /// Re-indexes the library [uuid] through `alexandria_library_index_start`
  /// (core UC-01, 0.6.0).
  ///
  /// The only way to scan a folder again: the core indexes nothing that is
  /// not a library. [priority] means what it means to [indexRefreshStart].
  /// Refused with `INDEX_ERR_CONFLICT` while the library already has a
  /// running or paused run, and `INDEX_ERR_NOT_FOUND` for a library the core
  /// no longer has.
  Future<CoreRunStart> libraryIndexStart(String uuid, [String? priority]);

  /// Reads a run's status and outcome through
  /// `alexandria_index_run_status_json` (FR-LB-07, FR-LB-08, UC-06).
  ///
  /// The status codes are the `RUN_*` family, not `INDEX_*`: they overlap
  /// numerically and disagree on what `4` means.
  Future<CoreJsonResponse> indexRunStatus(String runId);

  /// The files [runId] could not record, through
  /// `alexandria_index_run_failures_json` (core FR-FC-42).
  ///
  /// Asked for on demand rather than carried on the status above, which is
  /// polled every second while a run is in flight: this is wanted once, when
  /// the owner asks which files, if ever.
  Future<CoreJsonResponse> indexRunFailures(String runId);

  /// Starts a refresh run over everything already cataloged through
  /// `alexandria_index_refresh_start` (FR-LB-06, UC-07).
  ///
  /// Takes no root: a refresh covers the whole catalog rather than one folder,
  /// which is the difference between it and [libraryIndexStart]. [priority] means the
  /// same thing there does: null is the core's default.
  Future<CoreRunStart> indexRefreshStart([String? priority]);

  /// Pauses a run so it can be resumed later (FR-FC-32).
  ///
  /// Returns the core's status code rather than a payload: there is nothing
  /// to read back, and the interesting outcomes are refusals — a run that is
  /// not running answers `RUN_ERR_INVALID_STATE`.
  Future<int> indexPause(String runId);

  /// Abandons a run (FR-FC-34). Terminal; the run keeps its tally for the
  /// record but cannot be resumed.
  Future<int> indexCancel(String runId);

  /// Resumes a paused run, optionally re-pacing it (FR-FC-33).
  ///
  /// [priority] is `"normal"`, `"low"`, or null meaning *keep the width the
  /// run already has* — which is not the same as `"normal"`, and is what
  /// keeps a plain resume from silently re-pacing a throttled scan.
  ///
  /// Answers with the same run id it was given, not a new one.
  Future<CoreRunStart> indexResume(String runId, String? priority);

  /// Every run that is outstanding — running or paused (FR-FC-35).
  ///
  /// The whole picture in one call, which is what lets a client show
  /// background activity and offer resume at launch without tracking run ids
  /// itself.
  Future<CoreJsonResponse> indexRunsActive();

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
  /// `{"type":"video","state":"active"}`.
  Future<CoreJsonResponse> filesList(String jsonFilters);

  /// Reads one file by its UUID through `alexandria_file_get_by_uuid`
  /// (FR-CT-05, UC-13).
  ///
  /// Answers the `FileView` body: the record a listing would show, plus
  /// the type-specific metadata and the values the core extracted from the
  /// file — none of which a listing carries.
  Future<CoreJsonResponse> fileByUuid(String uuid);

  /// Replaces the type-specific metadata of the file [uuid] identifies
  /// (FR-ME-02, UC-16).
  ///
  /// [jsonPatch] is the whole metadata object, tagged by type. The core
  /// replaces the editable columns with it rather than merging: a field the
  /// body omits is written as NULL, which is how a field is cleared.
  Future<CoreJsonResponse> fileEditMetadata(String uuid, String jsonPatch);

  /// Resolves the file [uuid] identifies to something a local player can open,
  /// through `alexandria_file_playback_source` (FR-PL-01).
  ///
  /// Answers `{uuid, path, mimeType, sizeBytes}`. No bytes cross the boundary:
  /// the player opens the path directly, which is what playing without
  /// transcoding needs.
  Future<CoreJsonResponse> filePlaybackSource(String uuid);

  /// Reads one page of a comic-book archive through `alexandria_comic_page`
  /// (FR-VW-03, UC-23).
  ///
  /// Answers `{uuid, page, pageCount, mimeType, bytesBase64}`. The bytes do
  /// cross the boundary here, unlike playback's: a page has no path of its own
  /// because it lives inside the archive, and it is bounded — which is what
  /// lets the archive be read without being extracted to disk.
  Future<CoreJsonResponse> comicPage(String uuid, int page);

  /// A downscaled picture of the file [uuid], through
  /// `alexandria_file_thumbnail` (UC-40).
  ///
  /// Answers `{"uuid":…,"mimeType":"image/jpeg","bytesBase64":…}`. For audio
  /// it is the embedded front cover; a file with none answers a playback
  /// error rather than an empty picture.
  Future<CoreJsonResponse> fileThumbnail(String uuid);

  /// Reads a text file's content from disk through
  /// `alexandria_file_read_content` (FR-ME-06, UC-18).
  ///
  /// Answers the `FileContent` body: the uuid and the content as a string.
  Future<CoreJsonResponse> fileReadContent(String uuid);

  /// Writes edited content back to a text file through
  /// `alexandria_file_edit_content` (FR-ME-08, UC-18).
  ///
  /// [jsonBody] carries the content. Answers the `File` record the core
  /// refreshed, whose content hash is what the next save compares against.
  Future<CoreJsonResponse> fileEditContent(String uuid, String jsonBody);

  /// Renames the file [uuid] identifies, on disk and in the catalog, through
  /// `alexandria_file_rename` (FR-ME-04, UC-17).
  ///
  /// Answers the `File` body the core echoed. A disk failure comes back as
  /// `FILE_ERR_DISK` and leaves the catalog untouched.
  Future<CoreJsonResponse> fileRename(String uuid, String name);

  /// Soft-deletes the file [uuid] identifies through
  /// `alexandria_file_soft_delete` (FR-LC-01, UC-33).
  ///
  /// Answers the `File` the core echoed, now marked deleted. The file on disk
  /// is untouched: only the catalog row changes.
  Future<CoreJsonResponse> fileSoftDelete(String uuid);

  /// Restores the file [uuid] identifies through `alexandria_file_restore`
  /// (FR-LC-04, UC-34).
  ///
  /// The core enforces the retention window: a record past it comes back as
  /// `FILE_ERR_NOT_FOUND`.
  Future<CoreJsonResponse> fileRestore(String uuid);

  /// Purges the file [uuid] identifies through `alexandria_file_purge`
  /// (FR-LC-05, UC-35).
  ///
  /// The catalog row only; the file on disk is untouched. The core enforces
  /// the retention window and answers `FILE_ERR_INVALID_STATE` for a record
  /// still inside it, or one that is not deleted at all.
  Future<CoreJsonResponse> filePurge(String uuid);

  /// Purges the file [uuid] identifies from disk as well as from the catalog,
  /// through `alexandria_file_purge_on_disk` (FR-LC-06, UC-36).
  ///
  /// Answers a `PurgeOnDiskOutcome`, whose `diskFilePresent` says whether
  /// there was a file to remove. A disk failure comes back as `FILE_ERR_DISK`
  /// and leaves both the file and the record alone.
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid);

  /// Reads the client-relevant configuration through
  /// `alexandria_settings_json` (FR-LC-03, UC-34).
  ///
  /// Answers the retention window this core enforces.
  Future<CoreJsonResponse> settings();

  /// Lists the owner's collections through `alexandria_collections_list`
  /// (FR-OG-06, UC-26).
  ///
  /// [jsonFilters] optionally narrows to one `kind`; an empty string is every
  /// collection. Answers an array of `CollectionSummary` — each collection and
  /// the number of items it holds.
  Future<CoreJsonResponse> collectionsList(String jsonFilters);

  /// Creates a collection through `alexandria_collection_create` (FR-OG-01,
  /// UC-26).
  ///
  /// [jsonBody] carries `name` and `kind`; the kind is fixed at creation and
  /// decides which items the collection will accept.
  Future<CoreJsonResponse> collectionCreate(String jsonBody);

  /// Renames a collection through `alexandria_collection_rename` (FR-OG-02,
  /// UC-26).
  Future<CoreJsonResponse> collectionRename(String uuid, String jsonBody);

  /// Deletes a collection through `alexandria_collection_delete` (FR-OG-03,
  /// UC-26).
  ///
  /// The items it held are unlinked, never deleted — which is what the
  /// confirmation promises before this is called.
  Future<CoreJsonResponse> collectionDelete(String uuid);

  /// Lists a collection's members through
  /// `alexandria_collection_list_items` (FR-OG-06, UC-27).
  ///
  /// Answers the collection's `kind` and its current members — files or
  /// bookmarks, depending on that kind.
  Future<CoreJsonResponse> collectionListItems(String uuid);

  /// Adds items to a collection through `alexandria_collection_add_items`
  /// (FR-OG-04, UC-27).
  ///
  /// [jsonBody] carries the item uuids. The core validates every one before
  /// linking any, so a batch either all lands or none of it does.
  Future<CoreJsonResponse> collectionAddItems(String uuid, String jsonBody);

  /// Removes one item from a collection through
  /// `alexandria_collection_remove_item` (FR-OG-05, UC-27).
  ///
  /// The item stays in the catalog; only the link goes.
  Future<CoreJsonResponse> collectionRemoveItem(String uuid, String itemUuid);

  /// Creates a browser bookmark through `alexandria_bookmark_create`
  /// (FR-OG-08, UC-28).
  Future<CoreJsonResponse> bookmarkCreate(String jsonBody);

  /// Updates a bookmark through `alexandria_bookmark_update` (FR-OG-09).
  Future<CoreJsonResponse> bookmarkUpdate(String uuid, String jsonBody);

  /// Browses bookmarks through `alexandria_bookmarks_list` (FR-OG-10).
  ///
  /// [jsonFilters] optionally carries a containing collection; an empty
  /// string is every bookmark.
  Future<CoreJsonResponse> bookmarksList(String jsonFilters);

  /// Soft-deletes the bookmark [uuid] identifies through
  /// `alexandria_bookmark_soft_delete` (FR-LC-01, UC-33).
  Future<CoreJsonResponse> bookmarkSoftDelete(String uuid);

  /// Restores the bookmark [uuid] identifies through
  /// `alexandria_bookmark_restore` (FR-LC-04, UC-34).
  Future<CoreJsonResponse> bookmarkRestore(String uuid);

  /// Purges the bookmark [uuid] identifies through
  /// `alexandria_bookmark_purge` (FR-LC-05, UC-35).
  Future<CoreJsonResponse> bookmarkPurge(String uuid);

  /// Creates a watchlist through `alexandria_watchlist_create` (FR-TR-01).
  Future<CoreJsonResponse> watchlistCreate(String jsonBody);

  /// Deletes one through `alexandria_watchlist_delete` (FR-TR-02).
  Future<CoreJsonResponse> watchlistDelete(String uuid);

  /// Adds a video through `alexandria_watchlist_add_video` (FR-TR-03).
  Future<CoreJsonResponse> watchlistAddVideo(String uuid, String jsonBody);

  /// Removes one through `alexandria_watchlist_remove_video` (FR-TR-04).
  Future<CoreJsonResponse> watchlistRemoveVideo(String uuid, String videoUuid);

  /// Records progress through `alexandria_watchlist_update_progress`
  /// (FR-TR-05 … FR-TR-07).
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
  );

  /// Creates a reading list through `alexandria_reading_list_create`
  /// (FR-TR-08).
  Future<CoreJsonResponse> readingListCreate(String jsonBody);

  /// Deletes one through `alexandria_reading_list_delete` (FR-TR-09).
  Future<CoreJsonResponse> readingListDelete(String uuid);

  /// Adds an item through `alexandria_reading_list_add_item` (FR-TR-10).
  Future<CoreJsonResponse> readingListAddItem(String uuid, String jsonBody);

  /// Removes one through `alexandria_reading_list_remove_item` (FR-TR-11).
  Future<CoreJsonResponse> readingListRemoveItem(String uuid, String itemUuid);

  /// Records progress through `alexandria_reading_list_update_progress`
  /// (FR-TR-12 … FR-TR-14).
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
  );

  /// Browses reading lists through `alexandria_reading_lists_list`
  /// (FR-TR-11).
  Future<CoreJsonResponse> readingListsList(String jsonFilters);

  /// Browses watchlists and the watch progress of everything they track
  /// through `alexandria_watchlists_list` (FR-WL-08).
  ///
  /// [jsonFilters] is the filter body; an empty string means every watchlist.
  /// UC-16 reads it to answer one question — is this video's progress counted
  /// per episode — and UC-29 and UC-30 are what present it.
  Future<CoreJsonResponse> watchlistsList(String jsonFilters);

  /// Adds a folder as a library through `alexandria_library_register`
  /// (core FR-FC-36).
  ///
  /// [jsonBody] carries the `name`, the `rootPath`, and an optional
  /// `priority` for the library's first index run, which the same call
  /// starts. The answer is the library with that run's `runId` beside its
  /// fields.
  Future<CoreJsonResponse> libraryRegister(String jsonBody);

  /// Every registered library, through `alexandria_libraries_list`.
  Future<CoreJsonResponse> librariesList();

  /// One level of a library's tree, through `alexandria_library_browse`.
  ///
  /// [path] is the folder to list, relative to the library's root; empty is
  /// the top. One level rather than the whole tree — a course with two
  /// hundred classes is a large document to build so the owner can look at
  /// the six things in one folder.
  Future<CoreJsonResponse> libraryBrowse(String uuid, String path);

  /// Points a library at the folder it moved to, through
  /// `alexandria_library_move` (libraries design).
  ///
  /// [jsonBody] carries the new `rootPath`. The files the library holds move
  /// with it and keep their uuids, which is what makes this a correction
  /// rather than a re-index.
  Future<CoreJsonResponse> libraryMove(String uuid, String jsonBody);

  /// Renames a library, through `alexandria_library_rename` (core 0.7.0).
  ///
  /// [jsonBody] carries the new `name`. Answers the renamed library. Allowed
  /// whatever the library's run is doing, including while it is paused; a
  /// blank name answers `LIBRARY_ERR_INVALID_INPUT`.
  Future<CoreJsonResponse> libraryRename(String uuid, String jsonBody);

  /// Pins or unpins a library, through `alexandria_library_set_pinned`
  /// (core 0.7.0).
  ///
  /// Returns the core's status code rather than a payload: there is nothing
  /// to read back, and the list is read again to show the change.
  Future<int> librarySetPinned(String uuid, bool pinned);

  /// Marks a library as a favorite or not, through
  /// `alexandria_library_set_favorite` (core 0.7.0). The same codes as
  /// [librarySetPinned].
  Future<int> librarySetFavorite(String uuid, bool favorite);

  /// The catalog's totals — how many libraries, and how many files of each
  /// type — through `alexandria_catalog_stats_json` (core 0.7.0).
  ///
  /// A `LibraryJsonResult`, so its status is read in the library family.
  Future<CoreJsonResponse> catalogStats();

  /// Removes a library, through `alexandria_library_remove`.
  ///
  /// Deletes the library's catalog records — its files, their progress and
  /// collection membership, and its runs — and touches nothing on disk.
  /// Refused while the library has a running run.
  Future<CoreJsonResponse> libraryRemove(String uuid);

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

/// [reply] as the shape the call that produced it declares.
///
/// An isolate reply crosses the boundary as `Object?`, because the port
/// carries no type. Every call below then has to say what shape came back,
/// and this is the one place that says how: the shape is guaranteed by the
/// isolate protocol — the operation the worker ran decides it — rather than
/// by the type system, so it is asserted once here instead of at 55 call
/// sites.
///
/// Checked rather than cast. `as T` on a mismatch throws `TypeError`, which
/// no gateway catches and which therefore takes the application down; a
/// protocol violation is a bug, but it is not one worth crashing an owner's
/// session over when every caller already handles [CoreCallException] and
/// turns it into a readable failure (FR-UX-09).
///
/// [T] is bound to [Object], which is what keeps a genuinely nullable reply
/// out: `version()` answers `String?` — the core reports none when the
/// library answered nothing — and folding that into this helper would turn a
/// legitimate null into a thrown protocol violation. It is cast directly at
/// its own call site, where `as String?` asserts nothing this helper would.
T _reply<T extends Object>(Object? reply) {
  if (reply is T) return reply;

  throw CoreCallException(
    'the core worker answered ${reply.runtimeType} where $T was expected',
  );
}

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
      _reply<int>(await _isolate.call('healthStatus'));

  @override
  Future<int> initialize(String databasePath) async =>
      _reply<int>(await _isolate.call('init', [databasePath]));

  @override
  Future<CoreJsonResponse> indexRunStatus(String runId) async =>
      _reply<CoreJsonResponse>(await _isolate.call('indexRunStatus', [runId]));

  @override
  Future<CoreJsonResponse> indexRunFailures(String runId) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('indexRunFailures', [runId]),
      );

  @override
  Future<CoreRunStart> indexRefreshStart([String? priority]) async =>
      _reply<CoreRunStart>(
        await _isolate.call('indexRefreshStart', [priority]),
      );

  @override
  Future<CoreRunStart> libraryIndexStart(
    String uuid, [
    String? priority,
  ]) async => _reply<CoreRunStart>(
    await _isolate.call('libraryIndexStart', [uuid, priority]),
  );

  @override
  Future<int> indexPause(String runId) async =>
      _reply<int>(await _isolate.call('indexPause', [runId]));

  @override
  Future<int> indexCancel(String runId) async =>
      _reply<int>(await _isolate.call('indexCancel', [runId]));

  @override
  Future<CoreRunStart> indexResume(String runId, String? priority) async =>
      _reply<CoreRunStart>(
        await _isolate.call('indexResume', [runId, priority]),
      );

  @override
  Future<CoreJsonResponse> indexRunsActive() async =>
      _reply<CoreJsonResponse>(await _isolate.call('indexRunsActive'));

  @override
  Future<int> indexCountFiles() async =>
      _reply<int>(await _isolate.call('countFiles'));

  @override
  Future<CoreJsonResponse> filesList(String jsonFilters) async =>
      _reply<CoreJsonResponse>(await _isolate.call('filesList', [jsonFilters]));

  @override
  Future<CoreJsonResponse> fileByUuid(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileByUuid', [uuid]));

  @override
  Future<CoreJsonResponse> fileEditMetadata(
    String uuid,
    String jsonPatch,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('fileEditMetadata', [uuid, jsonPatch]),
  );

  @override
  Future<CoreJsonResponse> filePlaybackSource(String uuid) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('filePlaybackSource', [uuid]),
      );

  @override
  Future<CoreJsonResponse> comicPage(String uuid, int page) async =>
      _reply<CoreJsonResponse>(await _isolate.call('comicPage', [uuid, page]));

  @override
  Future<CoreJsonResponse> fileThumbnail(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileThumbnail', [uuid]));

  @override
  Future<CoreJsonResponse> fileReadContent(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileReadContent', [uuid]));

  @override
  Future<CoreJsonResponse> fileEditContent(
    String uuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('fileEditContent', [uuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> fileRename(String uuid, String name) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileRename', [uuid, name]));

  @override
  Future<CoreJsonResponse> fileSoftDelete(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileSoftDelete', [uuid]));

  @override
  Future<CoreJsonResponse> bookmarkSoftDelete(String uuid) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('bookmarkSoftDelete', [uuid]),
      );

  @override
  Future<CoreJsonResponse> fileRestore(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('fileRestore', [uuid]));

  @override
  Future<CoreJsonResponse> bookmarkRestore(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('bookmarkRestore', [uuid]));

  @override
  Future<CoreJsonResponse> filePurge(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('filePurge', [uuid]));

  @override
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('filePurgeOnDisk', [uuid]));

  @override
  Future<CoreJsonResponse> bookmarkPurge(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('bookmarkPurge', [uuid]));

  @override
  Future<CoreJsonResponse> settings() async =>
      _reply<CoreJsonResponse>(await _isolate.call('settings'));

  @override
  Future<CoreJsonResponse> collectionsList(String jsonFilters) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('collectionsList', [jsonFilters]),
      );

  @override
  Future<CoreJsonResponse> collectionCreate(String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('collectionCreate', [jsonBody]),
      );

  @override
  Future<CoreJsonResponse> collectionRename(
    String uuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('collectionRename', [uuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> collectionDelete(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('collectionDelete', [uuid]));

  @override
  Future<CoreJsonResponse> collectionListItems(String uuid) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('collectionListItems', [uuid]),
      );

  @override
  Future<CoreJsonResponse> collectionAddItems(
    String uuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('collectionAddItems', [uuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> collectionRemoveItem(
    String uuid,
    String itemUuid,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('collectionRemoveItem', [uuid, itemUuid]),
  );

  @override
  Future<CoreJsonResponse> bookmarkCreate(String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('bookmarkCreate', [jsonBody]),
      );

  @override
  Future<CoreJsonResponse> bookmarkUpdate(String uuid, String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('bookmarkUpdate', [uuid, jsonBody]),
      );

  @override
  Future<CoreJsonResponse> bookmarksList(String jsonFilters) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('bookmarksList', [jsonFilters]),
      );

  @override
  Future<CoreJsonResponse> readingListCreate(String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('readingListCreate', [jsonBody]),
      );

  @override
  Future<CoreJsonResponse> readingListDelete(String uuid) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('readingListDelete', [uuid]),
      );

  @override
  Future<CoreJsonResponse> readingListAddItem(
    String uuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('readingListAddItem', [uuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> readingListRemoveItem(
    String uuid,
    String itemUuid,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('readingListRemoveItem', [uuid, itemUuid]),
  );

  @override
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('readingListUpdateProgress', [
      uuid,
      itemUuid,
      jsonBody,
    ]),
  );

  @override
  Future<CoreJsonResponse> readingListsList(String jsonFilters) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('readingListsList', [jsonFilters]),
      );

  @override
  Future<CoreJsonResponse> watchlistCreate(String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('watchlistCreate', [jsonBody]),
      );

  @override
  Future<CoreJsonResponse> watchlistDelete(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('watchlistDelete', [uuid]));

  @override
  Future<CoreJsonResponse> watchlistAddVideo(
    String uuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('watchlistAddVideo', [uuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> watchlistRemoveVideo(
    String uuid,
    String videoUuid,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('watchlistRemoveVideo', [uuid, videoUuid]),
  );

  @override
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
  ) async => _reply<CoreJsonResponse>(
    await _isolate.call('watchlistUpdateProgress', [uuid, videoUuid, jsonBody]),
  );

  @override
  Future<CoreJsonResponse> watchlistsList(String jsonFilters) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('watchlistsList', [jsonFilters]),
      );

  @override
  Future<CoreJsonResponse> libraryRegister(String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('libraryRegister', [jsonBody]),
      );

  @override
  Future<CoreJsonResponse> librariesList() async =>
      _reply<CoreJsonResponse>(await _isolate.call('librariesList'));

  @override
  Future<CoreJsonResponse> libraryBrowse(String uuid, String path) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('libraryBrowse', [uuid, path]),
      );

  @override
  Future<CoreJsonResponse> libraryMove(String uuid, String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('libraryMove', [uuid, jsonBody]),
      );

  @override
  Future<CoreJsonResponse> libraryRename(String uuid, String jsonBody) async =>
      _reply<CoreJsonResponse>(
        await _isolate.call('libraryRename', [uuid, jsonBody]),
      );

  @override
  Future<int> librarySetPinned(String uuid, bool pinned) async =>
      _reply<int>(await _isolate.call('librarySetPinned', [uuid, pinned]));

  @override
  Future<int> librarySetFavorite(String uuid, bool favorite) async =>
      _reply<int>(await _isolate.call('librarySetFavorite', [uuid, favorite]));

  @override
  Future<CoreJsonResponse> catalogStats() async =>
      _reply<CoreJsonResponse>(await _isolate.call('catalogStats'));

  @override
  Future<CoreJsonResponse> libraryRemove(String uuid) async =>
      _reply<CoreJsonResponse>(await _isolate.call('libraryRemove', [uuid]));

  @override
  Future<void> dispose() => _isolate.dispose();
}
