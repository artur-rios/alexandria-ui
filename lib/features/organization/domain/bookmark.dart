import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';

/// A browser bookmark, as the application consumes it
/// (System Requirements §4.3).
@freezed
abstract class Bookmark with _$Bookmark {
  /// Creates a bookmark.
  const factory Bookmark({
    /// The public identifier passed on every call about it.
    required String uuid,

    /// The address it opens.
    required String url,

    /// What it is called in a listing.
    required String title,

    /// The bookmark collection it is filed in, if any.
    ///
    /// Carried but never offered: choosing one needs a list of the owner's
    /// collections, and the core publishes no query that answers which exist.
    /// A bookmark that already carries one keeps it through an update rather
    /// than being quietly unfiled by an interface that cannot show it.
    String? collectionUuid,

    /// Whether the core reports it as deleted.
    @Default(false) bool isDeleted,

    /// When the record was soft-deleted.
    ///
    /// What the deleted view counts the retention window from (UC-34), and
    /// `null` when the core answered without one — which reads as
    /// "restorable, for an unknown while".
    DateTime? deletedAt,
  }) = _Bookmark;
}

/// Why a bookmark cannot be sent to the core (UC-28 AF-01, FR-OG-12).
enum BookmarkFieldError {
  /// Nothing was entered, or only whitespace.
  empty,

  /// The address does not parse as one.
  malformedUrl,

  /// It parses, but not as something a browser could open.
  unopenableUrl,
}

/// What is wrong with [url], or `null` when it can be sent (AF-01).
///
/// Checked before the call because FR-OG-12 asks for it there: the core would
/// refuse it too, and a round trip to be told that "htp://" is not an address
/// is a worse answer than an immediate one.
BookmarkFieldError? validateBookmarkUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return BookmarkFieldError.empty;

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) return BookmarkFieldError.malformedUrl;

  // A scheme and something to resolve it against. `Uri.tryParse` accepts a
  // bare word as a relative reference, which is not an address a browser can
  // be handed.
  if (!parsed.hasScheme || parsed.host.isEmpty) {
    return BookmarkFieldError.unopenableUrl;
  }

  // The schemes a browser opens. A `file:` or `javascript:` bookmark is not a
  // page, and handing either to the platform's opener is not what the owner
  // saved a bookmark for.
  const openable = {'http', 'https'};
  if (!openable.contains(parsed.scheme.toLowerCase())) {
    return BookmarkFieldError.unopenableUrl;
  }

  return null;
}

/// What is wrong with [title], or `null` when it can be sent (AF-01).
BookmarkFieldError? validateBookmarkTitle(String title) =>
    title.trim().isEmpty ? BookmarkFieldError.empty : null;
