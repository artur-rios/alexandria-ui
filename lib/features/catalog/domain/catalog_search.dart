import 'file_details.dart';

/// Matching a search term against the loaded catalog (UC-11, FR-CT-06).
///
/// Client-side by the specification's own design: main flow step 2 matches
/// "for the loaded catalog", and AF-03 describes searching what has loaded
/// while more arrives. The core publishes no search call, and this is not a
/// workaround for that — it is what the use case asks for.
///
/// What is matched is the file's name and path, plus the type-specific
/// metadata FR-CT-06 also asks for: each row the listing answers now carries
/// it, exactly as the single-file call does, so there is no second call to
/// make and nothing here to fake.
bool matchesSearch(FileDetails details, String term) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return false;

  if (details.file.name.toLowerCase().contains(needle)) return true;
  if (details.file.path.toLowerCase().contains(needle)) return true;

  return details.metadata.values.any(
    (value) => value.toLowerCase().contains(needle),
  );
}

/// Whether [term] is something to search for at all (AF-02).
///
/// Blank and whitespace are the same thing here: the owner has not asked a
/// question, so the previous listing is what belongs on screen.
bool isSearchable(String term) => term.trim().isNotEmpty;

/// The rows of [files] matching [term], in the order they arrived.
List<FileDetails> searchResults(Iterable<FileDetails> files, String term) => [
  for (final details in files)
    if (matchesSearch(details, term)) details,
];

/// Where [term] appears in [text], as the span to highlight (main flow step 3).
///
/// `null` when it does not appear, which is the ordinary case for a file
/// matched on its path but shown by its name.
({int start, int end})? highlightRange(String text, String term) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return null;

  final start = text.toLowerCase().indexOf(needle);
  if (start < 0) return null;

  return (start: start, end: start + needle.length);
}
