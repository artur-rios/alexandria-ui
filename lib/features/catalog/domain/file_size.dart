/// [bytes] as an owner reads a file size (UC-13, FR-CT-05).
///
/// Not localized: the unit symbols are the same in both supported languages,
/// and a size is read the same way in each — the same reasoning the details
/// view already applies to a duration.
///
/// Binary units, because that is what a file manager on either supported
/// platform shows for the same file, and a size that disagrees with the one
/// beside it in Explorer reads as a bug.
String formatFileSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];

  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }

  // One decimal, and none when it would be a trailing zero: "4.7 MB" is the
  // detail worth having, "4.0 MB" is noise.
  final rounded = size.toStringAsFixed(size < 10 && unit > 0 ? 1 : 0);
  final trimmed = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;

  return '$trimmed ${units[unit]}';
}
