import 'package:alexandria_desktop/core/bindings/core_client.dart';
import 'package:alexandria_desktop/core/bindings/core_isolate.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';

/// A [CoreClient] that never loads a native library (Testing Specification §2.3
/// and §6.2).
///
/// A hand-written fake rather than a `mocktail` stub because startup spans
/// several calls in a fixed order, and the Testing Specification prefers a fake
/// wherever the interaction spans more than one call: a fake that misbehaves
/// fails loudly, while a mis-stubbed mock passes quietly.
class FakeCoreClient implements CoreClient {
  /// Creates a fake reporting a healthy, supported core by default.
  FakeCoreClient({
    this.versionResult = '0.1.0',
    int? healthResult,
    int? initializeResult,
    this.failOnVersion = false,
    this.failOnHealth = false,
    this.failOnInitialize = false,
    CoreJsonResponse? authLocalLoginResult,
    this.failOnAuthLocalLogin = false,
    CoreJsonResponse? authLocalRegisterResult,
    this.failOnAuthLocalRegister = false,
    CoreJsonResponse? authLocalSetCredentialsResult,
    this.failOnAuthLocalSetCredentials = false,
    CoreRunStart? indexStartResult,
    this.failOnIndexStart = false,
    CoreJsonResponse? indexRunStatusResult,
    this.failOnIndexRunStatus = false,
    CoreRunStart? indexRefreshStartResult,
    this.failOnIndexRefreshStart = false,
    this.countFilesResult = 120,
    CoreJsonResponse? filesListResult,
    this.failOnFilesList = false,
    CoreJsonResponse? fileByUuidResult,
    this.failOnFileByUuid = false,
  }) : healthResult = healthResult ?? coreHealthyStatusCode,
       initializeResult = initializeResult ?? CoreStatusFamily.indexing.okCode,
       authLocalLoginResult =
           authLocalLoginResult ??
           (
             status: CoreStatusFamily.auth.okCode,
             json:
                 '{"success":true,'
                 '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50",'
                 // A confirmed account: the steady state a returning owner
                 // logs in to. Registration's fake below is the unconfirmed
                 // one, which is what the core answers there.
                 '"emailConfirmed":true}',
           ),
       indexStartResult =
           indexStartResult ??
           (status: 0, runId: '3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b'),
       fileByUuidResult =
           fileByUuidResult ??
           (
             status: 0,
             // The FileView body: the record, plus what only this call
             // answers.
             json:
                 '{"file":{"uuid":"6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f",'
                 '"name":"Kind of Blue.flac",'
                 '"path":"/home/owner/music/Kind of Blue.flac",'
                 '"fileType":"audio","state":"active"},'
                 '"metadata":{"type":"audio","artist":"Miles Davis",'
                 '"album":"Kind of Blue","year":1959}}',
           ),
       filesListResult =
           filesListResult ??
           (
             status: 0,
             json:
                 '[{"uuid":"6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f",'
                 '"name":"Kind of Blue.flac",'
                 '"path":"/home/owner/music/Kind of Blue.flac",'
                 '"fileType":"audio","state":"active"}]',
           ),
       indexRefreshStartResult =
           indexRefreshStartResult ??
           (status: 0, runId: '8c2d0e51-77af-4b93-8a10-2f6c4d9b1e37'),
       indexRunStatusResult =
           indexRunStatusResult ??
           (
             status: 0,
             // A finished index run, in the shape the core's CatalogRun body
             // takes: the counts are flattened into it and the index kind
             // carries scanned/indexed/skipped/failed.
             json:
                 '{"runId":"3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b",'
                 '"kind":"index","status":"complete",'
                 '"root":"/home/owner/music",'
                 '"startedAt":"2026-08-19T10:30:00Z",'
                 '"finishedAt":"2026-08-19T10:31:00Z",'
                 '"scanned":120,"indexed":118,"skipped":2,"failed":0}',
           ),
       authLocalSetCredentialsResult =
           authLocalSetCredentialsResult ??
           (
             status: CoreStatusFamily.auth.okCode,
             // The core answers with the account body. UC-04 reads nothing
             // from it, so the shape here is only what the real core sends.
             json: '{"email":"owner@example.com","emailConfirmed":true}',
           ),
       authLocalRegisterResult =
           authLocalRegisterResult ??
           (
             status: CoreStatusFamily.auth.okCode,
             json:
                 '{"success":true,"email":"owner@example.com",'
                 '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50",'
                 // What the real core answers today: the account is created
                 // unconfirmed, and nothing delivers the message.
                 '"emailConfirmed":false,"confirmationSent":false,'
                 '"confirmationError":"mail_not_configured"}',
           );

  /// What [version] returns.
  final String? versionResult;

  /// What [healthStatus] returns.
  final int healthResult;

  /// What [initialize] returns.
  final int initializeResult;

  /// Whether [version] throws instead of returning.
  final bool failOnVersion;

  /// Whether [healthStatus] throws instead of returning.
  final bool failOnHealth;

  /// Whether [initialize] throws instead of returning.
  final bool failOnInitialize;

  /// What [authLocalLogin] returns. Defaults to a successful login.
  final CoreJsonResponse authLocalLoginResult;

  /// Whether [authLocalLogin] throws instead of returning.
  final bool failOnAuthLocalLogin;

  /// The database paths [initialize] was called with, in order.
  final List<String> initializedWith = [];

  /// What [authLocalRegister] returns. Defaults to a created account.
  final CoreJsonResponse authLocalRegisterResult;

  /// Whether [authLocalRegister] throws instead of returning.
  final bool failOnAuthLocalRegister;

  /// What [authLocalSetCredentials] answers (UC-04).
  final CoreJsonResponse authLocalSetCredentialsResult;

  /// Whether [authLocalSetCredentials] throws instead of answering.
  final bool failOnAuthLocalSetCredentials;

  /// The JSON bodies [authLocalRegister] was called with, in order.
  final List<String> authLocalRegisterBodies = [];

  /// The JSON bodies [authLocalLogin] was called with, in order.
  ///
  /// Recorded so a test can assert that the core was *not* called when local
  /// validation already rejected the input (Testing Specification §6.3).
  final List<String> authLocalLoginBodies = [];

  /// What [authLocalSetCredentials] was called with, in order.
  ///
  /// Empty is the assertion that matters for UC-04 AF-01: local validation
  /// failures never reach the core.
  final List<({String jsonBody, String token})> authLocalSetCredentialsCalls =
      [];

  /// What [indexStart] answers (UC-06).
  final CoreRunStart indexStartResult;

  /// Whether [indexStart] throws instead of answering.
  final bool failOnIndexStart;

  /// What [indexRunStatus] answers (UC-06).
  final CoreJsonResponse indexRunStatusResult;

  /// Whether [indexRunStatus] throws instead of answering.
  final bool failOnIndexRunStatus;

  /// What [indexRefreshStart] answers (UC-07).
  final CoreRunStart indexRefreshStartResult;

  /// Whether [indexRefreshStart] throws instead of answering.
  final bool failOnIndexRefreshStart;

  /// How many files [indexCountFiles] reports (UC-07 AF-02).
  final int countFilesResult;

  /// The tokens [indexRefreshStart] was called with, in order.
  final List<String> indexRefreshStarts = [];

  /// What [filesList] answers (UC-09).
  final CoreJsonResponse filesListResult;

  /// Whether [filesList] throws instead of answering.
  final bool failOnFilesList;

  /// What [fileByUuid] answers (UC-13).
  final CoreJsonResponse fileByUuidResult;

  /// Whether [fileByUuid] throws instead of answering.
  final bool failOnFileByUuid;

  /// What [fileByUuid] was called with, in order.
  final List<({String uuid, String token})> fileByUuidCalls = [];

  /// What [filesList] was called with, in order.
  final List<({String filters, String token})> filesListCalls = [];

  /// What [indexStart] was called with, in order.
  final List<({String root, String token})> indexStarts = [];

  /// What [indexRunStatus] was called with, in order.
  final List<({String runId, String token})> indexRunStatusCalls = [];

  /// How many times [dispose] was called.
  int disposeCount = 0;

  @override
  Future<String?> version() async {
    if (failOnVersion) throw const CoreCallException('version call failed');
    return versionResult;
  }

  @override
  Future<int> healthStatus() async {
    if (failOnHealth) throw const CoreCallException('health call failed');
    return healthResult;
  }

  @override
  Future<int> initialize(String databasePath) async {
    if (failOnInitialize) throw const CoreCallException('init call failed');
    initializedWith.add(databasePath);
    return initializeResult;
  }

  @override
  Future<CoreJsonResponse> authLocalLogin(String jsonBody) async {
    if (failOnAuthLocalLogin) {
      throw const CoreCallException('auth local login call failed');
    }
    authLocalLoginBodies.add(jsonBody);
    return authLocalLoginResult;
  }

  @override
  Future<CoreJsonResponse> authLocalRegister(String jsonBody) async {
    if (failOnAuthLocalRegister) {
      throw const CoreCallException('auth local register call failed');
    }
    authLocalRegisterBodies.add(jsonBody);
    return authLocalRegisterResult;
  }

  @override
  Future<CoreJsonResponse> authLocalSetCredentials(
    String jsonBody,
    String token,
  ) async {
    if (failOnAuthLocalSetCredentials) {
      throw const CoreCallException('auth local set-credentials call failed');
    }
    // Both are recorded: the body so a test can assert what was sent, and the
    // token so it can assert the call was authorized with the active session
    // rather than with nothing (UC-04 main flow step 4).
    authLocalSetCredentialsCalls.add((jsonBody: jsonBody, token: token));
    return authLocalSetCredentialsResult;
  }

  @override
  Future<CoreRunStart> indexStart(String root, String token) async {
    if (failOnIndexStart) {
      throw const CoreCallException('index start call failed');
    }
    indexStarts.add((root: root, token: token));
    return indexStartResult;
  }

  @override
  Future<CoreJsonResponse> indexRunStatus(String runId, String token) async {
    if (failOnIndexRunStatus) {
      throw const CoreCallException('index run status call failed');
    }
    indexRunStatusCalls.add((runId: runId, token: token));
    return indexRunStatusResult;
  }

  @override
  Future<CoreRunStart> indexRefreshStart(String token) async {
    if (failOnIndexRefreshStart) {
      throw const CoreCallException('index refresh start call failed');
    }
    indexRefreshStarts.add(token);
    return indexRefreshStartResult;
  }

  @override
  Future<int> indexCountFiles() async => countFilesResult;

  @override
  Future<CoreJsonResponse> filesList(String jsonFilters, String token) async {
    if (failOnFilesList) {
      throw const CoreCallException('files list call failed');
    }
    filesListCalls.add((filters: jsonFilters, token: token));
    return filesListResult;
  }

  @override
  Future<CoreJsonResponse> fileByUuid(String uuid, String token) async {
    if (failOnFileByUuid) {
      throw const CoreCallException('file get call failed');
    }
    fileByUuidCalls.add((uuid: uuid, token: token));
    return fileByUuidResult;
  }

  @override
  Future<void> dispose() async => disposeCount++;
}
