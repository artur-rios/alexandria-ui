import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../libraries/domain/library.dart';
import '../../libraries/domain/library_gateway.dart';
import '../../shell/domain/session_activity.dart';
import '../domain/audio_scope_cleanup.dart';
import '../domain/folder_registration.dart';
import '../domain/library_source.dart';

/// Takes audio out of the stored tracked folders when a session begins
/// (remove-music design, "Stored index scopes").
///
/// A folder that tracked nothing but audio is unregistered, and a mixed
/// scope drops audio and keeps the rest ([cleanUpAudioScopes]). A music-only
/// folder that was also a library has its library removed from the core
/// first, through the Libraries screen's own path
/// (`LibrariesController.remove`).
///
/// Here rather than at startup because the core will not list or remove a
/// library without a credential, and the folder and its library have to go
/// together: a folder unregistered while its library stayed would leave an
/// empty library with nothing left to retry it. Nothing reads a folder's
/// scope before this — indexing and the folders screen both need a session.
///
/// Runs at every sign-in and needs no flag. Once the stored folders name no
/// audio it finds nothing to change and writes nothing. A library the core
/// would not remove keeps its folder in the store as it was, so the next
/// sign-in tries again; that is logged and never blocks the sign-in.
class AudioLibraryCleanupActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const AudioLibraryCleanupActivity(this._ref);

  static final Logger _log = Logger('library_sources');

  final Ref _ref;

  /// The cleanup finishes or gives up within one call; there is nothing to
  /// lose by signing out.
  @override
  bool get holdsUnsavedChanges => false;

  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async {}

  @override
  Future<void> begin() async {
    final store = _ref.read(librarySourceStoreProvider);
    final sources = store.read();
    final (:kept, :removed) = cleanUpAudioScopes(sources);

    // Only the libraries of folders being unregistered are asked about, so
    // clean data reaches the core with nothing at all.
    final gone = Set<LibrarySource>.identity()..addAll(removed);
    final retained = Set<LibrarySource>.identity()
      ..addAll(
        await _removeLibraries([
          for (final source in removed)
            if (source.isLibrary) source,
        ]),
      );

    // Rebuilt in the stored order: a folder whose library could not be
    // removed goes back where it was, unchanged, and every other one is the
    // cleanup's answer for it, which [kept] holds in the same order.
    final cleaned = kept.iterator;
    final written = <LibrarySource>[];
    for (final source in sources) {
      if (!gone.contains(source)) {
        cleaned.moveNext();
        written.add(cleaned.current);
      } else if (retained.contains(source)) {
        written.add(source);
      }
    }

    // The cleanup passes an untouched folder through as the same record, so
    // identity is what says nothing changed — clean data, or a store whose
    // only change was a removal the core refused.
    if (_sameRecords(written, sources)) return;

    await store.write(written);
    for (final source in gone.difference(retained)) {
      _log.info('music-only folder unregistered on upgrade: ${source.path}');
    }

    // Built before this ran, it would still hold the folders as they were,
    // and the next write it makes would put them back.
    _ref.invalidate(librarySourcesControllerProvider);
  }

  /// Removes the core library of each of [folders], answering the folders
  /// whose library could not be removed.
  Future<List<LibrarySource>> _removeLibraries(
    List<LibrarySource> folders,
  ) async {
    if (folders.isEmpty) return const [];

    final credential = _ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return folders;

    // The folder knows its library by root, the core by uuid, so the core's
    // list is what turns one into the other.
    final browse = await _ref
        .read(libraryGatewayProvider)
        .browse(credential: credential);
    final List<Library> libraries;
    switch (browse) {
      case LibraryBrowseLoaded(libraries: final listed):
        libraries = listed;
      case LibraryBrowseFailed(:final failure):
        _log.warning(
          'music-only libraries could not be listed; their folders are kept '
          'for the next sign-in (${failure.runtimeType})',
        );
        return folders;
    }

    final retained = <LibrarySource>[];
    for (final folder in folders) {
      final root = normalizeFolderPath(folder.path);
      final library = libraries
          .where((library) => normalizeFolderPath(library.rootPath) == root)
          .firstOrNull;

      // Already gone from the core — removed by hand, or by an earlier
      // sign-in that could not write the folders afterwards. Nothing is left
      // to retry, so the folder goes.
      if (library == null) continue;

      final failure = await _ref
          .read(librariesControllerProvider.notifier)
          .remove(library.uuid);
      if (failure == null) {
        _log.info('music-only library removed on upgrade: ${folder.path}');
      } else {
        _log.warning(
          'music-only library could not be removed; its folder is kept for '
          'the next sign-in: ${folder.path} (${failure.runtimeType})',
        );
        retained.add(folder);
      }
    }

    return retained;
  }

  static bool _sameRecords(List<LibrarySource> a, List<LibrarySource> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}
