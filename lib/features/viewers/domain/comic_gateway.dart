import 'dart:typed_data';

import 'file_viewer.dart';

/// One page of a comic-book archive (FR-VW-03).
class ComicPage {
  /// Creates a page.
  const ComicPage({
    required this.number,
    required this.pageCount,
    required this.bytes,
  });

  /// Which page this is, counting from one as the core does.
  final int number;

  /// How many pages the archive holds.
  final int pageCount;

  /// The image itself, decoded from what the core sent.
  final Uint8List bytes;
}

/// What reading a page produced (UC-23 main flow step 3).
sealed class ComicPageOutcome {
  const ComicPageOutcome();
}

/// The core read the page.
class ComicPageRead extends ComicPageOutcome {
  /// Creates the outcome.
  const ComicPageRead({required this.page});

  /// The page.
  final ComicPage page;
}

/// The core could not (AF-01 … AF-04).
class ComicPageFailed extends ComicPageOutcome {
  /// Creates the outcome.
  const ComicPageFailed({required this.failure});

  /// Why.
  final ViewerFailure failure;
}

/// Reads a comic-book archive a page at a time (FR-VW-03).
///
/// A page at a time, because that is what the core publishes and because
/// reading a four-hundred-megabyte archive into memory to show page one is not
/// how anybody reads a comic. Nothing is extracted to disk on either side of
/// the boundary.
abstract interface class ComicGateway {
  /// Reads [page] of the archive [uuid] identifies, counting from one.
  Future<ComicPageOutcome> readPage({
    required String uuid,
    required int page,
    required String credential,
  });
}
