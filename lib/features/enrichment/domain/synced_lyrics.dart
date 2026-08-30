/// One line of lyrics and the moment it is sung.
class SyncedLyricLine {
  /// Creates a line.
  const SyncedLyricLine({required this.at, required this.text});

  /// How far into the track this line begins.
  final Duration at;

  /// The words. Empty for a timed gap — an intro, a solo, the space between
  /// verses — which is a real marker and not a blank to be discarded: it is
  /// what stops the previous line staying highlighted through a minute of
  /// saxophone.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is SyncedLyricLine && other.at == at && other.text == text;

  @override
  int get hashCode => Object.hash(at, text);

  @override
  String toString() => 'SyncedLyricLine($at, "$text")';
}

/// Lyrics with timestamps, in the order they are sung.
class SyncedLyrics {
  /// Creates lyrics from [lines], which must already be in time order.
  const SyncedLyrics(this.lines);

  /// The lines, ascending by [SyncedLyricLine.at].
  final List<SyncedLyricLine> lines;

  /// Whether there is anything to show.
  bool get isEmpty => lines.isEmpty;

  /// Which line is being sung at [position], or `null` before the first one.
  ///
  /// The last line whose timestamp has passed — not the nearest, which would
  /// jump ahead to a line that has not been reached yet. `null` before the
  /// first timestamp is a real state: a track with a long intro has nothing
  /// to highlight for its first thirty seconds, and highlighting the opening
  /// line for all of it would be wrong.
  ///
  /// Binary search rather than a scan: this is asked on every position
  /// update — several times a second, for the whole of a track — and a
  /// linear walk over a few hundred lines each time is work that does not
  /// need doing.
  int? activeIndexAt(Duration position) {
    if (lines.isEmpty || position < lines.first.at) return null;

    var low = 0;
    var high = lines.length - 1;
    while (low < high) {
      // Rounded up, so the search moves when `low` and `high` are adjacent.
      final middle = (low + high + 1) ~/ 2;
      if (lines[middle].at <= position) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    return low;
  }
}

/// The lines an LRC document carries, in time order.
///
/// LRC is a loose format and this is deliberately forgiving of it: a
/// timestamp may carry two or three fractional digits or none at all, one
/// line may be stamped with several times when a chorus repeats, and the
/// file may open with metadata tags (`[ar:…]`, `[length:…]`) that look like
/// timestamps but are not. Anything unrecognized is skipped rather than
/// failing the parse — a single odd line should cost that line, not the
/// whole song.
List<SyncedLyricLine> parseLrc(String document) {
  // `[mm:ss]`, `[mm:ss.xx]`, or `[mm:ss.xxx]`. The minutes are unbounded
  // because a live recording can run past an hour, and the fraction is
  // optional because plenty of files carry whole seconds.
  final stamp = RegExp(r'\[(\d+):([0-5]?\d)(?:[.:](\d{1,3}))?\]');
  final lines = <SyncedLyricLine>[];

  for (final raw in document.split(RegExp(r'\r\n|\r|\n'))) {
    final stamps = stamp.allMatches(raw).toList();
    if (stamps.isEmpty) continue;

    // Only the run of timestamps at the very start belongs to this line. A
    // bracketed aside later in the text — `[laughs]`, or a stray `[00:12]`
    // quoted inside a line — is part of the words, not a second cue.
    var consumed = 0;
    final leading = <RegExpMatch>[];
    for (final match in stamps) {
      if (match.start != consumed) break;
      leading.add(match);
      consumed = match.end;
    }
    if (leading.isEmpty) continue;

    final text = raw.substring(consumed).trim();

    for (final match in leading) {
      final minutes = int.tryParse(match.group(1)!);
      final seconds = int.tryParse(match.group(2)!);
      if (minutes == null || seconds == null) continue;

      // `.5` is five tenths and `.05` is five hundredths — padded rather
      // than read as a bare integer, or a two-digit fraction would be a
      // hundred times too small.
      final fraction = match.group(3);
      final milliseconds = fraction == null
          ? 0
          : int.parse(fraction.padRight(3, '0'));

      lines.add(
        SyncedLyricLine(
          at: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: text,
        ),
      );
    }
  }

  // A chorus stamped with several times arrives out of order, and a file is
  // not obliged to be sorted in the first place.
  lines.sort((a, b) => a.at.compareTo(b.at));

  return lines;
}
