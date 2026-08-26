/// The physical medium the album animation shows (FR-PL-07, BR-21).
enum AlbumMedium {
  /// A record on a turntable.
  vinyl,

  /// A cassette in a tape deck.
  tape,

  /// A disc in a CD player.
  disc,
}

/// The year the compact disc took over from the cassette, commercially.
const int _discEra = 1992;

/// The year the cassette overtook vinyl.
const int _tapeEra = 1985;

/// The medium an album of [year] is shown on (FR-PL-07).
///
/// Chosen from the year the album carries rather than at random, because a
/// medium that changed between two plays of the same record would read as a
/// bug. The thresholds are roughly when each format succeeded the last, which
/// makes the choice recognisable rather than arbitrary — an album from 1971
/// arrives on a turntable.
///
/// An album with no year is a disc: it is the medium a file most likely came
/// from, and it is the one the owner is least likely to find surprising.
AlbumMedium mediumForYear(int? year) {
  if (year == null) return AlbumMedium.disc;
  if (year >= _discEra) return AlbumMedium.disc;
  if (year >= _tapeEra) return AlbumMedium.tape;

  return AlbumMedium.vinyl;
}

/// What the owner chose the animation should show (FR-PL-11, UC-21).
///
/// The medium and the *choice of* medium are different things: [AlbumMedium]
/// is what is on screen, and this is how the application decided. Keeping them
/// apart is what lets the by-year rule stay one function that the pinned modes
/// simply do not call.
enum AlbumAnimationMode {
  /// The album's year decides, which is the default.
  byYear,

  /// Always a record.
  vinyl,

  /// Always a cassette.
  tape,

  /// Always a compact disc.
  disc,

  /// No animation at all.
  off;

  /// The mode [name] names, or `null` when it names none.
  ///
  /// Used to read a stored choice back, where an unrecognized value means the
  /// owner's preference is simply unknown and the default applies.
  static AlbumAnimationMode? byName(String? name) {
    for (final mode in AlbumAnimationMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

/// The medium [mode] shows for an album of [year], or `null` when the owner
/// has turned the animation off (FR-PL-11).
///
/// `null` rather than a medium plus a separate "is it on" flag: there is
/// exactly one question here — what, if anything, to draw — and a caller that
/// has to ask two of them is a caller that can get the answer half right.
AlbumMedium? mediumFor(AlbumAnimationMode mode, int? year) => switch (mode) {
  AlbumAnimationMode.byYear => mediumForYear(year),
  AlbumAnimationMode.vinyl => AlbumMedium.vinyl,
  AlbumAnimationMode.tape => AlbumMedium.tape,
  AlbumAnimationMode.disc => AlbumMedium.disc,
  AlbumAnimationMode.off => null,
};

/// How long one full turn of [medium] takes (Reference values).
///
/// The single source of truth for the three rates: `AlbumStage` (Task 5) and
/// `AlbumVisor` (Task 8) both draw the same medium turning, at the same
/// rate, and a second copy of these numbers in either widget would be a place
/// the two could quietly drift apart.
Duration spinPeriodFor(AlbumMedium medium) => switch (medium) {
  AlbumMedium.vinyl => const Duration(milliseconds: 1500),
  AlbumMedium.disc => const Duration(milliseconds: 900),
  AlbumMedium.tape => const Duration(milliseconds: 1800),
};
