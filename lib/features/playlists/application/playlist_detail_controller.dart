import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/playlist.dart';
import '../domain/playlist_gateway.dart';

/// The destination `ReorderableListView.onReorder` hands the core, from the
/// indices Flutter hands the callback (playlists design section 3).
///
/// Flutter's own contract for `onReorder`: `newIndex` is computed as if the
/// dragged item were already removed from the list, so for a **downward**
/// move (`newIndex > oldIndex`) it is one higher than the index the item
/// actually lands at once the removal and the reinsertion are both accounted
/// for. Dragging index 0 to the end of a 4-item list reports `newIndex: 4`,
/// not the `3` that is actually the last position — this is the single most
/// common bug in this widget, and it is why the subtraction happens here,
/// once, rather than at every call site. An **upward** move needs no
/// correction: nothing between the drop point and the item's old position
/// shifted before the index was computed.
///
/// The result is the plain `toIndex` `PlaylistGateway.moveEntry` expects
/// (BR-02): this application sends only the destination, never a position it
/// worked out itself.
int reorderDestinationIndex({required int oldIndex, required int newIndex}) =>
    newIndex > oldIndex ? newIndex - 1 : newIndex;

/// One playlist and its tracks, in the order the core sent them (playlists
/// design sections 3 and 4).
///
/// Mirrors `PlaylistsController`, not `FileDetailsController`: state is
/// `null` both for "no session yet" (FR-AU-07) *and* for a session the core
/// rejects, exactly as `PlaylistsController.build` answers `const []` for
/// both. `FileDetailsController` is a different precedent — it *throws* on a
/// rejected session instead, precisely so the detail view does not read as a
/// record with nothing in it.
///
/// The consequence carried over from `PlaylistsScreen` along with the
/// pattern: `PlaylistDetailScreen` is a `showDialog` route, which survives
/// `MaterialApp.home` swapping to the login screen. On a rejected session the
/// owner was left looking at a fullscreen dialog with a blank title and a
/// blank body, floating silently above the login screen underneath, until
/// they dismissed it themselves.
///
/// Settled where it said it should be — together, and for every screen with
/// the same exposure rather than this one: `SessionRouteGuard` closes the
/// routes above `home` when a session ends. What is left here is the state
/// shape itself, which stays as it is because `PlaylistsController` answers
/// the same way and the two are read together.
class PlaylistDetailController extends AsyncNotifier<PlaylistView?> {
  /// Creates the controller for the playlist [uuid] identifies.
  PlaylistDetailController(this.uuid);

  /// The playlist this instance reads and writes.
  final String uuid;

  @override
  Future<PlaylistView?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    return _read(credential);
  }

  Future<PlaylistView?> _read(String credential) async {
    final outcome = await ref
        .read(playlistGatewayProvider)
        .read(uuid: uuid, credential: credential);

    switch (outcome) {
      case PlaylistReadLoaded(:final view):
        return view;

      // A rejected session returns the owner to login, as everywhere else.
      case PlaylistReadFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      // Including the playlist no longer existing — the screen's failure
      // state is what says so, with the retry AF-03 asks for.
      case PlaylistReadFailed(:final failure):
        throw failure;
    }
  }

  /// Reads the playlist again, which is how a write's effect reaches the
  /// screen (BR-02: the displayed order is always the stored order, never one
  /// computed locally).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// Removes the entry [entryUuid] identifies.
  ///
  /// Addressed by the entry's own uuid, never by the file it points at: a
  /// playlist may hold the same track twice, and only the entry's uuid tells
  /// them apart (playlists design section 2).
  Future<void> removeEntry(String entryUuid) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    final outcome = await ref
        .read(playlistGatewayProvider)
        .removeEntry(uuid: uuid, entryUuid: entryUuid, credential: credential);

    await _afterWrite(outcome);
  }

  /// Moves the entry [entryUuid] identifies to [toIndex].
  ///
  /// [toIndex] is the plain destination the core expects, already converted
  /// by [reorderDestinationIndex] — never Flutter's raw `onReorder` indices
  /// (BR-02).
  Future<void> moveEntry({required String entryUuid, required int toIndex}) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    final outcome = await ref
        .read(playlistGatewayProvider)
        .moveEntry(
          uuid: uuid,
          entryUuid: entryUuid,
          toIndex: toIndex,
          credential: credential,
        );

    await _afterWrite(outcome);
  }

  /// What every write does with its answer: no echoed record, so the only
  /// place an order or a count can be trusted is a fresh read (BR-02).
  Future<void> _afterWrite(PlaylistWrite outcome) async {
    switch (outcome) {
      case PlaylistWriteDone():
        await reload();

      // A rejected session is discarded, which returns the owner to login.
      case PlaylistWriteFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);

      // Any other refusal — including the entry or the playlist itself
      // having gone since the screen opened — is resolved by reading again
      // rather than inventing a second state for it: a playlist that is
      // still there shows its current order, and one that is gone surfaces
      // through the same failure-and-retry state a read failure already
      // has.
      case PlaylistWriteFailed():
        await reload();
    }
  }
}
