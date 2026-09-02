import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// Playback's share of signing out (UC-03 main flow step 3, FR-AU-09).
///
/// `AlbumAnimationController` remembers which record it last showed an
/// insertion for (`_shownFor`) across every rebuild for the length of the
/// running session — that is what stops the same album's next track from
/// replaying the insertion. Nothing about that memory belongs to a *later*
/// session: an owner who signs out, signs back in and plays the very same
/// album is starting over, and the animation owes that play an insertion the
/// same way the first session's first play did (Finding 4).
///
/// `AlbumCoverController` remembers, and holds a decoded image for, the
/// record currently playing (design section 4) the same way — its own
/// `forgetSession` releases that image and forgets which album it belongs
/// to, so a later session's first play of the very same album fetches its
/// cover again rather than finding this controller still showing an image
/// held from before.
///
/// `forgetSession` rather than `_ref.invalidate`: both controllers are
/// `Notifier`s, and invalidating one reruns its `build` on the same instance
/// rather than replacing it, so their own per-session memory would otherwise
/// survive untouched across the very reset this activity exists to perform.
/// Calling each controller's own method is what actually clears it, the same
/// way `CatalogSessionActivity` resets the catalog's own per-session state.
class PlaybackSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const PlaybackSessionActivity(this._ref);

  final Ref _ref;

  /// The cover is a picture derived from the queue, not a draft — there is
  /// nothing here an owner could lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  /// The cover belongs to the session's own window, not to the core.
  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async {
    _ref.read(albumCoverControllerProvider.notifier).forgetSession();
  }

  /// Nothing to start: this activity only has state to drop, not work to do.
  @override
  Future<void> begin() async {}
}
