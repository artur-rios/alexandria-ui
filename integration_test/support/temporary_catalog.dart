import 'dart:io';

import 'package:alexandria_desktop/core/startup/core_paths.dart';
import 'package:path/path.dart' as p;

/// The throwaway database and fixture library every integration run gets
/// (IR-14, Testing Specification §7.3).
///
/// A test that would touch a real library folder, the real application-support
/// directory, or the developer's catalog is a defect in the test, not a
/// configuration to work around. This class is what makes the correct thing the
/// easy thing: everything it hands out lives under one temporary directory that
/// is removed afterwards.
class TemporaryCatalog {
  TemporaryCatalog._(this._root);

  final Directory _root;

  /// Creates the temporary root.
  static TemporaryCatalog create() =>
      TemporaryCatalog._(Directory.systemTemp.createTempSync('alexandria_it'));

  /// The catalog database path. The file does not exist until the core creates
  /// it.
  String get databasePath => p.join(_root.path, 'catalog.db');

  /// The fixture library folder, created empty.
  Directory get libraryDirectory =>
      Directory(p.join(_root.path, 'library'))..createSync(recursive: true);

  /// Writes a small sample file into the fixture library and returns it.
  ///
  /// Small on purpose: these exist so indexing has something to find, not so
  /// the suite exercises a real media decoder.
  File addFixture(String name, [String contents = 'fixture']) {
    final file = File(p.join(libraryDirectory.path, name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    return file;
  }

  /// Removes everything this run created, as far as the operating system
  /// allows.
  ///
  /// Best-effort, deliberately. `alexandria_index_init` opens the SQLite
  /// database into a process-global in the core, and the core's FFI surface
  /// publishes no shutdown or close call — so within one test process the
  /// handle outlives the client that opened it, and Windows refuses to delete a
  /// file that is still open.
  ///
  /// Inventing a call the core does not expose is forbidden by BR-02, and
  /// failing the run over a leftover file in the system temporary directory
  /// would report a cleanup problem as a test failure. What matters for §7.3 is
  /// that nothing was ever written outside this directory, and that holds
  /// either way. A close call on the core would let this become strict.
  void dispose() {
    if (!_root.existsSync()) return;

    try {
      _root.deleteSync(recursive: true);
    } on FileSystemException {
      // The core still holds the database open; the operating system reclaims
      // the temporary directory.
    }
  }
}

/// Resolves the core's shared library the same way the application does
/// (IR-04).
///
/// The integration suite loads the real library through the real resolver
/// rather than a path of its own — verifying that boundary is the point of the
/// suite, and a test that bypassed the resolver would not be testing it.
String? resolveRealCoreLibrary() =>
    CorePaths.fromPlatform().resolveLibraryPath();

/// Why the suite skipped, when the core's shared library is not present.
String get missingCoreReason =>
    'the Alexandria core was not found on any of '
    '${CorePaths.fromPlatform().librarySearchPaths.join(', ')}. '
    'Build alexandria-ffi and place it in native/, per the README.';
