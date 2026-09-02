import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/track_energy.dart';

/// The sound of the track being shown, read once and held (UC-21, FR-MP-07).
///
/// Keyed by file and auto-disposed: a player moves through a queue, and an
/// envelope for every track ever played is tens of kilobytes each held for
/// the life of the process.
///
/// `null` is "there is nothing to draw" — the read is still in flight, the
/// core could not decode the file, or no session exists to ask under. All
/// three are the same thing to a visualiser: bars at rest. The distinction
/// matters to nobody on screen, which is why this returns a value rather
/// than an outcome to be switched on.
class TrackEnergyController extends AsyncNotifier<TrackEnergy?> {
  /// Creates the controller for [fileUuid].
  TrackEnergyController(this.fileUuid);

  /// The track whose sound to read.
  final String fileUuid;

  @override
  Future<TrackEnergy?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    final outcome = await ref
        .read(energyGatewayProvider)
        .readEnergy(fileUuid: fileUuid, credential: credential);

    switch (outcome) {
      case TrackEnergyLoaded(:final energy):
        return energy;

      // A rejected session returns the owner to login, as everywhere else.
      case TrackEnergyUnavailable(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      // Anything else reads as "nothing to draw" rather than as an error.
      // A file the core cannot decode still plays — mpv is not ffmpeg's
      // decoder — and a player that put a failure banner over the artwork
      // because the *bars* could not be drawn would be shouting about the
      // wrong thing.
      case TrackEnergyUnavailable():
        return null;
    }
  }
}
