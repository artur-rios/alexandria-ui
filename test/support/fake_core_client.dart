import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/bindings/core_client.dart';
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
    this.versionResult = '0.7.0',
    int? healthResult,
    int? initializeResult,
    this.failOnVersion = false,
    this.failOnHealth = false,
    this.failOnInitialize = false,
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
                 '"name":"Deep Blue Sea.mkv",'
                 '"path":"/home/owner/films/Deep Blue Sea.mkv",'
                 '"fileType":"video","state":"active"},'
                 '"metadata":{"type":"video","title":"Deep Blue Sea",'
                 '"year":1999,"mediaKind":"movie"}}',
           ),
       healthResult = healthResult ?? coreHealthyStatusCode,
       initializeResult = initializeResult ?? CoreStatusFamily.indexing.okCode,
       fileByUuidResult =
           fileByUuidResult ??
           (
             status: 0,
             // The FileView body: the record, plus what only this call
             // answers.
             json:
                 '{"file":{"uuid":"6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f",'
                 '"name":"Deep Blue Sea.mkv",'
                 '"path":"/home/owner/films/Deep Blue Sea.mkv",'
                 '"fileType":"video","state":"active"},'
                 '"metadata":{"type":"video","title":"Deep Blue Sea",'
                 '"year":1999}}',
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
                 '"name":"Deep Blue Sea.mkv",'
                 '"path":"/home/owner/films/Deep Blue Sea.mkv",'
                 '"fileType":"video","state":"active"},'
                 '"metadata":{"type":"video","title":"Deep Blue Sea",'
                 '"year":1999}}]',
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
  final bool failOnInitialize;

  /// The database paths [initialize] was called with, in order.
  final List<String> initializedWith = [];

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
  final List<({String? priority})> indexRefreshStarts = [];

  /// What [filesList] answers (UC-11, UC-34, UC-37).
  final CoreJsonResponse filesListResult;

  /// Whether [filesList] throws instead of answering.
  final bool failOnFilesList;

  /// What [fileByUuid] answers (UC-13).
  final CoreJsonResponse fileByUuidResult;

  /// Whether [fileByUuid] throws instead of answering.
  final bool failOnFileByUuid;

  /// What [fileByUuid] was called with, in order.
  final List<({String uuid})> fileByUuidCalls = [];

  /// What [fileEditMetadata] answers (UC-15).
  final CoreJsonResponse fileEditMetadataResult;

  /// Whether [fileEditMetadata] throws instead of answering.
  final bool failOnFileEditMetadata;

  /// What [fileEditMetadata] was called with, in order.
  ///
  /// The patch is kept as sent, because the shape of the body is part of the
  /// contract: the core reads the type tag off it to check the file's subtype.
  final List<({String uuid, String patch})> fileEditMetadataCalls = [];

  /// What [filesList] was called with, in order.
  final List<({String filters})> filesListCalls = [];

  /// What [indexRunStatus] was called with, in order.
  final List<({String runId})> indexRunStatusCalls = [];

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

  /// What `indexRunFailures` answers.
  CoreJsonResponse runFailuresResponse = (status: RUN_OK, json: '[]');

  /// Every failures read asked for, in order.
  final List<({String runId})> indexRunFailuresCalls = [];

  @override
  Future<CoreJsonResponse> indexRunFailures(String runId) async {
    indexRunFailuresCalls.add((runId: runId));
    return runFailuresResponse;
  }

  @override
  Future<CoreJsonResponse> indexRunStatus(String runId) async {
    if (failOnIndexRunStatus) {
      throw const CoreCallException('index run status call failed');
    }
    indexRunStatusCalls.add((runId: runId));
    return indexRunStatusResult;
  }

  @override
  Future<CoreRunStart> indexRefreshStart([String? priority]) async {
    if (failOnIndexRefreshStart) {
      throw const CoreCallException('index refresh start call failed');
    }
    indexRefreshStarts.add((priority: priority));
    return indexRefreshStartResult;
  }

  /// What [libraryIndexStart] answers.
  CoreRunStart libraryIndexStartResult = (status: 0, runId: 'library-run-1');

  /// What [libraryIndexStart] was called with, in order.
  final List<({String uuid, String? priority})> libraryIndexStarts = [];

  @override
  Future<CoreRunStart> libraryIndexStart(
    String uuid, [
    String? priority,
  ]) async {
    libraryIndexStarts.add((uuid: uuid, priority: priority));
    return libraryIndexStartResult;
  }

  /// What [fileThumbnail] answers. No picture by default.
  CoreJsonResponse fileThumbnailResult = (
    status: PLAYBACK_ERR_NOT_FOUND,
    json: null,
  );

  /// What [fileThumbnail] was called with, in order.
  final List<({String uuid})> fileThumbnailCalls = [];

  @override
  Future<CoreJsonResponse> fileThumbnail(String uuid) async {
    fileThumbnailCalls.add((uuid: uuid));
    return fileThumbnailResult;
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
  final List<({String runId})> indexPauses = [];

  /// Every run id [indexCancel] was called with, in order.
  final List<({String runId})> indexCancels = [];

  @override
  Future<int> indexPause(String runId) async {
    if (failOnIndexPause) {
      throw const CoreCallException('index pause call failed');
    }
    indexPauses.add((runId: runId));
    return indexPauseResult;
  }

  @override
  Future<int> indexCancel(String runId) async {
    if (failOnIndexCancel) {
      throw const CoreCallException('index cancel call failed');
    }
    indexCancels.add((runId: runId));
    return indexCancelResult;
  }

  /// What [indexResume] answers. Defaults to resuming the same run
  /// [indexStartResult] mints, since a resume answers the id it was given.
  CoreRunStart? indexResumeResult;

  /// Whether [indexResume] throws instead of answering.
  bool failOnIndexResume = false;

  /// Every call [indexResume] received, in order — the priority included, so
  /// a test can assert a plain resume passed null rather than "normal".
  final List<({String runId, String? priority})> indexResumes = [];

  @override
  Future<CoreRunStart> indexResume(String runId, String? priority) async {
    if (failOnIndexResume) {
      throw const CoreCallException('index resume call failed');
    }
    indexResumes.add((runId: runId, priority: priority));
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

  @override
  Future<CoreJsonResponse> indexRunsActive() async {
    if (failOnIndexRunsActive) {
      throw const CoreCallException('index runs active call failed');
    }
    return indexRunsActiveResult;
  }

  @override
  Future<int> indexCountFiles() async => countFilesResult;

  @override
  Future<CoreJsonResponse> filesList(String jsonFilters) async {
    if (failOnFilesList) {
      throw const CoreCallException('files list call failed');
    }
    filesListCalls.add((filters: jsonFilters));
    return filesListResult;
  }

  @override
  Future<CoreJsonResponse> fileByUuid(String uuid) async {
    if (failOnFileByUuid) {
      throw const CoreCallException('file get call failed');
    }
    fileByUuidCalls.add((uuid: uuid));
    return fileByUuidResult;
  }

  @override
  Future<CoreJsonResponse> fileEditMetadata(
    String uuid,
    String jsonPatch,
  ) async {
    if (failOnFileEditMetadata) {
      throw const CoreCallException('metadata edit call failed');
    }
    fileEditMetadataCalls.add((uuid: uuid, patch: jsonPatch));
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
  Future<CoreJsonResponse> filePlaybackSource(String uuid) async =>
      playbackSourceResponse;

  /// What [bookmarksList] answers (UC-28).
  CoreJsonResponse bookmarksResponse = (status: BOOKMARK_OK, json: '[]');

  /// What [bookmarkCreate] and [bookmarkUpdate] answer (UC-28).
  CoreJsonResponse bookmarkWriteResponse = (status: BOOKMARK_OK, json: null);

  /// Every bookmark write asked for, in order.
  final List<({String? uuid, String body})> bookmarkWrites = [];

  @override
  Future<CoreJsonResponse> bookmarksList(String jsonFilters) async =>
      bookmarksResponse;

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
  Future<CoreJsonResponse> filePurge(String uuid) async {
    purged.add(uuid);
    return filePurgeResponse;
  }

  @override
  Future<CoreJsonResponse> filePurgeOnDisk(String uuid) async {
    purged.add(uuid);
    return filePurgeOnDiskResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkPurge(String uuid) async {
    purged.add(uuid);
    return bookmarkPurgeResponse;
  }

  @override
  Future<CoreJsonResponse> fileRestore(String uuid) async {
    restored.add(uuid);
    return fileRestoreResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkRestore(String uuid) async {
    restored.add(uuid);
    return bookmarkRestoreResponse;
  }

  @override
  Future<CoreJsonResponse> fileSoftDelete(String uuid) async {
    softDeleted.add(uuid);
    return fileSoftDeleteResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkSoftDelete(String uuid) async {
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
  Future<CoreJsonResponse> collectionListItems(String uuid) async =>
      collectionMembersResult;

  @override
  Future<CoreJsonResponse> collectionAddItems(
    String uuid,
    String jsonBody,
  ) async {
    collectionWrites.add((uuid: uuid, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionRemoveItem(
    String uuid,
    String itemUuid,
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
  Future<CoreJsonResponse> settings() async => settingsResult;

  @override
  Future<CoreJsonResponse> collectionsList(String jsonFilters) async =>
      collectionsListResult;

  @override
  Future<CoreJsonResponse> collectionCreate(String jsonBody) async {
    collectionWrites.add((uuid: null, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionRename(
    String uuid,
    String jsonBody,
  ) async {
    collectionWrites.add((uuid: uuid, body: jsonBody));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> collectionDelete(String uuid) async {
    collectionWrites.add((uuid: uuid, body: null));
    return collectionWriteResult;
  }

  @override
  Future<CoreJsonResponse> bookmarkCreate(String jsonBody) async {
    bookmarkWrites.add((uuid: null, body: jsonBody));
    return bookmarkWriteResponse;
  }

  @override
  Future<CoreJsonResponse> bookmarkUpdate(String uuid, String jsonBody) async {
    bookmarkWrites.add((uuid: uuid, body: jsonBody));
    return bookmarkWriteResponse;
  }

  /// What [comicPage] answers (UC-23).
  CoreJsonResponse comicPageResponse = (status: PLAYBACK_OK, json: null);

  /// Every page asked for, in order.
  final List<({String uuid, int page})> comicPages = [];

  @override
  Future<CoreJsonResponse> comicPage(String uuid, int page) async {
    comicPages.add((uuid: uuid, page: page));
    return comicPageResponse;
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
  Future<CoreJsonResponse> fileReadContent(String uuid) async =>
      readContentResponse;

  @override
  Future<CoreJsonResponse> fileEditContent(String uuid, String jsonBody) async {
    contentWrites.add((uuid: uuid, body: jsonBody));
    return editContentResponse;
  }

  /// What [fileRename] answers (UC-17).
  CoreJsonResponse renameResponse = (status: FILE_OK, json: null);

  /// Every rename asked for, in order.
  final List<({String uuid, String name})> renames = [];

  @override
  Future<CoreJsonResponse> fileRename(String uuid, String name) async {
    renames.add((uuid: uuid, name: name));
    return renameResponse;
  }

  /// What every reading-list call answers (UC-31, UC-32).
  CoreJsonResponse readingListResponse = (status: READING_LIST_OK, json: '[]');

  @override
  Future<CoreJsonResponse> readingListsList(String jsonFilters) async =>
      readingListResponse;

  @override
  Future<CoreJsonResponse> readingListCreate(String jsonBody) async =>
      readingListResponse;

  @override
  Future<CoreJsonResponse> readingListDelete(String uuid) async =>
      readingListResponse;

  @override
  Future<CoreJsonResponse> readingListAddItem(
    String uuid,
    String jsonBody,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListRemoveItem(
    String uuid,
    String itemUuid,
  ) async => readingListResponse;

  @override
  Future<CoreJsonResponse> readingListUpdateProgress(
    String uuid,
    String itemUuid,
    String jsonBody,
  ) async => readingListResponse;

  /// What every watchlist write answers (UC-29, UC-30).
  CoreJsonResponse watchlistWriteResponse = (status: WATCHLIST_OK, json: '{}');

  @override
  Future<CoreJsonResponse> watchlistCreate(String jsonBody) async =>
      watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistDelete(String uuid) async =>
      watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistAddVideo(
    String uuid,
    String jsonBody,
  ) async => watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistRemoveVideo(
    String uuid,
    String videoUuid,
  ) async => watchlistWriteResponse;

  @override
  Future<CoreJsonResponse> watchlistUpdateProgress(
    String uuid,
    String videoUuid,
    String jsonBody,
  ) async => watchlistWriteResponse;

  /// What [watchlistsList] answers (UC-16 AF-03).
  ///
  /// An empty array by default: a library nobody has built a watchlist in
  /// records no episodes, so nothing warns.
  CoreJsonResponse watchlists = (status: WATCHLIST_OK, json: '[]');

  @override
  Future<CoreJsonResponse> watchlistsList(String jsonFilters) async =>
      watchlists;

  /// What every library call answers, and what they were called with.
  ///
  /// The recorded arguments are the assertion that matters for
  /// `libraryBrowse`: it takes three consecutive strings, so a transposition
  /// compiles and answers an empty folder rather than failing.
  CoreJsonResponse libraryResponse = (status: LIBRARY_OK, json: '[]');

  /// Every library registration asked for, in order.
  final List<({String jsonBody})> libraryRegisterCalls = [];

  /// Every tree read asked for, in order.
  final List<({String uuid, String path})> libraryBrowseCalls = [];

  /// Every library removal asked for, in order.
  final List<({String uuid})> libraryRemoveCalls = [];

  /// What [libraryRemove] answers, when it should differ from
  /// [libraryResponse].
  ///
  /// Its own field because a removal is read after a list: a removal the core
  /// refuses has to follow a list it answered, and one shared response cannot
  /// be both.
  CoreJsonResponse? libraryRemoveResponse;

  /// Every library move asked for, in order.
  ///
  /// Recorded like `libraryBrowse` above and for the same reason: three
  /// consecutive strings, so a transposition compiles and moves a library to
  /// a path spelled as a JSON body.
  final List<({String uuid, String jsonBody})> libraryMoveCalls = [];

  @override
  Future<CoreJsonResponse> libraryRegister(String jsonBody) async {
    libraryRegisterCalls.add((jsonBody: jsonBody));
    return libraryResponse;
  }

  @override
  Future<CoreJsonResponse> librariesList() async => libraryResponse;

  @override
  Future<CoreJsonResponse> libraryBrowse(String uuid, String path) async {
    libraryBrowseCalls.add((uuid: uuid, path: path));
    return libraryResponse;
  }

  @override
  Future<CoreJsonResponse> libraryMove(String uuid, String jsonBody) async {
    libraryMoveCalls.add((uuid: uuid, jsonBody: jsonBody));
    return libraryResponse;
  }

  /// What [libraryRename] answers.
  CoreJsonResponse libraryRenameResponse = (status: LIBRARY_OK, json: '{}');

  /// Every library rename asked for, in order.
  ///
  /// Recorded like `libraryMove` above and for the same reason: two
  /// consecutive strings, so a transposition compiles and renames a library
  /// called by its uuid.
  final List<({String uuid, String jsonBody})> libraryRenameCalls = [];

  @override
  Future<CoreJsonResponse> libraryRename(String uuid, String jsonBody) async {
    libraryRenameCalls.add((uuid: uuid, jsonBody: jsonBody));
    return libraryRenameResponse;
  }

  /// What [librarySetPinned] answers.
  int librarySetPinnedResult = LIBRARY_OK;

  /// Every pin change asked for, in order.
  final List<({String uuid, bool pinned})> librarySetPinnedCalls = [];

  @override
  Future<int> librarySetPinned(String uuid, bool pinned) async {
    librarySetPinnedCalls.add((uuid: uuid, pinned: pinned));
    return librarySetPinnedResult;
  }

  /// What [librarySetFavorite] answers.
  int librarySetFavoriteResult = LIBRARY_OK;

  /// Every favorite change asked for, in order.
  final List<({String uuid, bool favorite})> librarySetFavoriteCalls = [];

  @override
  Future<int> librarySetFavorite(String uuid, bool favorite) async {
    librarySetFavoriteCalls.add((uuid: uuid, favorite: favorite));
    return librarySetFavoriteResult;
  }

  /// What [catalogStats] answers: an empty catalog by default, every type
  /// present and zero, as the core answers one.
  CoreJsonResponse catalogStatsResponse = (
    status: LIBRARY_OK,
    json:
        '{"libraries":0,"filesByType":{"video":0,"audio":0,"document":0,'
        '"comic":0,"text":0,"html":0,"image":0}}',
  );

  /// How many times [catalogStats] was asked.
  int catalogStatsCalls = 0;

  @override
  Future<CoreJsonResponse> catalogStats() async {
    catalogStatsCalls++;
    return catalogStatsResponse;
  }

  @override
  Future<CoreJsonResponse> libraryRemove(String uuid) async {
    libraryRemoveCalls.add((uuid: uuid));
    return libraryRemoveResponse ?? libraryResponse;
  }
}
