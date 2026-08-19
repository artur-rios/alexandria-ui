import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_file.dart';
import '../domain/catalog_gateway.dart';
import '../domain/library_type.dart';

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

/// Every file the catalog holds, across every type (UC-11).
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
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return const CatalogSearchIndex();

    final gateway = ref.read(catalogGatewayProvider);
    final files = <CatalogFile>[];
    var complete = true;

    for (final type in LibraryType.values) {
      final listing = await gateway.listFiles(
        type: type,
        credential: credential,
      );

      switch (listing) {
        case CatalogListingLoaded(files: final loaded):
          files.addAll(loaded);

        // AF-04's cousin: one type that could not be read does not fail the
        // search. What it does is make the result incomplete, which AF-03 says
        // has to be visible rather than presented as the whole answer.
        case CatalogListingFailed(failure: final UnauthorizedFailure failure):
          session.invalidate(failure);
          throw failure;

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

  /// Every file that could be read.
  final List<CatalogFile> files;

  /// Whether every type answered.
  ///
  /// `false` means the results are a partial answer, which AF-03 requires be
  /// said rather than presented as the whole one.
  final bool isComplete;

  /// Whether the catalog holds nothing at all (AF-04).
  bool get isEmpty => files.isEmpty && isComplete;
}
