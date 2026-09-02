import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/view_layout.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/music_layout_controller.dart';
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
    // Watched, not read: this is what starts (and keeps alive) the library
    // read behind `musicLibraryProvider`.
    final asyncLibrary = ref.watch(musicLibraryProvider);
    final browse = ref.watch(musicBrowseControllerProvider);
    final layout = ref.watch(musicLayoutControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _ViewSwitcher(selected: browse.view)),
            const _ShuffleEverythingButton(),
            _LayoutSwitcher(selected: layout),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Breadcrumb(state: browse),
        Expanded(
          child: AsyncStateView<MusicLibrary>(
            value: asyncLibrary,
            onRetry: () => ref.invalidate(musicLibraryProvider),
            isEmpty: (loaded) => loaded.entries.isEmpty,
            emptyBuilder: (context) => const _Empty(),
            builder: (context, loaded) =>
                _List(state: browse, library: loaded.entries, layout: layout),
          ),
        ),
      ],
    );
  }
}

/// Which list the area is showing, given where the owner has drilled to.
class _List extends ConsumerWidget {
  const _List({
    required this.state,
    required this.library,
    required this.layout,
  });

  final MusicBrowseState state;
  final List<MusicEntry> library;

  /// Rows or tiles, the same choice wherever the owner has drilled to: a
  /// layout that changed under them as they went into a record would be a
  /// setting they had to re-make at every level.
  final ViewLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (state) {
    MusicBrowseState(inAlbum: true) => MusicTrackList(
      entries: tracksOfAlbum(state.album, state.artist, library),
      numbered: true,
      layout: layout,
    ),
    MusicBrowseState(view: MusicView.artists, inArtist: true) => MusicGroupList(
      groups: albumsOfArtist(state.artist, library),
      kind: MusicGroupKind.album,
      layout: layout,
    ),
    MusicBrowseState(view: MusicView.artists) => MusicGroupList(
      groups: artistsIn(library),
      kind: MusicGroupKind.artist,
      layout: layout,
    ),
    MusicBrowseState(view: MusicView.albums) => MusicGroupList(
      groups: albumsIn(library),
      kind: MusicGroupKind.album,
      layout: layout,
    ),
    MusicBrowseState(view: MusicView.songs) => MusicTrackList(
      entries: songsIn(library),
      numbered: false,
      layout: layout,
    ),
  };
}

/// Rows or tiles, remembered (FR-CT-03, FR-CT-04).
class _LayoutSwitcher extends ConsumerWidget {
  const _LayoutSwitcher({required this.selected});

  final ViewLayout selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<ViewLayout>(
      segments: [
        for (final layout in MusicLayoutController.offered)
          ButtonSegment(
            value: layout,
            icon: Icon(layout.icon),
            tooltip: layout.label(l10n),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (chosen) => unawaited(
        ref.read(musicLayoutControllerProvider.notifier).choose(chosen.single),
      ),
    );
  }
}

/// Plays the whole audio library in an order nobody chose (FR-PL-06).
///
/// Beside the views rather than inside one of them: an owner who wants
/// something to play is not browsing, and making them first pick a record to
/// shuffle would be asking them the question they opened this to avoid.
class _ShuffleEverythingButton extends ConsumerWidget {
  const _ShuffleEverythingButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: l10n.audioShuffleAll,
      icon: const Icon(Icons.shuffle),
      onPressed: () => unawaited(
        ref
            .read(audioPlaybackControllerProvider.notifier)
            .playEverythingShuffled(label: l10n.audioShuffleAllLabel),
      ),
    );
  }
}

/// How each layout presents itself in the switcher.
extension _ViewLayoutPresentation on ViewLayout {
  IconData get icon => switch (this) {
    ViewLayout.list => Icons.view_list_outlined,
    ViewLayout.detailedList => Icons.view_agenda_outlined,
    ViewLayout.grid => Icons.grid_view_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ViewLayout.list => l10n.layoutList,
    ViewLayout.detailedList => l10n.layoutDetailedList,
    ViewLayout.grid => l10n.layoutGrid,
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
      // The record's artist, on both paths into a record: whose record it is
      // is a fact about the record, not about how the owner reached it, and
      // the track rows inside only name a performer where it differs from
      // this (`music_rows.dart`) — so on the Albums path, where no artist was
      // ever drilled through, this crumb is the only place an ordinary
      // record's artist is named at all.
      if (state.inArtist || state.inAlbum)
        (
          state.artist ?? l10n.musicUnknownArtist,
          // A control only where it leads somewhere the owner has been: the
          // Artists path came through this artist's own list of albums and
          // goes back to it. Reached from Albums there is no such list to
          // return to — inventing one would take the owner somewhere they
          // never were — so the name is plain text.
          state.inArtist && state.inAlbum ? controller.upToArtist : null,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
