import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../library_sources/application/index_runs_state.dart';
import '../../library_sources/domain/index_run.dart';
import '../domain/catalog_file.dart';
import '../domain/index_run_summary.dart';
import '../domain/listing_view.dart';

/// The most recently added files (UC-14, FR-CT-11).
///
/// Built from the catalog the search already loads rather than a query of its
/// own: the core publishes no "recent files" call, and asking every type again
/// would be the same work twice. It is a section in its own right, so its
/// failure is its own and does not take the rest of the dashboard down (AF-03).
class RecentFilesController extends AsyncNotifier<List<CatalogFile>> {
  /// How many files the dashboard shows.
  ///
  /// Enough to be a glance rather than a listing — the listings are one click
  /// away and this is the front page.
  static const int limit = 8;

  @override
  Future<List<CatalogFile>> build() async {
    final index = await ref.watch(catalogSearchProvider.future);

    final byNewest = sortFiles(
      index.files,
      const ListingView(
        sortField: SortField.indexed,
        direction: SortDirection.descending,
      ),
    );

    return byNewest.take(limit).toList();
  }

  /// Loads the catalog again (AF-03's retry).
  Future<void> reload() => ref.read(catalogSearchProvider.notifier).reload();
}

/// What [runs] says about the most recent run.
///
/// A run in flight wins over a finished one: what is happening now is more use
/// to the owner than what happened before it, and AF-04 asks for exactly that.
/// A refresh counts the same as a scan — both are runs, and the dashboard
/// reports the library's state rather than which operation produced it.
IndexRunSummary mostRecentRun(IndexRunsState runs) {
  if (runs.hasRunInFlight || runs.isRefreshing) return IndexRunSummary.running;

  final finished = [...runs.runs.values, ?runs.refreshRun];
  if (finished.isEmpty) return IndexRunSummary.none;

  // The worst outcome among them, so a failure is not hidden by a success that
  // happened to be recorded beside it.
  if (finished.any((run) => run.status == IndexRunStatus.failed)) {
    return IndexRunSummary.failed;
  }
  // The core calls this `paused` now, not `interrupted` — a run the
  // application was closed on is resumable, not abandoned. `IndexRunSummary`
  // keeps its own `interrupted` word for now; a later task carries the
  // renaming through the dashboard's copy.
  if (finished.any((run) => run.status == IndexRunStatus.paused)) {
    return IndexRunSummary.interrupted;
  }

  return IndexRunSummary.complete;
}
