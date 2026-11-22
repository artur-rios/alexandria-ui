import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/app_activity.dart';

/// Indexing's share of the application's activities.
///
/// A scan runs inside the core on the core's own runtime (FR-LB-07), so
/// ending this activity neither stops it nor waits for it. What the
/// application drops is the polling and the outcomes it was holding on
/// screen; the run itself carries on in the core.
class IndexAppActivity implements AppActivity {
  /// Creates the activity over [_ref].
  const IndexAppActivity(this._ref);

  final Ref _ref;

  /// A scan is the core's work, not an unsaved edit — there is nothing here
  /// the owner could lose by closing.
  @override
  bool get holdsUnsavedChanges => false;

  @override
  Future<void> end() async {
    // Invalidating disposes the controller, and its `onDispose` stops the
    // poller, so nothing is still polling the core while the application
    // closes.
    //
    // Ending can land here while `begin()`'s own `startRefresh` call is
    // still awaiting this same gateway — invalidating disposes the very
    // notifier that call is suspended inside of, and it resumes afterwards
    // to assign `state` and read `activeRunsControllerProvider`. Verified
    // safe rather than assumed: `index_app_activity_test.dart`'s
    // `GivenTheGatewayCallIsStillPending_WhenTheActivityEndsMidFlight_
    // ThenNothingThrows` drives exactly this race and nothing throws —
    // Riverpod does not tear the old instance down until something forces a
    // rebuild by reading the provider again, which neither `startRefresh`'s
    // resumption nor this method does.
    _ref.invalidate(indexRunsControllerProvider);
  }

  /// Re-checks the library, once, when the application is ready (FR-LB-21).
  ///
  /// One of the cases where it does nothing — an empty catalog — is already
  /// `startRefresh`'s own rule, so it is not restated here: one place decides
  /// when a refresh may start, and a second copy of that decision would be
  /// one to keep in step.
  ///
  /// The other — a run already outstanding — is not one `startRefresh` can
  /// see on its own here. `IndexRunsController` is built fresh at startup, so
  /// its `isRefreshing` only knows about a run *this* controller started; a
  /// scan the core was still doing from a previous run of the application
  /// (FR-LB-19) is invisible to it. `ActiveRunsController` is the one place
  /// that already asks the core what is outstanding, anywhere, so it is asked
  /// first: a fresh read, because the state it was built with may already be
  /// stale by the time the activities begin.
  ///
  /// `hasWork` counts a *paused* run as outstanding too, not only one still
  /// running — deliberately. A pause is the owner choosing to hold a scan
  /// where it is, not abandoning it; starting a second one alongside it
  /// would be stranger than waiting, and the paused run is not silent about
  /// it either, since the strip already shows it. Do not narrow this to
  /// "in flight" — that would fire a re-check every launch until the owner
  /// resumes or cancels the very run this check is meant to respect.
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
