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
    //
    // Signing out can land here while `begin()`'s own `startRefresh` call is
    // still awaiting this same gateway — invalidating disposes the very
    // notifier that call is suspended inside of, and it resumes afterwards
    // to assign `state` and read `activeRunsControllerProvider`. Verified
    // safe rather than assumed: `index_session_activity_test.dart`'s
    // `GivenTheGatewayCallIsStillPending_WhenTheOwnerSignsOutMidFlight_
    // ThenNothingThrows` drives exactly this race and nothing throws —
    // Riverpod does not tear the old instance down until something forces a
    // rebuild by reading the provider again, which neither `startRefresh`'s
    // resumption nor this method does.
    _ref.invalidate(indexRunsControllerProvider);
  }

  /// Re-checks the library, once, when a session is established (FR-LB-21).
  ///
  /// Two of the three cases where it does nothing — an empty catalog, no
  /// credential — are already `startRefresh`'s own rules, so they are not
  /// restated here: one place decides when a refresh may start, and a second
  /// copy of that decision would be one to keep in step.
  ///
  /// The third — a run already outstanding — is not one `startRefresh` can
  /// see on its own here. `IndexRunsController` is built fresh at sign-in, so
  /// its `isRefreshing` only knows about a run *this* controller started; a
  /// scan the core was still doing from a previous session (FR-LB-19) is
  /// invisible to it. `ActiveRunsController` is the one place that already
  /// asks the core what is outstanding, anywhere, so it is asked first: a
  /// fresh read, because the state it was built with may already be stale by
  /// the time a session begins.
  @override
  Future<void> begin() async {
    if (!_ref.read(preferencesControllerProvider).rechecksAtStartup) return;

    final activeRuns = _ref.read(activeRunsControllerProvider.notifier);
    await activeRuns.refresh();
    if (_ref.read(activeRunsControllerProvider).hasWork) return;

    await _ref
        .read(indexRunsControllerProvider.notifier)
        .startRefresh(reportRefusals: false);
  }
}
