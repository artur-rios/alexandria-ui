import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';

part 'audio_playback_state.freezed.dart';

/// What the player bar shows (libraries-only design §6).
@freezed
abstract class AudioPlaybackState with _$AudioPlaybackState {
  /// Creates the state.
  const factory AudioPlaybackState({
    /// The tracks next and previous move through: the list the current one
    /// was started from, active audio files only.
    @Default(<CatalogFile>[]) List<CatalogFile> queue,

    /// Where in [queue] the loaded track is, or -1 when nothing is loaded.
    @Default(-1) int index,

    /// Whether it is playing right now.
    @Default(false) bool playing,

    /// How far into the track it is.
    @Default(Duration.zero) Duration position,

    /// How long the track is, once the engine knows.
    Duration? duration,

    /// The loaded track's front cover, when it has one.
    Uint8List? cover,

    /// The name of the last track that could not be opened and was skipped.
    String? skippedName,

    /// Why nothing could be played, when nothing left in the queue opened.
    Failure? failure,
  }) = _AudioPlaybackState;

  const AudioPlaybackState._();

  /// The loaded track, or null when nothing is.
  CatalogFile? get current =>
      index >= 0 && index < queue.length ? queue[index] : null;

  /// Whether the bar has anything to show.
  bool get isLoaded => current != null || failure != null;
}
