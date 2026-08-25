import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../catalog/presentation/music_metadata_form.dart';
import '../application/audio_playback_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';

/// What a group of tracks is (UC-46 main flow step 2).
enum MusicGroupKind {
  /// An artist, which drills into their albums.
  artist,

  /// An album, which drills into its tracks.
  album,
}

/// A tag, trimmed, or [whenAbsent] for a file whose tags carry none.
///
/// The one place a blank or absent tag becomes a word, so nothing that names
/// a track — a [MusicEntry]'s own title or artist, or a search result reading
/// a fetched [MusicMetadata] before a [MusicEntry] exists for it — has to
/// remember the rule itself. That is what keeps "never the file name"
/// (FR-CT-13) one rule instead of one remembered at every call site.
String tagOr(String? value, String whenAbsent) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? whenAbsent : trimmed;
}

/// A track's title, or the word for a file whose tags carry none.
String musicTitleOf(MusicEntry entry, AppLocalizations l10n) =>
    tagOr(entry.metadata.title, l10n.musicUnknownTitle);

/// A track's artist, or the word for a file whose tags carry none.
String musicArtistOf(MusicEntry entry, AppLocalizations l10n) =>
    tagOr(entry.metadata.artist, l10n.musicUnknownArtist);

/// A group's name, or the word for the files that name none.
String musicGroupName(
  MusicGroup group,
  AppLocalizations l10n, {
  required MusicGroupKind kind,
}) =>
    group.name ??
    switch (kind) {
      MusicGroupKind.artist => l10n.musicUnknownArtist,
      MusicGroupKind.album => l10n.musicUnknownAlbum,
    };

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
        final artist = group.entries.first.artist;

        return ListTile(
          leading: Icon(
            kind == MusicGroupKind.artist
                ? Icons.person_outline
                : Icons.album_outlined,
          ),
          title: Text(musicGroupName(group, l10n, kind: kind)),
          // An album says whose it is; an artist is already the answer to
          // that question.
          subtitle: kind == MusicGroupKind.album
              ? Text(artist ?? l10n.musicUnknownArtist)
              : null,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

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
            subtitle: numbered ? null : Text(musicArtistOf(entry, l10n)),
            // Inside a record, a track plays the record from there; in Songs
            // it plays alone, because there is no record around it to
            // continue.
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
          ),
        );
      },
    );
  }
}

/// A track's own actions (UC-46, FR-CT-14).
///
/// Right-click is what a desktop owner reaches for, and the button beside the
/// row is what makes the same five actions reachable without a right mouse
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
        MenuItemButton(
          leadingIcon: const Icon(Icons.info_outline),
          onPressed: () =>
              FileDetailsView.show(context, ref, entry.file.uuid),
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
