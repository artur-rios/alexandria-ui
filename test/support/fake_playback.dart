import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playback/domain/playback_position_store.dart';
import 'package:alexandria_ui/features/playback/domain/playback_session.dart';
import 'package:alexandria_ui/features/playback/domain/playback_source.dart';

/// A [PlaybackSourceGateway] that never reaches the core (Testing
/// Specification §2.3).
class FakePlaybackSourceGateway implements PlaybackSourceGateway {
  /// Creates a gateway answering [path] for every file.
  FakePlaybackSourceGateway({this.path = '/home/owner/videos/Stalker.mkv'});

  /// The path a resolve answers with.
  String path;

  /// What [resolve] answers, in order. Falls back to [path].
  final List<PlaybackSourceOutcome> outcomes = [];

  /// Every uuid resolved, in order.
  final List<String> resolved = [];

  @override
  Future<PlaybackSourceOutcome> resolve({
    required String uuid,
    required String credential,
  }) async {
    resolved.add(uuid);

    if (outcomes.isNotEmpty) return outcomes.removeAt(0);

    return PlaybackSourceOutcome.resolved(
      source: PlaybackSource(uuid: uuid, path: path),
    );
  }

  /// The refusal the core gives for a file that is not on disk (UC-19 AF-01).
  static const PlaybackSourceOutcome missingOnDisk =
      PlaybackSourceOutcome.failed(
        failure: Failure.disk(family: CoreStatusFamily.playback, code: 6),
      );
}

/// A [PlaybackPositionStore] held in memory (Testing Specification §2.3).
class FakePlaybackPositionStore implements PlaybackPositionStore {
  /// Creates a store holding [positions].
  FakePlaybackPositionStore([Map<String, PlaybackPosition>? positions])
    : _positions = {...?positions};

  final Map<String, PlaybackPosition> _positions;

  /// Every uuid forgotten, in order.
  final List<String> forgotten = [];

  /// Every position written, in order.
  final List<PlaybackPosition> recorded = [];

  @override
  PlaybackPosition? positionFor(String fileUuid) => _positions[fileUuid];

  @override
  Future<void> record(PlaybackPosition position) async {
    recorded.add(position);
    _positions[position.fileUuid] = position;
  }

  @override
  Future<void> forget(String fileUuid) async {
    forgotten.add(fileUuid);
    _positions.remove(fileUuid);
  }
}

/// A [PlaybackSession] a test registers to stand in for the other medium.
///
/// UC-19 AF-05 is about the *other* player stopping, and until UC-20 builds
/// one this is what there is to stop.
class FakePlaybackSession implements PlaybackSession {
  /// Creates a session of [medium], running or not.
  FakePlaybackSession({required this.medium, this.isActive = true});

  @override
  final PlaybackMedium medium;

  @override
  bool isActive;

  /// How many times it was stopped.
  int stopCount = 0;

  @override
  Future<void> stop() async {
    stopCount++;
    isActive = false;
  }
}
