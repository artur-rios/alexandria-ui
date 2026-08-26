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

  /// Re-checks the library, once, when a session is established (FR-LB-21).
  ///
  /// The three cases where it does nothing — a run already outstanding, an
  /// empty catalog, no credential — are already `startRefresh`'s own rules,
  /// so they are not restated here: one place decides when a refresh may
  /// start, and a second copy of that decision would be one to keep in step.
  /// What this adds is that none of them is announced, because nobody asked.
  ///
  /// Also guarded on the core being loaded. `indexRunsControllerProvider`
  /// reads the core through `indexGatewayProvider` at build time, and that
  /// provider throws — loudly and by design, since reading it early is a
  /// programming error it wants surfaced — rather than answer with nothing
  /// to read from. Production only ever reaches [begin] after startup has
  /// reached [StartupReady], so this is never what stops it there; it is
  /// what stops a container that established a session without ever loading
  /// one, which has nothing here to re-check either.
  @override
  Future<void> begin() async {
    if (!_ref.read(preferencesControllerProvider).rechecksAtStartup) return;
    if (_ref.read(startupControllerProvider.notifier).core == null) return;

    await _ref
        .read(indexRunsControllerProvider.notifier)
        .startRefresh(reportRefusals: false);
  }
}
