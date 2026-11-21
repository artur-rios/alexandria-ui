import 'dart:io';

import '../domain/update_ports.dart';
import 'linux_update_helper.dart';
import 'windows_setup_installer.dart';

/// [UpdateInstaller] for the Linux installer and the AppImage
/// (update-check design §3 step 4).
///
/// Neither can replace a running application from inside it, so a small
/// helper does it after the application exits: it is written beside the
/// package and started in its own session, so it outlives this process.
class LinuxHelperInstaller implements UpdateInstaller {
  /// Creates the installer.
  const LinuxHelperInstaller({
    required this.appImage,
    required this.processId,
    required this.executable,
    this.start = startDetached,
  });

  /// Whether the update replaces an AppImage rather than running the
  /// installer.
  final bool appImage;

  /// This process's id, which the helper waits on.
  final int processId;

  /// The executable to start again afterwards.
  final String executable;

  /// Starts the installer, detached.
  final ProcessStarter start;

  @override
  Future<void> launch({
    required File package,
    required String installLocation,
    required String fromVersion,
  }) async {
    final helper = File('${package.parent.path}/update-helper.sh')
      ..writeAsStringSync(linuxUpdateHelperScript);

    await start('setsid', [
      'sh',
      helper.path,
      '$processId',
      if (appImage) 'appimage' else 'installer',
      package.path,
      installLocation,
      executable,
    ]);
  }
}
