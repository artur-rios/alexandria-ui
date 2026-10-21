import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/view_layout.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../catalog/presentation/music_metadata_form.dart';
import '../../playlists/presentation/add_to_playlist_button.dart';
import '../application/audio_playback_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';
import 'music_display_name.dart';

/// The artists, or the albums (UC-46 main flow step 2).
///
/// Rows or tiles, as the owner has asked (FR-CT-03). These are the two views
/// with a picture apiece, and a wall of faces or sleeves is how a shelf of
/// records is actually read; the rows stay because they hold more per screen
/// and say whose a record is in words.
class MusicGroupList extends ConsumerWidget {
  /// Creates the list.
  const MusicGroupList({
    required this.groups,
    required this.kind,
    this.layout = ViewLayout.list,
    super.key,
  });

  /// What to show.
  final List<MusicGroup> groups;

  /// Whether these are artists or albums.
  final MusicGroupKind kind;

  /// Rows or tiles.
  final ViewLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (layout) {
    ViewLayout.grid => _GroupGrid(groups: groups, kind: kind),
    // A detailed list is a listing's way of showing a path, and neither an
    // artist nor a record has one, so it draws as the plain list rather than
    // as something this area never offered.
    _ => _GroupRows(groups: groups, kind: kind),
  };
}

/// The rows.
///
/// A builder rather than a column: FR-CT-10 asks that scrolling cost not grow
/// with the size of the library, and that applies to a list of albums exactly
/// as it applies to a list of files.
class _GroupRows extends ConsumerWidget {
  const _GroupRows({required this.groups, required this.kind});

  final List<MusicGroup> groups;
  final MusicGroupKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(musicBrowseControllerProvider.notifier);

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        // Only an album row needs whose it is — an artist row already is
        // the answer to that question, and does not read this.
        //
        // The album's artist, not the first track's performer: it is what
        // `albumsIn` grouped the record by, so it is what `tracksOfAlbum`
        // has to be drilled in with — a compilation drilled in by one
        // performer would open on a record of one track.
        final artist = kind == MusicGroupKind.album
            ? group.entries.first.albumArtist
            : null;

        return ListTile(
          leading: kind == MusicGroupKind.artist
              ? const _ArtistPortrait(diameter: 40)
              // And a record is shown as its sleeve, for the same reason: a
              // generic disc glyph says an album is an album, where the
              // sleeve says which one.
              : _AlbumArt(fileUuid: _representative(group)),
          title: Text(musicGroupName(group, l10n, kind: kind)),
          // An album says whose it is; an artist is already the answer to
          // that question.
          subtitle: kind == MusicGroupKind.album
              ? Text(artist ?? l10n.musicUnknownArtist)
              : null,
          // Task 5 entry point 2: every track the group holds. An album row's
          // own `group.entries` is already track-ordered (`_inTrackOrder`),
          // so an album is added in the order the record itself is in. An
          // artist row's `group.entries` is not: `artistsIn` groups it with
          // the same `_inTrackOrder`, which sorts by track number alone —
          // with no album key, so two records interleave track-for-track
          // rather than playing one after the other. `inArtistOrder` is the
          // album-then-track sort that matches what "Play artist" queues and
          // what drilling into the artist's own albums shows.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShuffleButton(group: group, kind: kind),
              AddToPlaylistButton(
                fileUuids: kind == MusicGroupKind.artist
                    ? [
                        for (final file in inArtistOrder(group.entries))
                          file.uuid,
                      ]
                    : [for (final entry in group.entries) entry.file.uuid],
                tooltip: kind == MusicGroupKind.album
                    ? l10n.playlistAddAlbumTo
                    : l10n.playlistAddArtistTo,
              ),
            ],
          ),
          // Drilling in rather than playing: playing a whole artist or record
          // is on the submenu, where it is a decision rather than something a
          // mis-aimed click does.
          onTap: () => kind == MusicGroupKind.artist
              ? controller.openArtist(group.name)
              : controller.openAlbum(group.name, artist),
        );
      },
    );
  }
}

/// The track whose tags a group's picture is taken from, if it has any.
String? _representative(MusicGroup group) =>
    group.entries.isEmpty ? null : group.entries.first.file.uuid;

/// The tiles (FR-CT-03, FR-CT-10).
///
/// The picture is the tile: an owner scanning for a record is scanning for a
/// sleeve they would recognise across a room, and a name under it is the
/// caption, not the subject. A builder here too, for the same reason the rows
/// are one.
class _GroupGrid extends ConsumerWidget {
  const _GroupGrid({required this.groups, required this.kind});

  final List<MusicGroup> groups;
  final MusicGroupKind kind;

  /// How wide a tile may grow before the grid takes another column.
  ///
  /// Wider than a file tile's: this one is carrying a picture meant to be
  /// recognised, where that one carries a glyph and a file name.
  static const double _extent = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(musicBrowseControllerProvider.notifier);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _extent,
        // Taller than it is wide: the picture is square, and the caption and
        // its controls live in what is left.
        childAspectRatio: 3 / 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final artist = kind == MusicGroupKind.album
            ? group.entries.first.albumArtist
            : null;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => kind == MusicGroupKind.artist
                ? controller.openArtist(group.name)
                : controller.openAlbum(group.name, artist),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    // Laid out by what the tile is given rather than by a
                    // fixed size: the grid's columns change with the width of
                    // the window, and a picture that ignored that would
                    // either overflow the narrow case or float in the wide
                    // one.
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = constraints.biggest.shortestSide;

                        return kind == MusicGroupKind.artist
                            ? _ArtistPortrait(diameter: side)
                            : _AlbumArt(
                                fileUuid: _representative(group),
                                side: side,
                              );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    musicGroupName(group, l10n, kind: kind),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (kind == MusicGroupKind.album)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      artist ?? l10n.musicUnknownArtist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // The same two controls the row carries, so choosing tiles
                // costs the owner nothing they could do with rows.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ShuffleButton(group: group, kind: kind),
                    AddToPlaylistButton(
                      fileUuids: kind == MusicGroupKind.artist
                          ? [
                              for (final file in inArtistOrder(group.entries))
                                file.uuid,
                            ]
                          : [
                              for (final entry in group.entries)
                                entry.file.uuid,
                            ],
                      tooltip: kind == MusicGroupKind.album
                          ? l10n.playlistAddAlbumTo
                          : l10n.playlistAddArtistTo,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The sleeve embedded in a track's tags, or the glyph that stands in for one
/// (UC-46).
///
/// The picture comes from the core's thumbnail of the file — the same one the
/// player shows — and is read, never fetched over a network: it is a file this
/// machine already holds, cached on disk after the first read.
///
/// Keyed by a file rather than by a record, because that is where a picture
/// actually lives. A record's tile passes any one of its tracks: a picture
/// belongs to a file's tag, and the record is a grouping this application
/// made.
class _AlbumArt extends ConsumerWidget {
  const _AlbumArt({required this.fileUuid, this.side = 40});

  final String? fileUuid;

  /// The size of the square.
  ///
  /// Defaults to the size of the icon a `ListTile` would otherwise lead with,
  /// so rows keep their height whether a sleeve was found or not.
  final double side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = SizedBox(
      width: side,
      height: side,
      child: FittedBox(child: Icon(Icons.album_outlined, size: side)),
    );

    final uuid = fileUuid;
    if (uuid == null) return fallback;

    final art = ref.watch(albumArtControllerProvider(uuid)).value;
    if (art == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: SizedBox.square(
        dimension: side,
        child: RawImage(image: art, fit: BoxFit.cover),
      ),
    );
  }
}

/// Plays a record or an artist in an order nobody chose (FR-PL-06).
///
/// On the row itself rather than only in a menu: shuffling a record is a
/// thing owners do constantly, and a control they have to go looking for is
/// one they stop using.
class _ShuffleButton extends ConsumerWidget {
  const _ShuffleButton({required this.group, required this.kind});

  final MusicGroup group;
  final MusicGroupKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (group.entries.isEmpty) return const SizedBox.shrink();

    final first = group.entries.first.file;

    return IconButton(
      tooltip: kind == MusicGroupKind.album
          ? l10n.audioShuffleAlbum
          : l10n.audioShuffleArtist,
      icon: const Icon(Icons.shuffle),
      // The same gathering "play album" does, in a different order: the queue
      // is the record (or the artist's whole catalogue), never the one track
      // this button happens to have in hand.
      onPressed: () {
        final player = ref.read(audioPlaybackControllerProvider.notifier);

        unawaited(
          kind == MusicGroupKind.album
              ? player.playAlbum(first, shuffled: true)
              : player.playArtist(first, shuffled: true),
        );
      },
    );
  }
}

/// The icon that stands in for an artist's face.
class _ArtistPortrait extends StatelessWidget {
  const _ArtistPortrait({required this.diameter});

  /// The size of the icon.
  ///
  /// A row asks for the size of the icon a `ListTile` would otherwise lead
  /// with; a tile asks for a much larger one, which is what a grid is for.
  final double diameter;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: diameter,
    height: diameter,
    child: FittedBox(child: Icon(Icons.person_outline, size: diameter)),
  );
}

/// The tracks (UC-46 main flow step 3).
class MusicTrackList extends ConsumerWidget {
  /// Creates the list.
  const MusicTrackList({
    required this.entries,
    required this.numbered,
    this.layout = ViewLayout.list,
    super.key,
  });

  /// The tracks to show, already in the order they belong in.
  final List<MusicEntry> entries;

  /// Whether each row leads with its track number.
  ///
  /// True inside an album, where the number is what orders the record; false
  /// in Songs, where the list spans the library and a number belonging to some
  /// other record would say nothing.
  final bool numbered;

  /// Rows or tiles.
  final ViewLayout layout;

  /// The performer to put under a row's title, or `null` for a row that
  /// names none.
  ///
  /// In Songs the performer is always shown: the list spans the library, and
  /// a title alone does not say whose track it is.
  ///
  /// Inside an album it is shown only where it differs from the record's own
  /// artist — which is what a compilation is: twelve performers under one
  /// album artist, and the whole point of grouping by the album artist is
  /// that their names are still worth reading. On an ordinary single-artist
  /// record the same name under all twelve rows would be noise, so it is left
  /// off — the record's own artist is named in the breadcrumb above the list
  /// on both paths into a record (`music_library_view.dart`), so leaving it
  /// off a row does not take it off the screen. A track whose tags name no
  /// performer shows nothing rather than "Unknown artist", for the same
  /// reason: the crumb has already answered whose record this is, and a row
  /// that only says "unknown" adds nothing to it.
  String? _performerOf(MusicEntry entry, AppLocalizations l10n) {
    if (!numbered) return musicArtistOf(entry, l10n);

    final performer = entry.artist;

    return performer == null || performer == entry.albumArtist
        ? null
        : performer;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (layout == ViewLayout.grid) return _grid(context, ref, l10n);

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final performer = _performerOf(entry, l10n);

        return MusicRowMenu(
          entry: entry,
          child: ListTile(
            leading: numbered
                ? SizedBox(
                    width: AppSpacing.xl,
                    child: Text(
                      entry.metadata.track?.toString() ?? '',
                      textAlign: TextAlign.end,
                    ),
                  )
                : const Icon(Icons.music_note_outlined),
            title: Text(musicTitleOf(entry, l10n)),
            subtitle: performer == null ? null : Text(performer),
            // Inside a record, a track plays the record from there; in Songs
            // it plays alone, because there is no record around it to
            // continue.
            onTap: () {
              final player = ref.read(audioPlaybackControllerProvider.notifier);

              unawaited(
                numbered
                    ? player.playAlbum(entry.file)
                    : player.playTrack(entry.file),
              );
            },
          ),
        );
      },
    );
  }

  /// The same tracks as sleeves (FR-CT-03).
  ///
  /// A track's picture is its record's, so a screen of tiles reads as the
  /// records the tracks came from — which is exactly what it is useful for,
  /// and why the title stays under the picture rather than replacing it.
  Widget _grid(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 3 / 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final performer = _performerOf(entry, l10n);

        return MusicRowMenu(
          entry: entry,
          overlaid: true,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final player = ref.read(
                  audioPlaybackControllerProvider.notifier,
                );

                unawaited(
                  numbered
                      ? player.playAlbum(entry.file)
                      : player.playTrack(entry.file),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) => _AlbumArt(
                          fileUuid: entry.file.uuid,
                          side: constraints.biggest.shortestSide,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musicTitleOf(entry, l10n),
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (performer != null)
                          Text(
                            performer,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A track's own actions (UC-46, FR-CT-14).
///
/// Right-click is what a desktop owner reaches for, and the button beside the
/// row is what makes the same six actions reachable without a right mouse
/// button and from the keyboard. Both open the one menu, so there is no second
/// list of actions to keep in step.
class MusicRowMenu extends ConsumerWidget {
  /// Creates the wrapper.
  const MusicRowMenu({
    required this.entry,
    required this.child,
    this.overlaid = false,
    super.key,
  });

  /// The track the menu acts on.
  final MusicEntry entry;

  /// The row itself.
  final Widget child;

  /// Whether the button sits over [child] rather than beside it.
  ///
  /// Beside it is right for a row, which has width to spare and a fixed
  /// height. A tile has neither: a button in a column of its own would
  /// squeeze the picture the tile exists to show, so there it sits in the
  /// corner, over the artwork.
  final bool overlaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.play_arrow),
          onPressed: () => _play(ref, (player) => player.playTrack(entry.file)),
          child: Text(l10n.audioPlay),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.album_outlined),
          onPressed: () => _play(ref, (player) => player.playAlbum(entry.file)),
          child: Text(l10n.audioPlayAlbum),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: () =>
              _play(ref, (player) => player.playArtist(entry.file)),
          child: Text(l10n.audioPlayArtist),
        ),
        // The same two queues in an order nobody chose (FR-PL-06). Under the
        // plays they shuffle, so the pair reads as one decision — which
        // record, then in what order.
        MenuItemButton(
          leadingIcon: const Icon(Icons.shuffle),
          onPressed: () => _play(
            ref,
            (player) => player.playAlbum(entry.file, shuffled: true),
          ),
          child: Text(l10n.audioShuffleAlbum),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.shuffle_on_outlined),
          onPressed: () => _play(
            ref,
            (player) => player.playArtist(entry.file, shuffled: true),
          ),
          child: Text(l10n.audioShuffleArtist),
        ),
        // Task 5 entry point 1: the one track this row is, addressed by its
        // own file uuid — never the album or artist it belongs to. Called
        // with this row's own `context` and `ref`, not built as a menu-item
        // widget of its own — see `addToPlaylistMenu`'s own doc.
        addToPlaylistMenu(context, ref, fileUuids: [entry.file.uuid]),
        MenuItemButton(
          leadingIcon: const Icon(Icons.info_outline),
          onPressed: () => FileDetailsView.show(context, ref, entry.file.uuid),
          child: Text(l10n.detailsTitle),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => MusicMetadataForm.showFor(
            context,
            ref,
            entry.file.uuid,
            entry.metadata,
          ),
          child: Text(l10n.detailsEditMetadata),
        ),
      ],
      builder: (context, controller, _) {
        final button = IconButton(
          tooltip: l10n.musicRowActions,
          icon: const Icon(Icons.more_vert),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );

        return GestureDetector(
          onSecondaryTapDown: (details) =>
              controller.open(position: details.localPosition),
          child: overlaid
              ? Stack(
                  children: [
                    Positioned.fill(child: child),
                    Positioned(top: 0, right: 0, child: button),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: child),
                    button,
                  ],
                ),
        );
      },
    );
  }

  void _play(
    WidgetRef ref,
    Future<void> Function(AudioPlaybackController player) play,
  ) => unawaited(play(ref.read(audioPlaybackControllerProvider.notifier)));
}
