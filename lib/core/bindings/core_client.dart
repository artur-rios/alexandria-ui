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

  /// Releases the worker isolate and the shared library.
  Future<void> dispose();
}

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
  Future<void> dispose() => _isolate.dispose();
}
