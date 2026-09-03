import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/stats_gateway.dart';

/// Tells the core a track was played (play history design).
///
/// A thin collaborator rather than a controller: it holds no state and has
/// no screen. What it exists for is to keep the player from knowing about
/// credentials and gateways, and to make the swallowing of a failed record
/// a deliberate, tested decision rather than an omission.
class PlayRecorder {
  /// Creates a recorder over [_ref].
  const PlayRecorder(this._ref);

  static final Logger _log = Logger('stats');

  final Ref _ref;

  /// Records a play of [fileUuid], and never throws.
  ///
  /// A play that could not be written is logged and dropped. Nothing the
  /// owner is doing depends on it: interrupting the music to report that a
  /// statistic went unrecorded would be a worse failure than the missing
  /// row. A rejected session is the one exception — it returns the owner to
  /// login, as everywhere else, because the session is over regardless of
  /// what was being recorded when it ended.
  Future<void> record(String fileUuid) async {
    final credential = _ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return;

    final outcome = await _ref
        .read(statsGatewayProvider)
        .record(fileUuid: fileUuid, credential: credential);

    switch (outcome) {
      case PlayRecordedDone():
        return;

      case PlayRecordedFailed(failure: final UnauthorizedFailure failure):
        _ref.read(sessionControllerProvider.notifier).invalidate(failure);

      case PlayRecordedFailed(:final failure):
        _log.info('a play was not recorded: $failure');
    }
  }
}
