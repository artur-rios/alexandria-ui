import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/bindings/core_isolate.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';

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
    this.versionResult = '0.2.0',
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
    CoreJsonResponse? fileEditMetadataResult,
    this.failOnFileEditMetadata = false,
    int? pauseStatus,
    String? activeRunsJson,
    String? resumeRunId,
  }) : fileEditMetadataResult =
           fileEditMetadataResult ??
           (
             status: 0,
             // The FileMetadata body: the record, plus the metadata that was
             // just written.
             json:
                 '{"file":{"uuid":"6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f",'
                 '"name":"Kind of Blue.flac",'
                 '"path":"/home/owner/music/Kind of Blue.flac",'
                 '"fileType":"audio","state":"active"},'
                 '"metadata":{"type":"audio","title":"So What",'
                 '"artist":"Miles Davis","album":"Kind of Blue",'
                 '"year":1959,"genre":"Jazz","track":1}}',
           ),
       healthResult = healthResult ?? coreHealthyStatusCode,
       initializeResult = initializeResult ?? CoreStatusFamily.indexing.okCode,
       authLocalLoginResult =
           authLocalLoginResult ??
           (
             status: CoreStatusFamily.auth.okCode,
             json:
                 '{"success":true,'
                 '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50"}',
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
             // Each row is a FileView too, the same shape `fileByUuidResult`
             // answers: the core's listing route answers this now, not a bare
             // file record.
             json:
                 '[{"file":{"uuid":"6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f",'
                 '"name":"Kind of Blue.flac",'
                 '"path":"/home/owner/music/Kind of Blue.flac",'
                 '"fileType":"audio","state":"active"},'
                 '"metadata":{"type":"audio","artist":"Miles Davis",'
                 '"album":"Kind of Blue","year":1959}}]',
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
             json: '{"success":true,"email":"owner@example.com"}',
           ),
       authLocalRegisterResult =
           authLocalRegisterResult ??
           (
             status: CoreStatusFamily.auth.okCode,
             json:
                 '{"success":true,"email":"owner@example.com",'
                 '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50",'
                 // The ten codes the core mints at registration, returned on
                 // this call and never again (FR-AU-12). Two here: the count
                 // is the core's business, and a fake that insisted on ten
                 // would be asserting it.
                 '"recoveryCodes":["aaaa-bbbb","cccc-dddd"]}',
           ) {
    // Assigned in the body rather than the initializer list: these three
    // back mutable fields further down the class (set post-construction by
    // other tests), and giving them constructor shortcuts here is only for
    // the common case of a test that knows its answer up front.
    if (pauseStatus != null) indexPauseResult = pauseStatus;
    if (activeRunsJson != null) {
      indexRunsActiveResult = (status: 0, json: activeRunsJson);
    }
    if (resumeRunId != null) {
      indexResumeResult = (status: 0, runId: resumeRunId);
    }
  }

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
  ///
  /// Not final, unlike its siblings: `initialize` is the one call this
  /// application makes *twice* — once at startup and again when the owner
  /// changes the music-lookup preference — so a test needs a core that
  /// accepted the first and refuses the second.
  bool failOnInitialize;

  /// What [authLocalLogin] returns. Defaults to a successful login.
  final CoreJsonResponse authLocalLoginResult;

  /// Whether [authLocalLogin] throws instead of returning.
  final bool failOnAuthLocalLogin;

  /// The music-lookup configurations [initialize] was called with, in order —
  /// what the core would have been configured for (music enrichment design).
  final List<MusicLookup> musicLookupsInitializedWith = [];

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

  /// What [indexRefreshStart] was called with, in order.
  final List<({String token, String? priority})> indexRefreshStarts = [];

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

  /// What [fileEditMetadata] answers (UC-15).
  final CoreJsonResponse fileEditMetadataResult;

  /// Whether [fileEditMetadata] throws instead of answering.
  final bool failOnFileEditMetadata;

  /// What [fileEditMetadata] was called with, in order.
  ///
  /// The patch is kept as sent, because the shape of the body is part of the
  /// contract: the core reads the type tag off it to check the file's subtype.
  final List<({String uuid, String patch, String token})>
  fileEditMetadataCalls = [];

  /// What [filesList] was called with, in order.
  final List<({String filters, String token})> filesListCalls = [];

  /// What [indexStart] was called with, in order.
  ///
  /// The scope included, and kept as `String?` rather than flattened to a
  /// list: an absent scope and an empty one are different arguments to the
  /// core, and a test asserting "no scope was sent" has to be able to tell
  /// null from `''`.
  final List<({String root, String token, String? priority, String? types})>
  indexStarts = [];

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
  Future<int> initialize(
    String databasePath, {
    required MusicLookup musicLookup,
  }) async {
    if (failOnInitialize) throw const CoreCallException('init call failed');
    initializedWith.add(databasePath);
    musicLookupsInitializedWith.add(musicLookup);
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

  /// What reading the account answers (UC-42).
  CoreJsonResponse authLocalAccountResult = (
    status: AUTH_OK,
    json: '{"email":"owner@example.com","recoveryCodesRemaining":7}',
  );

  /// What regenerating the recovery codes answers (UC-42).
  CoreJsonResponse authLocalRegenerateRecoveryCodesResult = (
    status: AUTH_OK,
    json: '{"recoveryCodes":["new-aaaa","new-bbbb"]}',
  );

  @override
  Future<CoreJsonResponse> authLocalAccount(String token) async =>
      authLocalAccountResult;

  @override
  Future<CoreJsonResponse> authLocalRegenerateRecoveryCodes(
    String token,
  ) async => authLocalRegenerateRecoveryCodesResult;

  /// What a recovery redemption answers (UC-41). A success by default.
  CoreJsonResponse authLocalRedeemRecoveryCodeResult = (
    status: AUTH_OK,
    json:
        '{"success":true,"email":"owner@example.com",'
        '"recoveryCodesRemaining":9}',
  );

  /// Every redemption body sent, in order.
  final List<String> recoveryRedemptions = [];

  @override
  Future<CoreJsonResponse> authLocalRedeemRecoveryCode(String jsonBody) async {
    recoveryRedemptions.add(jsonBody);
    return authLocalRedeemRecoveryCodeResult;
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
  Future<CoreRunStart> indexStart(
    String root,
    String token, [
    String? priority,
    String? types,
  ]) async {
    if (failOnIndexStart) {
      throw const CoreCallException('index start call failed');
    }
    indexStarts.add((
      root: root,
      token: token,
      priority: priority,
      types: types,
    ));
    return indexStartResult;
  }

  /// What `indexRunFailures` answers, and every run it was asked about.
  ///
  /// Recorded because the call takes the run id and the token in that order
  /// — a transposition compiles and asks the core about a token.
  CoreJsonResponse runFailuresResponse = (status: RUN_OK, json: '[]');

  /// Every failures read asked for, in order.
  final List<({String runId, String token})> indexRunFailuresCalls = [];

  @override
  Future<CoreJsonResponse> indexRunFailures(String runId, String token) async {
    indexRunFailuresCalls.add((runId: runId, token: token));
    return runFailuresResponse;
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
  Future<CoreRunStart> indexRefreshStart(
    String token, [
    String? priority,
  ]) async {
    if (failOnIndexRefreshStart) {
      throw const CoreCallException('index refresh start call failed');
    }
    indexRefreshStarts.add((token: token, priority: priority));
    return indexRefreshStartResult;
  }

  /// What [indexPause] answers.
  int indexPauseResult = 0;

  /// Whether [indexPause] throws instead of answering.
  bool failOnIndexPause = false;

  /// What [indexCancel] answers.
  int indexCancelResult = 0;

  /// Whether [indexCancel] throws instead of answering.
  bool failOnIndexCancel = false;

  /// Every run id [indexPause] was called with, in order.
  final List<({String runId, String token})> indexPauses = [];

  /// Every run id [indexCancel] was called with, in order.
  final List<({String runId, String token})> indexCancels = [];

  @override
  Future<int> indexPause(String runId, String token) async {
    if (failOnIndexPause) {
      throw const CoreCallException('index pause call failed');
    }
    indexPauses.add((runId: runId, token: token));
    return indexPauseResult;
  }

  @override
  Future<int> indexCancel(String runId, String token) async {
    if (failOnIndexCancel) {
      throw const CoreCallException('index cancel call failed');
    }
    indexCancels.add((runId: runId, token: token));
    return indexCancelResult;
  }

  /// What [indexResume] answers. Defaults to resuming the same run
  /// [indexStartResult] mints, since a resume answers the id it was given.
  CoreRunStart? indexResumeResult;

  /// Whether [indexResume] throws instead of answering.
  bool failOnIndexResume = false;

  /// Every call [indexResume] received, in order — the priority included, so
  /// a test can assert a plain resume passed null rather than "normal".
  final List<({String runId, String? priority, String token})> indexResumes =
      [];

  @override
  Future<CoreRunStart> indexResume(
    String runId,
    String? priority,
    String token,
  ) async {
    if (failOnIndexResume) {
      throw const CoreCallException('index resume call failed');
    }
    indexResumes.add((runId: runId, priority: priority, token: token));
    return indexResumeResult ?? (status: 0, runId: runId);
  }

  /// What [indexRunsActive] answers. Empty by default: no outstanding runs is
  /// the normal case.
  CoreJsonResponse indexRunsActiveResult = (status: 0, json: '[]');

  /// Whether [indexRunsActive] throws instead of answering.
  ///
  /// A poll that cannot reach the core must not be mistaken for a core that
  /// answered "nothing running" — this is what lets a test of that distinction
  /// exist (Task 5: a failed poll keeps the runs the controller already knew
  /// about rather than reporting no work on no evidence).
  bool failOnIndexRunsActive = false;

  /// Every token [indexRunsActive] was called with, in order.
  final List<String> indexRunsActiveCalls = [];

  @override
  Future<CoreJsonResponse> indexRunsActive(String token) async {
    if (failOnIndexRunsActive) {
      throw const CoreCallException('index runs active call failed');
    }
    indexRunsActiveCalls.add(token);
    return indexRunsActiveResult;
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
  Future<CoreJsonResponse> fileEditMetadata(
    String uuid,
    String jsonPatch,
    String token,
  ) async {
    if (failOnFileEditMetadata) {
      throw const CoreCallException('metadata edit call failed');
    }
    fileEditMetadataCalls.add((uuid: uuid, patch: jsonPatch, token: token));
    return fileEditMetadataResult;
  }

  @override
  Future<void> dispose() async => disposeCount++;

  /// What [filePlaybackSource] answers (UC-19).
  CoreJsonResponse playbackSourceResponse = (
    status: PLAYBACK_OK,
    json: '{"uuid":"a-uuid","path":"/home/owner/videos/a.mkv"}',
  );

  @override
  Future<CoreJsonResponse> filePlaybackSource(
    String uuid,
    String token,
  ) async => playbackSourceResponse;

  /// What [bookmarksList] answers (UC-28).
  CoreJsonResponse bookmarksResponse = (status: BOOKMARK_OK, json: '[]');

  /// What [bookmarkCreate] and [bookmarkUpdate] answer (UC-28).
  CoreJsonResponse bookmarkWriteResponse = (status: BOOKMARK_OK, json: null);

  /// Every bookmark write asked for, in order.
  final List<({String? uuid, String body})> bookmarkWrites = [];

  @override
  Future<CoreJsonResponse> bookmarksList(
    String jsonFilters,
    String token,
  ) async => bookmarksResponse;

  /// Every record soft-deleted, in order (UC-33).
  final List<String> softDeleted = [];

  /// What a file soft-delete answers.
  CoreJsonResponse fileSoftDeleteResponse = (status: FILE_OK, json: null);

  /// What a bookmark soft-delete answers.
  CoreJsonResponse bookmarkSoftDeleteResponse = (
    status: BOOKMARK_OK,
    json: null,
  );

  /// Every record restored, in order (UC-34).
  final List<String> restored = [];

  /// What a file restore answers.
  CoreJsonResponse fileRestoreResponse = (status: FILE_OK, json: null);

  /// What a bookmark restore answers.
  CoreJsonResponse bookmarkRestoreResponse = (status: BOOKMARK_OK, json: null);

  /// Every record purged, in order (UC-35, UC-36).
  final List<String> purged = [];

  /// What a file purge answers.
  CoreJsonResponse filePurgeResponse = (status: FILE_OK, json: null);

  /// What a purge on disk answers.
  CoreJsonResponse filePurgeOnDiskResponse = (status: FILE_OK, json: null);

  /// What a bookmark purge answers.
  CoreJsonResponse bookmarkPurgeResponse = (status: BOOKMARK_OK, json: null);

  @override
  Future<CoreJsonResponse> filePurge(String uuid, String token) async {
    purged.add(uuid);
    return filePurgeResponse;
  }

  @override
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid, String token) async {
    purged.add(uuid);
    return filePurgeOnDiskResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkPurge(String uuid, String token) async {
    purged.add(uuid);
    return bookmarkPurgeResponse;
  }

  @override
  Future<CoreJsonResponse> fileRestore(String uuid, String token) async {
    restored.add(uuid);
    return fileRestoreResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkRestore(String uuid, String token) async {
    restored.add(uuid);
    return bookmarkRestoreResponse;
  }

  @override
  Future<CoreJsonResponse> fileSoftDelete(String uuid, String token) async {
    softDeleted.add(uuid);
    return fileSoftDeleteResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkSoftDelete(String uuid, String token) async {
    softDeleted.add(uuid);
    return bookmarkSoftDeleteResponse;
  }

  /// What listing the collections answers (UC-26).
  CoreJsonResponse collectionsListResult = (status: COLLECTION_OK, json: '[]');

  /// What a collection write answers (UC-26).
  CoreJsonResponse collectionWriteResult = (status: COLLECTION_OK, json: null);

  /// Every collection write asked for, in order.
  final List<({String? uuid, String? body})> collectionWrites = [];

  /// What listing a collection's members answers (UC-27).
  CoreJsonResponse collectionMembersResult = (
    status: COLLECTION_OK,
    json: '{"collectionUuid":"c-1","kind":"file","items":[]}',
  );

  @override
  Future<CoreJsonResponse> collectionListItems(
    String uuid,
    String token,
  ) async => collectionMembersResult;

  @override
  Future<CoreJsonResponse> collectionAddItems(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    collectionWrites.add((uuid: uuid, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionRemoveItem(
    String uuid,
    String itemUuid,
    String token,
  ) async {
    collectionWrites.add((uuid: uuid, body: itemUuid));
    return collectionWriteResult;
  }

  /// What the settings read answers (UC-34, core UC-47).
  CoreJsonResponse settingsResult = (
    status: SETTINGS_OK,
    json: '{"deletion":{"retentionDays":30}}',
  );

  @override
  Future<CoreJsonResponse> settings(String token) async => settingsResult;

  @override
  Future<CoreJsonResponse> collectionsList(
    String jsonFilters,
    String token,
  ) async => collectionsListResult;

  @override
  Future<CoreJsonResponse> collectionCreate(
    String jsonBody,
    String token,
  ) async {
    collectionWrites.add((uuid: null, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionRename(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    collectionWrites.add((uuid: uuid, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionDelete(String uuid, String token) async {
    collectionWrites.add((uuid: uuid, body: null));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> bookmarkCreate(String jsonBody, String token) async {
    bookmarkWrites.add((uuid: null, body: jsonBody));
    return bookmarkWriteResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkUpdate(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    bookmarkWrites.add((uuid: uuid, body: jsonBody));
    return bookmarkWriteResponse;
  }

  /// What [comicPage] answers (UC-23).
  CoreJsonResponse comicPageResponse = (status: PLAYBACK_OK, json: null);

  /// Every page asked for, in order.
  final List<({String uuid, int page})> comicPages = [];

  @override
  Future<CoreJsonResponse> comicPage(
    String uuid,
    int page,
    String token,
  ) async {
    comicPages.add((uuid: uuid, page: page));
    return comicPageResponse;
  }

  /// What [fileThumbnail] answers (UC-21, FR-PL-07).
  CoreJsonResponse thumbnailResponse = (status: PLAYBACK_OK, json: null);

  /// Raised by [fileThumbnail] instead of answering, when set.
  bool failOnFileThumbnail = false;

  @override
  Future<CoreJsonResponse> fileThumbnail(String uuid, String token) async {
    if (failOnFileThumbnail) {
      throw const CoreCallException('file thumbnail call failed');
    }
    return thumbnailResponse;
  }

  /// What [fileReadContent] answers (UC-18).
  CoreJsonResponse readContentResponse = (
    status: FILE_OK,
    json: '{"uuid":"a-uuid","content":""}',
  );

  /// What [fileEditContent] answers (UC-18).
  CoreJsonResponse editContentResponse = (status: FILE_OK, json: null);

  /// Every content write asked for, in order.
  final List<({String uuid, String body})> contentWrites = [];

  @override
  Future<CoreJsonResponse> fileReadContent(String uuid, String token) async =>
      readContentResponse;

  @override
  Future<CoreJsonResponse> fileEditContent(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    contentWrites.add((uuid: uuid, body: jsonBody));
    return editContentResponse;
  }

  /// What [fileRename] answers (UC-17).
  CoreJsonResponse renameResponse = (status: FILE_OK, json: null);

  /// Every rename asked for, in order.
  final List<({String uuid, String name})> renames = [];

  @override
  Future<CoreJsonResponse> fileRename(
    String uuid,
    String name,
    String token,
  ) async {
    renames.add((uuid: uuid, name: name));
    return renameResponse;
  }

  /// What every reading-list call answers (UC-31, UC-32).
  CoreJsonResponse readingListResponse = (status: READING_LIST_OK, json: '[]');

  @override
  Future<CoreJsonResponse> readingListsList(
    String jsonFilters,
    String token,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListCreate(
    String jsonBody,
    String token,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListDelete(String uuid, String token) async =>
      readingListResponse;

  @override
  Future<CoreJsonResponse> readingListAddItem(
    String uuid,
    String jsonBody,
    String token,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListRemoveItem(
    String uuid,
    String itemUuid,
    String token,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
    String token,
  ) async => readingListResponse;

  /// What every watchlist write answers (UC-29, UC-30).
  CoreJsonResponse watchlistWriteResponse = (status: WATCHLIST_OK, json: '{}');

  @override
  Future<CoreJsonResponse> watchlistCreate(
    String jsonBody,
    String token,
  ) async => watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistDelete(String uuid, String token) async =>
      watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistAddVideo(
    String uuid,
    String jsonBody,
    String token,
  ) async => watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistRemoveVideo(
    String uuid,
    String videoUuid,
    String token,
  ) async => watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
    String token,
  ) async => watchlistWriteResponse;

  /// What [watchlistsList] answers (UC-16 AF-03).
  ///
  /// An empty array by default: a library nobody has built a watchlist in
  /// records no episodes, so nothing warns.
  CoreJsonResponse watchlists = (status: WATCHLIST_OK, json: '[]');

  @override
  Future<CoreJsonResponse> watchlistsList(
    String jsonFilters,
    String token,
  ) async => watchlists;

  /// What every playlist call answers, unless a test wants a failure or a
  /// specific payload instead.
  CoreJsonResponse playlistResponse = (status: PLAYLIST_OK, json: '{}');

  /// What [playlistCreate] was called with, in order.
  final List<({String jsonBody, String token})> playlistCreateCalls = [];

  @override
  Future<CoreJsonResponse> playlistCreate(String jsonBody, String token) async {
    playlistCreateCalls.add((jsonBody: jsonBody, token: token));
    return playlistResponse;
  }

  /// What [playlistRename] was called with, in order.
  final List<({String uuid, String jsonBody, String token})>
  playlistRenameCalls = [];

  @override
  Future<CoreJsonResponse> playlistRename(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    playlistRenameCalls.add((uuid: uuid, jsonBody: jsonBody, token: token));
    return playlistResponse;
  }

  /// What [playlistDelete] was called with, in order.
  final List<({String uuid, String token})> playlistDeleteCalls = [];

  @override
  Future<CoreJsonResponse> playlistDelete(String uuid, String token) async {
    playlistDeleteCalls.add((uuid: uuid, token: token));
    return playlistResponse;
  }

  /// What [playlistsList] was called with, in order.
  final List<String> playlistsListCalls = [];

  @override
  Future<CoreJsonResponse> playlistsList(String token) async {
    playlistsListCalls.add(token);
    return playlistResponse;
  }

  /// What [playlistRead] was called with, in order.
  final List<({String uuid, String token})> playlistReadCalls = [];

  @override
  Future<CoreJsonResponse> playlistRead(String uuid, String token) async {
    playlistReadCalls.add((uuid: uuid, token: token));
    return playlistResponse;
  }

  /// What every library call answers, and what they were called with.
  ///
  /// The recorded arguments are the assertion that matters for
  /// `libraryBrowse`: it takes three consecutive strings, so a transposition
  /// compiles and answers an empty folder rather than failing.
  CoreJsonResponse libraryResponse = (status: LIBRARY_OK, json: '[]');

  /// Every library registration asked for, in order.
  final List<({String jsonBody, String token})> libraryRegisterCalls = [];

  /// Every tree read asked for, in order.
  final List<({String uuid, String path, String token})> libraryBrowseCalls =
      [];

  /// Every library removal asked for, in order.
  final List<({String uuid, String token})> libraryRemoveCalls = [];

  /// Every library move asked for, in order.
  ///
  /// Recorded like `libraryBrowse` above and for the same reason: three
  /// consecutive strings, so a transposition compiles and moves a library to
  /// a path spelled as a JSON body.
  final List<({String uuid, String jsonBody, String token})> libraryMoveCalls =
      [];

  @override
  Future<CoreJsonResponse> libraryRegister(
    String jsonBody,
    String token,
  ) async {
    libraryRegisterCalls.add((jsonBody: jsonBody, token: token));
    return libraryResponse;
  }

  @override
  Future<CoreJsonResponse> librariesList(String token) async => libraryResponse;

  @override
  Future<CoreJsonResponse> libraryBrowse(
    String uuid,
    String path,
    String token,
  ) async {
    libraryBrowseCalls.add((uuid: uuid, path: path, token: token));
    return libraryResponse;
  }

  @override
  Future<CoreJsonResponse> libraryMove(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    libraryMoveCalls.add((uuid: uuid, jsonBody: jsonBody, token: token));
    return libraryResponse;
  }

  @override
  Future<CoreJsonResponse> libraryRemove(String uuid, String token) async {
    libraryRemoveCalls.add((uuid: uuid, token: token));
    return libraryResponse;
  }

  /// What the two enrichment calls answer, and what they were called with.
  ///
  /// The recorded arguments are the assertion that matters for
  /// `enrichmentReadTrack`: it takes three consecutive strings, so a
  /// transposition compiles and misbehaves silently.
  CoreJsonResponse enrichmentResponse = (status: ENRICHMENT_OK, json: '{}');

  /// Every enrichment run asked for, in order.
  final List<({String scopeJson, String token})> enrichmentRunCalls = [];

  /// Every track read asked for, in order.
  final List<({String uuid, String artist, String token})>
  enrichmentReadCalls = [];

  @override
  Future<CoreJsonResponse> enrichmentRun(String scopeJson, String token) async {
    enrichmentRunCalls.add((scopeJson: scopeJson, token: token));
    return enrichmentResponse;
  }

  @override
  Future<CoreJsonResponse> enrichmentReadTrack(
    String uuid,
    String artist,
    String token,
  ) async {
    enrichmentReadCalls.add((uuid: uuid, artist: artist, token: token));
    return enrichmentResponse;
  }

  /// What [playlistAddEntries] was called with, in order.
  final List<({String uuid, String jsonBody, String token})>
  playlistAddEntriesCalls = [];

  @override
  Future<CoreJsonResponse> playlistAddEntries(
    String uuid,
    String jsonBody,
    String token,
  ) async {
    playlistAddEntriesCalls.add((uuid: uuid, jsonBody: jsonBody, token: token));
    return playlistResponse;
  }

  /// What [playlistRemoveEntry] was called with, in order.
  ///
  /// Kept as `entryUuid` rather than folded into a file uuid or an index: the
  /// entry is what the core addresses, and a playlist may hold the same track
  /// more than once.
  final List<({String uuid, String entryUuid, String token})>
  playlistRemoveEntryCalls = [];

  @override
  Future<CoreJsonResponse> playlistRemoveEntry(
    String uuid,
    String entryUuid,
    String token,
  ) async {
    playlistRemoveEntryCalls.add((
      uuid: uuid,
      entryUuid: entryUuid,
      token: token,
    ));
    return playlistResponse;
  }

  /// What [playlistMoveEntry] was called with, in order.
  final List<({String uuid, String entryUuid, String jsonBody, String token})>
  playlistMoveEntryCalls = [];

  @override
  Future<CoreJsonResponse> playlistMoveEntry(
    String uuid,
    String entryUuid,
    String jsonBody,
    String token,
  ) async {
    playlistMoveEntryCalls.add((
      uuid: uuid,
      entryUuid: entryUuid,
      jsonBody: jsonBody,
      token: token,
    ));
    return playlistResponse;
  }
}
