import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../enrichment/application/artist_portrait_backfill_controller.dart';
import '../../catalog/presentation/music_metadata_form.dart';
import '../../playlists/presentation/add_to_playlist_button.dart';
import '../application/audio_playback_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';
import 'music_display_name.dart';

/// The artists, or the albums (UC-46 main flow step 2).
///
/// A builder rather than a column: FR-CT-10 asks that scrolling cost not grow
/// with the size of the library, and that applies to a list of albums exactly
/// as it applies to a list of files.
class MusicGroupList extends ConsumerWidget {
  /// Creates the list.
  const MusicGroupList({required this.groups, required this.kind, super.key});

  /// What to show.
  final List<MusicGroup> groups;

  /// Whether these are artists or albums.
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
          // An artist is shown as a face where enrichment has found one
          // (music enrichment design). The photographs used to appear over
          // the lyrics of whatever was playing, which is the one place an
          // owner is not looking for artists — here they are what the list
          // is *of*, and a column of faces is how a shelf of records reads.
          leading: kind == MusicGroupKind.artist
              ? _ArtistPortrait(group: group)
              : const Icon(Icons.album_outlined),
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
          trailing: AddToPlaylistButton(
            fileUuids: kind == MusicGroupKind.artist
                ? [for (final file in inArtistOrder(group.entries)) file.uuid]
                : [for (final entry in group.entries) entry.file.uuid],
            tooltip: kind == MusicGroupKind.album
                ? l10n.playlistAddAlbumTo
                : l10n.playlistAddArtistTo,
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

/// The photograph enrichment cached for an artist, or the icon that stands in
/// for one (music enrichment design).
///
/// Read, never fetched. A list of artists is a screenful of rows, and looking
/// each one up as it scrolled past would be dozens of provider calls a second
/// against services that rate-limit to one — so this shows what a lookup has
/// already found, and the lookups themselves stay where the owner asks for
/// them (the lyrics button, and the enrichment sweep). A library nobody has
/// enriched looks exactly as it did before, which is the honest state of it.
///
/// Keyed by a representative track rather than by the artist: the core reads
/// enrichment per file, and every file of an artist row answers with the same
/// artist. The first is as good as any.
class _ArtistPortrait extends ConsumerWidget {
  const _ArtistPortrait({required this.group});

  final MusicGroup group;

  /// The size of the circle, matching the icon a `ListTile` would otherwise
  /// lead with so rows keep their height whether a face was found or not.
  static const double _diameter = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fallback = SizedBox(
      width: _diameter,
      height: _diameter,
      child: Icon(Icons.person_outline),
    );

    // The untagged group is not an artist at all — it is the files that name
    // none — so there is nobody to have a photograph of.
    // The same key the startup pass fills, from the one function that
    // decides it: a row looking under a different track than the pass wrote
    // under would show nothing however much was fetched.
    final key = artistPortraitKeyFor(group);
    if (key == null) return fallback;

    final enrichment = ref.watch(trackEnrichmentControllerProvider(key));

    final image = enrichment.value?.artistImage;
    if (image == null) return fallback;

    return ClipOval(
      child: Image.file(
        File(image.path),
        width: _diameter,
        height: _diameter,
        fit: BoxFit.cover,
        // The bytes are a cache the core wrote, and a cache can be cleared,
        // moved, or half-written. A missing or unreadable file falls back to
        // the icon rather than to Flutter's broken-image glyph, which would
        // read as a defect in the application rather than as a picture that
        // is simply not there any more.
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

/// The tracks (UC-46 main flow step 3).
class MusicTrackList extends ConsumerWidget {
  /// Creates the list.
  const MusicTrackList({
    required this.entries,
    required this.numbered,
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
}

/// A track's own actions (UC-46, FR-CT-14).
///
/// Right-click is what a desktop owner reaches for, and the button beside the
/// row is what makes the same six actions reachable without a right mouse
/// button and from the keyboard. Both open the one menu, so there is no second
/// list of actions to keep in step.
class MusicRowMenu extends ConsumerWidget {
  /// Creates the wrapper.
  const MusicRowMenu({required this.entry, required this.child, super.key});

  /// The track the menu acts on.
  final MusicEntry entry;

  /// The row itself.
  final Widget child;

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
      builder: (context, controller, _) => GestureDetector(
        onSecondaryTapDown: (details) =>
            controller.open(position: details.localPosition),
        child: Row(
          children: [
            Expanded(child: child),
            IconButton(
              tooltip: l10n.musicRowActions,
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ],
        ),
      ),
    );
  }

  void _play(
    WidgetRef ref,
    Future<void> Function(AudioPlaybackController player) play,
  ) => unawaited(play(ref.read(audioPlaybackControllerProvider.notifier)));
}
