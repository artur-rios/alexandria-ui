import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

import '../domain/install_kind.dart';
import '../domain/update_ports.dart';

/// [InstallKindProbe] over the facts an installation leaves on disk
/// (update-check design §1).
///
/// Every check is a fact rather than a guess: an uninstall key whose folder
/// is this executable's, a manifest whose prefix holds it, `$APPIMAGE`,
/// `FLATPAK_ID`. Anything uncertain is [InstallKind.manual], which is always
/// safe — the owner is sent to the release page. So is an installation this
/// user cannot write to: updating it would need elevation, which the
/// application never asks for.
class PlatformInstallKindProbe implements InstallKindProbe {
  /// Creates the probe over the given seams; [PlatformInstallKindProbe.system]
  /// is the real one.
  PlatformInstallKindProbe({
    required this.isWindows,
    required this.executable,
    required this.environment,
    required this.exists,
    required this.isWritable,
    required this.readFile,
    required this.registryInstallLocation,
  });

  /// The probe over this process, this machine's files, and its registry.
  factory PlatformInstallKindProbe.system() => PlatformInstallKindProbe(
    isWindows: Platform.isWindows,
    executable: Platform.resolvedExecutable,
    environment: Platform.environment,
    exists: (path) => File(path).existsSync(),
    isWritable: _canWriteTo,
    readFile: (path) {
      try {
        return File(path).readAsStringSync();
      } on FileSystemException {
        return null;
      }
    },
    registryInstallLocation: _readInstallLocation,
  );

  /// Whether this runs on Windows.
  final bool isWindows;

  /// The running executable's full path.
  final String executable;

  /// The process environment.
  final Map<String, String> environment;

  /// Whether a file exists.
  final bool Function(String path) exists;

  /// Whether this user can create files in a folder.
  final bool Function(String directory) isWritable;

  /// A file's text, or null when it cannot be read.
  final String? Function(String path) readFile;

  /// The Windows setup's recorded install folder, or null.
  final String? Function() registryInstallLocation;

  ({InstallKind kind, String? location})? _detected;

  @override
  InstallKind detect() => (_detected ??= _detect()).kind;

  @override
  String? installLocation() => (_detected ??= _detect()).location;

  ({InstallKind kind, String? location}) _detect() {
    const manual = (kind: InstallKind.manual, location: null);

    if (environment.containsKey('FLATPAK_ID')) {
      return (kind: InstallKind.flatpak, location: null);
    }

    final appImage = environment['APPIMAGE'];
    if (appImage != null && appImage.isNotEmpty) {
      return isWritable(_parentOf(appImage))
          ? (kind: InstallKind.appImage, location: appImage)
          : manual;
    }

    final folder = _parentOf(executable);

    if (isWindows) {
      final recorded = registryInstallLocation();
      if (recorded == null || !_samePath(recorded, folder, ignoreCase: true)) {
        return manual;
      }
      return isWritable(folder)
          ? (kind: InstallKind.windowsInstaller, location: folder)
          : manual;
    }

    for (final manifest in _manifestPaths()) {
      if (!exists(manifest)) continue;
      final prefix = _manifestPrefix(readFile(manifest));
      if (prefix == null || !_holds(prefix, executable)) continue;

      return isWritable(prefix)
          ? (kind: InstallKind.linuxInstaller, location: _trimmed(prefix))
          : manual;
    }

    return manual;
  }

  /// Where the Linux installer writes its manifest: the user's state folder,
  /// then the system one a root install uses.
  List<String> _manifestPaths() {
    final state =
        environment['XDG_STATE_HOME'] ??
        '${environment['HOME'] ?? ''}/.local/state';

    return [
      '$state/alexandria/install.manifest',
      '/var/lib/alexandria/install.manifest',
    ];
  }

  static String? _manifestPrefix(String? text) {
    if (text == null) return null;
    for (final line in text.split('\n')) {
      if (line.startsWith('prefix=')) return line.substring('prefix='.length);
    }
    return null;
  }

  /// Whether [path] lies inside [folder].
  bool _holds(String folder, String path) => _normal(
    path,
    ignoreCase: false,
  ).startsWith('${_normal(folder, ignoreCase: false)}/');

  bool _samePath(String a, String b, {required bool ignoreCase}) =>
      _normal(a, ignoreCase: ignoreCase) == _normal(b, ignoreCase: ignoreCase);

  static String _normal(String path, {required bool ignoreCase}) {
    final slashes = path.replaceAll(r'\', '/');
    final trimmed = slashes.endsWith('/') && slashes.length > 1
        ? slashes.substring(0, slashes.length - 1)
        : slashes;
    return ignoreCase ? trimmed.toLowerCase() : trimmed;
  }

  static String _trimmed(String path) =>
      path.length > 1 && (path.endsWith('/') || path.endsWith(r'\'))
      ? path.substring(0, path.length - 1)
      : path;

  static String _parentOf(String path) {
    final cut = path.lastIndexOf(RegExp(r'[/\\]'));
    return cut <= 0 ? path : path.substring(0, cut);
  }

  static bool _canWriteTo(String directory) {
    try {
      final probe = File(
        '$directory${Platform.pathSeparator}.alexandria-write-probe-$pid',
      )..writeAsStringSync('');
      probe.deleteSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  /// The setup's `InstallLocation`, from the current user's key first and
  /// then the machine's, in both registry views.
  static String? _readInstallLocation() {
    const key =
        r'Software\Microsoft\Windows\CurrentVersion\Uninstall\'
        r'{8F2A6C41-9B3E-4D77-A5C2-1E6D0B9F4A38}_is1';
    // KEY_WOW64_64KEY and KEY_WOW64_32KEY: the setup may have registered in
    // either view.
    const views = [RegistryAccess(.new(0x0100)), RegistryAccess(.new(0x0200))];

    for (final root in [CURRENT_USER, LOCAL_MACHINE]) {
      for (final view in views) {
        try {
          final opened = root.open(
            key,
            config: RegistryOpenConfig(access: RegistryAccess.read | view),
          );
          try {
            final location = opened.getString('InstallLocation');
            if (location != null && location.isNotEmpty) return location;
          } finally {
            opened.close();
          }
        } on Object {
          // Not registered in this hive or view; the next one may be.
        }
      }
    }
    return null;
  }
}
