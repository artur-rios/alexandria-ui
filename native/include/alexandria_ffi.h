#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * FFI status codes returned by index operations.
 */
#define INDEX_OK 0

#define INDEX_ERR_INVALID_INPUT 1

#define INDEX_ERR_UNAUTHORIZED 2

#define INDEX_ERR_NOT_INITIALIZED 3

#define INDEX_ERR_OTHER 4

/**
 * FFI status codes returned by file operations (UC-04+). Deliberately
 * separate from `INDEX_*` so a future use case can grow either set without
 * colliding; `FILE_OK == INDEX_OK == 0` by convention.
 */
#define FILE_OK 0

#define FILE_ERR_INVALID_INPUT 1

#define FILE_ERR_UNAUTHORIZED 2

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

#define COLLECTION_ERR_UNAUTHORIZED 2

#define COLLECTION_ERR_NOT_INITIALIZED 3

#define COLLECTION_ERR_NOT_FOUND 4

#define COLLECTION_ERR_INVALID_STATE 5

#define COLLECTION_ERR_OTHER 9

/**
 * FFI status codes returned by bookmark operations (UC-15+). Deliberately
 * separate from `COLLECTION_*` — per the convention above — so bookmark use
 * cases can grow their own set without colliding; `BOOKMARK_OK ==
 * COLLECTION_OK == 0` by convention. There is no disk code: a bookmark is
 * catalog-only metadata with nothing on disk.
 */
#define BOOKMARK_OK 0

#define BOOKMARK_ERR_INVALID_INPUT 1

#define BOOKMARK_ERR_UNAUTHORIZED 2

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

#define WATCHLIST_ERR_UNAUTHORIZED 2

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

#define READING_LIST_ERR_UNAUTHORIZED 2

#define READING_LIST_ERR_NOT_INITIALIZED 3

#define READING_LIST_ERR_NOT_FOUND 4

#define READING_LIST_ERR_INVALID_STATE 5

#define READING_LIST_ERR_OTHER 9

/**
 * FFI status codes returned by local-auth operations (UC-34/UC-35).
 * Deliberately separate from the other `*_OK == 0` families — per the
 * convention above — so local-auth use cases can grow their own set
 * without colliding.
 */
#define AUTH_OK 0

#define AUTH_ERR_INVALID_INPUT 1

#define AUTH_ERR_UNAUTHORIZED 2

#define AUTH_ERR_NOT_INITIALIZED 3

#define AUTH_ERR_INVALID_STATE 5

#define AUTH_ERR_CONFIG 8

#define AUTH_ERR_OTHER 9

/**
 * Result of starting an index run. `run_id` is a NUL-terminated UUID string
 * on success (empty on failure).
 */
typedef struct IndexStartResult {
  int status;
  char run_id[37];
} IndexStartResult;

/**
 * Result of `alexandria_file_edit_metadata` (UC-04). On success `status` is
 * `FILE_OK` and `json` is a NUL-terminated JSON string of the `FileMetadata`
 * body — byte-for-byte the same shape HTTP returns from
 * `PATCH /v1/files/{uuid}/metadata` (FR-FC-24 / NFR-09). On failure `json`
 * is NULL and `status` carries the mapped error code. The caller must free
 * `json` with `alexandria_free_string`.
 */
typedef struct FileMetadataResult {
  int status;
  char *json;
} FileMetadataResult;

/**
 * Result of `alexandria_files_list` and `alexandria_file_get_by_uuid` (UC-03).
 * On success `status` is `FILE_OK` and `json` is a NUL-terminated JSON string
 * — byte-for-byte the same shape HTTP returns from `GET /v1/files` (a JSON
 * array of `File` records) or `GET /v1/files/{uuid}` (a `FileView` object),
 * so the FFI and HTTP surfaces agree modulo key ordering (parity, FR-FC-24 /
 * NFR-09). On failure `json` is NULL and `status` carries the mapped error
 * code. The caller must free `json` with `alexandria_free_string`.
 */
typedef struct FileJsonResult {
  int status;
  char *json;
} FileJsonResult;

/**
 * Result of `alexandria_collection_create` (UC-10). On success `status` is
 * `COLLECTION_OK` and `json` is a NUL-terminated JSON string of the
 * `Collection` body — byte-for-byte the same shape HTTP returns from
 * `POST /v1/collections` (FR-FC-24 / NFR-09). On failure `json` is NULL and
 * `status` carries the mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct CollectionJsonResult {
  int status;
  char *json;
} CollectionJsonResult;

/**
 * Result of `alexandria_bookmark_create` (UC-15). On success `status` is
 * `BOOKMARK_OK` and `json` is a NUL-terminated JSON string of the `Bookmark`
 * body — byte-for-byte the same shape HTTP returns from `POST
 * /v1/bookmarks` (FR-FC-24 / NFR-09). On failure `json` is NULL and `status`
 * carries the mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct BookmarkJsonResult {
  int status;
  char *json;
} BookmarkJsonResult;

/**
 * Result of `alexandria_watchlist_create` (UC-20). On success `status` is
 * `WATCHLIST_OK` and `json` is a NUL-terminated JSON string of the
 * `Watchlist` body — byte-for-byte the same shape HTTP returns from `POST
 * /v1/watchlists` (FR-FC-24 / NFR-09). On failure `json` is NULL and
 * `status` carries the mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct WatchlistJsonResult {
  int status;
  char *json;
} WatchlistJsonResult;

/**
 * Result of `alexandria_reading_list_create` (UC-26). On success `status`
 * is `READING_LIST_OK` and `json` is a NUL-terminated JSON string of the
 * `ReadingList` body — byte-for-byte the same shape HTTP returns from
 * `POST /v1/reading-lists` (FR-FC-24 / NFR-09). On failure `json` is NULL
 * and `status` carries the mapped error code. The caller must free `json`
 * with `alexandria_free_string`.
 */
typedef struct ReadingListJsonResult {
  int status;
  char *json;
} ReadingListJsonResult;

/**
 * Result of `alexandria_auth_local_login` / `alexandria_auth_local_set_credentials`
 * (UC-34/UC-35). On success `status` is `AUTH_OK` and `json` is a
 * NUL-terminated JSON string of the `LocalLoginResult` /
 * `LocalCredentialsResult` body — byte-for-byte the same shape HTTP
 * returns from the matching `/v1/auth/local/*` endpoint (FR-FC-24 /
 * NFR-09). On failure `json` is NULL and `status` carries the mapped
 * error code. The caller must free `json` with `alexandria_free_string`.
 */
typedef struct AuthJsonResult {
  int status;
  char *json;
} AuthJsonResult;

const char *alexandria_version(void);

int32_t alexandria_health_status_code(void);

/**
 * Initialize the FFI services against a database path (created/migrated on
 * demand). Safe to call again to point at a different database (replaces).
 * Returns 0 on success, a non-zero status otherwise.
 *
 * Configuration is loaded the same way `alexandria-http` loads it — from the
 * path in `ALEXANDRIA_CONFIG` (default `config.toml`), with `ALEXANDRIA_*`
 * environment overrides applied — so a setting such as the auth mode or the
 * retention window means the same thing on both surfaces (FR-FC-24 / NFR-09).
 * A missing or unreadable config file falls back to defaults rather than
 * failing, matching the HTTP binary. `db_path` wins over the config's
 * `database.path`: the embedder passed it explicitly.
 */
int alexandria_index_init(const char *db_path);

/**
 * Start an asynchronous index scan of `root`. Returns a `IndexStartResult`
 * with a `run_id` and `status` (parity with HTTP 202 body). The scan runs in
 * the background on the FFI runtime; read results via the accessor functions.
 */
struct IndexStartResult alexandria_index_start(const char *root, const char *token);

/**
 * Start an asynchronous re-index/refresh of every cataloged path (UC-02).
 * Takes only a token (no root — refresh touches everything cataloged) and
 * returns a `IndexStartResult` with a `run_id` and `status` (parity with the
 * HTTP `POST /v1/index/refresh` 202 body). The refresh runs in the background
 * on the FFI runtime; read results via the accessor functions.
 */
struct IndexStartResult alexandria_index_refresh_start(const char *token);

/**
 * Count of indexed files. For tests waiting for the background scan.
 */
int64_t alexandria_index_count_files(void);

/**
 * Edit a file's type-specific metadata (UC-04 / FR-FC-14..18).
 *
 * `uuid` is the file's public UUID string; `json_patch` is the JSON body
 * (the `SubtypeMetadata` enum, internally tagged by `type`) that HTTP would
 * send. The function deserializes it, calls the same `EditMetadataHandler`
 * the HTTP route uses, and on success serializes the returned `FileMetadata`
 * back to JSON — so the FFI and HTTP surfaces agree byte-for-byte modulo key
 * ordering (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct FileMetadataResult alexandria_file_edit_metadata(const char *uuid,
                                                        const char *json_patch,
                                                        const char *token);

/**
 * List/query files filtered by type and lifecycle state (UC-03 / FR-FC-12).
 *
 * `json_filters` is a JSON string `{"type":"audio","state":"all"}` (empty
 * string or NULL for defaults). The function deserializes it, calls the same
 * `BrowseFilesHandler` the HTTP route uses, and on success serializes the
 * returned `Vec<File>` back to a JSON array — so the FFI and HTTP surfaces
 * agree byte-for-byte modulo key ordering (parity, FR-FC-24 / NFR-09).
 * `token` is the bearer auth token.
 */
struct FileJsonResult alexandria_files_list(const char *json_filters, const char *token);

/**
 * Get a single file's metadata by its public UUID (UC-03 / FR-FC-13).
 *
 * `uuid` is the file's public UUID string. The function calls the same
 * `BrowseFilesHandler::get_by_uuid` the HTTP route uses, and on success
 * serializes the returned `FileView` back to JSON — the same shape HTTP
 * returns from `GET /v1/files/{uuid}` (parity, FR-FC-24 / NFR-09). `token`
 * is the bearer auth token.
 */
struct FileJsonResult alexandria_file_get_by_uuid(const char *uuid, const char *token);

/**
 * Read a TextFile's content from disk (UC-32 / FR-TX-01).
 *
 * `uuid` is the file's public UUID (NUL-terminated string). On success
 * `json` carries the `FileContent` — byte-for-byte the same shape HTTP
 * returns from `GET /v1/files/{uuid}/content` (parity, FR-FC-24 / NFR-09).
 * `token` is the bearer auth token.
 */
struct FileJsonResult alexandria_file_read_content(const char *uuid, const char *token);

/**
 * Write edited content back to a TextFile on disk (UC-33 / FR-TX-02,
 * FR-TX-03).
 *
 * `uuid` is the file's public UUID (NUL-terminated string). `json_body` is
 * the JSON body HTTP would send (`content`). The function deserializes it,
 * calls the same `EditTextFileContentHandler` the HTTP route uses, and on
 * success serializes the returned `File` back to JSON — so the FFI and
 * HTTP surfaces agree byte-for-byte modulo key ordering (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct FileJsonResult alexandria_file_edit_content(const char *uuid,
                                                   const char *json_body,
                                                   const char *token);

/**
 * Rename a file (and its on-disk file) (UC-05 / FR-FC-19).
 *
 * `uuid` is the file's public UUID string; `name` is the new file name. The
 * function calls the same `RenameFileHandler` the HTTP route uses and on
 * success serializes the returned `File` back to JSON — the same shape HTTP
 * returns from `POST /v1/files/{uuid}/rename`, so the FFI and HTTP surfaces
 * agree byte-for-byte modulo key ordering (parity, FR-FC-24 / NFR-09).
 * `token` is the bearer auth token. A disk failure (AF-02) maps to
 * `FILE_ERR_DISK`; the catalog is left untouched in that case.
 */
struct FileJsonResult alexandria_file_rename(const char *uuid, const char *name, const char *token);

/**
 * Soft-delete a file (UC-06 / FR-FC-20).
 *
 * `uuid` is the file's public UUID string; `token` is the bearer auth token.
 * The function calls the same `SoftDeleteFileHandler` the HTTP route uses
 * and on success serializes the returned `File` back to JSON — the same
 * shape HTTP returns from `DELETE /v1/files/{uuid}`, so the FFI and HTTP
 * surfaces agree byte-for-byte modulo key ordering (parity, FR-FC-24 /
 * NFR-09). The on-disk file is untouched (only `state` and `deleted_at`
 * change on the catalog row).
 */
struct FileJsonResult alexandria_file_soft_delete(const char *uuid, const char *token);

/**
 * Restore a soft-deleted file (UC-07 / FR-FC-21).
 *
 * `uuid` is the file's public UUID string; `token` is the bearer auth token.
 * The function calls the same `RestoreFileHandler` the HTTP route uses and
 * on success serializes the returned `File` back to JSON — the same shape
 * HTTP returns from `POST /v1/files/{uuid}/restore`, so the FFI and HTTP
 * surfaces agree byte-for-byte modulo key ordering (parity, FR-FC-24 /
 * NFR-09). The on-disk file is untouched (only `state` and `deleted_at`
 * change on the catalog row). The retention window (default 30 days,
 * NFR-10) is enforced; a record past it is reported as `NotFound`
 * (`FILE_ERR_NOT_FOUND`) since UC-08 owns the actual hard purge.
 */
struct FileJsonResult alexandria_file_restore(const char *uuid, const char *token);

/**
 * Hard-purge a soft-deleted file's catalog row (UC-08 / FR-FC-22).
 *
 * `uuid` is the file's public UUID string; `token` is the bearer auth
 * token. The function calls the same `PurgeFileHandler` the HTTP route
 * uses (`DELETE /v1/files/{uuid}?purge=true`) and on success serializes
 * the pre-delete `File` back to JSON as confirmation — the same shape
 * HTTP returns, so the FFI and HTTP surfaces agree byte-for-byte modulo
 * key ordering (parity, FR-FC-24 / NFR-09). Only the catalog row (and its
 * subtype row) is removed; the on-disk file is untouched (NFR-07). The
 * retention window (default 30 days, NFR-10) is enforced: a record still
 * within it, or not `deleted`, is reported as `FILE_ERR_INVALID_STATE`.
 */
struct FileJsonResult alexandria_file_purge(const char *uuid, const char *token);

/**
 * Purge a file both on disk and in the catalog (UC-09 / FR-FC-23).
 *
 * `uuid` is the file's public UUID string; `token` is the bearer auth
 * token. The function calls the same `PurgeFileOnDiskHandler` the HTTP
 * route uses (`DELETE /v1/files/{uuid}?purge-on-disk=true`) and on success
 * serializes the returned [`PurgeOnDiskOutcome`] back to JSON — the same
 * shape HTTP returns, so the FFI and HTTP surfaces agree byte-for-byte
 * modulo key ordering (parity, FR-FC-24 / NFR-09). Unlike UC-08 there is no
 * retention gate: an `active` or `deleted` record is purgeable, the only
 * precondition is that it exists. A missing on-disk file is still a
 * success, reported via `diskFilePresent: false` (AF-01); a disk failure
 * is reported as `FILE_ERR_DISK` (AF-02) and leaves the record untouched.
 */
struct FileJsonResult alexandria_file_purge_on_disk(const char *uuid, const char *token);

/**
 * Create a flat file or bookmark collection (UC-10 / FR-CO-01, FR-CO-02).
 *
 * `json_body` is the JSON body HTTP would send (`name` + `kind`). The
 * function deserializes it, calls the same `CreateCollectionHandler` the HTTP
 * route uses, and on success serializes the returned `Collection` back to
 * JSON — so the FFI and HTTP surfaces agree byte-for-byte modulo key ordering
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_create(const char *json_body, const char *token);

/**
 * Rename a collection (UC-11 / FR-CO-03).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). `json_body`
 * is the JSON body HTTP would send (`{"name": …}`). The function
 * deserializes it, calls the same `RenameCollectionHandler` the HTTP route
 * uses, and on success serializes the returned `Collection` back to JSON —
 * so the FFI and HTTP surfaces agree byte-for-byte modulo key ordering
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_rename(const char *uuid,
                                                         const char *json_body,
                                                         const char *token);

/**
 * Delete a collection, unlinking its items (UC-12 / FR-CO-04).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). On success
 * `json` carries the pre-delete `Collection` as confirmation — byte-for-byte
 * the same shape HTTP returns from `DELETE /v1/collections/{uuid}` (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_delete(const char *uuid, const char *token);

/**
 * Add items to a collection (UC-13 / FR-CO-05).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). `json_body`
 * is the JSON body HTTP would send (`itemUuids`). The function deserializes
 * it, calls the same `AddItemsToCollectionHandler` the HTTP route uses, and
 * on success serializes the returned `CollectionItemsResult` back to JSON —
 * so the FFI and HTTP surfaces agree byte-for-byte modulo key ordering
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_add_items(const char *uuid,
                                                            const char *json_body,
                                                            const char *token);

/**
 * Remove an item from a collection (UC-14 / FR-CO-06).
 *
 * `collection_uuid` and `item_uuid` are the collection's and item's public
 * UUIDs (NUL-terminated strings). On success `json` carries the
 * `collectionUuid`/`itemUuid` confirmation — byte-for-byte the same shape
 * HTTP returns from `DELETE /v1/collections/{uuid}/items/{itemUuid}`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_remove_item(const char *collection_uuid,
                                                              const char *item_uuid,
                                                              const char *token);

/**
 * List the items in a collection (UC-14 / FR-CO-07).
 *
 * `uuid` is the collection's public UUID (NUL-terminated string). On
 * success `json` carries the `kind` and current members — byte-for-byte
 * the same shape HTTP returns from `GET /v1/collections/{uuid}/items`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct CollectionJsonResult alexandria_collection_list_items(const char *uuid, const char *token);

/**
 * Create a browser bookmark, optionally in an existing bookmark collection
 * (UC-15 / FR-BM-01).
 *
 * `json_body` is the JSON body HTTP would send (`url` + `title` +
 * `collectionUuid`). The function deserializes it, calls the same
 * `CreateBookmarkHandler` the HTTP route uses, and on success serializes the
 * returned `Bookmark` back to JSON — so the FFI and HTTP surfaces agree
 * byte-for-byte modulo key ordering (parity, FR-FC-24 / NFR-09). `token` is
 * the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmark_create(const char *json_body, const char *token);

/**
 * Update a bookmark's url, title, and containing collection (UC-16 /
 * FR-BM-02).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). `json_body`
 * is the JSON body HTTP would send (`url` + `title` + `collectionUuid`).
 * The function deserializes it, calls the same `UpdateBookmarkHandler` the
 * HTTP route uses, and on success serializes the returned `Bookmark` back
 * to JSON — so the FFI and HTTP surfaces agree byte-for-byte modulo key
 * ordering (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmark_update(const char *uuid,
                                                     const char *json_body,
                                                     const char *token);

/**
 * Browse bookmarks, optionally filtered by containing collection (UC-17 /
 * FR-BM-06).
 *
 * `json_filters` is a JSON string `{"collectionUuid":"…","state":"all"}`
 * (empty string or NULL for defaults). The function deserializes it, calls
 * the same `BrowseBookmarksHandler` the HTTP route uses, and on success
 * serializes the returned `Vec<Bookmark>` back to a JSON array — so the FFI
 * and HTTP surfaces agree byte-for-byte modulo key ordering (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmarks_list(const char *json_filters, const char *token);

/**
 * Soft-delete a bookmark (UC-18 / FR-BM-03).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the updated `Bookmark` — byte-for-byte the same shape HTTP
 * returns from `DELETE /v1/bookmarks/{uuid}` (parity, FR-FC-24 / NFR-09).
 * `token` is the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmark_soft_delete(const char *uuid, const char *token);

/**
 * Restore a soft-deleted bookmark (UC-18 / FR-BM-05).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the restored `Bookmark` — byte-for-byte the same shape
 * HTTP returns from `POST /v1/bookmarks/{uuid}/restore` (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmark_restore(const char *uuid, const char *token);

/**
 * Hard-purge a bookmark (UC-19 / FR-BM-04).
 *
 * `uuid` is the bookmark's public UUID (NUL-terminated string). On success
 * `json` carries the pre-purge `Bookmark` as confirmation — byte-for-byte
 * the same shape HTTP returns from `DELETE /v1/bookmarks/{uuid}?purge=true`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct BookmarkJsonResult alexandria_bookmark_purge(const char *uuid, const char *token);

/**
 * Create a named watchlist for tracking video consumption (UC-20 /
 * FR-WL-01).
 *
 * `json_body` is the JSON body HTTP would send (`name`). The function
 * deserializes it, calls the same `CreateWatchlistHandler` the HTTP route
 * uses, and on success serializes the returned `Watchlist` back to JSON —
 * so the FFI and HTTP surfaces agree byte-for-byte modulo key ordering
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlist_create(const char *json_body, const char *token);

/**
 * Add a video to a watchlist (UC-22 / FR-WL-02, FR-WL-03).
 *
 * `uuid` is the watchlist's public UUID (NUL-terminated string). `json_body`
 * is the JSON body HTTP would send (`videoUuid`). The function deserializes
 * it, calls the same `AddVideoToWatchlistHandler` the HTTP route uses, and
 * on success serializes the returned `WatchProgress` back to JSON — so the
 * FFI and HTTP surfaces agree byte-for-byte modulo key ordering (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlist_add_video(const char *uuid,
                                                          const char *json_body,
                                                          const char *token);

/**
 * Browse watchlists and their items' watch progress (UC-21 / FR-WL-08).
 *
 * `json_filters` is the JSON filter HTTP would build from its query string
 * (`watchlistUuid`); an empty string or `null` means every watchlist. On
 * success `json` carries a JSON array of `WatchlistWithProgress` — byte-for-
 * byte the same shape HTTP returns from `GET /v1/watchlists` (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlists_list(const char *json_filters, const char *token);

/**
 * Update watch progress (UC-23 / FR-WL-04, FR-WL-05).
 *
 * `watchlist_uuid` and `video_uuid` are the watchlist's and video's public
 * UUIDs (NUL-terminated strings). `json_body` is the JSON body HTTP would
 * send (`state`, optional `currentEpisode`/`totalEpisodes`). On success
 * `json` carries the updated `WatchProgress` — byte-for-byte the same shape
 * HTTP returns from `PATCH /v1/watchlists/{uuid}/items/{videoUuid}`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlist_update_progress(const char *watchlist_uuid,
                                                                const char *video_uuid,
                                                                const char *json_body,
                                                                const char *token);

/**
 * Remove a video from a watchlist (UC-24 / FR-WL-06).
 *
 * `watchlist_uuid` and `video_uuid` are the watchlist's and video's public
 * UUIDs (NUL-terminated strings). On success `json` carries the
 * `watchlistUuid`/`videoUuid` confirmation — byte-for-byte the same shape
 * HTTP returns from `DELETE /v1/watchlists/{uuid}/items/{videoUuid}`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlist_remove_video(const char *watchlist_uuid,
                                                             const char *video_uuid,
                                                             const char *token);

/**
 * Delete a watchlist (UC-25 / FR-WL-07).
 *
 * `uuid` is the watchlist's public UUID (NUL-terminated string). On success
 * `json` carries the pre-delete `Watchlist` — byte-for-byte the same shape
 * HTTP returns from `DELETE /v1/watchlists/{uuid}` (parity, FR-FC-24 /
 * NFR-09). `token` is the bearer auth token.
 */
struct WatchlistJsonResult alexandria_watchlist_delete(const char *uuid, const char *token);

/**
 * Count of cataloged files currently marked missing on disk (UC-02 AF-01).
 */
int64_t alexandria_index_count_missing(void);

/**
 * JSON array of `{"path","name","type","hash"}` for every indexed file, or a
 * NUL pointer on error. Caller must free it with `alexandria_free_string`.
 */
char *alexandria_index_files_json(void);

/**
 * Create a named reading list for tracking book/comic consumption (UC-26 /
 * FR-RL-01).
 *
 * `json_body` is the JSON body HTTP would send (`name`). The function
 * deserializes it, calls the same `CreateReadingListHandler` the HTTP
 * route uses, and on success serializes the returned `ReadingList` back to
 * JSON — so the FFI and HTTP surfaces agree byte-for-byte modulo key
 * ordering (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct ReadingListJsonResult alexandria_reading_list_create(const char *json_body,
                                                            const char *token);

/**
 * Add a book or comic to a reading list (UC-28 / FR-RL-02, FR-RL-03).
 *
 * `uuid` is the reading list's public UUID (NUL-terminated string).
 * `json_body` is the JSON body HTTP would send (`itemUuid`). The function
 * deserializes it, calls the same `AddItemToReadingListHandler` the HTTP
 * route uses, and on success serializes the returned `ReadingProgress`
 * back to JSON — so the FFI and HTTP surfaces agree byte-for-byte modulo
 * key ordering (parity, FR-FC-24 / NFR-09). `token` is the bearer auth
 * token.
 */
struct ReadingListJsonResult alexandria_reading_list_add_item(const char *uuid,
                                                              const char *json_body,
                                                              const char *token);

/**
 * Browse reading lists and their items' read progress (UC-27 / FR-RL-08).
 *
 * `json_filters` is the JSON filter HTTP would build from its query string
 * (`readingListUuid`); an empty string or `null` means every reading list.
 * On success `json` carries a JSON array of `ReadingListWithProgress` —
 * byte-for-byte the same shape HTTP returns from `GET /v1/reading-lists`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct ReadingListJsonResult alexandria_reading_lists_list(const char *json_filters,
                                                           const char *token);

/**
 * Update reading progress (UC-29 / FR-RL-04, FR-RL-05).
 *
 * `reading_list_uuid` and `item_uuid` are the reading list's and item's
 * public UUIDs (NUL-terminated strings). `json_body` is the JSON body HTTP
 * would send (`state`, optional `currentIssue`/`totalIssues`). On success
 * `json` carries the updated `ReadingProgress` — byte-for-byte the same
 * shape HTTP returns from `PATCH /v1/reading-lists/{uuid}/items/{itemUuid}`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct ReadingListJsonResult alexandria_reading_list_update_progress(const char *reading_list_uuid,
                                                                     const char *item_uuid,
                                                                     const char *json_body,
                                                                     const char *token);

/**
 * Remove an item from a reading list (UC-30 / FR-RL-06).
 *
 * `reading_list_uuid` and `item_uuid` are the reading list's and item's
 * public UUIDs (NUL-terminated strings). On success `json` carries the
 * `readingListUuid`/`itemUuid` confirmation — byte-for-byte the same shape
 * HTTP returns from `DELETE /v1/reading-lists/{uuid}/items/{itemUuid}`
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct ReadingListJsonResult alexandria_reading_list_remove_item(const char *reading_list_uuid,
                                                                 const char *item_uuid,
                                                                 const char *token);

/**
 * Delete a reading list (UC-31 / FR-RL-07).
 *
 * `uuid` is the reading list's public UUID (NUL-terminated string). On
 * success `json` carries the pre-delete `ReadingList` — byte-for-byte the
 * same shape HTTP returns from `DELETE /v1/reading-lists/{uuid}` (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct ReadingListJsonResult alexandria_reading_list_delete(const char *uuid, const char *token);

/**
 * Local login (UC-34 / FR-AU-04): verify email + password and create a
 * session. `json_body` is the JSON body HTTP would send (`email`,
 * `password`). On success `json` carries the `LocalLoginResult` — the
 * caller presents its `sessionId` on subsequent requests instead of a
 * bearer token in local mode.
 *
 * Deliberately takes no `token`: this is how a caller obtains credentials
 * in the first place (mirrors the HTTP route being outside the auth gate).
 */
struct AuthJsonResult alexandria_auth_local_login(const char *json_body);

/**
 * Set or change local-login credentials (UC-35 / FR-AU-05, FR-AU-06).
 * `json_body` is the JSON body HTTP would send (`email`, `password`).
 * `token` is optional: required only once credentials already exist
 * (AF-03) — pass an empty string on first-time setup.
 */
struct AuthJsonResult alexandria_auth_local_set_credentials(const char *json_body,
                                                            const char *token);

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
