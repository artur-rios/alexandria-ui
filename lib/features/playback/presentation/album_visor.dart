import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/album_cover.dart';
import 'now_playing_screen.dart';

/// The album's own cover in the playback bar (UC-21, FR-UX-01).
///
/// It used to be a window with a record turning behind it, and before that a
/// window with a record turning behind it *and* a cover when there was one.
/// The turning medium is gone from the whole application now: a drawn record
/// is the same drawing for every album ever played — it says something is on,
/// and nothing whatever about *which* record. The sleeve is what an owner
/// recognises at a glance across a room, which is precisely what a bar that
/// is on screen all session is for.
///
/// Pressing it opens the player, because a sleeve in a bar is the thing an
/// owner reaches for when they want to see what is playing.
class AlbumVisor extends ConsumerWidget {
  /// Creates the visor.
  const AlbumVisor({this.size = defaultSize, super.key});

  /// [size]'s own default — `PlaybackBar.height` derives its own room for the
  /// visor from this rather than a second, hardcoded copy of the same number.
  static const double defaultSize = 64;

  /// How wide and tall the sleeve is drawn, as a square.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cover = switch (ref.watch(albumCoverControllerProvider)) {
      AlbumCoverFetched(:final image) => image,
      AlbumCoverDesigned() => null,
    };

    return Semantics(
      button: true,
      image: true,
      label: l10n.albumCoverLabel,
      child: GestureDetector(
        onTap: () => unawaited(NowPlayingScreen.show(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.12),
          child: SizedBox.square(
            dimension: size,
            child: _Sleeve(cover: cover, theme: theme),
          ),
        ),
      ),
    );
  }
}

/// The picture, or what stands in for one until it arrives.
class _Sleeve extends StatelessWidget {
  const _Sleeve({required this.cover, required this.theme});

  final ui.Image? cover;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => cover == null
      ? ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.album_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      : RawImage(image: cover, fit: BoxFit.cover);
}
