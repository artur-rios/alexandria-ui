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
  Future<CoreJsonResponse> watchlistsList(
    String jsonFilters,
    String token,
  ) async =>
      await _isolate.call('watchlistsList', [jsonFilters, token])
          as CoreJsonResponse;

  @override
  Future<void> dispose() => _isolate.dispose();
}
