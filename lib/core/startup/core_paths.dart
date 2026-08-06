import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the two paths startup needs: the core's shared library (IR-04) and
/// the catalog database (IR-05).
///
/// Both are overridable, and the overrides exist for a stated reason rather than
/// as general configuration (Operations & Infrastructure Document §3): the
/// library override is for developing against a locally built core, and the
/// database override is what points development and the integration suite at a
/// scratch database so no run touches a real catalog.
class CorePaths {
  /// Creates a resolver.
  ///
  /// [environment] and [resolveApplicationSupportDirectory] are injectable so
  /// the unit tests can exercise every branch without a native library, a real
  /// environment, or the developer's own application-support directory.
  const CorePaths({
    Map<String, String> environment = const {},
    Future<Directory> Function()? resolveApplicationSupportDirectory,
  })
  // An initializing formal is impossible here: the field is private and a
  // named parameter cannot be, so `this._environment` is not expressible.
  // ignore: prefer_initializing_formals
  : _environment = environment,
    _resolveApplicationSupportDirectory =
        resolveApplicationSupportDirectory ?? getApplicationSupportDirectory;

  /// Reads the environment as the process sees it.
  CorePaths.fromPlatform({
    Future<Directory> Function()? resolveApplicationSupportDirectory,
  }) : this(
         environment: Platform.environment,
         resolveApplicationSupportDirectory:
             resolveApplicationSupportDirectory,
       );

  final Map<String, String> _environment;
  final Future<Directory> Function() _resolveApplicationSupportDirectory;

  /// Overrides the resolved shared-library path. For development against a
  /// locally built core.
  static const String libraryPathVariable = 'ALEXANDRIA_CORE_LIBRARY';

  /// Overrides the resolved database path at run time.
  static const String databasePathVariable = 'ALEXANDRIA_DB_PATH';

  /// Overrides the resolved database path at build time.
  static const String databasePathDefine = String.fromEnvironment(
    'ALEXANDRIA_DB_PATH',
  );

  /// The folder the settings store, the log file, and the database live in.
  static const String applicationFolderName = 'Alexandria';

  /// The shared library's file name on the running platform.
  static String get libraryFileName {
    if (Platform.isWindows) return 'alexandria_ffi.dll';
    if (Platform.isLinux) return 'libalexandria_ffi.so';

    // IR-01 configures no other target. Reaching this means the application was
    // built for a platform it does not support, which is worth failing loudly
    // rather than probing for a file that cannot exist.
    throw UnsupportedError(
      'Alexandria Desktop targets Windows and Linux only; '
      'this build is running on ${Platform.operatingSystem}',
    );
  }

  /// Every location the shared library is looked for, in order (IR-04).
  ///
  /// The installed application resolves it relative to its own executable, which
  /// is what makes a packaged build self-contained. The working-directory entries
  /// are what let a development checkout run against `native/` without an
  /// environment variable.
  List<String> get librarySearchPaths {
    final override = _environment[libraryPathVariable];
    if (override != null && override.isNotEmpty) return [override];

    final fileName = libraryFileName;
    final executableDirectory = p.dirname(Platform.resolvedExecutable);
    final platformFolder = Platform.isWindows ? 'windows' : 'linux';

    return [
      p.join(executableDirectory, fileName),
      p.join(executableDirectory, 'lib', fileName),
      p.join(executableDirectory, 'blobs', fileName),
      p.join('native', platformFolder, fileName),
      p.join('build', platformFolder, fileName),
    ];
  }

  /// The first search path that exists, or `null` when none does.
  ///
  /// Returning `null` rather than throwing lets startup step 1 report every path
  /// it tried, which is the difference between an actionable failure and "could
  /// not load".
  String? resolveLibraryPath() {
    for (final candidate in librarySearchPaths) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  /// The application-support directory, created when absent (IR-05).
  Future<Directory> resolveApplicationDirectory() async {
    final base = await _resolveApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, applicationFolderName));

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    return directory;
  }

  /// The catalog database path (IR-05).
  ///
  /// The run-time variable wins over the build-time define, which wins over the
  /// application-support directory: the more specific the override, the later it
  /// was chosen and the more it should be honored.
  Future<String> resolveDatabasePath() async {
    final runtimeOverride = _environment[databasePathVariable];
    if (runtimeOverride != null && runtimeOverride.isNotEmpty) {
      return runtimeOverride;
    }
    if (databasePathDefine.isNotEmpty) return databasePathDefine;

    final directory = await resolveApplicationDirectory();
    return p.join(directory.path, 'catalog.db');
  }
}
