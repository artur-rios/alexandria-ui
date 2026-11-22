import 'dart:typed_data';

import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playback/domain/cover_gateway.dart';
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

  /// The path each file resolves to, when a test needs to tell them apart.
  String Function(String uuid)? pathFor;

  /// Files that resolve as missing on disk, whenever they are asked for.
  final Set<String> failing = {};

  @override
  Future<PlaybackSourceOutcome> resolve({required String uuid}) async {
    resolved.add(uuid);

    if (failing.contains(uuid)) return missingOnDisk;
    if (outcomes.isNotEmpty) return outcomes.removeAt(0);

    return PlaybackSourceOutcome.resolved(
      source: PlaybackSource(uuid: uuid, path: pathFor?.call(uuid) ?? path),
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

/// A [PlaybackSession] a test registers to stand in for a player.
///
/// Closing for an update stops whatever player is running, and this is what a
/// test gives it to stop.
class FakePlaybackSession implements PlaybackSession {
  /// Creates a session, running or not.
  FakePlaybackSession({this.isActive = true});

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

/// Covers a test hands out by file uuid; none by default.
class FakeCoverGateway implements CoverGateway {
  final Map<String, Uint8List> covers = {};

  @override
  Future<Uint8List?> cover({required String uuid}) async => covers[uuid];
}
