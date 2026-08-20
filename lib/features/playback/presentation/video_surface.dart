import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/playback_colors.dart';

/// Where the decoded frames are drawn (FR-PL-01).
///
/// The surface itself belongs to the engine, and the engine is a native
/// library no widget test can load. So the widget that draws it is bound in
/// the composition root like every other outward dependency: the application
/// binds media_kit's, and a test binds a placeholder and still exercises every
/// control around it.
class VideoSurface extends ConsumerWidget {
  /// Creates the surface.
  const VideoSurface({required this.isFullScreen, super.key});

  /// Whether the surface fills the window (FR-PL-02).
  final bool isFullScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ColoredBox(
    color: context.playbackColors.surround,
    child: SizedBox.expand(child: ref.watch(videoSurfaceProvider)(context)),
  );
}
