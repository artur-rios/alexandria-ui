import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';

/// What a group of tracks is (UC-46 main flow step 2).
enum MusicGroupKind {
  /// An artist, which drills into their albums.
  artist,

  /// An album, which drills into its tracks.
  album,
}

/// A track's title, or the word for a file whose tags carry none.
///
/// The one place an absent tag becomes a word, so the area and the search
/// results cannot disagree about what a file with no title is called — and so
/// that "never the file name" (FR-CT-13) is enforced in one function rather
/// than remembered at every call site.
String musicTitleOf(MusicEntry entry, AppLocalizations l10n) =>
    entry.title ?? l10n.musicUnknownTitle;

/// A track's artist, or the word for a file whose tags carry none.
String musicArtistOf(MusicEntry entry, AppLocalizations l10n) =>
    entry.artist ?? l10n.musicUnknownArtist;

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

        return ListTile(
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
          // Inside a record, a track plays the record from there; in Songs it
          // plays alone, because there is no record around it to continue.
          onTap: () {
            final player = ref.read(audioPlaybackControllerProvider.notifier);

            unawaited(
              numbered
                  ? player.playAlbum(entry.file)
                  : player.playTrack(entry.file),
            );
          },
        );
      },
    );
  }
}
