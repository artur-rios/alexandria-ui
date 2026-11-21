import 'dart:io';

import '../domain/update_ports.dart';

/// Starts a program that outlives the application.
typedef ProcessStarter =
    Future<void> Function(String executable, List<String> arguments);

/// Starts [executable] detached, so it keeps running after the application
/// exits.
Future<void> startDetached(String executable, List<String> arguments) =>
    Process.start(executable, arguments, mode: ProcessStartMode.detached);

/// [UpdateInstaller] for the Windows setup (update-check design §3 step 4).
///
/// Runs the new setup silently into the folder this copy was installed in.
/// `/UPDATE` tells the setup an update is under way: it answers its own
/// questions with their defaults and starts the application again when it is
/// done. Inno's restart manager waits for this process to close.
class WindowsSetupInstaller implements UpdateInstaller {
  /// Creates the installer.
  const WindowsSetupInstaller({this.start = startDetached});

  /// Starts the installer, detached.
  final ProcessStarter start;

  @override
  Future<void> launch({
    required File package,
    required String installLocation,
    required String fromVersion,
  }) => start(package.path, [
    '/SILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
    '/UPDATE',
    // One argument; Dart quotes it on the command line when it holds spaces,
    // which is the form Inno reads.
    '/DIR=$installLocation',
  ]);
}
