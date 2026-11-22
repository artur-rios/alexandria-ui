import '../../libraries/domain/library.dart';
import '../../libraries/domain/library_order.dart';

/// [libraries] in the order the left menu lists them: the pinned ones A–Z,
/// then the others A–Z (spec §3).
///
/// A–Z is [byLibraryName], the one order every list of libraries uses.
List<Library> menuOrder(List<Library> libraries) => [
  ...libraries.where((library) => library.pinned).toList()..sort(byLibraryName),
  ...libraries.where((library) => !library.pinned).toList()
    ..sort(byLibraryName),
];
