/// The SHA-256 [sumsFileText] gives for [assetName], lower-case, or null when
/// it has no line for that exact name.
///
/// The text is `sha256sum` output: `<hex>  <name>`, or `<hex> *<name>` in its
/// binary mode.
String? checksumFor(String sumsFileText, String assetName) {
  for (final line in sumsFileText.split('\n')) {
    final match = RegExp(
      r'^([0-9a-fA-F]{64}) [ *](.+)$',
    ).firstMatch(line.trim());
    if (match == null) continue;
    if (match.group(2) == assetName) return match.group(1)!.toLowerCase();
  }
  return null;
}
