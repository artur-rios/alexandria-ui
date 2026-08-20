import '../../catalog/domain/library_type.dart';

/// The viewers, keyed by the type each presents (FR-VW-01).
///
/// A registry rather than a conditional in the detail screen, on the
/// requirement's own words: adding a type or replacing a viewer is a
/// registration, and nothing in the listing or the detail view changes for it.
///
/// The registry holds identifiers rather than widgets, so the domain stays
/// clear of Flutter — the presentation layer maps an identifier to the screen
/// that opens.
class ViewerRegistry {
  /// Creates a registry over [_viewers].
  const ViewerRegistry(this._viewers);

  /// An empty registry, which presents nothing (FR-VW-08's answer).
  static const ViewerRegistry empty = ViewerRegistry({});

  final Map<LibraryType, ViewerKind> _viewers;

  /// The viewer registered for [type], or `null` when there is none.
  ViewerKind? viewerFor(LibraryType type) => _viewers[type];

  /// Whether [type] has a viewer at all.
  bool canPresent(LibraryType type) => _viewers.containsKey(type);
}

/// The viewers this application registers.
///
/// An enum rather than a class hierarchy: each value is one screen, the set is
/// closed by the file types the core classifies, and a switch over it is what
/// the presentation layer wants at the one place it resolves a viewer.
enum ViewerKind {
  /// PDFs and e-books (UC-22).
  document,

  /// Comic-book archives (UC-23).
  comic,

  /// Still images (UC-24).
  image,

  /// Saved HTML pages and rendered Markdown (UC-25).
  page,
}
