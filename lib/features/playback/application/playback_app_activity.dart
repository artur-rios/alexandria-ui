import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/app_activity.dart';

/// Playback's share of the application's activities.
class PlaybackAppActivity implements AppActivity {
  /// Creates the activity over [_ref].
  const PlaybackAppActivity(this._ref);

  final Ref _ref;

  /// A resume point is written as playback goes — there is nothing here an
  /// owner could lose by closing.
  @override
  bool get holdsUnsavedChanges => false;

  /// Stops whatever is playing.
  ///
  /// Closing for an update stops playback before the installer runs, so no
  /// player is still writing a resume point while the application exits.
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
