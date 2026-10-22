import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/playback_session.dart';

/// The video player, as sign-out sees it (UC-03 main flow step 2).
class VideoPlaybackSession implements PlaybackSession {
  /// Creates the session over [_ref].
  const VideoPlaybackSession(this._ref);

  final Ref _ref;

  @override
  bool get isActive => _ref.read(videoPlaybackControllerProvider).isOpen;

  @override
  Future<void> stop() =>
      _ref.read(videoPlaybackControllerProvider.notifier).closeIfOpen();
}
