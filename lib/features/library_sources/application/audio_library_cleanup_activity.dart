import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../libraries/domain/library_gateway.dart';
import '../../shell/domain/session_activity.dart';
import '../domain/folder_registration.dart';

/// Removes the libraries that were made of music-only folders, once there is
/// a session to remove them with (remove-music design, "Stored index
/// scopes").
///
/// Startup unregisters a folder that tracked nothing but audio, but it runs
/// before anyone has signed in, and the core will not remove a library
/// without a credential. So startup remembers which of those folders were
/// libraries, and the first session of the launch removes them here through
/// the Libraries screen's own path (`LibrariesController.remove`).
///
/// Never fails the sign-in. A library the core cannot find or will not remove
/// is logged and left: the folder is already unregistered, so the most it
/// costs is an empty library the owner can remove by hand.
class AudioLibraryCleanupActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const AudioLibraryCleanupActivity(this._ref);

  static final Logger _log = Logger('library_sources');

  final Ref _ref;

  /// A removal is finished or abandoned in one call; there is nothing to
  /// lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async {}

  @override
  Future<void> begin() async {
    final folders = _ref
        .read(startupControllerProvider.notifier)
        .takeAudioLibrariesToRemove();
    if (folders.isEmpty) return;

    final credential = _ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    // The folder knows its library by name and root, the core by uuid, so the
    // core's list is what turns one into the other.
    final browse = await _ref
        .read(libraryGatewayProvider)
        .browse(credential: credential);
    if (browse case LibraryBrowseFailed(:final failure)) {
      _log.warning(
        'music-only libraries could not be listed, so they were left: '
        '${failure.runtimeType}',
      );
      return;
    }
    final libraries = (browse as LibraryBrowseLoaded).libraries;

    for (final folder in folders) {
      final root = normalizeFolderPath(folder.path);
      final library = libraries
          .where((library) => normalizeFolderPath(library.rootPath) == root)
          .firstOrNull;
      if (library == null) {
        _log.info('no library to remove for music-only folder ${folder.path}');
        continue;
      }

      final failure = await _ref
          .read(librariesControllerProvider.notifier)
          .remove(library.uuid);
      if (failure == null) {
        _log.info('music-only library removed on upgrade: ${folder.path}');
      } else {
        _log.warning(
          'music-only library could not be removed: ${folder.path} '
          '(${failure.runtimeType})',
        );
      }
    }
  }
}
