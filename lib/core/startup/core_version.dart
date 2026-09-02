/// The range of Alexandria core versions this application supports (IR-06).
///
/// The core is pre-1.0, so a minor bump is a breaking change: `0.2.x` is
/// accepted and `0.3.0` is not. Widening this is a deliberate decision made
/// after the FFI surface has actually been checked, not a default that drifts
/// upward on its own.
///
/// Moved to `0.2.x` with the core that stamps a row's metadata and looks a
/// recording up when naming it exactly misses. Both are invisible from here
/// when they are missing — an artists list quietly grouping by performer, a
/// lyrics lookup quietly answering nothing — and an owner rebuilding one
/// repository and not the other met exactly that. This is the line that
/// turns it into a sentence at startup instead.
abstract final class CoreVersionRange {
  /// The lowest accepted version, inclusive.
  static const String minimum = '0.3.0';

  /// The lowest rejected version, exclusive upper bound.
  static const String exclusiveMaximum = '0.4.0';

  /// How the range reads in a failure message.
  static const String description = '>=$minimum <$exclusiveMaximum';

  /// Whether [version] is inside the supported range.
  ///
  /// An unparseable version is *not* supported. A core that will not say what
  /// it is has already failed the check this exists to make — treating it as
  /// acceptable would let the one case this guards against through.
  static bool supports(String? version) {
    final found = _parse(version);
    if (found == null) return false;

    return _compare(found, _parse(minimum)!) >= 0 &&
        _compare(found, _parse(exclusiveMaximum)!) < 0;
  }

  /// Parses `major.minor.patch`, ignoring any pre-release or build suffix.
  static List<int>? _parse(String? version) {
    if (version == null) return null;

    final core = version.trim().split(RegExp('[-+]')).first;
    final parts = core.split('.');
    if (parts.length != 3) return null;

    final numbers = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      numbers.add(value);
    }
    return numbers;
  }

  static int _compare(List<int> left, List<int> right) {
    for (var i = 0; i < 3; i++) {
      final difference = left[i] - right[i];
      if (difference != 0) return difference;
    }
    return 0;
  }
}
