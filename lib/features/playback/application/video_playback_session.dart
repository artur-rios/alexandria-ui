import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/playback_session.dart';

/// The video player, as the one-at-a-time rule sees it (UC-19 AF-05,
/// FR-PL-08).
class VideoPlaybackSession implements PlaybackSession {
  /// Creates the session over [_ref].
  const VideoPlaybackSession(this._ref);

  final Ref _ref;

  @override
  PlaybackMedium get medium => PlaybackMedium.video;

  @override
  bool get isActive => _ref.read(videoPlaybackControllerProvider).isOpen;

  @override
  Future<void> stop() =>
      _ref.read(videoPlaybackControllerProvider.notifier).stopForOtherMedium();
}
