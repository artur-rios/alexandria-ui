import 'library.dart';

/// Orders [a] and [b] A–Z by name, ignoring case, then by uuid.
///
/// The one A–Z every list of libraries uses — the left menu, home's
/// favorites, Manage libraries — so the three never disagree. Not the core's
/// order: it sorts names byte by byte, which puts "alpha" after "Zeta". Two
/// libraries with the same name fall back to their uuids, so a list does not
/// swap them over between one reload and the next.
int byLibraryName(Library a, Library b) {
  final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return order != 0 ? order : a.uuid.compareTo(b.uuid);
}
