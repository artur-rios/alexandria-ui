import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'bookmark.dart';

part 'bookmark_gateway.freezed.dart';

/// What listing bookmarks produced (UC-28 main flow step 2).
@freezed
sealed class BookmarkListing with _$BookmarkListing {
  /// The core answered, possibly with nothing.
  const factory BookmarkListing.loaded({required List<Bookmark> bookmarks}) =
      BookmarkListingLoaded;

  /// The core could not answer (AF-06, and anything unexpected).
  const factory BookmarkListing.failed({required Failure failure}) =
      BookmarkListingFailed;
}

/// What writing a bookmark produced (UC-28 main flow steps 4 and 5).
@freezed
sealed class BookmarkWrite with _$BookmarkWrite {
  /// The core stored it and echoed what it holds.
  const factory BookmarkWrite.saved({required Bookmark bookmark}) =
      BookmarkSaved;

  /// The core refused (AF-02, AF-05, AF-06).
  const factory BookmarkWrite.failed({required Failure failure}) =
      BookmarkWriteFailed;
}

/// The core's bookmark operations (FR-OG-08 … FR-OG-10).
abstract interface class BookmarkGateway {
  /// Every bookmark, or those in [collectionUuid] (FR-OG-10).
  Future<BookmarkListing> list({
    required String credential,
    String? collectionUuid,
  });

  /// Creates a bookmark (FR-OG-08).
  Future<BookmarkWrite> create({
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  });

  /// Updates the bookmark [uuid] identifies (FR-OG-09).
  Future<BookmarkWrite> update({
    required String uuid,
    required String url,
    required String title,
    required String credential,
    String? collectionUuid,
  });
}
