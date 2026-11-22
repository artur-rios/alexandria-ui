import '../../libraries/domain/library.dart';

/// [libraries] in the order the left menu lists them: the pinned ones A–Z,
/// then the others A–Z (spec §3).
///
/// A–Z ignores case, with the comparison the listings sort names by. Two
/// libraries with the same name fall back to their uuids, so the menu does
/// not swap them over between one reload and the next.
List<Library> menuOrder(List<Library> libraries) {
  int byName(Library a, Library b) {
    final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return order != 0 ? order : a.uuid.compareTo(b.uuid);
  }

  return [
    ...libraries.where((library) => library.pinned).toList()..sort(byName),
    ...libraries.where((library) => !library.pinned).toList()..sort(byName),
  ];
}
