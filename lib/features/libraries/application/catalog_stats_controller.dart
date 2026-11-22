import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/catalog_stats.dart';

/// The catalog's totals (libraries design).
///
/// Invalidated with the other catalog projections: a finished run, a library
/// added or removed, a deletion.
class CatalogStatsController extends AsyncNotifier<CatalogStats> {
  @override
  Future<CatalogStats> build() => ref.read(libraryGatewayProvider).stats();

  /// Reads the totals again, which is also the retry after a failure.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
