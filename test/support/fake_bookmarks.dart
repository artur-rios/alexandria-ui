import 'package:alexandria_ui/features/organization/domain/bookmark.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark_gateway.dart';
import 'package:alexandria_ui/features/organization/domain/browser_launcher.dart';

/// A [BookmarkGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeBookmarkGateway implements BookmarkGateway {
  /// Creates a gateway holding [bookmarks].
  FakeBookmarkGateway({List<Bookmark>? bookmarks})
    : bookmarks = [...?bookmarks];

  /// What a listing answers.
  final List<Bookmark> bookmarks;

  /// What [list] answers instead, when a test says so.
  BookmarkListing? listing;

  /// What a write answers, in order.
  ///
  /// A list so a test can have the core refuse once and accept the retry,
  /// which is the whole of AF-02: the form stays open and the owner corrects
  /// it.
  final List<BookmarkWrite> writeOutcomes = [];

  /// Every write asked for, in order.
  ///
  /// Empty is the assertion AF-01 needs: an address that does not parse never
  /// reaches the core.
  final List<({String? uuid, String url, String title, String? collection})>
  writes = [];

  /// The collection each listing was filtered by, in order.
  final List<String?> filters = [];

  /// Whether each listing asked for deleted records, in order (UC-34).
  final List<bool> deletedFilters = [];

  /// What a deleted listing answers (UC-34).
  final List<Bookmark> deletedBookmarks = [];

  @override
  Future<BookmarkListing> list({
    required String credential,
    String? collectionUuid,
    bool deleted = false,
  }) async {
    filters.add(collectionUuid);
    deletedFilters.add(deleted);
    if (deleted) return BookmarkListing.loaded(bookmarks: deletedBookmarks);

    return listing ?? BookmarkListing.loaded(bookmarks: bookmarks);
  }

  @override
  Future<BookmarkWrite> create({
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  }) async {
    writes.add((
      uuid: null,
      url: url,
      title: title,
      collection: collectionUuid,
    ));

    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final created = Bookmark(
      uuid: 'created-${bookmarks.length}',
      url: url,
      title: title,
      collectionUuid: collectionUuid,
    );
    bookmarks.add(created);

    return BookmarkWrite.saved(bookmark: created);
  }

  @override
  Future<BookmarkWrite> update({
    required String uuid,
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  }) async {
    writes.add((
      uuid: uuid,
      url: url,
      title: title,
      collection: collectionUuid,
    ));

    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final updated = Bookmark(
      uuid: uuid,
      url: url,
      title: title,
      collectionUuid: collectionUuid,
    );
    final index = bookmarks.indexWhere((entry) => entry.uuid == uuid);
    if (index >= 0) bookmarks[index] = updated;

    return BookmarkWrite.saved(bookmark: updated);
  }
}

/// A [BrowserLauncher] that opens nothing (Testing Specification §2.3).
class FakeBrowserLauncher implements BrowserLauncher {
  /// Creates a launcher that succeeds unless [opens] says otherwise.
  FakeBrowserLauncher({this.opens = true});

  /// Whether the platform takes the URL. `false` is UC-28 AF-04.
  bool opens;

  /// Every URL handed over, in order.
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return opens;
  }
}
