import 'dart:async';
import 'dart:io';

import 'install_kind.dart';
import 'release_info.dart';

/// Why the latest release could not be read.
class UpdateCheckException implements Exception {
  /// Creates the exception.
  const UpdateCheckException(this.message);

  /// What went wrong, for the log.
  final String message;

  @override
  String toString() => 'UpdateCheckException: $message';
}

/// Where the latest release is read from.
abstract interface class ReleaseSource {
  /// The latest release. Throws [UpdateCheckException] when it cannot be read.
  Future<ReleaseInfo> latest();
}

/// How this copy was installed, and where.
abstract interface class InstallKindProbe {
  /// The kind of installation this is.
  InstallKind detect();

  /// The folder (Windows), prefix (Linux installer) or file (AppImage) an
  /// update replaces; null for the kinds that do not update themselves.
  String? installLocation();
}

/// Asks a download in flight to stop.
class CancelToken {
  final Completer<void> _cancelled = Completer<void>();

  /// Stops the download, even one waiting on a stalled connection.
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;
}

/// Downloads files and hashes them.
abstract interface class Downloader {
  /// Downloads [url] into [to], reporting progress. A failed or cancelled
  /// download deletes what it wrote and throws.
  Future<File> download(
    Uri url,
    File to, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  });

  /// The lower-case hex SHA-256 of [file].
  Future<String> sha256Of(File file);
}

/// Starts the installation of a downloaded package, outliving the
/// application.
abstract interface class UpdateInstaller {
  /// Starts installing [package] over [installLocation]. The application
  /// exits straight after.
  Future<void> launch({
    required File package,
    required String installLocation,
    required String fromVersion,
  });
}
