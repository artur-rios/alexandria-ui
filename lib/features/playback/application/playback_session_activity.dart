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
/// same way the first session's first play did (Finding 4). Invalidating
/// disposes the controller and lets it rebuild from empty on the next read,
/// exactly as `CatalogSessionActivity` already resets the catalog's own
/// per-session state.
class PlaybackSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const PlaybackSessionActivity(this._ref);

  final Ref _ref;

  /// The animation is a display choice derived from the queue, not a draft —
  /// there is nothing here an owner could lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  /// The animation belongs to the session's own window, not to the core.
  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async {
    _ref.invalidate(albumAnimationControllerProvider);
  }
}
