import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/lifecycle/domain/deleted_record.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark.dart';
import 'package:flutter_test/flutter_test.dart';

/// One soft-deleted record as the deleted view lists it (UC-34, FR-LC-03).
void main() {
  final deletedAt = DateTime.utc(2026, 9, 1, 8);

  group('DeletedRecord.ofFile', () {
    test(
      'GivenADeletedFile_WhenItIsProjected_ThenItKeepsItsKindNameAndType',
      () {
        final record = DeletedRecord.ofFile(
          CatalogFile(
            uuid: 'f-1',
            name: 'talk.mkv',
            path: '/media/talk.mkv',
            type: FileType.video,
            isDeleted: true,
            deletedAt: deletedAt,
          ),
        );

        expect(record.uuid, 'f-1');
        expect(record.kind, DeletedRecordKind.file);
        expect(record.name, 'talk.mkv');
        expect(record.type, FileType.video);
        expect(record.deletedAt, deletedAt);
        expect(record.isDeleted, isTrue);
      },
    );

    test('GivenAFileRestoredSince_WhenItIsProjected_ThenItIsNotDeleted', () {
      // Carried from the core, not assumed from the listing it came out of.
      final record = DeletedRecord.ofFile(
        const CatalogFile(
          uuid: 'f-1',
          name: 'talk.mkv',
          path: '/media/talk.mkv',
          type: FileType.video,
        ),
      );

      expect(record.isDeleted, isFalse);
      expect(record.deletedAt, isNull);
    });
  });

  group('DeletedRecord.ofBookmark', () {
    test('GivenADeletedBookmark_WhenItIsProjected_ThenItIsNamedByItsTitle', () {
      final record = DeletedRecord.ofBookmark(
        Bookmark(
          uuid: 'b-1',
          url: 'https://example.com/',
          title: 'Example',
          isDeleted: true,
          deletedAt: deletedAt,
        ),
      );

      expect(record.uuid, 'b-1');
      expect(record.kind, DeletedRecordKind.bookmark);
      expect(record.name, 'Example');
      expect(record.type, isNull);
      expect(record.deletedAt, deletedAt);
      expect(record.isDeleted, isTrue);
    });
  });

  group('retentionAt', () {
    final record = DeletedRecord(
      uuid: 'f-1',
      kind: DeletedRecordKind.file,
      name: 'talk.mkv',
      deletedAt: deletedAt,
      isDeleted: true,
    );

    test(
      'GivenAKnownWindow_WhenTheStandingIsRead_ThenItCountsFromTheDeletion',
      () {
        final retention = record.retentionAt(
          deletedAt.add(const Duration(days: 10)),
          days: 30,
        );

        expect(retention.remaining, const Duration(days: 20));
      },
    );

    test('GivenAnUnreadWindow_WhenTheStandingIsRead_ThenItIsUnknown', () {
      expect(record.retentionAt(deletedAt, days: null).isKnown, isFalse);
    });
  });
}
