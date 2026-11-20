import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/di/providers.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/file_type.dart';
import '../domain/media_player.dart';
import '../domain/playback_source.dart';
import 'audio_playback_state.dart';

/// Plays music from the library in the player bar (libraries-only design
/// §6).
///
/// Its own engine, separate from the video player's, so a track keeps
/// playing while the owner browses and a video does not have to tear it
/// down — opening one only pauses it. The queue is the list a track was
/// started from; next and previous move through it, and a track that cannot
/// be opened is skipped rather than ending the album.
class AudioPlaybackController extends Notifier<AudioPlaybackState> {
  static final Logger _log = Logger('playback');

  /// How far into a track "previous" restarts it instead of going back.
  static const Duration restartThreshold = Duration(seconds: 3);

  StreamSubscription<PlaybackStatus>? _statuses;

  /// Bumped on every track change, so an answer for a track the owner has
  /// already moved past is dropped instead of loading over the new one.
  int _generation = 0;

  MediaPlayer get _player => ref.read(audioPlayerProvider);

  @override
  AudioPlaybackState build() {
    ref.onDispose(() => unawaited(_statuses?.cancel()));

    return const AudioPlaybackState();
  }

  /// Plays [file], with [queue] — the list it was started from — as what
  /// next and previous move through.
  ///
  /// The queue keeps active audio files only: a deleted record or another
  /// type in the list it came from has nothing to play. [file] itself is
  /// always kept.
  Future<void> play(CatalogFile file, List<CatalogFile> queue) async {
    final playable = [
      for (final entry in queue)
        if (entry.uuid == file.uuid ||
            (entry.type == FileType.audio && !entry.isDeleted))
          entry,
    ];
    if (!playable.any((entry) => entry.uuid == file.uuid)) {
      playable
        ..clear()
        ..add(file);
    }

    state = AudioPlaybackState(queue: playable);
    await _openFrom(playable.indexWhere((entry) => entry.uuid == file.uuid));
  }

  /// Plays or pauses the loaded track.
  Future<void> togglePlaying() async {
    if (state.current == null) return;

    if (state.playing) {
      await _player.pause();
      state = state.copyWith(playing: false);
    } else {
      await _player.play();
      state = state.copyWith(playing: true);
    }
  }

  /// The next track in the queue; nothing after the last.
  Future<void> next() async {
    if (state.index + 1 >= state.queue.length) return;

    await _openFrom(state.index + 1);
  }

  /// The previous track — or the start of this one, once it is past
  /// [restartThreshold], the way every player's back button works.
  Future<void> previous() async {
    if (state.current == null) return;

    if (state.position > restartThreshold || state.index == 0) {
      await seekTo(Duration.zero);
      return;
    }

    await _openFrom(state.index - 1, backwards: true);
  }

  /// Moves within the loaded track.
  Future<void> seekTo(Duration position) async {
    if (state.current == null) return;

    await _player.seek(position);
    state = state.copyWith(position: position);
  }

  /// Stops and unloads everything; the bar goes away.
  Future<void> stop() async {
    _generation++;
    unawaited(_statuses?.cancel());
    _statuses = null;
    state = const AudioPlaybackState();
    await _player.stop();
  }

  /// Pauses the music because a video is opening.
  ///
  /// Paused rather than stopped: the owner gets their place back when the
  /// video is done.
  Future<void> pauseForVideo() async {
    if (!state.playing) return;

    await _player.pause();
    state = state.copyWith(playing: false);
  }

  /// Takes the tracks of a removed library out of the queue.
  ///
  /// The core deleted their records with the library, so none of them can be
  /// played again. A playing one stops; the rest of the queue stays as it
  /// was.
  Future<void> dropLibrary(String libraryUuid) async {
    final current = state.current;
    if (current == null) return;

    if (current.libraryUuid == libraryUuid) {
      await stop();
      return;
    }

    final kept = [
      for (final entry in state.queue)
        if (entry.libraryUuid != libraryUuid) entry,
    ];
    state = state.copyWith(
      queue: kept,
      index: kept.indexWhere((entry) => entry.uuid == current.uuid),
    );
  }

  /// Opens the queue's track at [start], skipping past any that cannot be
  /// opened — forwards, or backwards when [backwards] — and says so.
  Future<void> _openFrom(int start, {bool backwards = false}) async {
    final generation = ++_generation;
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    String? skipped;
    Failure? lastFailure;
    final step = backwards ? -1 : 1;

    for (var i = start; i >= 0 && i < state.queue.length; i += step) {
      final file = state.queue[i];
      final outcome = await ref
          .read(playbackSourceGatewayProvider)
          .resolve(uuid: file.uuid, credential: credential);
      if (generation != _generation) return;

      switch (outcome) {
        case PlaybackSourceResolved(:final source):
          _listenToEngine();
          await _player.open(source.path);
          if (generation != _generation) return;

          state = state.copyWith(
            index: i,
            playing: true,
            position: Duration.zero,
            duration: null,
            cover: null,
            skippedName: skipped,
            failure: null,
          );
          unawaited(_loadCover(file, credential, generation));
          return;

        case PlaybackSourceFailed(failure: final UnauthorizedFailure failure):
          ref.read(sessionControllerProvider.notifier).invalidate(failure);
          await stop();
          return;

        case PlaybackSourceFailed(:final failure):
          _log.info('skipped ${file.uuid}: ${failure.coreStatusCode}');
          skipped = file.name;
          lastFailure = failure;
      }
    }

    // Nothing from [start] on could be opened.
    await _player.stop();
    state = state.copyWith(
      playing: false,
      skippedName: skipped,
      failure:
          lastFailure ??
          const Failure.unexpected(
            family: CoreStatusFamily.playback,
            code: PLAYBACK_ERR_OTHER,
          ),
    );
  }

  Future<void> _loadCover(
    CatalogFile file,
    String credential,
    int generation,
  ) async {
    final cover = await ref
        .read(coverGatewayProvider)
        .cover(uuid: file.uuid, credential: credential);
    if (generation != _generation || cover == null) return;

    state = state.copyWith(cover: cover);
  }

  /// Follows the engine: where the track is, and when it ends or cannot be
  /// decoded.
  void _listenToEngine() {
    unawaited(_statuses?.cancel());

    _statuses = _player.status.listen((status) {
      if (state.current == null) return;

      if (status.failedToDecode) {
        state = state.copyWith(skippedName: state.current?.name);
        unawaited(_advanceOrSettle());
        return;
      }

      if (status.hasEnded) {
        unawaited(_advanceOrSettle());
        return;
      }

      state = state.copyWith(
        playing: status.isPlaying,
        position: status.position,
        duration: status.duration ?? state.duration,
      );
    });
  }

  /// The next track, or — after the last — the end, paused where it is.
  Future<void> _advanceOrSettle() async {
    if (state.index + 1 < state.queue.length) {
      await _openFrom(state.index + 1);
      return;
    }

    state = state.copyWith(playing: false);
  }
}
