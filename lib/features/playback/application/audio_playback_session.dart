import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/playback_session.dart';

/// The audio player, as the one-at-a-time rule sees it (UC-20 AF-05,
/// FR-PL-08).
class AudioPlaybackSession implements PlaybackSession {
  /// Creates the session over [_ref].
  const AudioPlaybackSession(this._ref);

  final Ref _ref;

  @override
  PlaybackMedium get medium => PlaybackMedium.audio;

  @override
  bool get isActive => _ref.read(audioPlaybackControllerProvider).isActive;

  @override
  Future<void> stop() =>
      _ref.read(audioPlaybackControllerProvider.notifier).stopForOtherMedium();
}
