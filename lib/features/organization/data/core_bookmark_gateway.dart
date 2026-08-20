import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_gateway.dart';

/// [BookmarkGateway] over the core's bookmark calls (UC-28).
class CoreBookmarkGateway implements BookmarkGateway {
  /// Wraps [_core].
  const CoreBookmarkGateway(this._core);

  final CoreClient _core;

  @override
  Future<BookmarkListing> list({
    required String credential,
    String? collectionUuid,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.bookmarksList(
        // An empty filter is every bookmark, which is what the screen opens
        // on (main flow step 1).
        collectionUuid == null
            ? ''
            : jsonEncode({'collectionUuid': collectionUuid}),
        credential,
      );
    } on CoreCallException {
      return _unreadableListing();
    }

    if (!CoreStatusFamily.bookmark.isOk(response.status)) {
      return BookmarkListing.failed(
        failure: mapCoreStatus(CoreStatusFamily.bookmark, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableListing();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return BookmarkListing.loaded(
        bookmarks: [
          for (final row in rows) _bookmarkFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      return _unreadableListing();
    }
  }

  @override
  Future<BookmarkWrite> create({
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  }) => _write(
    () => _core.bookmarkCreate(
      jsonEncode(_body(url, title, collectionUuid)),
      credential,
    ),
  );

  @override
  Future<BookmarkWrite> update({
    required String uuid,
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  }) => _write(
    () => _core.bookmarkUpdate(
      uuid,
      jsonEncode(_body(url, title, collectionUuid)),
      credential,
    ),
  );

  /// The body both writes take.
  ///
  /// The collection is left out rather than sent as null when there is none:
  /// this application cannot offer one (the core publishes no query listing
  /// collections), and an explicit null would unfile a bookmark somebody
  /// filed elsewhere.
  static Map<String, Object?> _body(
    String url,
    String title,
    String? collectionUuid,
  ) => {'url': url, 'title': title, 'collectionUuid': ?collectionUuid};

  Future<BookmarkWrite> _write(Future<CoreJsonResponse> Function() call) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return _unwritable();
    }

    // AF-02, AF-05 and AF-06 all arrive here and are told apart by the status
    // the mapper reads: a value the core refused, a bookmark it does not have,
    // and a rejected session.
    if (!CoreStatusFamily.bookmark.isOk(response.status)) {
      return BookmarkWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.bookmark, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unwritable();

    try {
      return BookmarkWrite.saved(
        bookmark: _bookmarkFrom(jsonDecode(json) as Map<String, dynamic>),
      );
    } on Object {
      return _unwritable();
    }
  }

  static Bookmark _bookmarkFrom(Map<String, dynamic> row) => Bookmark(
    uuid: row['uuid'] as String,
    url: row['url'] as String,
    title: row['title'] as String,
    collectionUuid: row['collectionUuid'] as String?,
    isDeleted: row['state'] == 'deleted',
  );

  BookmarkListing _unreadableListing() => const BookmarkListing.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.bookmark,
      code: BOOKMARK_ERR_OTHER,
    ),
  );

  BookmarkWrite _unwritable() => const BookmarkWrite.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.bookmark,
      code: BOOKMARK_ERR_OTHER,
    ),
  );
}
