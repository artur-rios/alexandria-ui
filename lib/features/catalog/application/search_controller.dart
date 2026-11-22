import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_details.dart';
import '../domain/file_type.dart';

/// What the owner has typed (UC-11 main flow step 1).
///
/// Its own notifier so the term survives the results reloading, and so
/// clearing it is one call rather than a state machine.
class SearchTermController extends Notifier<String> {
  @override
  String build() => '';

  /// Records what the owner typed.
  set term(String value) => state = value;

  /// Clears the search, restoring the previous listing (AF-02).
  void clear() => state = '';
}

/// Every file the catalog holds, across every type (UC-11), libraries
/// included.
///
/// Loaded once and matched in memory, which is what main flow step 2 asks
/// for — it matches "for the loaded catalog", not through a query the core
/// does not publish.
///
/// The whole catalog is a lot to hold, and this is the place that would have
/// to change if it stops fitting: the core would need a search call, and this
/// would become a thin caller of it. Nothing above here would know.
class CatalogSearchController extends AsyncNotifier<CatalogSearchIndex> {
  @override
  Future<CatalogSearchIndex> build() async {
    final gateway = ref.read(catalogGatewayProvider);
    final files = <FileDetails>[];
    var complete = true;

    for (final type in FileType.values) {
      final listing = await gateway.listFiles(type: type);

      switch (listing) {
        case CatalogListingLoaded(files: final loaded):
          files.addAll(loaded);

        case CatalogListingFailed():
          complete = false;
      }
    }

    return CatalogSearchIndex(files: files, isComplete: complete);
  }

  /// Loads the catalog again.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// The catalog as the search sees it.
class CatalogSearchIndex {
  /// Creates an index.
  const CatalogSearchIndex({this.files = const [], this.isComplete = true});

  /// Every file that could be read, with the metadata each row carries.
  final List<FileDetails> files;

  /// Whether every type answered.
  ///
  /// `false` means the results are a partial answer, which AF-03 requires be
  /// said rather than presented as the whole one.
  final bool isComplete;

  /// Whether the catalog holds nothing at all (AF-04).
  bool get isEmpty => files.isEmpty && isComplete;
}
