import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// Indexing's share of signing out (UC-03 AF-02).
///
/// A scan runs inside the core on the core's own runtime (FR-LB-07), so
/// signing out neither stops it nor waits for it. What the application drops
/// is the polling and the outcomes it was holding on screen; the run itself
/// carries on, and the owner is told so rather than left to assume it died
/// with the session.
class IndexSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const IndexSessionActivity(this._ref);

  final Ref _ref;

  /// A scan is the core's work, not an unsaved edit — there is nothing here
  /// the owner could lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  @override
  bool get continuesInTheCore {
    final runs = _ref.read(indexRunsControllerProvider);
    return runs.hasRunInFlight || runs.isRefreshing;
  }

  @override
  Future<void> end() async {
    // Invalidating disposes the controller, and its `onDispose` stops the
    // poller — which is what has to stop, because every poll carries the
    // credential the next line discards (FR-AU-06).
    _ref.invalidate(indexRunsControllerProvider);
  }

  // A no-op for now: Task 3 fills this in with the library re-check
  // (FR-LB-21). The hook fires here; it just has nothing to do yet.
  @override
  Future<void> begin() async {}
}
