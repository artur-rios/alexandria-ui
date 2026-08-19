import 'catalog_file.dart';

/// Matching a search term against the loaded catalog (UC-11, FR-CT-06).
///
/// Client-side by the specification's own design: main flow step 2 matches
/// "for the loaded catalog", and AF-03 describes searching what has loaded
/// while more arrives. The core publishes no search call, and this is not a
/// workaround for that — it is what the use case asks for.
///
/// What is matched is the file's name and its path. `FR-CT-06` also asks for
/// type-specific metadata, which the core's file projection does not carry: a
/// listing answers uuid, name, path, type and state, and nothing about an
/// album or an author. That half arrives when the catalog carries metadata,
/// and is deliberately absent rather than faked.
bool matchesSearch(CatalogFile file, String term) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return false;

  return file.name.toLowerCase().contains(needle) ||
      file.path.toLowerCase().contains(needle);
}

/// Whether [term] is something to search for at all (AF-02).
///
/// Blank and whitespace are the same thing here: the owner has not asked a
/// question, so the previous listing is what belongs on screen.
bool isSearchable(String term) => term.trim().isNotEmpty;

/// The files of [files] matching [term], in the order they arrived.
List<CatalogFile> searchResults(Iterable<CatalogFile> files, String term) => [
  for (final file in files)
    if (matchesSearch(file, term)) file,
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
