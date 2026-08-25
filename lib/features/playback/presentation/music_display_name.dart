import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';
import '../domain/playback_queue.dart';

/// The metadata-first naming rule and its Unknown fallbacks, in one place so
/// the views and the search results cannot disagree (FR-CT-13).
///
/// Everything here answers the same question — what does this track, artist,
/// album, or queue get called — from a [MusicEntry], a fetched
/// [MusicMetadata], or a [PlaybackQueue], and never from a file's name on
/// disk.

/// A tag, trimmed, or [whenAbsent] for a file whose tags carry none.
///
/// The one place a blank or absent tag becomes a word, so nothing that names
/// a track — a [MusicEntry]'s own title or artist, or a search result reading
/// a fetched [MusicMetadata] before a [MusicEntry] exists for it — has to
/// remember the rule itself. That is what keeps "never the file name"
/// (FR-CT-13) one rule instead of one remembered at every call site.
String tagOr(String? value, String whenAbsent) =>
    trimmedOrNull(value) ?? whenAbsent;

/// A track's title, or the word for a file whose tags carry none.
String musicTitleOf(MusicEntry entry, AppLocalizations l10n) =>
    tagOr(entry.metadata.title, l10n.musicUnknownTitle);

/// A track's artist, or the word for a file whose tags carry none.
String musicArtistOf(MusicEntry entry, AppLocalizations l10n) =>
    tagOr(entry.metadata.artist, l10n.musicUnknownArtist);

/// [file] read as a [MusicEntry], never by its name on disk (FR-CT-13).
///
/// Shared by the bar, the skip notice and the full player, so nothing that
/// names the file currently playing can disagree with what the browsing area
/// already agreed a track is called, and the file name the owner never wants
/// to see does not reappear just because the queue was built from a track the
/// progress read has not caught up to yet.
///
/// Watches [musicLibraryProvider] as well as the progress it publishes to,
/// because playback is reachable without ever opening the music area — from
/// search, from the dashboard, from a file's own details — and nothing else
/// would otherwise start the read this entry is drawn from.
MusicEntry musicEntryForFile(WidgetRef ref, CatalogFile file) {
  ref.watch(musicLibraryProvider);
  final progress = ref.watch(musicLibraryProgressProvider);

  return progress.entries.firstWhere(
    (candidate) => candidate.file.uuid == file.uuid,
    // Not yet read (or read after the caller last rebuilt): reads as
    // untitled rather than by name, which is what an entry with no title
    // does too.
    orElse: () => MusicEntry(file: file, metadata: const MusicMetadata()),
  );
}

/// [file]'s title from its metadata, never its name on disk (FR-CT-13).
String musicTitleForFile(
  WidgetRef ref,
  CatalogFile file,
  AppLocalizations l10n,
) => musicTitleOf(musicEntryForFile(ref, file), l10n);

/// [file]'s artist from its metadata, never its name on disk (FR-CT-13).
String musicArtistForFile(
  WidgetRef ref,
  CatalogFile file,
  AppLocalizations l10n,
) => musicArtistOf(musicEntryForFile(ref, file), l10n);

/// The queue's own name, or `null` when there is none to show (UC-20,
/// UC-21, FR-CT-13).
///
/// `null` for a single track: the bar and the full player already show that
/// track's own title beside this label (via [musicTitleForFile]), so
/// repeating it here would be noise rather than information, and both
/// surfaces already treat `null` as "no queue name" — the bar omits the
/// line, and the full player's title falls back to the generic one. For an
/// album or an artist, a `null` [PlaybackQueue.label] means the *tag* is
/// absent, not the queue itself, so this reads through [tagOr] to the same
/// rule an absent album or artist tag gets everywhere else.
String? queueLabelOf(PlaybackQueue queue, AppLocalizations l10n) =>
    switch (queue.kind) {
      QueueKind.track => null,
      QueueKind.album => tagOr(queue.label, l10n.musicUnknownAlbum),
      QueueKind.artist => tagOr(queue.label, l10n.musicUnknownArtist),
    };

/// What a group of tracks is (UC-46 main flow step 2).
enum MusicGroupKind {
  /// An artist, which drills into their albums.
  artist,

  /// An album, which drills into its tracks.
  album,
}

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
