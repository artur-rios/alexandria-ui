import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// Playback's share of signing out (UC-03 main flow step 3, FR-AU-09).
class PlaybackSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const PlaybackSessionActivity(this._ref);

  final Ref _ref;

  /// A resume point is written as playback goes — there is nothing here an
  /// owner could lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  /// The player belongs to the session's own window, not to the core.
  @override
  bool get continuesInTheCore => false;

  /// Stops whatever is playing.
  ///
  /// Sign-out's step 2 is "stop playback" (UC-03), and this is the activity
  /// sign-out reads for it. Left running, a video went on playing with no
  /// surface at all, its dialog popped by the route guard — still writing
  /// resume points for the session that had ended.
  @override
  Future<void> end() async {
    for (final session in _ref.read(playbackSessionsProvider)) {
      if (session.isActive) await session.stop();
    }
  }

  /// Nothing to start: this activity only has work to stop, not to begin.
  @override
  Future<void> begin() async {}
}
