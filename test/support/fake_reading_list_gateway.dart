import 'package:alexandria_desktop/features/tracking/domain/reading_list.dart';
import 'package:alexandria_desktop/features/tracking/domain/reading_list_gateway.dart';

/// A [ReadingListGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeReadingListGateway implements ReadingListGateway {
  /// Creates a gateway holding [readingLists].
  FakeReadingListGateway({List<ReadingList>? readingLists})
    : readingLists = [...?readingLists];

  /// What a browse answers.
  final List<ReadingList> readingLists;

  /// What [browse] answers instead, when a test says so.
  ReadingListBrowse? browseOutcome;

  /// What the next write answers, in order.
  final List<ReadingListWrite> writeOutcomes = [];

  /// Every name created, in order.
  final List<String> created = [];

  /// Every reading list deleted, in order.
  final List<String> deleted = [];

  /// Every item added, in order.
  final List<({String list, String item})> added = [];

  /// Every item removed, in order.
  final List<({String list, String item})> removed = [];

  /// Every progress update, in order.
  final List<
    ({
      String list,
      String item,
      ReadingState state,
      int? currentIssue,
      int? totalIssues,
    })
  >
  progressUpdates = [];

  @override
  Future<ReadingListBrowse> browse({required String credential}) async =>
      browseOutcome ?? ReadingListBrowse.loaded(readingLists: readingLists);

  @override
  Future<ReadingListWrite> create({
    required String name,
    required String credential,
  }) async {
    created.add(name);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    readingLists.add(
      ReadingList(uuid: 'created-${readingLists.length}', name: name),
    );
    return const ReadingListWrite.done();
  }

  @override
  Future<ReadingListWrite> delete({
    required String uuid,
    required String credential,
  }) async {
    deleted.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    readingLists.removeWhere((list) => list.uuid == uuid);
    return const ReadingListWrite.done();
  }

  @override
  Future<ReadingListWrite> addItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  }) async {
    added.add((list: uuid, item: itemUuid));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (list) => list.copyWith(
        items: [
          ...list.items,
          ReadingProgress(
            readingListUuid: uuid,
            itemUuid: itemUuid,
            targetKind: ReadingTargetKind.document,
            state: ReadingState.pending,
          ),
        ],
      ),
    );
    return const ReadingListWrite.done();
  }

  @override
  Future<ReadingListWrite> removeItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  }) async {
    removed.add((list: uuid, item: itemUuid));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (list) => list.copyWith(
        items: [
          for (final item in list.items)
            if (item.itemUuid != itemUuid) item,
        ],
      ),
    );
    return const ReadingListWrite.done();
  }

  @override
  Future<ReadingListWrite> updateProgress({
    required String uuid,
    required String itemUuid,
    required ReadingState state,
    required String credential,
    int? currentIssue,
    int? totalIssues,
  }) async {
    progressUpdates.add((
      list: uuid,
      item: itemUuid,
      state: state,
      currentIssue: currentIssue,
      totalIssues: totalIssues,
    ));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (list) => list.copyWith(
        items: [
          for (final item in list.items)
            if (item.itemUuid == itemUuid)
              item.copyWith(
                state: state,
                currentIssue: currentIssue,
                totalIssues: totalIssues,
              )
            else
              item,
        ],
      ),
    );
    return const ReadingListWrite.done();
  }

  void _replace(String uuid, ReadingList Function(ReadingList) change) {
    final index = readingLists.indexWhere((list) => list.uuid == uuid);
    if (index >= 0) readingLists[index] = change(readingLists[index]);
  }
}
