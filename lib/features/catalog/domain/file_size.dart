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
  var rounded = size.toStringAsFixed(size < 10 && unit > 0 ? 1 : 0);

  // Rounding, not just division, decides the unit. 1048575 B divides to
  // 1023.999... KB — under the 1024 threshold the loop above checks, so it
  // stops at KB — and then toStringAsFixed(0) rounds that up to "1024",
  // printing "1024 KB" next to a file manager that reads the same file as
  // "1.0 MB". Promoting here, once, after rounding, keeps the printed number
  // and the printed unit in agreement.
  if (double.parse(rounded) >= 1024 && unit < units.length - 1) {
    unit++;
    size /= 1024;
    rounded = size.toStringAsFixed(size < 10 && unit > 0 ? 1 : 0);
  }

  final trimmed = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;

  return '$trimmed ${units[unit]}';
}
