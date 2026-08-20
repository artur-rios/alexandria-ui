import 'dart:typed_data';

import 'package:alexandria_desktop/features/viewers/domain/comic_gateway.dart';
import 'package:alexandria_desktop/features/viewers/domain/file_viewer.dart';

/// A [ComicGateway] that never reaches the core (Testing Specification §2.3).
class FakeComicGateway implements ComicGateway {
  /// Creates a gateway over an archive of [pageCount] pages.
  FakeComicGateway({this.pageCount = 3});

  /// How many pages the archive holds.
  int pageCount;

  /// Pages that will not decode (UC-23 AF-04).
  final Set<int> undecodable = {};

  /// What the whole archive answers, when it refuses (AF-01 … AF-03).
  ViewerFailure? archiveFailure;

  /// Every page asked for, in order.
  final List<int> requested = [];

  @override
  Future<ComicPageOutcome> readPage({
    required String uuid,
    required int page,
    required String credential,
  }) async {
    requested.add(page);

    final failure = archiveFailure;
    if (failure != null) return ComicPageFailed(failure: failure);

    if (undecodable.contains(page)) {
      return const ComicPageFailed(failure: ViewerFailure.unreadable);
    }

    // A one-pixel PNG is enough: what is asserted is which page came back,
    // never what it looks like.
    return ComicPageRead(
      page: ComicPage(number: page, pageCount: pageCount, bytes: onePixelPng),
    );
  }

  /// The smallest PNG that decodes.
  static final Uint8List onePixelPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
}
