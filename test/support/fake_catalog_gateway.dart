import 'package:alexandria_desktop/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';

/// A [CatalogGateway] that never reaches the core (Testing Specification §2.3).
///
/// Answers per type, because UC-09 is about types being listed independently:
/// one that fails must not take the others down with it (AF-02).
class FakeCatalogGateway implements CatalogGateway {
  /// Creates a gateway whose types are empty unless a test fills them.
  FakeCatalogGateway({Map<LibraryType, CatalogListing>? listings})
    : listings = {...?listings};

  /// What each type answers. A type with no entry answers an empty listing.
  final Map<LibraryType, CatalogListing> listings;

  /// Every type asked for, in order.
  ///
  /// Empty is the assertion that matters when there is no session: no catalog
  /// call is made without one (FR-AU-07).
  final List<LibraryType> requested = [];

  /// The credentials each call was made with.
  final List<String> credentials = [];

  @override
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
  }) async {
    requested.add(type);
    credentials.add(credential);

    return listings[type] ?? const CatalogListing.loaded(files: []);
  }
}

/// A file of [type], for a test that needs one in a listing.
CatalogFile aFile({
  String uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f',
  String name = 'Kind of Blue.flac',
  String path = '/home/owner/music/Kind of Blue.flac',
  LibraryType type = LibraryType.audio,
  DateTime? missingAt,
}) => CatalogFile(
  uuid: uuid,
  name: name,
  path: path,
  type: type,
  missingAt: missingAt,
);
