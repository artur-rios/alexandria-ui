import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../lifecycle/domain/file_hold.dart';

/// The video player, as UC-33 AF-04 sees it.
class VideoFileHold implements FileHold {
  /// Creates the hold over [_ref].
  const VideoFileHold(this._ref);

  final Ref _ref;

  @override
  bool holds(String uuid) {
    final playback = _ref.read(videoPlaybackControllerProvider);
    return playback.isOpen && playback.file?.uuid == uuid;
  }

  @override
  Future<void> release() =>
      _ref.read(videoPlaybackControllerProvider.notifier).closeIfOpen();
}
