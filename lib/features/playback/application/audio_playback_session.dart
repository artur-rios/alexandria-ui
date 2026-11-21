import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../lifecycle/domain/file_hold.dart';
import '../domain/playback_session.dart';

/// The music playing in the player bar, which sign-out stops (UC-03).
class AudioPlaybackSession implements PlaybackSession {
  /// Creates the session over [_ref].
  const AudioPlaybackSession(this._ref);

  final Ref _ref;

  @override
  bool get isActive => _ref.read(audioPlaybackControllerProvider).isLoaded;

  @override
  Future<void> stop() =>
      _ref.read(audioPlaybackControllerProvider.notifier).stop();
}

/// The track the player bar has loaded, which a delete or a rename must let
/// go of first, as the video player's file is.
class AudioFileHold implements FileHold {
  /// Creates the hold over [_ref].
  const AudioFileHold(this._ref);

  final Ref _ref;

  @override
  bool holds(String uuid) =>
      _ref.read(audioPlaybackControllerProvider).current?.uuid == uuid;

  @override
  Future<void> release() =>
      _ref.read(audioPlaybackControllerProvider.notifier).stop();
}
