import '../../catalog/domain/file_type.dart';

/// The catalog's totals, as home shows them.
class CatalogStats {
  /// Creates the totals.
  const CatalogStats({required this.libraries, required this.filesByType});

  /// How many libraries are registered.
  final int libraries;

  /// How many files each type holds, every type present.
  final Map<FileType, int> filesByType;
}
