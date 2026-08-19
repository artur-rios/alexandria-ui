import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'catalog_file.dart';
import 'library_type.dart';

part 'catalog_gateway.freezed.dart';

/// What listing a type produced (UC-09 main flow steps 3 and 4).
@freezed
sealed class CatalogListing with _$CatalogListing {
  /// The core answered with [files], which may be empty (AF-01).
  const factory CatalogListing.loaded({required List<CatalogFile> files}) =
      CatalogListingLoaded;

  /// The core could not answer (AF-02, AF-04).
  const factory CatalogListing.failed({required Failure failure}) =
      CatalogListingFailed;
}

/// The application's view of the core's catalog queries (IR-02, NFR-17).
abstract interface class CatalogGateway {
  /// The active files of [type], merged across every registered folder
  /// (FR-CT-02, FR-LB-04).
  ///
  /// Filtered to active records by the core: deleted ones belong to UC-34's
  /// listing, not to this one.
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
  });
}
