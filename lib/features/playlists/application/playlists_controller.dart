import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/playlist.dart';
import '../domain/playlist_gateway.dart';

/// The owner's playlists (playlists design).
class PlaylistsController extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final browse = await ref
        .read(playlistGatewayProvider)
        .browse(credential: credential);

    switch (browse) {
      case PlaylistBrowseLoaded(:final playlists):
        return playlists;

      // A rejected session returns the owner to login, as everywhere else.
      case PlaylistBrowseFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case PlaylistBrowseFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again, which is how a write's effect reaches the screen.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// What the playlists screen is reporting, if anything.
enum PlaylistNotice {
  /// Nothing.
  none,

  /// The core has no such playlist any more.
  notFound,

  /// The core refused for a reason of its own.
  refused,
}

/// The playlists screen's own state, beside the playlists themselves.
class PlaylistsState {
  /// Creates a state.
  const PlaylistsState({
    this.name = '',
    this.nameError,
    this.isWriting = false,
    this.renaming,
    this.notice = PlaylistNotice.none,
    this.refusal,
  });

  /// The name being typed into the create or rename field.
  final String name;

  /// What local validation refused — a blank name never reaches the core.
  final PlaylistNameError? nameError;

  /// Whether a create, rename, or delete is in flight.
  final bool isWriting;

  /// The playlist being renamed, or `null` when none is.
  final String? renaming;

  /// What the screen is reporting.
  final PlaylistNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;

  /// A copy with the given changes.
  ///
  /// The mark and the notice are cleared rather than carried whenever they are
  /// not given: each belongs to one attempt.
  PlaylistsState copyWith({
    String? name,
    PlaylistNameError? nameError,
    bool? isWriting,
    String? renaming,
    PlaylistNotice notice = PlaylistNotice.none,
    Failure? refusal,
  }) => PlaylistsState(
    name: name ?? this.name,
    nameError: nameError,
    isWriting: isWriting ?? this.isWriting,
    renaming: renaming,
    notice: notice,
    refusal: refusal,
  );
}

/// Drives creating, renaming, and deleting playlists.
class PlaylistsForm extends Notifier<PlaylistsState> {
  @override
  PlaylistsState build() => const PlaylistsState();

  /// Records the name being typed, dropping the mark that was on it.
  void editName(String name) =>
      state = state.copyWith(name: name, renaming: state.renaming);

  /// Opens [uuid] for renaming, seeding the field with [currentName].
  void startRenaming({required String uuid, required String currentName}) =>
      state = state.copyWith(name: currentName, renaming: uuid);

  /// Closes the rename without sending it.
  void cancelRenaming() => state = const PlaylistsState();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = state.copyWith(renaming: state.renaming);

  /// Creates a playlist.
  Future<void> create() async {
    if (state.isWriting) return;

    // The blank name never reaches the core (BR-02: the core's own name rule
    // is not re-implemented here, only this one courtesy check is).
    final nameError = validatePlaylistName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError, renaming: state.renaming);
      return;
    }

    await _call(
      (gateway, credential) =>
          gateway.create(name: state.name.trim(), credential: credential),
    );
  }

  /// Renames the playlist being renamed.
  Future<void> renameSubmitted() async {
    final uuid = state.renaming;
    if (uuid == null || state.isWriting) return;

    final nameError = validatePlaylistName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError, renaming: uuid);
      return;
    }

    await _call(
      (gateway, credential) => gateway.rename(
        uuid: uuid,
        name: state.name.trim(),
        credential: credential,
      ),
    );
  }

  /// Deletes a playlist.
  ///
  /// The confirmation is the screen's: it has to say that the tracks
  /// themselves are untouched before this is reached — the core deletes the
  /// playlist and its entries, never the files.
  Future<void> delete(String uuid) => _call(
    (gateway, credential) => gateway.delete(uuid: uuid, credential: credential),
  );

  /// Adds [fileUuids] to the playlist [playlistUuid] identifies, in one call
  /// (Task 5; BR-02).
  ///
  /// Every track in [fileUuids] is sent, in the order given, with nothing
  /// filtered or deduped first: a track already in the playlist is added
  /// again rather than refused, because the core allows duplicates and this
  /// application does not invent a rule it does not have. One call for the
  /// whole list is also what keeps "add this album" one transaction rather
  /// than one request per track, which is the difference between the core
  /// adding all of them or none and a failure halfway leaving half an album
  /// added.
  Future<void> addEntries({
    required String playlistUuid,
    required List<String> fileUuids,
  }) => _call(
    (gateway, credential) => gateway.addEntries(
      uuid: playlistUuid,
      fileUuids: fileUuids,
      credential: credential,
    ),
    // Adding entries never changes a playlist's own uuid or name, which is
    // all `playlistsControllerProvider`'s browse holds — unlike create,
    // rename, and delete, nothing in that list needs refreshing, so this
    // skips the round-trip and the rebuild of every row watching it.
    reloadOnSuccess: false,
  );

  /// Runs [call] and turns its answer into what the screen shows.
  Future<void> _call(
    Future<PlaylistWrite> Function(PlaylistGateway, String credential) call, {
    bool reloadOnSuccess = true,
  }) async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    state = state.copyWith(isWriting: true, renaming: state.renaming);

    final outcome = await call(ref.read(playlistGatewayProvider), credential);

    switch (outcome) {
      case PlaylistWriteDone():
        // The screen reads the core again rather than being patched here —
        // for the callers that need it; see `reloadOnSuccess`.
        if (reloadOnSuccess) {
          await ref.read(playlistsControllerProvider.notifier).reload();
        }
        state = const PlaylistsState();

      // A rejected session is discarded, which returns the owner to login.
      case PlaylistWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // The playlist is gone, so the screen says so and reads the core again.
      case PlaylistWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(playlistsControllerProvider.notifier).reload();
        state = state.copyWith(
          isWriting: false,
          renaming: state.renaming,
          notice: PlaylistNotice.notFound,
          refusal: failure,
        );

      // The core refused the name. The form stays open with what the owner
      // typed, because correcting it is the next thing they do.
      case PlaylistWriteFailed(:final failure):
        state = state.copyWith(
          isWriting: false,
          renaming: state.renaming,
          notice: PlaylistNotice.refused,
          refusal: failure,
        );
    }
  }
}
