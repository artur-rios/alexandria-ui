import 'package:flutter/material.dart';

/// The colors the players are drawn on (UC-19, UC-20, FR-UX-07).
///
/// A theme extension rather than literals in the player, because BR-18 puts
/// every color in `lib/core/theme/` and this one genuinely is not in the
/// Material scheme: a video is letterboxed against black in both brightnesses,
/// since anything lighter is what the eye reads as part of the picture.
///
/// The same in light and dark on purpose. That is the point — the surround of
/// a moving image is not a surface the theme tints.
@immutable
class PlaybackColors extends ThemeExtension<PlaybackColors> {
  /// Creates the colors.
  const PlaybackColors({required this.surround, required this.onSurround});

  /// The ground a video is letterboxed against.
  final Color surround;

  /// What is legible on top of it — the player's own messages and controls
  /// while it fills the window.
  final Color onSurround;

  /// The values both themes use.
  static const PlaybackColors standard = PlaybackColors(
    surround: Color(0xFF000000),
    onSurround: Color(0xFFF2F2F2),
  );

  @override
  PlaybackColors copyWith({Color? surround, Color? onSurround}) =>
      PlaybackColors(
        surround: surround ?? this.surround,
        onSurround: onSurround ?? this.onSurround,
      );

  @override
  PlaybackColors lerp(ThemeExtension<PlaybackColors>? other, double t) {
    if (other is! PlaybackColors) return this;

    return PlaybackColors(
      surround: Color.lerp(surround, other.surround, t) ?? surround,
      onSurround: Color.lerp(onSurround, other.onSurround, t) ?? onSurround,
    );
  }
}

/// Reads the playback colors from [context].
extension PlaybackColorsOf on BuildContext {
  /// The playback colors the active theme carries.
  PlaybackColors get playbackColors =>
      Theme.of(this).extension<PlaybackColors>() ?? PlaybackColors.standard;
}
