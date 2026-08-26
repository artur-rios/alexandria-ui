import 'dart:ui' as ui;

/// What a sleeve shows (UC-21, FR-PL-07, design section 4).
///
/// Two outcomes, and both are normal: the album's own embedded picture when
/// the file carries one, and the designed jacket — the album and artist
/// typeset on a colour derived from the album's name — when it does not. A
/// file with no embedded picture is common rather than exceptional, so this
/// is not an outcome-plus-error pair; there is nothing here for a caller to
/// treat as a failure.
sealed class AlbumCover {
  const AlbumCover();
}

/// The album's own picture, decoded and ready to paint.
///
/// [image] is owned by whoever produced this value — `AlbumCoverController`
/// today — and must be disposed exactly once, after nothing can paint it any
/// longer. This type does not dispose it itself: a sealed value class with no
/// lifecycle of its own is what lets the same decoded image be handed to a
/// painter on every rebuild without this class having an opinion on when the
/// image stops being needed.
final class AlbumCoverFetched extends AlbumCover {
  /// Wraps the decoded [image].
  const AlbumCoverFetched({required this.image});

  /// The decoded picture.
  final ui.Image image;
}

/// The designed jacket — the case's normal fallback, not a stand-in for a
/// broken fetch (design section 4).
///
/// Reached three ways, all of them ordinary: the file carries no embedded
/// picture (`InvalidInput`, common), the core could not answer for any other
/// reason, or the cover has simply not arrived yet. Nothing about reaching
/// this variant is worth telling the owner about.
final class AlbumCoverDesigned extends AlbumCover {
  /// Creates the designed-jacket outcome.
  const AlbumCoverDesigned();
}
