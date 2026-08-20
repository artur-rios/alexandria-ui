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
