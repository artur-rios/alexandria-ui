import '../../catalog/domain/file_type.dart';

/// What a viewer needs to know about the file it is presenting.
///
/// Not the [CatalogFile] itself: a viewer reads bytes from a path the core
/// resolved (FR-VW-07), and the record it came from is the screen's business.
class ViewerTarget {
  /// Creates a target.
  const ViewerTarget({
    required this.uuid,
    required this.name,
    required this.path,
    required this.type,
  });

  /// The file's public identifier, which its remembered position is keyed by.
  final String uuid;

  /// Its name, for the viewer's heading.
  final String name;

  /// Where it is on disk.
  final String path;

  /// What the core classified it as.
  final FileType type;
}

/// Why a viewer could not present a file (FR-VW-08).
enum ViewerFailure {
  /// The file is not where the catalog says it is (AF-01 everywhere in M-07).
  missingOnDisk,

  /// The bytes are not the format the extension claims, or are damaged.
  unreadable,

  /// The document is encrypted, and this application neither prompts for a
  /// password nor stores one (UC-22 AF-03).
  encrypted,

  /// The format is one no bundled decoder handles (UC-23 AF-03).
  unsupportedFormat,

  /// No viewer is registered for the type at all (UC-22 AF-04, FR-VW-08).
  noViewer,
}
