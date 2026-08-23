import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';

/// A [LifecycleGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeLifecycleGateway implements LifecycleGateway {
  /// What the next write answers, in order.
  final List<LifecycleWrite> outcomes = [];

  /// Every file soft-deleted, in order.
  final List<String> deletedFiles = [];

  /// Every bookmark soft-deleted, in order.
  final List<String> deletedBookmarks = [];

  @override
  Future<LifecycleWrite> softDeleteFile({
    required String uuid,
    required String credential,
  }) async {
    deletedFiles.add(uuid);
    return _next();
  }

  @override
  Future<LifecycleWrite> softDeleteBookmark({
    required String uuid,
    required String credential,
  }) async {
    deletedBookmarks.add(uuid);
    return _next();
  }

  /// Every record restored, in order.
  final List<String> restored = [];

  @override
  Future<LifecycleWrite> restoreFile({
    required String uuid,
    required String credential,
  }) async {
    restored.add(uuid);
    return _next();
  }

  @override
  Future<LifecycleWrite> restoreBookmark({
    required String uuid,
    required String credential,
  }) async {
    restored.add(uuid);
    return _next();
  }

  /// What a purge on disk answers.
  PurgeOnDiskOutcome purgeOnDiskOutcome = const PurgeOnDiskOutcome.purged(
    diskFilePresent: true,
  );

  /// Every record purged, in order.
  final List<String> purged = [];

  @override
  Future<LifecycleWrite> purgeFile({
    required String uuid,
    required String credential,
  }) async {
    purged.add(uuid);
    return _next();
  }

  @override
  Future<LifecycleWrite> purgeBookmark({
    required String uuid,
    required String credential,
  }) async {
    purged.add(uuid);
    return _next();
  }

  @override
  Future<PurgeOnDiskOutcome> purgeFileOnDisk({
    required String uuid,
    required String credential,
  }) async {
    purged.add(uuid);
    return purgeOnDiskOutcome;
  }

  LifecycleWrite _next() =>
      outcomes.isEmpty ? const LifecycleWrite.done() : outcomes.removeAt(0);
}
