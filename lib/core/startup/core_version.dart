/// The range of Alexandria core versions this application supports (IR-06).
///
/// The core is pre-1.0, so a minor bump is a breaking change: `0.1.x` is
/// accepted and `0.2.0` is not. Widening this is a deliberate decision made
/// after the FFI surface has actually been checked, not a default that drifts
/// upward on its own.
abstract final class CoreVersionRange {
  /// The lowest accepted version, inclusive.
  static const String minimum = '0.1.0';

  /// The lowest rejected version, exclusive upper bound.
  static const String exclusiveMaximum = '0.2.0';

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
