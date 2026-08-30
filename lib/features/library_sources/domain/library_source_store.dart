import 'library_source.dart';

/// Where the registered source folders are kept (FR-LB-03).
///
/// Declared here so the application layer depends on this rather than on the
/// settings store and its JSON, which is data-layer work. The implementation
/// is bound in the composition root, and a test binds one backed by a map.
abstract interface class LibrarySourceStore {
  /// Every registered folder, in the order they were registered.
  ///
  /// Answers an empty list rather than throwing when nothing readable is
  /// stored: an owner with no folders is a state the interface already handles
  /// (FR-LB-11).
  List<LibrarySource> read();

  /// Replaces the stored folders with [sources].
  Future<void> write(List<LibrarySource> sources);
}
