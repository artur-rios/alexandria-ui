import 'dart:convert';

import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../domain/comic_gateway.dart';
import '../domain/file_viewer.dart';

/// [ComicGateway] over `alexandria_comic_page` (UC-23, FR-VW-03).
class CoreComicGateway implements ComicGateway {
  /// Wraps [_core].
  const CoreComicGateway(this._core);

  final CoreClient _core;

  @override
  Future<ComicPageOutcome> readPage({
    required String uuid,
    required int page,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.comicPage(uuid, page, credential);
    } on CoreCallException {
      return const ComicPageFailed(failure: ViewerFailure.unreadable);
    }

    if (!CoreStatusFamily.playback.isOk(response.status)) {
      return ComicPageFailed(
        failure: _failureFor(
          mapCoreStatus(CoreStatusFamily.playback, response.status),
        ),
      );
    }

    final json = response.json;
    if (json == null) {
      return const ComicPageFailed(failure: ViewerFailure.unreadable);
    }

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final encoded = body['bytesBase64'] as String?;
      // AF-04: a page the core answered with nothing in it. The viewer marks
      // the gap and reads on, which is why this is a page-level failure and
      // not an archive-level one.
      if (encoded == null) {
        return const ComicPageFailed(failure: ViewerFailure.unreadable);
      }

      return ComicPageRead(
        page: ComicPage(
          number: body['page'] as int? ?? page,
          pageCount: body['pageCount'] as int? ?? 0,
          bytes: base64Decode(encoded),
        ),
      );
    } on Object {
      return const ComicPageFailed(failure: ViewerFailure.unreadable);
    }
  }

  /// What the core's refusal means to a reader.
  ///
  /// AF-01, AF-02 and AF-03 are three different things to say, and the core's
  /// status is what tells them apart: a file that is not on disk, an archive
  /// whose bytes will not open, and a state the core will not read from —
  /// which for a comic is an archive format nothing bundled decodes, CBR being
  /// the one the Technology Stack Document defers.
  static ViewerFailure _failureFor(Failure failure) => switch (failure) {
    DiskFailure() || NotFoundFailure() => ViewerFailure.missingOnDisk,
    InvalidStateFailure() => ViewerFailure.unsupportedFormat,
    _ => ViewerFailure.unreadable,
  };
}
