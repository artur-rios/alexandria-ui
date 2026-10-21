/// A tag, trimmed, or [whenAbsent] for a file whose tags carry none.
///
/// The metadata-first naming rule's Unknown fallback, in one place so the
/// screens that name an audio file cannot disagree (FR-CT-13). It is the one
/// place a blank or absent tag becomes a word, so nothing that names a track —
/// a search result, the dashboard, a deletion's confirmation — has to
/// remember the rule itself. That is what keeps "never the file name"
/// (FR-CT-13) one rule instead of one remembered at every call site.
String tagOr(String? value, String whenAbsent) {
  final trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? whenAbsent : trimmed;
}
