#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * FFI status codes returned by index operations.
 *
 * Code 2 is missing here and in every family below: it was
 * `*_ERR_UNAUTHORIZED`, retired with authentication, and is never reused,
 * so a caller built against an older core cannot read a new failure as it.
 */
#define INDEX_OK 0

#define INDEX_ERR_INVALID_INPUT 1

#define INDEX_ERR_NOT_INITIALIZED 3

#define INDEX_ERR_OTHER 4

/**
 * `alexandria_index_init` only: this core is executing a run, so it will not
 * replace its services.
 *
 * Its own code rather than `INDEX_ERR_OTHER` because it is a "not now", not
 * a failure: nothing is wrong with the call, and the same call after the
 * scan settles succeeds. A caller that can tell the two apart says "this
 * takes effect when the scan finishes" instead of reporting an error for
 * something that is going to work.
 */
#define INDEX_ERR_BUSY 5

/**
 * `alexandria_library_index_start` named no library.
 */
#define INDEX_ERR_NOT_FOUND 6

/**
 * The library already has an unfinished run (FR-FC-43).
 */
#define INDEX_ERR_CONFLICT 7

/**
 * FFI status codes returned by file operations (UC-04+). Deliberately
 * separate from `INDEX_*` so a future use case can grow either set without
 * colliding; `FILE_OK == INDEX_OK == 0` by convention.
 */
#define FILE_OK 0

#define FILE_ERR_INVALID_INPUT 1

#define FILE_ERR_NOT_INITIALIZED 3

#define FILE_ERR_NOT_FOUND 4

#define FILE_ERR_INVALID_STATE 5

#define FILE_ERR_DISK 6

#define FILE_ERR_INTEGRITY 7

#define FILE_ERR_OTHER 9

/**
 * FFI status codes returned by collection operations (UC-10+). Deliberately
 * separate from `INDEX_*` and `FILE_*` — per the convention above — so the
 * Collections use cases can grow their own set without colliding;
 * `COLLECTION_OK == FILE_OK == 0` by convention. There is no disk code: a
 * collection is catalog-only metadata with nothing on disk.
 */
#define COLLECTION_OK 0

#define COLLECTION_ERR_INVALID_INPUT 1

#define COLLECTION_ERR_NOT_INITIALIZED 3

#define COLLECTION_ERR_NOT_FOUND 4

#define COLLECTION_ERR_INVALID_STATE 5

#define COLLECTION_ERR_OTHER 9

/**
 * FFI status codes returned by playback operations (UC-38…UC-40).
 * Deliberately separate from `INDEX_*`, `FILE_*`, and `COLLECTION_*` — per
 * the convention above — so F-10 can grow its own set without colliding;
 * `PLAYBACK_OK == FILE_OK == 0` by convention.
 */
#define PLAYBACK_OK 0

#define PLAYBACK_ERR_INVALID_INPUT 1

#define PLAYBACK_ERR_NOT_INITIALIZED 3

#define PLAYBACK_ERR_NOT_FOUND 4

#define PLAYBACK_ERR_INVALID_STATE 5

#define PLAYBACK_ERR_DISK 6

#define PLAYBACK_ERR_OTHER 9

/**
 * FFI status codes returned by bookmark operations (UC-15+). Deliberately
 * separate from `COLLECTION_*` — per the convention above — so bookmark use
 * cases can grow their own set without colliding; `BOOKMARK_OK ==
 * COLLECTION_OK == 0` by convention. There is no disk code: a bookmark is
 * catalog-only metadata with nothing on disk.
 */
#define BOOKMARK_OK 0

#define BOOKMARK_ERR_INVALID_INPUT 1

#define BOOKMARK_ERR_NOT_INITIALIZED 3

#define BOOKMARK_ERR_NOT_FOUND 4

#define BOOKMARK_ERR_INVALID_STATE 5

#define BOOKMARK_ERR_OTHER 9

/**
 * FFI status codes returned by watchlist operations (UC-20+). Deliberately
 * separate from `BOOKMARK_*` — per the convention above — so watchlist use
 * cases can grow their own set without colliding; `WATCHLIST_OK ==
 * BOOKMARK_OK == 0` by convention.
 */
#define WATCHLIST_OK 0

#define WATCHLIST_ERR_INVALID_INPUT 1

#define WATCHLIST_ERR_NOT_INITIALIZED 3

#define WATCHLIST_ERR_NOT_FOUND 4

#define WATCHLIST_ERR_INVALID_STATE 5

#define WATCHLIST_ERR_OTHER 9

/**
 * FFI status codes returned by reading list operations (UC-26+).
 * Deliberately separate from `WATCHLIST_*` — per the convention above — so
 * reading-list use cases can grow their own set without colliding;
 * `READING_LIST_OK == WATCHLIST_OK == 0` by convention.
 */
#define READING_LIST_OK 0

#define READING_LIST_ERR_INVALID_INPUT 1

#define READING_LIST_ERR_NOT_INITIALIZED 3

#define READING_LIST_ERR_NOT_FOUND 4

#define READING_LIST_ERR_INVALID_STATE 5

#define READING_LIST_ERR_OTHER 9

/**
 * FFI status codes returned by the settings read (UC-47 / FR-FC-30).
 * Deliberately separate from every other family — per the convention above —
 * so this surface can grow independently; `SETTINGS_OK == INDEX_OK == 0` by
 * convention.
 */
#define SETTINGS_OK 0

#define SETTINGS_ERR_NOT_INITIALIZED 3

#define SETTINGS_ERR_OTHER 9

/**
 * FFI status codes returned by run-status operations (UC-42, UC-48 / FR-FC-28, FR-FC-32 … FR-FC-35).
 * Deliberately separate from `INDEX_*`, `FILE_*`, `COLLECTION_*`, and
 * `PLAYBACK_*` — per the convention established above — so this surface can
 * grow independently; `RUN_OK == INDEX_OK == 0` by convention.
 */
#define RUN_OK 0

#define RUN_ERR_INVALID_INPUT 1

#define RUN_ERR_NOT_INITIALIZED 3

#define RUN_ERR_NOT_FOUND 4

/**
 * The run exists but is not in a state the requested verb permits — pausing
 * a run that is not `running`, or resuming one that is not `paused`
 * (`DomainError::InvalidState`, UC-48). Distinct from
 * `RUN_ERR_OTHER` for the same reason `FILE_ERR_INVALID_STATE` and
 * `COLLECTION_ERR_INVALID_STATE` are distinct from their own catch-alls: a
 * caller retrying a transient failure and a caller that asked for an
 * impossible transition need different responses.
 */
#define RUN_ERR_INVALID_STATE 5

#define RUN_ERR_OTHER 9

/**
 * FFI status codes returned by library operations (libraries design). Its
 * own set, per the convention above; `LIBRARY_OK == FILE_OK == 0`.
 */
#define LIBRARY_OK 0

#define LIBRARY_ERR_INVALID_INPUT 1

#define LIBRARY_ERR_NOT_INITIALIZED 3

#define LIBRARY_ERR_NOT_FOUND 4

/**
 * The folder overlaps a library that already exists.
 *
 * Its own code rather than an invalid input: the request was well formed
 * and the folder is a real one — what is wrong is the catalog's current
 * state, and a client that can tell the two apart says "that folder is
 * already inside another library" instead of "that is not a folder".
 */
#define LIBRARY_ERR_CONFLICT 6

#define LIBRARY_ERR_OTHER 9

/**
 * Result of starting an index run. `run_id` is a NUL-terminated UUID string
 * on success (empty on failure).
 *
 * Shared with `alexandria_index_resume` (UC-48), which reuses this same
 * struct shape for a call that is not starting anything new. That reuse
 * changes what `status` means: from `alexandria_library_index_start` and
 * `alexandria_index_refresh_start` it is one of the `INDEX_ERR_*`
 * constants, where `4` is `INDEX_ERR_OTHER`; from `alexandria_index_resume`
 * it is one of the `RUN_ERR_*` constants, where `4` is `RUN_ERR_NOT_FOUND`
 * instead. Check which function returned the value before reading `status`
 * against either family.
 */
typedef struct IndexStartResult {
  int status;
  char run_id[37];
} IndexStartResult;

/**
 * Result of `alexandria_file_edit_metadata` (UC-04). On success `status` is
 * `FILE_OK` and `json` is a NUL-terminated JSON string of the `FileMetadata`
 * body. On failure `json` is NULL and `status` carries the mapped error code.
 * The caller must free `json` with `alexandria_free_string`.
 */
typedef struct FileMetadataResult {
  int status;
  char *json;
} FileMetadataResult;

/**
 * Result of `alexandria_files_list` and `alexandria_file_get_by_uuid`
 * (UC-03). On success `status` is `FILE_OK` and `json` is a NUL-terminated
 * JSON string: an array of `FileView` objects for the listing (issue #116),
 * or a single `FileView` object for the lookup. On failure `json` is NULL
 * and `status` carries the mapped error code. The caller must free `json`
 * with `alexandria_free_string`.
 */
typedef struct FileJsonResult {
  int status;
  char *json;
} FileJsonResult;

/**
 * JSON result for the playback functions. `json` is NULL on error and
 * `status` carries the mapped code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct PlaybackJsonResult {
  int status;
  char *json;
} PlaybackJsonResult;

/**
 * Result of `alexandria_collection_create` (UC-10). On success `status` is
 * `COLLECTION_OK` and `json` is a NUL-terminated JSON string of the
 * `Collection` body. On failure `json` is NULL and `status` carries the
 * mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct CollectionJsonResult {
  int status;
  char *json;
} CollectionJsonResult;

/**
 * Result of `alexandria_bookmark_create` (UC-15). On success `status` is
 * `BOOKMARK_OK` and `json` is a NUL-terminated JSON string of the `Bookmark`
 * body. On failure `json` is NULL and `status` carries the mapped error code.
 * The caller must free `json` with `alexandria_free_string`.
 */
typedef struct BookmarkJsonResult {
  int status;
  char *json;
} BookmarkJsonResult;

/**
 * Result of `alexandria_watchlist_create` (UC-20). On success `status` is
 * `WATCHLIST_OK` and `json` is a NUL-terminated JSON string of the
 * `Watchlist` body. On failure `json` is NULL and `status` carries the mapped
 * error code. The caller must free `json` with `alexandria_free_string`.
 */
typedef struct WatchlistJsonResult {
  int status;
  char *json;
} WatchlistJsonResult;

/**
 * Result of `alexandria_reading_list_create` (UC-26). On success `status` is
 * `READING_LIST_OK` and `json` is a NUL-terminated JSON string of the
 * `ReadingList` body. On failure `json` is NULL and `status` carries the
 * mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct ReadingListJsonResult {
  int status;
  char *json;
} ReadingListJsonResult;

/**
 * Result of `alexandria_settings_json` (UC-47). On success `status` is
 * `SETTINGS_OK` and `json` is a NUL-terminated JSON string of the settings
 * body. On failure `json` is NULL and `status` carries the mapped error code.
 * The caller must free `json` with `alexandria_free_string`.
 */
typedef struct SettingsJsonResult {
  int status;
  char *json;
} SettingsJsonResult;

/**
 * Result of `alexandria_index_run_status_json` (UC-42). On success `status`
 * is `RUN_OK` and `json` is a NUL-terminated JSON string of the `CatalogRun`
 * body. On failure `json` is NULL and `status` carries the mapped error code.
 * The caller must free `json` with `alexandria_free_string`.
 */
typedef struct RunJsonResult {
  int status;
  char *json;
} RunJsonResult;

/**
 * Result of every library FFI function. On success `status` is `LIBRARY_OK`
 * and `json` is a NUL-terminated JSON string of the library body the call
 * answers. The caller must free `json` with `alexandria_free_string`.
 */
typedef struct LibraryJsonResult {
  int status;
  char *json;
} LibraryJsonResult;

/**
 * This core's version, as a NUL-terminated string such as `"0.6.0"`.
 *
 * The pointer is to static storage owned by the library: it stays valid for
 * the life of the process and must **not** be passed to
 * `alexandria_free_string`, which would free memory this library never
 * allocated.
 */
const char *alexandria_version(void);

int32_t alexandria_health_status_code(void);

/**
 * Initialize the FFI services against a database path (created/migrated on
 * demand). Returns 0 on success, a non-zero status otherwise.
 *
 * **Safe to call again — except while this core is walking a disk.** A second
 * call replaces the services wholesale, and a run already executing does not
 * come with them: its cell lives in the old [`RunRegistry`], so pause and
 * cancel stop reaching it and its progress stops being published, while the
 * walk itself carries on writing. Worse, the new services reconcile on the
 * way up (FR-FC-29) and rewrite that live run's row to `paused` on the
 * assumption that nothing is walking it. So a call made while
 * `alexandria_index_runs_active_json` would answer anything is refused with
 * `INDEX_ERR_BUSY` and changes nothing; the same call after the run settles
 * succeeds. Pointing at a *different* database is subject to the same rule,
 * for the same reason.
 *
 * Configuration is loaded from the path in `ALEXANDRIA_CONFIG` (default
 * `config.toml`), with `ALEXANDRIA_*` environment overrides applied. A
 * missing or unreadable config file falls back to defaults rather than
 * failing. `db_path` wins over the config's `database.path`: the embedder
 * passed it explicitly.
 */
int alexandria_index_init(const char *db_path);

/**
 * Start an asynchronous re-index/refresh of every cataloged path (UC-02).
 * Takes no root — refresh touches everything cataloged — and returns a
 * `IndexStartResult` with a `run_id` and `status`. The refresh runs in the
 * background on the FFI runtime; read results via the accessor functions.
 *
 * `priority` is parsed exactly as `alexandria_library_index_start`'s is — see that
 * function's doc comment for the accepted spellings and the NULL/garbage
 * fallback.
 */
struct IndexStartResult alexandria_index_refresh_start(const char *priority);

/**
 * Count of indexed files. For tests waiting for the background scan.
 */
int64_t alexandria_index_count_files(void);

/**
 * Edit a file's type-specific metadata (UC-04 / FR-FC-15..18).
 *
 * `uuid` is the file's public UUID string; `json_patch` is the JSON body (the
 * `SubtypeMetadata` enum, internally tagged by `type`). The function
 * deserializes it, calls `EditMetadataHandler`, and on success serializes the
 * returned `FileMetadata` back to JSON.
 */
struct FileMetadataResult alexandria_file_edit_metadata(const char *uuid, const char *json_patch);

/**
 * List/query files filtered by type and lifecycle state (UC-03 / FR-FC-12).
 *
 * `json_filters` is a JSON string `{"type":"video","state":"all"}` (empty
 * string or NULL for defaults), answered across every library unless
 * `"libraryUuid"` names one. The function deserializes it, calls
 * `BrowseFilesHandler`, and on success serializes the returned
 * `Vec<FileView>` back to a JSON array — each element the same
 * `{"file": …, "metadata": …, …}` shape `alexandria_file_get_by_uuid`
 * answers for one file (issue #116).
 */
struct FileJsonResult alexandria_files_list(const char *json_filters);

/**
 * Get a single file's metadata by its public UUID (UC-03 / FR-FC-13).
 *
 * `uuid` is the file's public UUID string. The function calls
 * `BrowseFilesHandler::get_by_uuid`, and on success serializes the returned
 * `FileView` back to JSON.
 */
struct FileJsonResult alexandria_file_get_by_uuid(const char *uuid);

/**
 * Read a TextFile's content from disk (UC-32 / FR-TX-01).
 *
 * `uuid` is the file's public UUID (NUL-terminated string). On success `json`
 * carries the `FileContent`.
 */
struct FileJsonResult alexandria_file_read_content(const char *uuid);

/**
 * Resolve a File to everything a local player needs to open it
 * (UC-38 / FR-MP-01, FR-MP-06).
 *
 * The FFI surface cannot carry a byte stream, so rather than stream the
 * file, this returns `{"uuid":…,"path":…,"mimeType":…,"sizeBytes":…}` and
 * the caller — Flutter desktop, on the same machine as the file — opens that
 * path directly. Zero bytes cross this boundary (FR-MP-06). A file whose
 * path resolves outside the configured `filesystem.root` gets
 * `PLAYBACK_ERR_INVALID_INPUT` and no descriptor (FR-FC-26).
 */
struct PlaybackJsonResult alexandria_file_playback_source(const char *uuid);

/**
 * One page of a CBZ ComicBook (UC-39 / FR-MP-04).
 *
 * Returns `{"uuid":…,"page":N,"pageCount":N,"mimeType":…,"bytesBase64":…}`.
 * Unlike UC-38, the bytes *do* cross the boundary: a comic page has no path
 * of its own — it lives inside an archive — and it is bounded, so
 * base64 inside the existing JSON payload keeps the FFI shape intact while
 * staying byte-exact with the page in the archive.
 */
struct PlaybackJsonResult alexandria_comic_page(const char *uuid, uint32_t page);

/**
 * A downscaled thumbnail for a video, image, or comic
 * (UC-40 / FR-MP-05). Returns
 * `{"uuid":…,"mimeType":"image/jpeg","bytesBase64":…}`. Bounded derived
 * bytes, so the same base64 rule as `alexandria_comic_page` applies.
 */
struct PlaybackJsonResult alexandria_file_thumbnail(const char *uuid);

/**
 * Write edited content back to a TextFile on disk (UC-33 / FR-TX-02,
 * FR-TX-03).
 *
 * `uuid` is the file's public UUID (NUL-terminated string). `json_body` is
 * the JSON body (`content`). The function deserializes it, calls
 * `EditTextFileContentHandler`, and on success serializes the returned `File`
 * back to JSON.
 */
struct FileJsonResult alexandria_file_edit_content(const char *uuid, const char *json_body);

/**
 * Rename a file (and its on-disk file) (UC-05 / FR-FC-19).
 *
 * `uuid` is the file's public UUID string; `name` is the new file name. The
 * function calls `RenameFileHandler` and on success serializes the returned
 * `File` back to JSON. A disk failure (AF-02) maps to `FILE_ERR_DISK`; the
 * catalog is left untouched in that case.
 */
struct FileJsonResult alexandria_file_rename(const char *uuid, const char *name);

/**
 * Soft-delete a file (UC-06 / FR-FC-20).
 *
 * `uuid` is the file's public UUID string. The function calls
 * `SoftDeleteFileHandler` and on success serializes the returned `File` back
 * to JSON. The on-disk file is untouched (only `state` and `deleted_at`
 * change on the catalog row).
 */
struct FileJsonResult alexandria_file_soft_delete(const char *uuid);

/**
 * Restore a soft-deleted file (UC-07 / FR-FC-21).
 *
 * `uuid` is the file's public UUID string. The function calls
 * `RestoreFileHandler` and on success serializes the returned `File` back to
 * JSON. The on-disk file is untouched (only `state` and `deleted_at` change
 * on the catalog row). The retention window (default 30 days, NFR-10) is
 * enforced; a record past it is reported as `NotFound` (`FILE_ERR_NOT_FOUND`)
 * since UC-08 owns the actual hard purge.
 */
struct FileJsonResult alexandria_file_restore(const char *uuid);

/**
 * Hard-purge a soft-deleted file's catalog row (UC-08 / FR-FC-22).
 *
 * `uuid` is the file's public UUID string. The function calls
 * `PurgeFileHandler` and on success serializes the pre-delete `File` back to
 * JSON as confirmation. Only the catalog row (and its subtype row) is
 * removed; the on-disk file is untouched (NFR-07). The retention window
 * (default 30 days, NFR-10) is enforced: a record still within it, or not
 * `deleted`, is reported as `FILE_ERR_INVALID_STATE`.
 */
struct FileJsonResult alexandria_file_purge(const char *uuid);

/**
 * Purge a file both on disk and in the catalog (UC-09 / FR-FC-23).
 *
 * `uuid` is the file's public UUID string. The function calls
 * `PurgeFileOnDiskHandler` and on success serializes the returned
 * [`PurgeOnDiskOutcome`] back to JSON. Unlike UC-08 there is no retention
 * gate: an `active` or `deleted` record is purgeable, the only precondition
 * is that it exists. A missing on-disk file is still a success, reported via
 * `diskFilePresent: false` (AF-01); a disk failure is reported as
 * `FILE_ERR_DISK` (AF-02) and leaves the record untouched.
 */
struct FileJsonResult alexandria_file_purge_on_disk(const char *uuid);

/**
 * Create a flat file or bookmark collection (UC-10 / FR-CO-01, FR-CO-02).
 *
 * `json_body` is the JSON body (`name` + `kind`). The function deserializes
 * it, calls `CreateCollectionHandler`, and on success serializes the returned
 * `Collection` back to JSON.
 */
struct CollectionJsonResult alexandria_collection_create(const char *json_body);

/**
 * Rename a collection (UC-11 / FR-CO-03).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). `json_body`
 * is the JSON body (`{"name": …}`). The function deserializes it, calls
 * `RenameCollectionHandler`, and on success serializes the returned
 * `Collection` back to JSON.
 */
struct CollectionJsonResult alexandria_collection_rename(const char *uuid, const char *json_body);

/**
 * Delete a collection, unlinking its items (UC-12 / FR-CO-04).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). On success
 * `json` carries the pre-delete `Collection` as confirmation.
 */
struct CollectionJsonResult alexandria_collection_delete(const char *uuid);

/**
 * Add items to a collection (UC-13 / FR-CO-05).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). `json_body`
 * is the JSON body (`itemUuids`). The function deserializes it, calls
 * `AddItemsToCollectionHandler`, and on success serializes the returned
 * `CollectionItemsResult` back to JSON.
 */
struct CollectionJsonResult alexandria_collection_add_items(const char *uuid,
                                                            const char *json_body);

/**
 * Remove an item from a collection (UC-14 / FR-CO-06).
 *
 * `collection_uuid` and `item_uuid` are the collection's and item's public
 * UUIDs (NUL-terminated strings). On success `json` carries the
 * `collectionUuid`/`itemUuid` confirmation.
 */
struct CollectionJsonResult alexandria_collection_remove_item(const char *collection_uuid,
                                                              const char *item_uuid);

/**
 * List the items in a collection (UC-14 / FR-CO-07).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). On success
 * `json` carries the `kind` and current members.
 */
struct CollectionJsonResult alexandria_collection_list_items(const char *uuid);

/**
 * List the owner's collections (UC-46 / FR-CO-08).
 *
 * `json_filters` is a JSON filter (`kind`); an empty string or `null` means
 * every collection. On success `json` carries a JSON array of
 * `CollectionSummary` — each collection with the number of items it holds.
 *
 * An owner with no collections gets an empty array and `COLLECTION_OK`, not
 * an error (AF-01). An unrecognised `kind` is `COLLECTION_ERR_INVALID_INPUT`
 * and nothing is queried (AF-02).
 */
struct CollectionJsonResult alexandria_collections_list(const char *json_filters);

/**
 * Create a browser bookmark, optionally in an existing bookmark collection
 * (UC-15 / FR-BM-01).
 *
 * `json_body` is the JSON body (`url` + `title` + `collectionUuid`). The
 * function deserializes it, calls `CreateBookmarkHandler`, and on success
 * serializes the returned `Bookmark` back to JSON.
 */
struct BookmarkJsonResult alexandria_bookmark_create(const char *json_body);

/**
 * Update a bookmark's url, title, and containing collection (UC-16 /
 * FR-BM-02).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). `json_body`
 * is the JSON body (`url` + `title` + `collectionUuid`). The function
 * deserializes it, calls `UpdateBookmarkHandler`, and on success serializes
 * the returned `Bookmark` back to JSON.
 */
struct BookmarkJsonResult alexandria_bookmark_update(const char *uuid, const char *json_body);

/**
 * Browse bookmarks, optionally filtered by containing collection (UC-17 /
 * FR-BM-06).
 *
 * `json_filters` is a JSON string `{"collectionUuid":"…","state":"all"}`
 * (empty string or NULL for defaults). The function deserializes it, calls
 * `BrowseBookmarksHandler`, and on success serializes the returned
 * `Vec<Bookmark>` back to a JSON array.
 */
struct BookmarkJsonResult alexandria_bookmarks_list(const char *json_filters);

/**
 * Soft-delete a bookmark (UC-18 / FR-BM-03).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the updated `Bookmark`.
 */
struct BookmarkJsonResult alexandria_bookmark_soft_delete(const char *uuid);

/**
 * Restore a soft-deleted bookmark (UC-18 / FR-BM-05).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the restored `Bookmark`.
 */
struct BookmarkJsonResult alexandria_bookmark_restore(const char *uuid);

/**
 * Hard-purge a bookmark (UC-19 / FR-BM-04).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the pre-purge `Bookmark` as confirmation.
 */
struct BookmarkJsonResult alexandria_bookmark_purge(const char *uuid);

/**
 * Create a named watchlist for tracking video consumption (UC-20 /
 * FR-WL-01).
 *
 * `json_body` is the JSON body (`name`). The function deserializes it, calls
 * `CreateWatchlistHandler`, and on success serializes the returned
 * `Watchlist` back to JSON.
 */
struct WatchlistJsonResult alexandria_watchlist_create(const char *json_body);

/**
 * Add a video to a watchlist (UC-22 / FR-WL-02, FR-WL-03).
 *
 * `uuid` is the watchlist's public UUID (NUL-terminated string). `json_body`
 * is the JSON body (`videoUuid`). The function deserializes it, calls
 * `AddVideoToWatchlistHandler`, and on success serializes the returned
 * `WatchProgress` back to JSON.
 */
struct WatchlistJsonResult alexandria_watchlist_add_video(const char *uuid, const char *json_body);

/**
 * Browse watchlists and their items' watch progress (UC-21 / FR-WL-08).
 *
 * `json_filters` is a JSON filter (`watchlistUuid`); an empty string or
 * `null` means every watchlist. On success `json` carries a JSON array of
 * `WatchlistWithProgress`.
 */
struct WatchlistJsonResult alexandria_watchlists_list(const char *json_filters);

/**
 * Update watch progress (UC-23 / FR-WL-04, FR-WL-05).
 *
 * `watchlist_uuid` and `video_uuid` are the watchlist's and video's public
 * UUIDs (NUL-terminated strings). `json_body` is the JSON body (`state`,
 * optional `currentEpisode`/`totalEpisodes`). On success `json` carries the
 * updated `WatchProgress`.
 */
struct WatchlistJsonResult alexandria_watchlist_update_progress(const char *watchlist_uuid,
                                                                const char *video_uuid,
                                                                const char *json_body);

/**
 * Remove a video from a watchlist (UC-24 / FR-WL-06).
 *
 * `watchlist_uuid` and `video_uuid` are the watchlist's and video's public
 * UUIDs (NUL-terminated strings). On success `json` carries the
 * `watchlistUuid`/`videoUuid` confirmation.
 */
struct WatchlistJsonResult alexandria_watchlist_remove_video(const char *watchlist_uuid,
                                                             const char *video_uuid);

/**
 * Delete a watchlist (UC-25 / FR-WL-07).
 *
 * `uuid` is the watchlist's public UUID (NUL-terminated string). On success
 * `json` carries the pre-delete `Watchlist`.
 */
struct WatchlistJsonResult alexandria_watchlist_delete(const char *uuid);

/**
 * Count of cataloged files currently marked missing on disk (UC-02 AF-01).
 */
int64_t alexandria_index_count_missing(void);

/**
 * JSON array of `{"path","name","type","hash","missingAt"}` for every
 * indexed file, or a NUL pointer on error. Caller must free it with
 * `alexandria_free_string`.
 *
 * `content_hash` is nullable (Task 3: indexing never computes one; Task 4:
 * neither does refresh) and is decoded as `Option<String>` — not `String` —
 * so a `NULL` row serializes as JSON `null` here, matching what the shared
 * `File`/`FileView` model emits for the same column (`alexandria_files_list`,
 * `catalog/model.rs`). Decoding it as a bare `String` used to silently turn a
 * SQL `NULL` into `""` instead (sqlx does not error on that mismatch for this
 * driver), so the two listings disagreed for every indexed or refreshed file
 * — not an edge case, since neither indexing nor refresh have computed a hash
 * since Task 3/4.
 */
char *alexandria_index_files_json(void);

/**
 * Create a named reading list for tracking book/comic consumption (UC-26 /
 * FR-RL-01).
 *
 * `json_body` is the JSON body (`name`). The function deserializes it, calls
 * `CreateReadingListHandler`, and on success serializes the returned
 * `ReadingList` back to JSON.
 */
struct ReadingListJsonResult alexandria_reading_list_create(const char *json_body);

/**
 * Add a book or comic to a reading list (UC-28 / FR-RL-02, FR-RL-03).
 *
 * `uuid` is the reading list's public UUID (NUL-terminated string).
 * `json_body` is the JSON body (`itemUuid`). The function deserializes it,
 * calls `AddItemToReadingListHandler`, and on success serializes the returned
 * `ReadingProgress` back to JSON.
 */
struct ReadingListJsonResult alexandria_reading_list_add_item(const char *uuid,
                                                              const char *json_body);

/**
 * Browse reading lists and their items' read progress (UC-27 / FR-RL-08).
 *
 * `json_filters` is a JSON filter (`readingListUuid`); an empty string or
 * `null` means every reading list. On success `json` carries a JSON array of
 * `ReadingListWithProgress`.
 */
struct ReadingListJsonResult alexandria_reading_lists_list(const char *json_filters);

/**
 * Update reading progress (UC-29 / FR-RL-04, FR-RL-05).
 *
 * `reading_list_uuid` and `item_uuid` are the reading list's and item's
 * public UUIDs (NUL-terminated strings). `json_body` is the JSON body
 * (`state`, optional `currentIssue`/`totalIssues`). On success `json` carries
 * the updated `ReadingProgress`.
 */
struct ReadingListJsonResult alexandria_reading_list_update_progress(const char *reading_list_uuid,
                                                                     const char *item_uuid,
                                                                     const char *json_body);

/**
 * Remove an item from a reading list (UC-30 / FR-RL-06).
 *
 * `reading_list_uuid` and `item_uuid` are the reading list's and item's
 * public UUIDs (NUL-terminated strings). On success `json` carries the
 * `readingListUuid`/`itemUuid` confirmation.
 */
struct ReadingListJsonResult alexandria_reading_list_remove_item(const char *reading_list_uuid,
                                                                 const char *item_uuid);

/**
 * Delete a reading list (UC-31 / FR-RL-07).
 *
 * `uuid` is the reading list's public UUID (NUL-terminated string). On
 * success `json` carries the pre-delete `ReadingList`.
 */
struct ReadingListJsonResult alexandria_reading_list_delete(const char *uuid);

/**
 * Report the client-relevant configuration (UC-47 / FR-FC-30).
 *
 * On success `json` carries the settings body — today
 * `{"deletion":{"retentionDays":30}}`, the soft-delete retention window this
 * core enforces on every restore and purge.
 *
 * The boundary the number describes is the core's own: elapsed time up to and
 * including `retentionDays` leaves a record restorable and not yet purgeable;
 * strictly past it, the record is purgeable and no longer restorable.
 */
struct SettingsJsonResult alexandria_settings_json(void);

/**
 * Report an index or re-index run's status and outcome (UC-42 / FR-FC-28).
 * `run_id` is the id `alexandria_library_index_start` or
 * `alexandria_index_refresh_start` returned. On success `json` carries the
 * run's `CatalogRun` body.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01), and
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid.
 */
struct RunJsonResult alexandria_index_run_status_json(const char *run_id);

/**
 * The files a run could not record, oldest first (FR-FC-42). `run_id` is the
 * id `alexandria_library_index_start` or `alexandria_index_refresh_start`
 * returned. On success `json` carries the array of failures.
 *
 * A call of its own rather than a field on the status above: status is
 * polled every second while a run is in flight, and this is wanted once, if
 * ever — when the owner asks which files. The list is bounded per run; the
 * run's own `failed` tally stays the authority on how many.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01), and
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid.
 */
struct RunJsonResult alexandria_index_run_failures_json(const char *run_id);

/**
 * Pause a running index or re-index run where it stands, leaving it resumable
 * (UC-48 / FR-FC-32). `run_id` is the id `alexandria_library_index_start` or
 * `alexandria_index_refresh_start` returned. Calls
 * `RunControlHandler::pause`.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is not currently `running` — pausing
 * an already-paused or already-finished run is refused rather than silently
 * accepted.
 */
int alexandria_index_pause(const char *run_id);

/**
 * Abandon a running or paused index or re-index run (UC-48 / FR-FC-34).
 * Terminal — a cancelled run is never resumed. `run_id` is the id
 * `alexandria_library_index_start` or `alexandria_index_refresh_start`
 * returned. Calls `RunControlHandler::cancel`.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is already terminal (`complete`,
 * `failed`, or already `cancelled`) — there is nothing left to abandon.
 */
int alexandria_index_cancel(const char *run_id);

/**
 * Put a paused index or re-index run back to work (UC-48 / FR-FC-33).
 * `run_id` is the id `alexandria_library_index_start` or
 * `alexandria_index_refresh_start` returned. Returns the *same* `run_id` on
 * success — a resume does not mint a fresh run, it continues the one it was
 * given — wrapped in the same `IndexStartResult` `alexandria_library_index_start`
 * returns (parity of shape, not of meaning: `status` here is a `RUN_ERR_*`
 * code, because resume is part of run control, not of starting a fresh run).
 *
 * `RunControlHandler::resume` only records the state transition; it does not
 * walk anything. Spawning the walk is this function's job, exactly as
 * `alexandria_library_index_start` spawns its own — the handler is kept free of the
 * runtime so `execute` is always spawned by whichever transport owns one.
 * Which handler gets spawned depends on `RunResumed::kind`: an index run
 * resumes into `index_handler.execute(&root, run_id)`, a refresh into
 * `refresh_handler.execute(run_id)` (a refresh carries no root — it touches
 * everything cataloged). A resumed index run whose stored `root` is somehow
 * absent — it should never be, every row `RunKind::Index` writes carries one
 * — is refused with `RUN_ERR_OTHER` and logged at `error`, rather than
 * silently doing nothing: a caller told `RUN_OK` for a run that never
 * actually resumes would have no way to notice.
 *
 * `priority` re-paces the run (FR-FC-08 / FR-FC-33): `"low"` or `"normal"`,
 * the same case-sensitive spelling `alexandria_library_index_start` accepts. Unlike
 * there, NULL or an unrecognised string does **not** mean `"normal"` — it
 * means *keep the width this run already has*, which is what every caller
 * written before this parameter existed was asking for. Passing NULL is
 * therefore the backward-compatible call, and `"normal"` is a real request
 * to speed a low-priority run back up. See `parse_resume_priority`.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is not currently `paused`.
 */
struct IndexStartResult alexandria_index_resume(const char *run_id, const char *priority);

/**
 * Every outstanding (`running` or `paused`) index and re-index run at once,
 * each with live progress overlaid exactly as
 * `alexandria_index_run_status_json` overlays a single run (UC-42 /
 * FR-FC-35). On success `json` is a NUL-terminated JSON array of `CatalogRun`
 * bodies, newest first. The caller must free `json` with
 * `alexandria_free_string`.
 *
 * A caller with nothing outstanding gets `RUN_OK` and an empty JSON array,
 * not an error — an idle library is the normal case, not a failure.
 */
struct RunJsonResult alexandria_index_runs_active_json(void);

/**
 * Free a string previously returned by an FFI accessor.
 *
 * # Safety
 *
 * `ptr` must be null, or a pointer returned by one of this library's
 * accessors and not yet freed. Passing anything else — a pointer this library
 * did not produce, or one already freed — is undefined behaviour. Declared
 * `unsafe` because that obligation is the caller's and cannot be checked here.
 */
void alexandria_free_string(char *ptr);

/**
 * Re-index one library (UC-01). `priority` is `"low"` or anything else
 * (normal), lenient as every start is.
 *
 * Answers `INDEX_OK` with the run id, `INDEX_ERR_NOT_FOUND` for an unknown
 * library, `INDEX_ERR_CONFLICT` while it has an unfinished run (FR-FC-43),
 * `INDEX_ERR_INVALID_INPUT` for a malformed uuid or
 * `INDEX_ERR_NOT_INITIALIZED`.
 */
struct IndexStartResult alexandria_library_index_start(const char *uuid, const char *priority);

/**
 * Add a folder as a library and start indexing it (FR-FC-36).
 *
 * `json_body` carries `name`, `rootPath`, and an optional `priority`
 * (`"low"`; anything else is normal) for the first run. On success `json` is
 * the library with the `runId` of its first index run beside its fields;
 * follow it with `alexandria_index_run_status_json`. Answers
 * `LIBRARY_ERR_INVALID_INPUT` for a blank name or folder, a folder that does
 * not exist or is not a folder, or one outside `filesystem.root`;
 * `LIBRARY_ERR_CONFLICT` when the folder overlaps an existing library. A
 * refusal stores nothing.
 */
struct LibraryJsonResult alexandria_library_register(const char *json_body);

/**
 * Point a library at the folder it moved to (libraries design).
 *
 * `json_body` is `{"rootPath": …}`. The library's files move with it, keeping their uuids and
 * everything that points at them. Answers `LIBRARY_ERR_CONFLICT` when the
 * destination overlaps another library, or when the catalog already holds
 * files there, and `LIBRARY_ERR_INVALID_INPUT` when `rootPath` is blank or
 * lies outside the configured `filesystem.root` (FR-FC-26).
 */
struct LibraryJsonResult alexandria_library_move(const char *uuid, const char *json_body);

/**
 * Every registered library.
 */
struct LibraryJsonResult alexandria_libraries_list(void);

/**
 * The catalog's totals: `{"libraries": n, "filesByType": {...}}`, with all
 * seven types present and `0` for an empty one. Counts what the default file
 * listing shows: active files, including those marked missing on disk;
 * soft-deleted files are not counted. `LIBRARY_ERR_NOT_INITIALIZED` before
 * `alexandria_index_init`, `LIBRARY_ERR_OTHER` when the query fails.
 */
struct LibraryJsonResult alexandria_catalog_stats_json(void);

/**
 * One level of a library's tree.
 *
 * `path` is the folder to list, relative to the library's root; NULL or an
 * empty string is the top. One level rather than the whole tree (FR-FC-39):
 * a course of two hundred classes is a large document to build and parse
 * when the owner is looking at one folder.
 */
struct LibraryJsonResult alexandria_library_browse(const char *uuid, const char *path);

/**
 * Rename a library, whenever the owner likes, including while its run is in
 * progress or paused. `json_body` is `{"name": "..."}`; the answer is the
 * updated library's JSON. `LIBRARY_ERR_INVALID_INPUT` for a `uuid` that is
 * not one, a body that is not JSON or has no string `name`, or a blank name;
 * `LIBRARY_ERR_NOT_INITIALIZED` before init; `LIBRARY_ERR_NOT_FOUND` for a
 * uuid no library has.
 */
struct LibraryJsonResult alexandria_library_rename(const char *uuid, const char *json_body);

/**
 * Pin a library to the top of the menu, or unpin it. Answers `LIBRARY_OK`,
 * `LIBRARY_ERR_INVALID_INPUT` when `uuid` is not a uuid,
 * `LIBRARY_ERR_NOT_INITIALIZED` before init, and `LIBRARY_ERR_NOT_FOUND`
 * for a uuid no library has. Setting the value a library already has is
 * not an error.
 */
int alexandria_library_set_pinned(const char *uuid, bool pinned);

/**
 * Mark a library as a favorite, or unmark it, independently of pinning.
 * Answers the same codes as `alexandria_library_set_pinned`.
 */
int alexandria_library_set_favorite(const char *uuid, bool favorite);

/**
 * Remove a library and its catalog records (FR-FC-40); nothing on disk is
 * touched. `LIBRARY_ERR_CONFLICT` while one of its runs is running
 * (FR-FC-43). On success `json` carries an empty object rather than NULL, so
 * a caller can tell success from the failure codes without a special case.
 */
struct LibraryJsonResult alexandria_library_remove(const char *uuid);
