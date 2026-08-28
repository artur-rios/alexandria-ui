import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import 'playlists_screen.dart';

/// The value [AddToPlaylistButton] and [addToPlaylistMenu] select to open
/// [PlaylistsScreen] instead of adding anywhere, when there is nowhere yet to
/// add to.
///
/// A leading `\u0000` cannot appear in a real playlist uuid the core
/// mints, so this sentinel can never collide with one.
const _createPlaylistValue = '\u0000create-playlist';

/// Sends [selection] to the core, or opens [PlaylistsScreen] to make a
/// playlist first (playlists design; UC-46; FR-PL-07).
///
/// One call for the whole of [fileUuids], never one per track (BR-02): the
/// core's own `addEntries` takes the whole batch precisely so an album either
/// enters a playlist whole or not at all. Nothing here filters or dedupes the
/// list first — a track already in the playlist is added again, exactly as
/// the core allows, because that decision belongs to the core alone.
Future<void> _addTo(
  BuildContext context,
  WidgetRef ref,
  String selection,
  List<String> fileUuids,
) {
  if (selection == _createPlaylistValue) return PlaylistsScreen.show(context);

  return ref
      .read(playlistsFormProvider.notifier)
      .addEntries(playlistUuid: selection, fileUuids: fileUuids);
}

/// Adds [fileUuids] to one of the owner's playlists, from a control of its
/// own — the whole-album and whole-artist actions on the browsing views, and
/// the now-playing screen's current track (playlists design entry points 2
/// and 3).
///
/// Follows `AddToReadingListButton`'s shape: a `PopupMenuButton` listing the
/// owner's playlists, one call to the core on selection. With no playlists
/// yet, the one item offered opens [PlaylistsScreen] to make one rather than
/// showing an empty menu — a dead end no owner could act on.
class AddToPlaylistButton extends ConsumerWidget {
  /// Creates the button.
  const AddToPlaylistButton({required this.fileUuids, this.tooltip, super.key});

  /// The files to add, in the order they are to be added in.
  final List<String> fileUuids;

  /// The tooltip and menu title, or [AppLocalizations.playlistAddTo] when
  /// `null` — a caller adding a whole album or artist names that instead, so
  /// the control does not just say "add to a playlist" for an action that
  /// adds many.
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsControllerProvider).value ?? const [];

    return PopupMenuButton<String>(
      tooltip: tooltip ?? l10n.playlistAddTo,
      icon: const Icon(Icons.playlist_add),
      onSelected: (selection) =>
          unawaited(_addTo(context, ref, selection, fileUuids)),
      itemBuilder: (context) => [
        if (playlists.isEmpty)
          PopupMenuItem<String>(
            value: _createPlaylistValue,
            child: Text(l10n.playlistAddCreateOne),
          )
        else
          for (final playlist in playlists)
            PopupMenuItem<String>(value: playlist.uuid, child: Text(playlist.name)),
      ],
    );
  }
}

/// [AddToPlaylistButton]'s own logic, shaped as a nested `MenuAnchor` entry
/// instead of a `PopupMenuButton` (playlists design entry point 1).
///
/// `MusicRowMenu`'s track actions are already a `MenuAnchor` of
/// `MenuItemButton`s, and a `PopupMenuButton` cannot sit inside one as a menu
/// item — so this reaches for `SubmenuButton`, the `MenuAnchor` family's own
/// nested-menu widget, to open the same choice of playlists from inside that
/// menu rather than a second, unrelated kind of popup.
///
/// A function, not its own `ConsumerWidget`: a `MenuItemButton`'s own
/// `onPressed` fires only after the menu holding it has already closed and
/// been removed from the tree, so a callback built from *this* function's own
/// `context` and `ref` would be reading both after they had already gone
/// invalid. Called instead from `MusicRowMenu.build`, with `context` and
/// `ref` from the row itself — the anchor that opens the menu, which stays
/// mounted for as long as the row does, unlike the menu's own transient
/// content.
Widget addToPlaylistMenu(
  BuildContext context,
  WidgetRef ref, {
  required List<String> fileUuids,
}) {
  final l10n = AppLocalizations.of(context);
  final playlists = ref.watch(playlistsControllerProvider).value ?? const [];
  // Read once, while the row is certainly still mounted, and closed over
  // below — never `ref.read` again from inside a `MenuItemButton`'s own
  // `onPressed`, which runs after the menu (and this function's own call)
  // is long done.
  final form = ref.read(playlistsFormProvider.notifier);

  Future<void> select(String selection) => selection == _createPlaylistValue
      ? PlaylistsScreen.show(context)
      : form.addEntries(playlistUuid: selection, fileUuids: fileUuids);

  return SubmenuButton(
    leadingIcon: const Icon(Icons.playlist_add),
    menuChildren: [
      if (playlists.isEmpty)
        MenuItemButton(
          onPressed: () => unawaited(select(_createPlaylistValue)),
          child: Text(l10n.playlistAddCreateOne),
        )
      else
        for (final playlist in playlists)
          MenuItemButton(
            onPressed: () => unawaited(select(playlist.uuid)),
            child: Text(playlist.name),
          ),
    ],
    child: Text(l10n.playlistAddTo),
  );
}
