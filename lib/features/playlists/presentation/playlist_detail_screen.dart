import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../playback/presentation/music_display_name.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/playlist_detail_controller.dart';
import '../domain/playlist.dart';

/// One playlist, its tracks, and their order (playlists design).
///
/// A dialog over whatever reached it, the same shape [PlaylistsScreen] uses:
/// opened on a uuid, read afresh from the core rather than trusting a copy
/// the caller already had.
class PlaylistDetailScreen extends ConsumerWidget {
  /// Creates the screen for the playlist [uuid] identifies.
  const PlaylistDetailScreen({required this.uuid, super.key});

  /// The playlist being shown.
  final String uuid;

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context, String uuid) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(child: PlaylistDetailScreen(uuid: uuid)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(playlistDetailControllerProvider(uuid));

    return Scaffold(
      appBar: AppBar(
        // Blank while the read is still in flight rather than a placeholder
        // word: the title is the one thing on this screen the core alone
        // knows, and there is nothing truer to show until it answers.
        title: Text(view.value?.playlist.name ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AsyncStateView<PlaylistView?>(
        value: view,
        onRetry: () =>
            ref.read(playlistDetailControllerProvider(uuid).notifier).reload(),
        isEmpty: (loaded) => loaded != null && loaded.entries.isEmpty,
        emptyBuilder: (context) =>
            Center(child: Text(l10n.playlistDetailEmpty)),
        builder: (context, loaded) => loaded == null
            ? const SizedBox.shrink()
            : _EntryList(playlistUuid: uuid, view: loaded),
      ),
    );
  }
}

/// The playlist's tracks, in the order the core sent them, reorderable.
///
/// Rendered from [view.entries] as read, never re-sorted and never patched
/// locally after a move — the core answers the full new order on every write,
/// and this always shows exactly that (BR-02, playlists design section 3).
class _EntryList extends ConsumerWidget {
  const _EntryList({required this.playlistUuid, required this.view});

  final String playlistUuid;
  final PlaylistView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = view.entries;

    return ReorderableListView.builder(
      itemCount: entries.length,
      // `onReorder`, not the newer `onReorderItem`: the newer callback already
      // pre-adjusts `newIndex` (it applies exactly the `newIndex -= 1`
      // correction below internally), which would silently double-correct
      // through [reorderDestinationIndex] and land a downward drag one short.
      // Staying on the raw, undoctored index is what keeps the conversion the
      // single place this is handled, exactly as the design requires — hence
      // the deliberate `ignore` rather than migrating off it.
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        final entry = entries[oldIndex];
        final toIndex = reorderDestinationIndex(
          oldIndex: oldIndex,
          newIndex: newIndex,
        );

        unawaited(
          ref
              .read(playlistDetailControllerProvider(playlistUuid).notifier)
              .moveEntry(entryUuid: entry.uuid, toIndex: toIndex),
        );
      },
      itemBuilder: (context, index) => _EntryTile(
        key: ValueKey(entries[index].uuid),
        playlistUuid: playlistUuid,
        entry: entries[index],
        index: index,
      ),
    );
  }
}

/// One track. Greyed and kept, never hidden, when its file is missing
/// (playlists design section 5).
class _EntryTile extends ConsumerWidget {
  const _EntryTile({
    required this.playlistUuid,
    required this.entry,
    required this.index,
    super.key,
  });

  final String playlistUuid;
  final PlaylistEntry entry;

  /// This tile's position in the currently rendered list, which is what
  /// [ReorderableDragStartListener] needs to report a drag — not
  /// [PlaylistEntry.position], which is the core's own bookkeeping and is not
  /// guaranteed to be a dense 0-based Flutter list index in every state this
  /// tile could ever render in.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // FR-CT-13: named by metadata, never by the file on disk.
    final title = tagOr(entry.metadata?.title, l10n.musicUnknownTitle);
    final artist = tagOr(entry.metadata?.artist, l10n.musicUnknownArtist);

    return ListTile(
      // A disabled ListTile reads its text and icon colours from the theme's
      // own disabled colour (BR-18 / FR-UX-07): "greyed" is a fact about this
      // widget's enabled state, never a colour literal chosen here.
      enabled: !entry.missing,
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Text(title),
      subtitle: Text(entry.missing ? l10n.detailsStateMissing : artist),
      trailing: IconButton(
        tooltip: l10n.playlistRemoveTrack,
        icon: const Icon(Icons.close),
        onPressed: () => unawaited(
          ref
              .read(playlistDetailControllerProvider(playlistUuid).notifier)
              .removeEntry(entry.uuid),
        ),
      ),
    );
  }
}
