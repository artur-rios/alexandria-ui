/// The range of Alexandria core versions this application supports (IR-06).
///
/// The core is pre-1.0, so a minor bump is a breaking change: `0.6.x` is
/// accepted and `0.7.0` is not. Widening this is a deliberate decision made
/// after the FFI surface has actually been checked, not a default that drifts
/// upward on its own.
///
/// Moved to `0.6.x` with the core that made libraries the only way into the
/// catalog: its FFI no longer exports `alexandria_index_start` or the per-run
/// type scope, adding a library starts its first run, and removing one
/// deletes its records. A `0.5.x` core still indexes folders outside any
/// library, which this build can no longer add or show, so it is refused at
/// startup by name and version instead of misbehaving quietly.
abstract final class CoreVersionRange {
  /// The lowest accepted version, inclusive.
  static const String minimum = '0.6.0';

  /// The lowest rejected version, exclusive upper bound.
  static const String exclusiveMaximum = '0.7.0';

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
