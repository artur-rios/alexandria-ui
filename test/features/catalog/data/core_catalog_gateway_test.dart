import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Parsing what the core answers for a listing (UC-09, FR-CT-05).
///
/// The core's listing route answers the same `FileView` record the single-
/// file call does — this is what proves the listing reuses that parse rather
/// than a second one of its own.
void main() {
  test(
    'GivenAFileViewRow_WhenTheListingIsRead_ThenItCarriesTheMetadataToo',
    () async {
      final core = FakeCoreClient(
        filesListResult: (
          status: 0,
          json:
              '[{"file":{"uuid":"1","name":"Kind of Blue.flac",'
              '"path":"/music/Kind of Blue.flac","fileType":"audio",'
              '"state":"active"},'
              '"metadata":{"type":"audio","title":"So What",'
              '"artist":"Miles Davis"}}]',
        ),
      );
      final gateway = CoreCatalogGateway(core);

      final listing = await gateway.listFiles(
        type: FileType.audio,
        credential: 'token',
      );

      expect(listing, isA<CatalogListingLoaded>());
      final row = (listing as CatalogListingLoaded).files.single;
      expect(row.file.uuid, '1');
      expect(row.metadata['title'], 'So What');
      expect(row.metadata['artist'], 'Miles Davis');
    },
  );

  test(
    'GivenARowWithNoFileObject_WhenTheListingIsRead_ThenItIsUnreadable',
    () async {
      // A malformed row must not throw past this gateway — every other
      // payload path in it answers `unreadable` instead, and the listing does
      // the same rather than crashing the caller.
      final core = FakeCoreClient(
        filesListResult: (status: 0, json: '[{"notAFile":true}]'),
      );
      final gateway = CoreCatalogGateway(core);

      final listing = await gateway.listFiles(
        type: FileType.audio,
        credential: 'token',
      );

      expect(listing, isA<CatalogListingFailed>());
    },
  );

  test(
    'GivenAFileOfAnUnknownType_WhenTheListingIsRead_ThenItIsDroppedNotFailed',
    () async {
      // A row this application does not recognize is left out of the listing
      // rather than making the whole listing unreadable (mirrors
      // `fileFromFileView` for a single row).
      final core = FakeCoreClient(
        filesListResult: (
          status: 0,
          json:
              '[{"file":{"uuid":"1","name":"a","path":"/a",'
              '"fileType":"somethingNew","state":"active"},'
              '"metadata":null}]',
        ),
      );
      final gateway = CoreCatalogGateway(core);

      final listing = await gateway.listFiles(
        type: FileType.audio,
        credential: 'token',
      );

      expect(listing, isA<CatalogListingLoaded>());
      expect((listing as CatalogListingLoaded).files, isEmpty);
    },
  );
  // Reading a file's embedded picture through `alexandria_file_thumbnail`
  // (UC-21, FR-PL-07) — the core answers `{uuid, mimeType, bytesBase64}`,
  // confirmed against `alexandria-ffi/src/lib.rs`'s own doc comment on
  // `alexandria_file_thumbnail` (not the `bytes` the task brief paraphrased
  // it as): the key actually on the wire is `bytesBase64`, matching
  // `alexandria_comic_page`'s convention.
  group('fileThumbnail', () {
    test(
      'GivenAPictureTheCoreAnswers_WhenReadingTheThumbnail_ThenItDecodesTheBytes',
      () async {
        final core = FakeCoreClient()
          ..thumbnailResponse = (
            status: PLAYBACK_OK,
            json:
                '{"uuid":"1","mimeType":"image/png","bytesBase64":"aGVsbG8="}',
          );
        final gateway = CoreCatalogGateway(core);

        final outcome = await gateway.fileThumbnail(
          uuid: '1',
          credential: 'token',
        );

        expect(outcome, isA<FileThumbnailRead>());
        expect(
          String.fromCharCodes((outcome as FileThumbnailRead).bytes),
          'hello',
        );
      },
    );

    test(
      'GivenAFileWithNoEmbeddedPicture_WhenReadingTheThumbnail_ThenItFailsWithoutThrowing',
      () async {
        // The core's own answer for a file that carries no picture — common
        // rather than exceptional (design section 4) — is `InvalidInput`,
        // not a missing-field payload.
        final core = FakeCoreClient()
          ..thumbnailResponse = (
            status: PLAYBACK_ERR_INVALID_INPUT,
            json: null,
          );
        final gateway = CoreCatalogGateway(core);

        final outcome = await gateway.fileThumbnail(
          uuid: '1',
          credential: 'token',
        );

        expect(outcome, isA<FileThumbnailFailed>());
        expect(
          (outcome as FileThumbnailFailed).failure,
          isA<InvalidInputFailure>(),
        );
      },
    );

    test(
      'GivenMalformedJson_WhenReadingTheThumbnail_ThenItFailsRatherThanThrowing',
      () async {
        final core = FakeCoreClient()
          ..thumbnailResponse = (status: PLAYBACK_OK, json: '{"uuid":"1"}');
        final gateway = CoreCatalogGateway(core);

        final outcome = await gateway.fileThumbnail(
          uuid: '1',
          credential: 'token',
        );

        expect(outcome, isA<FileThumbnailFailed>());
      },
    );

    test(
      'GivenTheCallThrows_WhenReadingTheThumbnail_ThenItFailsRatherThanThrowing',
      () async {
        final core = FakeCoreClient()..failOnFileThumbnail = true;
        final gateway = CoreCatalogGateway(core);

        final outcome = await gateway.fileThumbnail(
          uuid: '1',
          credential: 'token',
        );

        expect(outcome, isA<FileThumbnailFailed>());
      },
    );
  });
}
