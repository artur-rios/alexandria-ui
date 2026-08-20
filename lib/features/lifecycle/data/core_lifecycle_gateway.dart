import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/lifecycle_gateway.dart';

/// [LifecycleGateway] over the core's soft-delete calls (UC-33).
class CoreLifecycleGateway implements LifecycleGateway {
  /// Wraps [_core].
  const CoreLifecycleGateway(this._core);

  final CoreClient _core;

  @override
  Future<LifecycleWrite> softDeleteFile({
    required String uuid,
    required String credential,
  }) => _write(
    CoreStatusFamily.file,
    FILE_ERR_OTHER,
    () => _core.fileSoftDelete(uuid, credential),
  );

  @override
  Future<LifecycleWrite> softDeleteBookmark({
    required String uuid,
    required String credential,
  }) => _write(
    CoreStatusFamily.bookmark,
    BOOKMARK_ERR_OTHER,
    () => _core.bookmarkSoftDelete(uuid, credential),
  );

  @override
  Future<LifecycleWrite> restoreFile({
    required String uuid,
    required String credential,
  }) => _write(
    CoreStatusFamily.file,
    FILE_ERR_OTHER,
    () => _core.fileRestore(uuid, credential),
  );

  @override
  Future<LifecycleWrite> restoreBookmark({
    required String uuid,
    required String credential,
  }) => _write(
    CoreStatusFamily.bookmark,
    BOOKMARK_ERR_OTHER,
    () => _core.bookmarkRestore(uuid, credential),
  );

  /// Runs [call] and turns the core's status into an outcome.
  ///
  /// The family is a parameter because a file and a bookmark are different
  /// core families: the same number means different things in each, and
  /// reading one with the other's table is how a not-found becomes an
  /// unauthorized.
  Future<LifecycleWrite> _write(
    CoreStatusFamily family,
    int otherCode,
    Future<CoreJsonResponse> Function() call,
  ) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return LifecycleWrite.failed(
        failure: Failure.unexpected(family: family, code: otherCode),
      );
    }

    if (!family.isOk(response.status)) {
      return LifecycleWrite.failed(
        failure: mapCoreStatus(family, response.status),
      );
    }

    return const LifecycleWrite.done();
  }
}
