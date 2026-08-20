import 'package:alexandria_desktop/features/editing/domain/text_content_gateway.dart';

import 'fake_catalog_gateway.dart';

/// A [TextContentGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeTextContentGateway implements TextContentGateway {
  /// Creates a gateway whose files hold [content].
  FakeTextContentGateway({this.content = '# Notes\n\nSomething.'});

  /// What a read answers, unless [readOutcomes] says otherwise.
  String content;

  /// What [readContent] answers, in order. Falls back to [content].
  final List<TextContentRead> readOutcomes = [];

  /// What [writeContent] answers, in order.
  ///
  /// A list so a test can have the disk refuse once and accept the retry,
  /// which is what AF-03 leaves the owner able to do.
  final List<TextContentWrite> writeOutcomes = [];

  /// Every read asked for, in order.
  final List<String> reads = [];

  /// Every write asked for, in order.
  ///
  /// Empty is the assertion AF-01 needs: content that did not change is not
  /// written (FR-ME-08).
  final List<({String uuid, String content})> writes = [];

  @override
  Future<TextContentRead> readContent({
    required String uuid,
    required String credential,
  }) async {
    reads.add(uuid);

    if (readOutcomes.isNotEmpty) return readOutcomes.removeAt(0);

    return TextContentRead.loaded(content: content);
  }

  @override
  Future<TextContentWrite> writeContent({
    required String uuid,
    required String content,
    required String credential,
  }) async {
    writes.add((uuid: uuid, content: content));

    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    // Accepting means the file on disk now holds what was sent, and the
    // record carries a new hash for it — which is what the *next* AF-05 check
    // compares against.
    this.content = content;
    return TextContentWrite.written(
      file: aFile(
        uuid: uuid,
        name: 'Notes.md',
        contentHash: 'hash-of-${content.hashCode}',
      ),
    );
  }
}
