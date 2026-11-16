import 'package:alexandria_ui/features/catalog/data/file_view_parser.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one parse of the core's `FileView` row, shared by the listing and the
/// single-file read.
void main() {
  Map<String, dynamic> row([Map<String, dynamic> overrides = const {}]) => {
    'uuid': 'f-1',
    'name': 'talk.mkv',
    'path': '/media/talk.mkv',
    'fileType': 'video',
    'contentHash': 'abc',
    'sizeBytes': 2048,
    'mtime': '2026-08-01T10:00:00Z',
    'state': 'active',
    'indexedAt': '2026-08-02T10:00:00Z',
    ...overrides,
  };

  group('fileFromFileView', () {
    test('GivenACompleteRow_WhenItIsParsed_ThenEveryFieldIsRead', () {
      final file = fileFromFileView(
        row({
          'missingAt': '2026-08-03T10:00:00Z',
          'deletedAt': '2026-08-04T10:00:00Z',
        }),
      )!;

      expect(file.uuid, 'f-1');
      expect(file.name, 'talk.mkv');
      expect(file.path, '/media/talk.mkv');
      expect(file.type, FileType.video);
      expect(file.contentHash, 'abc');
      expect(file.sizeBytes, 2048);
      expect(file.mtime, DateTime.utc(2026, 8, 1, 10));
      expect(file.indexedAt, DateTime.utc(2026, 8, 2, 10));
      expect(file.missingAt, DateTime.utc(2026, 8, 3, 10));
      expect(file.deletedAt, DateTime.utc(2026, 8, 4, 10));
      expect(file.isMissing, isTrue);
    });

    test('GivenAnUnknownFileType_WhenItIsParsed_ThenTheRowIsDropped', () {
      expect(fileFromFileView(row({'fileType': 'audio'})), isNull);
    });

    test('GivenNoFileType_WhenItIsParsed_ThenTheRowIsDropped', () {
      expect(fileFromFileView(row({'fileType': null})), isNull);
    });

    test('GivenNoPathOrHash_WhenItIsParsed_ThenBothAreEmpty', () {
      final file = fileFromFileView(row({'path': null, 'contentHash': null}))!;

      expect(file.path, isEmpty);
      expect(file.contentHash, isEmpty);
    });

    test('GivenNoTimestampsOrSize_WhenItIsParsed_ThenEachIsNull', () {
      final file = fileFromFileView(
        row({'sizeBytes': null, 'mtime': null, 'indexedAt': null}),
      )!;

      expect(file.sizeBytes, isNull);
      expect(file.mtime, isNull);
      expect(file.indexedAt, isNull);
      expect(file.missingAt, isNull);
      expect(file.deletedAt, isNull);
      expect(file.isMissing, isFalse);
      expect(file.stamp.isReadable, isFalse);
    });

    test('GivenUnparseableTimestamps_WhenItIsParsed_ThenEachIsNull', () {
      // A malformed timestamp is "not known", not a reason to lose the row.
      final file = fileFromFileView(
        row({
          'mtime': 'yesterday',
          'indexedAt': 'soon',
          'missingAt': 'never',
          'deletedAt': '',
        }),
      )!;

      expect(file.mtime, isNull);
      expect(file.indexedAt, isNull);
      expect(file.missingAt, isNull);
      expect(file.deletedAt, isNull);
    });

    test('GivenAnMtimeThatIsNotAString_WhenItIsParsed_ThenItIsNull', () {
      final file = fileFromFileView(row({'mtime': 1754042400}))!;

      expect(file.mtime, isNull);
    });

    test('GivenTheDeletedState_WhenItIsParsed_ThenTheFileIsDeleted', () {
      expect(fileFromFileView(row({'state': 'deleted'}))!.isDeleted, isTrue);
    });

    test('GivenAnyOtherState_WhenItIsParsed_ThenTheFileIsNotDeleted', () {
      expect(fileFromFileView(row({'state': 'active'}))!.isDeleted, isFalse);
      expect(fileFromFileView(row({'state': null}))!.isDeleted, isFalse);
    });

    test('GivenASizeAndMtime_WhenItIsParsed_ThenTheStampCarriesBoth', () {
      final stamp = fileFromFileView(row())!.stamp;

      expect(stamp.sizeBytes, 2048);
      expect(stamp.mtime, DateTime.utc(2026, 8, 1, 10));
      expect(stamp.isReadable, isTrue);
    });
  });

  group('metadataFromFileView', () {
    test('GivenAMetadataObject_WhenItIsRead_ThenEachFieldIsAString', () {
      expect(
        metadataFromFileView(<String, dynamic>{
          'title': 'A talk',
          'year': 2026,
          'rating': 4.5,
        }),
        {'title': 'A talk', 'year': '2026', 'rating': '4.5'},
      );
    });

    test('GivenTheVariantTag_WhenItIsRead_ThenItIsLeftOut', () {
      expect(
        metadataFromFileView(<String, dynamic>{
          'type': 'video',
          'title': 'A talk',
        }),
        {'title': 'A talk'},
      );
    });

    test('GivenANullField_WhenItIsRead_ThenItIsLeftOut', () {
      expect(
        metadataFromFileView(<String, dynamic>{
          'title': 'A talk',
          'director': null,
        }),
        {'title': 'A talk'},
      );
    });

    test('GivenNoMetadata_WhenItIsRead_ThenTheFieldsAreEmpty', () {
      expect(metadataFromFileView(null), isEmpty);
    });

    test(
      'GivenMetadataThatIsNotAnObject_WhenItIsRead_ThenTheFieldsAreEmpty',
      () {
        expect(metadataFromFileView('title'), isEmpty);
        expect(metadataFromFileView(const ['title']), isEmpty);
      },
    );
  });
}
