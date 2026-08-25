import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/music_browse_controller.dart';
import '../application/music_library_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';
import 'music_display_name.dart';
import 'music_rows.dart';

/// The music area (UC-46, FR-CT-13).
///
/// Audio does not use the catalog listing. A listing shows one row per file
/// named by its name on disk, and for music that is the one thing an owner
/// never wants to read: the catalog holds the title, the artist and the album
/// for every one of these files. This area shows those instead, and the file
/// name appears nowhere in it.
class MusicLibraryView extends ConsumerWidget {
  /// Creates the area.
  const MusicLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: this is what starts (and keeps alive) the full-
    // library read behind `musicLibraryProvider`. Its `.future` resolves only
    // once every file has been read — which is what a track queue is built
    // from (`AudioPlaybackController._playGrouped`) — so this area must not
    // wait on it for its own rendering, or the screen would stay blank until
    // the last file was read. `musicLibraryProgressProvider` is published to
    // from inside that same read, one file at a time, and is what the rows
    // and the progress line below are drawn from instead.
    final asyncLibrary = ref.watch(musicLibraryProvider);
    final progress = ref.watch(musicLibraryProgressProvider);
    final browse = ref.watch(musicBrowseControllerProvider);

    // Until the listing itself has come back, there is no `total` yet to
    // tell "nothing catalogued" apart from "still finding out" — so the
    // ordinary loading state covers that gap. Once a file has been read (or
    // the listing answered empty), `progress` is authoritative even if the
    // underlying read is still running, or stuck on one file forever (a music
    // library test represents that with a call that never completes).
    final gate = switch (asyncLibrary) {
      AsyncError() => asyncLibrary,
      AsyncLoading() when progress.total == 0 => asyncLibrary,
      _ => AsyncData(progress),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ViewSwitcher(selected: browse.view),
        const SizedBox(height: AppSpacing.sm),
        _Breadcrumb(state: browse),
        Expanded(
          child: AsyncStateView<MusicLibrary>(
            value: gate,
            // Both halves of the pair, as `CatalogSessionActivity.end` does:
            // the progress provider is never awaited on its own, so
            // invalidating only the complete one would leave it re-serving
            // the failed run's last snapshot and the area would never show
            // as loading again.
            onRetry: () {
              ref.invalidate(musicLibraryProvider);
              ref.invalidate(musicLibraryProgressProvider);
            },
            isEmpty: (loaded) => loaded.total == 0,
            emptyBuilder: (context) => const _Empty(),
            builder: (context, loaded) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Named rather than shown as a bar: the owner wants to know
                // this will end and roughly when, which a count says and a
                // spinner does not.
                if (!loaded.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _Progress(library: loaded),
                  ),
                Expanded(child: _List(state: browse, library: loaded.entries)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Which list the area is showing, given where the owner has drilled to.
class _List extends ConsumerWidget {
  const _List({required this.state, required this.library});

  final MusicBrowseState state;
  final List<MusicEntry> library;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (state) {
    MusicBrowseState(inAlbum: true) => MusicTrackList(
      entries: tracksOfAlbum(state.album, state.artist, library),
      numbered: true,
    ),
    MusicBrowseState(view: MusicView.artists, inArtist: true) =>
      MusicGroupList(
        groups: albumsOfArtist(state.artist, library),
        kind: MusicGroupKind.album,
      ),
    MusicBrowseState(view: MusicView.artists) => MusicGroupList(
      groups: artistsIn(library),
      kind: MusicGroupKind.artist,
    ),
    MusicBrowseState(view: MusicView.albums) => MusicGroupList(
      groups: albumsIn(library),
      kind: MusicGroupKind.album,
    ),
    MusicBrowseState(view: MusicView.songs) => MusicTrackList(
      entries: songsIn(library),
      numbered: false,
    ),
  };
}

/// The three views (main flow step 2).
class _ViewSwitcher extends ConsumerWidget {
  const _ViewSwitcher({required this.selected});

  final MusicView selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<MusicView>(
        segments: [
          for (final view in MusicView.values)
            ButtonSegment(value: view, label: Text(view.label(l10n))),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => ref
            .read(musicBrowseControllerProvider.notifier)
            .show(chosen.single),
      ),
    );
  }
}

/// How far in the owner is, and the way back out (main flow step 3).
class _Breadcrumb extends ConsumerWidget {
  const _Breadcrumb({required this.state});

  final MusicBrowseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(musicBrowseControllerProvider.notifier);

    final crumbs = <(String, VoidCallback?)>[
      (
        l10n.musicBreadcrumbRoot,
        state.inArtist || state.inAlbum ? controller.upToArtists : null,
      ),
      if (state.inArtist)
        (
          state.artist ?? l10n.musicUnknownArtist,
          state.inAlbum ? controller.upToArtist : null,
        ),
      if (state.inAlbum) (state.album ?? l10n.musicUnknownAlbum, null),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (final (index, (label, onTap)) in crumbs.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Text('›', style: theme.textTheme.bodySmall),
              ),
            // The last crumb is where the owner already is, so it is text
            // rather than a control that would do nothing.
            if (onTap == null)
              Text(label, style: theme.textTheme.bodySmall)
            else
              TextButton(onPressed: onTap, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

/// How far the metadata read has got (main flow step 1).
class _Progress extends StatelessWidget {
  const _Progress({required this.library});

  final MusicLibrary library;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Text(
      l10n.musicLoading(library.entries.length, library.total),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Nothing is catalogued (AF-03).
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Text(
        l10n.musicEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// How each view names itself.
extension on MusicView {
  String label(AppLocalizations l10n) => switch (this) {
    MusicView.artists => l10n.musicViewArtists,
    MusicView.albums => l10n.musicViewAlbums,
    MusicView.songs => l10n.musicViewSongs,
  };
}
