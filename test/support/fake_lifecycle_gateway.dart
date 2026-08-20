import 'package:alexandria_desktop/features/lifecycle/domain/lifecycle_gateway.dart';

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

  LifecycleWrite _next() => outcomes.isEmpty
      ? const LifecycleWrite.done()
      : outcomes.removeAt(0);
}
