import 'dart:typed_data';

import '../../../core/failures/failure.dart';

/// The sound of a track, as levels (UC-21, FR-MP-07).
///
/// One byte per band per frame, row-major: every band of the first frame,
/// then the next frame. 0 is silence and 255 the loudest moment of *this*
/// recording — the core scales against the track itself, so a quietly
/// mastered record fills the bars exactly as a loud one does.
class TrackEnergy {
  /// Creates an envelope.
  const TrackEnergy({
    required this.bands,
    required this.frameMs,
    required this.levels,
  });

  /// How many levels each frame carries.
  final int bands;

  /// How long one frame covers, in milliseconds.
  final int frameMs;

  /// The levels themselves.
  final Uint8List levels;

  /// How many frames the envelope holds.
  int get frames => bands <= 0 ? 0 : levels.length ~/ bands;

  /// The level of [band] at [position], 0 to 1.
  ///
  /// Interpolated between the two frames either side of the moment asked
  /// for, which is what makes ten frames a second look continuous at sixty:
  /// without it the bars would step, and a level meter that steps reads as a
  /// dropped frame rather than as music.
  ///
  /// Zero past either end of the envelope — before a track starts and after
  /// what was measured — because a bar standing at whatever the last frame
  /// happened to hold would be the loudest moment of the track frozen on
  /// screen after the music stopped.
  double levelAt({required int band, required Duration position}) {
    if (bands <= 0 || band < 0 || band >= bands || frames == 0) return 0;

    final exact = position.inMicroseconds / (frameMs * 1000);
    if (exact < 0 || exact > frames - 1) return 0;

    final first = exact.floor();
    final second = (first + 1).clamp(0, frames - 1);
    final into = exact - first;

    final from = levels[first * bands + band] / 255;
    final to = levels[second * bands + band] / 255;

    return from + (to - from) * into;
  }
}

/// What reading a track's envelope produced.
sealed class TrackEnergyRead {
  const TrackEnergyRead();
}

/// The core answered.
final class TrackEnergyLoaded extends TrackEnergyRead {
  /// Creates the outcome.
  const TrackEnergyLoaded({required this.energy});

  /// The envelope.
  final TrackEnergy energy;
}

/// The core could not answer.
///
/// A state, not an error to raise: bars are an embellishment beside a
/// playing track, and a player that grew a red banner because a file would
/// not decode would be louder about the embellishment than about the music.
final class TrackEnergyUnavailable extends TrackEnergyRead {
  /// Creates the outcome.
  const TrackEnergyUnavailable({required this.failure});

  /// Why.
  final Failure failure;
}

/// Reading the sound of a track (UC-21, FR-MP-07).
abstract interface class EnergyGateway {
  /// The envelope for [fileUuid].
  ///
  /// **The first call for a track decodes it**, which is a second or two of
  /// the core's own CPU. Never awaited anywhere a frame is waiting on it.
  Future<TrackEnergyRead> readEnergy({
    required String fileUuid,
    required String credential,
  });
}
