import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/reading_list.dart';
import '../domain/reading_list_gateway.dart';

/// [ReadingListGateway] over the core's reading-list calls (UC-31, UC-32).
///
/// The watchlist gateway's twin, and deliberately not shared with it: the two
/// are different core families with different status codes and different
/// payload shapes, and a generic one would have to be told which it was at
/// every call.
class CoreReadingListGateway implements ReadingListGateway {
  /// Wraps [_core].
  const CoreReadingListGateway(this._core);

  final CoreClient _core;

  @override
  Future<ReadingListBrowse> browse({required String credential}) async {
    final CoreJsonResponse response;
    try {
      // An empty filter is every reading list, which is what the screen shows.
      response = await _core.readingListsList('', credential);
    } on CoreCallException {
      return _unreadable();
    }

    if (!CoreStatusFamily.readingList.isOk(response.status)) {
      return ReadingListBrowse.failed(
        failure: mapCoreStatus(CoreStatusFamily.readingList, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return ReadingListBrowse.loaded(
        readingLists: [
          for (final row in rows) _listFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      return _unreadable();
    }
  }

  @override
  Future<ReadingListWrite> create({
    required String name,
    required String credential,
  }) => _write(
    () => _core.readingListCreate(jsonEncode({'name': name}), credential),
  );

  @override
  Future<ReadingListWrite> delete({
    required String uuid,
    required String credential,
  }) => _write(() => _core.readingListDelete(uuid, credential));

  @override
  Future<ReadingListWrite> addItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  }) => _write(
    () => _core.readingListAddItem(
      uuid,
      jsonEncode({'itemUuid': itemUuid}),
      credential,
    ),
  );

  @override
  Future<ReadingListWrite> removeItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  }) => _write(() => _core.readingListRemoveItem(uuid, itemUuid, credential));

  @override
  Future<ReadingListWrite> updateProgress({
    required String uuid,
    required String itemUuid,
    required ReadingState state,
    required String credential,
    int? currentIssue,
    int? totalIssues,
  }) => _write(
    () => _core.readingListUpdateProgress(
      uuid,
      itemUuid,
      jsonEncode({
        'state': state.wireName,
        // Left out rather than sent as null: an absent issue is a standalone
        // book's progress, and an explicit null would be this application
        // deciding to clear a series' count.
        'currentIssue': ?currentIssue,
        'totalIssues': ?totalIssues,
      }),
      credential,
    ),
  );

  Future<ReadingListWrite> _write(
    Future<CoreJsonResponse> Function() call,
  ) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return const ReadingListWrite.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.readingList,
          code: READING_LIST_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.readingList.isOk(response.status)) {
      return ReadingListWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.readingList, response.status),
      );
    }

    return const ReadingListWrite.done();
  }

  static ReadingList _listFrom(Map<String, dynamic> row) {
    final items = row['items'];

    return ReadingList(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      items: [
        if (items is List<dynamic>)
          for (final item in items)
            if (item is Map<String, dynamic>) ?_progressFrom(item),
      ],
    );
  }

  /// The progress [row] describes, or `null` when the core answers a state or
  /// a kind this application does not know.
  static ReadingProgress? _progressFrom(Map<String, dynamic> row) {
    final state = ReadingState.fromWireName(row['state'] as String?);
    final kind = ReadingTargetKind.fromWireName(row['targetKind'] as String?);
    if (state == null || kind == null) return null;

    return ReadingProgress(
      readingListUuid: row['readingListUuid'] as String,
      itemUuid: row['itemUuid'] as String,
      targetKind: kind,
      state: state,
      currentIssue: row['currentIssue'] as int?,
      totalIssues: row['totalIssues'] as int?,
    );
  }

  ReadingListBrowse _unreadable() => const ReadingListBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.readingList,
      code: READING_LIST_ERR_OTHER,
    ),
  );
}
