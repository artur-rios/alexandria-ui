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
 * FFI status codes returned by playback operations (UC-38…UC-40).
 * Deliberately separate from `INDEX_*`, `FILE_*`, and `COLLECTION_*` — per
 * the convention above — so F-10 can grow its own set without colliding;
 * `PLAYBACK_OK == FILE_OK == 0` by convention.
 */
#define PLAYBACK_OK 0

#define PLAYBACK_ERR_INVALID_INPUT 1

#define PLAYBACK_ERR_UNAUTHORIZED 2

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
 * FFI status codes returned by playlist operations (Tasks 1-6).
 * Deliberately separate from `READING_LIST_*` / `WATCHLIST_*` — per the
 * convention above — so playlist use cases can grow their own set without
 * colliding; `PLAYLIST_OK == READING_LIST_OK == WATCHLIST_OK == 0` by
 * convention.
 */
#define PLAYLIST_OK 0

#define PLAYLIST_ERR_INVALID_INPUT 1

#define PLAYLIST_ERR_UNAUTHORIZED 2

#define PLAYLIST_ERR_NOT_INITIALIZED 3

#define PLAYLIST_ERR_NOT_FOUND 4

#define PLAYLIST_ERR_INVALID_STATE 5

#define PLAYLIST_ERR_OTHER 9

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
 * UC-41 AF-01/AF-02: the request conflicts with existing state — the
 * active auth mode is not local, or an account already exists. The FFI
 * counterpart of HTTP's `409`.
 */
#define AUTH_ERR_CONFLICT 10

/**
 * Refused because it came too soon after some earlier request — a rate
 * limit. The FFI counterpart of HTTP's `429`. Its own code because it is a
 * "not yet", not a mistake the caller made.
 */
#define AUTH_ERR_RATE_LIMITED 11

/**
 * A dependency the operation needs is unavailable. The FFI counterpart of
 * HTTP's `503`; the body's `code` says which.
 */
#define AUTH_ERR_SERVICE_UNAVAILABLE 12

/**
 * FFI status codes returned by the settings read (UC-47 / FR-FC-30).
 * Deliberately separate from every other family — per the convention above —
 * so this surface can grow independently; `SETTINGS_OK == INDEX_OK == 0` by
 * convention.
 */
#define SETTINGS_OK 0

#define SETTINGS_ERR_UNAUTHORIZED 2

#define SETTINGS_ERR_NOT_INITIALIZED 3

#define SETTINGS_ERR_OTHER 9

/**
 * FFI status codes returned by run-status operations (UC-42, UC-48 / FR-FC-28, FR-FC-32 … FR-FC-35).
 * Deliberately separate from `INDEX_*`, `FILE_*`, `COLLECTION_*`, `PLAYBACK_*`,
 * and `AUTH_*` — per the convention established above — so this surface can
 * grow independently; `RUN_OK == INDEX_OK == 0` by convention.
 */
#define RUN_OK 0

#define RUN_ERR_INVALID_INPUT 1

#define RUN_ERR_UNAUTHORIZED 2

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
 * FFI status codes returned by music enrichment (music enrichment design).
 * Its own set, per the convention above, so it can grow without colliding;
 * `ENRICHMENT_OK == PLAYLIST_OK == 0`.
 */
#define ENRICHMENT_OK 0

#define ENRICHMENT_ERR_INVALID_INPUT 1

#define ENRICHMENT_ERR_UNAUTHORIZED 2

#define ENRICHMENT_ERR_NOT_INITIALIZED 3

#define ENRICHMENT_ERR_NOT_FOUND 4

/**
 * Enrichment is switched off, or is on with no contact configured.
 *
 * Its own code rather than folded into `INVALID_INPUT`, because it is not
 * something the *caller* did: the request was well formed and the
 * installation is not configured for it. A client that can tell the two
 * apart says "your administrator has not enabled this" instead of marking
 * the owner's input wrong. `alexandria_settings_json` reports the same
 * fact up front, so a client need never discover it by being refused.
 */
#define ENRICHMENT_ERR_UNAVAILABLE 5

#define ENRICHMENT_ERR_OTHER 9

/**
 * Result of starting an index run. `run_id` is a NUL-terminated UUID string
 * on success (empty on failure).
 *
 * Shared with `alexandria_index_resume` (UC-48), which reuses this same
 * struct shape for a call that is not starting anything new. That reuse
 * changes what `status` means: from `alexandria_index_start` and
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
 * array of `FileView` objects, issue #116) or `GET /v1/files/{uuid}` (a
 * single `FileView` object), so the FFI and HTTP surfaces agree modulo key
 * ordering (parity, FR-FC-24 / NFR-09). On failure `json` is NULL and
 * `status` carries the mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
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
 * Result of every playlist FFI function. On success `status` is
 * `PLAYLIST_OK` and `json` is a NUL-terminated JSON string of the response
 * body — byte-for-byte the same shape HTTP returns from the matching
 * `/v1/playlists*` route (FR-FC-24 / NFR-09). On failure `json` is NULL
 * and `status` carries the mapped error code. The caller must free `json`
 * with `alexandria_free_string`.
 */
typedef struct PlaylistJsonResult {
  int status;
  char *json;
} PlaylistJsonResult;

/**
 * Result of `alexandria_auth_local_login` / `alexandria_auth_local_set_credentials`
 * (UC-34/UC-35). On success `status` is `AUTH_OK` and `json` is a
 * NUL-terminated JSON string of the `LocalLoginResult` /
 * `LocalCredentialsResult` body — byte-for-byte the same shape HTTP
 * returns from the matching `/v1/auth/local/*` endpoint (FR-FC-24 /
 * NFR-09).
 *
 * On failure `status` carries the mapped error code and `json` carries the
 * same error envelope HTTP returns for that failure (issue #101):
 * `{"error": …}`, plus `"code"` and `"params"` when the rejection has a
 * stable reason. `status` is the coarse class; `code` is the reason — six
 * distinct password-policy rejections all arrive as
 * `AUTH_ERR_INVALID_INPUT`, and only `code` tells them apart.
 *
 * `json` is NULL only when the library was never initialized, so there was
 * no service to answer at all. The caller must free `json` with
 * `alexandria_free_string` on every path; freeing NULL is a no-op.
 */
typedef struct AuthJsonResult {
  int status;
  char *json;
} AuthJsonResult;

/**
 * Result of `alexandria_settings_json` (UC-47). On success `status` is
 * `SETTINGS_OK` and `json` is a NUL-terminated JSON string of the settings
 * body — byte-for-byte the same shape HTTP returns from `GET /v1/settings`
 * (FR-FC-24 / NFR-09). On failure `json` is NULL and `status` carries the
 * mapped error code. The caller must free `json` with
 * `alexandria_free_string`.
 */
typedef struct SettingsJsonResult {
  int status;
  char *json;
} SettingsJsonResult;

/**
 * Result of `alexandria_index_run_status_json` (UC-42). On success `status`
 * is `RUN_OK` and `json` is a NUL-terminated JSON string of the `CatalogRun`
 * body — byte-for-byte the same shape HTTP returns from
 * `GET /v1/index/runs/{runId}` (FR-FC-24 / NFR-09). On failure `json` is
 * NULL and `status` carries the mapped error code. The caller must free
 * `json` with `alexandria_free_string`.
 */
typedef struct RunJsonResult {
  int status;
  char *json;
} RunJsonResult;

/**
 * Result of every enrichment FFI function. On success `status` is
 * `ENRICHMENT_OK` and `json` is a NUL-terminated JSON string of the
 * response body — byte-for-byte the same shape HTTP returns from the
 * matching `/v1/enrichment*` route (FR-FC-24 / NFR-09). On failure `json`
 * is NULL. The caller must free `json` with `alexandria_free_string`.
 */
typedef struct EnrichmentJsonResult {
  int status;
  char *json;
} EnrichmentJsonResult;

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
 *
 * `priority` is `"low"` or `"normal"` (case-sensitive, matching the HTTP
 * body's spelling exactly — FR-FC-24). NULL or any other string is treated
 * as `"normal"`: a client that cannot spell the value gets the safe default
 * rather than a rejected call.
 *
 * `types` is the run's scope: a comma-separated list of the wire names
 * `FileType` reads back (`"audio,image"`), the same words the HTTP body's
 * `types` array carries (FR-FC-24). NULL and the empty string are the same
 * absence and mean every type — see [`parse_scope`] for why an unrecognised
 * name is `INDEX_ERR_INVALID_INPUT` here where an unrecognised priority is
 * not.
 */
struct IndexStartResult alexandria_index_start(const char *root,
                                               const char *token,
                                               const char *priority,
                                               const char *types);

/**
 * Start an asynchronous re-index/refresh of every cataloged path (UC-02).
 * Takes only a token (no root — refresh touches everything cataloged) and
 * returns a `IndexStartResult` with a `run_id` and `status` (parity with the
 * HTTP `POST /v1/index/refresh` 202 body). The refresh runs in the background
 * on the FFI runtime; read results via the accessor functions.
 *
 * `priority` is parsed exactly as `alexandria_index_start`'s is — see that
 * function's doc comment for the accepted spellings and the NULL/garbage
 * fallback.
 */
struct IndexStartResult alexandria_index_refresh_start(const char *token, const char *priority);

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
 * returned `Vec<FileView>` back to a JSON array — each element the same
 * `{"file": …, "metadata": …, …}` shape `alexandria_file_get_by_uuid`
 * answers for one file (issue #116) — so the FFI and HTTP surfaces agree
 * byte-for-byte modulo key ordering (parity, FR-FC-24 / NFR-09). `token` is
 * the bearer auth token.
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
 * Resolve a File to everything a local player needs to open it
 * (UC-38 / FR-MP-01, FR-MP-06).
 *
 * The FFI surface cannot carry a byte stream, so where HTTP streams
 * `GET /v1/files/{uuid}/stream`, this returns
 * `{"uuid":…,"path":…,"mimeType":…,"sizeBytes":…}` and the caller — Flutter
 * desktop, on the same machine as the file — opens that path directly.
 * Zero bytes cross this boundary. Parity with HTTP is defined on this
 * descriptor and on the authorization, state, and error decisions rather
 * than on byte transfer (FR-MP-06).
 */
struct PlaybackJsonResult alexandria_file_playback_source(const char *uuid, const char *token);

/**
 * One page of a CBZ ComicBook (UC-39 / FR-MP-04).
 *
 * Returns `{"uuid":…,"page":N,"pageCount":N,"mimeType":…,"bytesBase64":…}`.
 * Unlike UC-38, the bytes *do* cross the boundary: a comic page has no path
 * of its own — it lives inside an archive — and it is bounded, so
 * base64 inside the existing JSON payload keeps the FFI shape intact while
 * staying byte-exact with HTTP.
 */
struct PlaybackJsonResult alexandria_comic_page(const char *uuid, uint32_t page, const char *token);

/**
 * A downscaled thumbnail for a video, image, or comic
 * (UC-40 / FR-MP-05). Returns
 * `{"uuid":…,"mimeType":"image/jpeg","bytesBase64":…}`. Bounded derived
 * bytes, so the same base64 rule as `alexandria_comic_page` applies.
 */
struct PlaybackJsonResult alexandria_file_thumbnail(const char *uuid, const char *token);

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
 * List the owner's collections (UC-46 / FR-CO-08).
 *
 * `json_filters` is the JSON filter HTTP would build from its query string
 * (`kind`); an empty string or `null` means every collection. On success
 * `json` carries a JSON array of `CollectionSummary` — each collection with
 * the number of items it holds — byte-for-byte the same shape HTTP returns
 * from `GET /v1/collections` (parity, FR-FC-24 / NFR-09). `token` is the
 * bearer auth token.
 *
 * An owner with no collections gets an empty array and `COLLECTION_OK`, not
 * an error (AF-01). An unrecognised `kind` is `COLLECTION_ERR_INVALID_INPUT`
 * and nothing is queried (AF-02).
 */
struct CollectionJsonResult alexandria_collections_list(const char *json_filters,
                                                        const char *token);

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
 * JSON array of `{"path","name","type","hash","missingAt"}` for every
 * indexed file, or a NUL pointer on error. Caller must free it with
 * `alexandria_free_string`.
 *
 * `content_hash` is nullable (Task 3: indexing never computes one; Task 4:
 * neither does refresh) and is decoded as `Option<String>` — not `String` —
 * so a `NULL` row serializes as JSON `null` here, matching what the shared
 * `File`/`FileView` model emits over HTTP for the same column
 * (`GET /v1/files`, `catalog/model.rs`). Decoding it as a bare `String`
 * used to silently turn a SQL `NULL` into `""` instead (sqlx does not error
 * on that mismatch for this driver), which was a byte-for-byte parity
 * violation (FR-FC-24) for every indexed or refreshed file — not an edge
 * case, since neither indexing nor refresh have computed a hash since
 * Task 3/4.
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
 * Create a named, empty playlist (Task 1).
 *
 * `json_body` is the JSON body HTTP would send (`name`). The function
 * deserializes it, calls the same `CreatePlaylistHandler` the HTTP route
 * uses, and on success serializes the returned `Playlist` back to JSON —
 * so the FFI and HTTP surfaces agree byte-for-byte modulo key ordering
 * (parity, FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_create(const char *json_body, const char *token);

/**
 * Rename a playlist, leaving its entries and their order untouched
 * (Task 2).
 *
 * `uuid` is the playlist's public UUID (NUL-terminated string).
 * `json_body` is the JSON body HTTP would send (`name`). Both surfaces
 * call the same `RenamePlaylistHandler` so they stay at parity (FR-FC-24 /
 * NFR-09). `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_rename(const char *uuid,
                                                     const char *json_body,
                                                     const char *token);

/**
 * Delete a playlist, removing its entries; referenced audio files are
 * preserved (Task 3).
 *
 * `uuid` is the playlist's public UUID (NUL-terminated string). On success
 * `json` carries the pre-delete `Playlist` — byte-for-byte the same shape
 * HTTP returns from `DELETE /v1/playlists/{uuid}` (parity, FR-FC-24 /
 * NFR-09). `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_delete(const char *uuid, const char *token);

/**
 * Every persisted playlist, without their tracks (Task 6).
 *
 * `token` is the bearer auth token. On success `json` carries a
 * `Vec<Playlist>` — byte-for-byte the same shape HTTP returns from
 * `GET /v1/playlists` (parity, FR-FC-24 / NFR-09).
 */
struct PlaylistJsonResult alexandria_playlists_list(const char *token);

/**
 * Read a playlist back with its tracks, in position order (Task 6).
 *
 * `uuid` is the playlist's public UUID (NUL-terminated string). On success
 * `json` carries a `PlaylistView` — byte-for-byte the same shape HTTP
 * returns from `GET /v1/playlists/{uuid}` (parity, FR-FC-24 / NFR-09).
 * `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_read(const char *uuid, const char *token);

/**
 * Append tracks to a playlist, in order, at consecutive positions after
 * whatever it already holds (Task 4). The whole slice succeeds or none of
 * it does.
 *
 * `uuid` is the playlist's public UUID (NUL-terminated string).
 * `json_body` is the JSON body HTTP would send (`fileUuids`). On success
 * `json` carries the new `Vec<PlaylistEntry>` — byte-for-byte the same
 * shape HTTP returns from `POST /v1/playlists/{uuid}/entries` (parity,
 * FR-FC-24 / NFR-09). `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_add_entries(const char *uuid,
                                                          const char *json_body,
                                                          const char *token);

/**
 * Remove one entry from a playlist, addressed by its own `entry_uuid`
 * rather than a file uuid, since a playlist may hold the same track more
 * than once (Task 4).
 *
 * `playlist_uuid` is the playlist's public UUID (NUL-terminated string);
 * `entry_uuid` is the entry's own public UUID (NUL-terminated string),
 * passed directly rather than through a body (there is nothing else to
 * carry) -- the internal rowid is never exposed on this transport, matching
 * HTTP's `{entryUuid}` path parameter (SRD §4.0). On success `json` is an
 * empty JSON object (`"{}"`) — the core handler answers
 * `Result<(), DomainError>`, nothing beyond success is available to echo
 * back, matching `DELETE /v1/playlists/{uuid}/entries/{entryUuid}`'s
 * `200 {}` exactly (parity, FR-FC-24 / NFR-09) rather than inventing an
 * FFI-only shape. `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_remove_entry(const char *playlist_uuid,
                                                           const char *entry_uuid,
                                                           const char *token);

/**
 * Move one playlist entry to a new index, renumbering the rest in one
 * transaction (Task 5), addressed by its own `entry_uuid` rather than a
 * file uuid, since a playlist may hold the same track more than once.
 *
 * `playlist_uuid` is the playlist's public UUID (NUL-terminated string);
 * `entry_uuid` is the entry's own public UUID (NUL-terminated string) —
 * the internal rowid is never exposed on this transport (SRD §4.0).
 * `json_body` is the JSON body HTTP would send (`toIndex`). On success
 * `json` carries the playlist's full new order (`Vec<PlaylistEntry>`) —
 * byte-for-byte the same shape HTTP returns from `POST
 * /v1/playlists/{uuid}/entries/{entryUuid}/move` (parity, FR-FC-24 /
 * NFR-09). `token` is the bearer auth token.
 */
struct PlaylistJsonResult alexandria_playlist_move_entry(const char *playlist_uuid,
                                                         const char *entry_uuid,
                                                         const char *json_body,
                                                         const char *token);

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
 * Windows login (UC-45 / FR-AU-20, FR-AU-22): open a session for the
 * Windows account this process runs as. Takes no credentials — the account
 * was already verified against the configured SID at startup. `json_body`
 * is accepted but ignored: it exists only for signature consistency with
 * this surface's other `alexandria_auth_*` neighbours, which all take a
 * body. On success `json` carries the `LocalLoginResult`, the same shape
 * `alexandria_auth_local_login` returns.
 */
struct AuthJsonResult alexandria_auth_windows_login(const char *_json_body);

/**
 * Set or change local-login credentials (UC-35 / FR-AU-05, FR-AU-06).
 * `json_body` is the JSON body HTTP would send (`email`, `password`).
 * `token` is required: this changes existing credentials. Creating the
 * account is `alexandria_auth_local_register` (UC-41).
 */
struct AuthJsonResult alexandria_auth_local_set_credentials(const char *json_body,
                                                            const char *token);

/**
 * Register the local account (UC-41 / FR-AU-10, FR-AU-11): create the
 * single owner's credentials and open a session. `json_body` is the JSON
 * body HTTP would send (`email`, `password`, `passwordConfirmation`). On
 * success `json` carries the `LocalRegisterResult`, whose `sessionId` the
 * caller presents on subsequent requests.
 *
 * Deliberately takes no `token`: there is nothing to authenticate with
 * before an account exists. Succeeds only once — a second call returns
 * `AUTH_ERR_CONFLICT` (AF-02).
 */
struct AuthJsonResult alexandria_auth_local_register(const char *json_body);

/**
 * Report the authenticated owner's account state (FR-AU-18): the same body
 * `GET /v1/auth/local/account` returns. `token` is the session id.
 *
 * This is the call a client makes to learn the stored address and how many
 * recovery codes remain unspent.
 */
struct AuthJsonResult alexandria_auth_local_account(const char *token);

/**
 * Redeem a recovery code for a new password (UC-43 / FR-AU-14 … FR-AU-16).
 * `json_body` is the JSON body HTTP would send: an object with `code`,
 * `newPassword`, and `passwordConfirmation`.
 *
 * Deliberately takes no session token: the code is the credential, and this
 * is the operation a caller who cannot authenticate uses to get back in.
 * Every session is invalidated on success.
 */
struct AuthJsonResult alexandria_auth_local_redeem_recovery_code(const char *json_body);

/**
 * Replace the owner's recovery codes with a fresh set of ten (UC-44 /
 * FR-AU-17), invalidating every old one. `token` is the session id the
 * caller authenticates with, exactly as `alexandria_auth_local_account`
 * takes it.
 */
struct AuthJsonResult alexandria_auth_local_regenerate_recovery_codes(const char *token);

/**
 * Report the client-relevant configuration (UC-47 / FR-FC-30).
 *
 * On success `json` carries the same body HTTP returns from
 * `GET /v1/settings` — today `{"deletion":{"retentionDays":30}}`, the
 * soft-delete retention window this server enforces on every restore and
 * purge. `token` is the bearer auth token.
 *
 * The boundary the number describes is the core's own: elapsed time up to and
 * including `retentionDays` leaves a record restorable and not yet purgeable;
 * strictly past it, the record is purgeable and no longer restorable.
 */
struct SettingsJsonResult alexandria_settings_json(const char *token);

/**
 * Report an index or re-index run's status and outcome (UC-42 / FR-FC-28).
 * `run_id` is the id `alexandria_index_start` or
 * `alexandria_index_refresh_start` returned. On success `json` carries the
 * same body the HTTP `GET /v1/index/runs/{runId}` route returns (FR-FC-24).
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_UNAUTHORIZED` for an unauthenticated caller (AF-02), and
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid.
 */
struct RunJsonResult alexandria_index_run_status_json(const char *run_id, const char *token);

/**
 * Pause a running index or re-index run where it stands, leaving it
 * resumable (UC-48 / FR-FC-32). `run_id` is the id `alexandria_index_start`
 * or `alexandria_index_refresh_start` returned; `token` is the bearer auth
 * token. Calls the same `RunControlHandler::pause` the HTTP route (Task 12)
 * calls.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_UNAUTHORIZED` for an unauthenticated caller (AF-02),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is not currently `running` — pausing
 * an already-paused or already-finished run is refused rather than silently
 * accepted.
 */
int alexandria_index_pause(const char *run_id, const char *token);

/**
 * Abandon a running or paused index or re-index run (UC-48 / FR-FC-34).
 * Terminal — a cancelled run is never resumed. `run_id` is the id
 * `alexandria_index_start` or `alexandria_index_refresh_start` returned;
 * `token` is the bearer auth token. Calls the same
 * `RunControlHandler::cancel` the HTTP route (Task 12) calls.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_UNAUTHORIZED` for an unauthenticated caller (AF-02),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is already terminal (`complete`,
 * `failed`, or already `cancelled`) — there is nothing left to abandon.
 */
int alexandria_index_cancel(const char *run_id, const char *token);

/**
 * Put a paused index or re-index run back to work (UC-48 / FR-FC-33).
 * `run_id` is the id `alexandria_index_start` or `alexandria_index_refresh_start`
 * returned; `token` is the bearer auth token. Returns the *same* `run_id` on
 * success — a resume does not mint a fresh run, it continues the one it was
 * given — wrapped in the same `IndexStartResult` `alexandria_index_start`
 * returns (parity of shape, not of meaning: `status` here is a `RUN_ERR_*`
 * code, because resume is part of run control, not of starting a fresh run).
 *
 * `RunControlHandler::resume` only records the state transition; it does not
 * walk anything. Spawning the walk is this function's job, exactly as
 * `alexandria_index_start` spawns its own — the handler is kept free of the
 * runtime so `execute` is always spawned by whichever transport owns one.
 * Which handler gets spawned depends on `RunResumed::kind`: an index run
 * resumes into `index_handler.execute(&root, run_id, &scope)` — the scope
 * read back off the run, so a resumed segment covers the file types the run
 * was started with — a refresh into
 * `refresh_handler.execute(run_id)` (a refresh carries no root — it touches
 * everything cataloged). A resumed index run whose stored `root` is somehow
 * absent — it should never be, every row `RunKind::Index` writes carries one
 * — is refused with `RUN_ERR_OTHER` and logged at `error`, rather than
 * silently doing nothing: a caller told `RUN_OK` for a run that never
 * actually resumes would have no way to notice.
 *
 * `priority` re-paces the run (FR-FC-08 / FR-FC-33): `"low"` or `"normal"`,
 * the same case-sensitive spelling `alexandria_index_start` accepts. Unlike
 * there, NULL or an unrecognised string does **not** mean `"normal"` — it
 * means *keep the width this run already has*, which is what every caller
 * written before this parameter existed was asking for. Passing NULL is
 * therefore the backward-compatible call, and `"normal"` is a real request
 * to speed a low-priority run back up. See `parse_resume_priority`.
 *
 * Returns `RUN_ERR_NOT_FOUND` for an id naming no run (AF-01),
 * `RUN_ERR_UNAUTHORIZED` for an unauthenticated caller (AF-02),
 * `RUN_ERR_INVALID_INPUT` when `run_id` is not a uuid, and
 * `RUN_ERR_INVALID_STATE` when the run is not currently `paused`.
 */
struct IndexStartResult alexandria_index_resume(const char *run_id,
                                                const char *token,
                                                const char *priority);

/**
 * Every outstanding (`running` or `paused`) index and re-index run at once,
 * each with live progress overlaid exactly as `alexandria_index_run_status_json`
 * overlays a single run (UC-42 / FR-FC-35). `token` is the bearer auth
 * token. On success `json` is a NUL-terminated JSON array of `CatalogRun`
 * bodies, newest first — byte-for-byte the same shape the HTTP
 * `GET /v1/index/runs?status=active` route (Task 12) returns (FR-FC-24 / NFR-09).
 * The caller must free `json` with `alexandria_free_string`.
 *
 * A caller with nothing outstanding gets `RUN_OK` and an empty JSON array,
 * not an error — an idle library is the normal case, not a failure.
 *
 * Returns `RUN_ERR_UNAUTHORIZED` for an unauthenticated caller (AF-02).
 */
struct RunJsonResult alexandria_index_runs_active_json(const char *token);

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
 * Run music enrichment (music enrichment design).
 *
 * `scope_json` is the JSON body `POST /v1/enrichment/runs` takes, and NULL
 * or an empty string means the same thing an absent body does there: sweep
 * everything not yet looked up. `{"fileUuid":"…"}` scopes it to one track,
 * `{"artist":"…"}` to one artist. `token` is the bearer auth token.
 *
 * **This call reaches the network** — the only FFI function in this library
 * that does — and it is slow by design: MusicBrainz is rate-limited to one
 * request per second and a sweep over a large library will take hours. A
 * caller must run it off whatever thread its interface draws on, and should
 * expect to show progress from the returned counts rather than a spinner.
 *
 * A run that reached nothing still succeeds: a service being down or having
 * no answer is counted in the report, not raised.
 */
struct EnrichmentJsonResult alexandria_enrichment_run(const char *scope_json, const char *token);

/**
 * Read what enrichment has stored for one track.
 *
 * `uuid` is the file's public UUID. `artist` is whose image to read — the
 * caller is a player already showing the track, so it is holding the tags
 * and passing the name costs nothing, where resolving it here would be a
 * second query for a fact it has. NULL means "no image wanted".
 *
 * Unlike the run above this makes **no network call** and works whether or
 * not enrichment is switched on: reading what was already cached is a plain
 * database read, so an owner who enabled it, ran it once and turned it off
 * keeps what they fetched.
 */
struct EnrichmentJsonResult alexandria_enrichment_read_track(const char *uuid,
                                                             const char *artist,
                                                             const char *token);
