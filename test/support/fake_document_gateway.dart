import 'package:alexandria_desktop/features/viewers/domain/document_gateway.dart';
import 'package:alexandria_desktop/features/viewers/domain/file_viewer.dart';
import 'package:alexandria_desktop/features/viewers/domain/reading_position_store.dart';

/// A [DocumentGateway] that never touches a disk (Testing Specification §2.3).
class FakeDocumentGateway implements DocumentGateway {
  /// Creates a gateway answering a two-chapter book.
  FakeDocumentGateway({DocumentOutcome? outcome})
    : outcome =
          outcome ??
          const DocumentIsBook(
            title: 'Solaris',
            chapters: [
              DocumentChapter(title: 'One', html: '<p>The first chapter.</p>'),
              DocumentChapter(title: 'Two', html: '<p>The second chapter.</p>'),
            ],
          );

  /// What [open] answers.
  DocumentOutcome outcome;

  /// Every path opened, in order.
  ///
  /// Empty is the assertion FR-VW-07 needs: nothing is read until the owner
  /// opens the file.
  final List<String> opened = [];

  @override
  Future<DocumentOutcome> open(String path) async {
    opened.add(path);
    return outcome;
  }

  /// What the gateway answers for a file that is not there (AF-01).
  static const DocumentOutcome missing = DocumentFailed(
    failure: ViewerFailure.missingOnDisk,
  );

  /// What it answers for bytes that are not the format claimed (AF-02).
  static const DocumentOutcome unreadable = DocumentFailed(
    failure: ViewerFailure.unreadable,
  );

  /// What it answers for a document nobody has the key to (AF-03).
  static const DocumentOutcome encrypted = DocumentFailed(
    failure: ViewerFailure.encrypted,
  );
}

/// A [ReadingPositionStore] held in memory (Testing Specification §2.3).
class FakeReadingPositionStore implements ReadingPositionStore {
  /// Creates a store holding [positions].
  FakeReadingPositionStore([Map<String, int>? positions])
    : _positions = {...?positions};

  final Map<String, int> _positions;

  /// Every position written, in order.
  final List<({String uuid, int position})> recorded = [];

  @override
  int? positionFor(String fileUuid) => _positions[fileUuid];

  @override
  Future<void> record(String fileUuid, int position) async {
    recorded.add((uuid: fileUuid, position: position));
    _positions[fileUuid] = position;
  }

  @override
  Future<void> forget(String fileUuid) async => _positions.remove(fileUuid);
}
