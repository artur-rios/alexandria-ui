/// A release's version, `major.minor.patch` (update-check design §2).
///
/// Only plain releases parse: a pre-release (`1.2.0-rc.1`) answers null, and
/// so does anything that is not three numbers. A build suffix (`+7`) is
/// ignored, because the release builds stamp one and it says nothing about
/// which release is newer.
class AppVersion implements Comparable<AppVersion> {
  /// Creates the version.
  const AppVersion(this.major, this.minor, this.patch);

  /// The major number.
  final int major;

  /// The minor number.
  final int minor;

  /// The patch number.
  final int patch;

  /// [raw] as a version — `1.2.3`, `v1.2.3` or `1.2.3+7` — or null.
  static AppVersion? parse(String raw) {
    var text = raw.trim();
    if (text.startsWith('v')) text = text.substring(1);

    final plus = text.indexOf('+');
    if (plus >= 0) text = text.substring(0, plus);

    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(text);
    if (match == null) return null;

    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  /// Whether this is a later release than [other].
  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
