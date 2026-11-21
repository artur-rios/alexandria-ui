import 'dart:io';

import 'package:alexandria_ui/features/updates/data/linux_helper_installer.dart';
import 'package:alexandria_ui/features/updates/data/linux_update_helper.dart';
import 'package:alexandria_ui/features/updates/data/windows_setup_installer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Starting the installers (update-check design §3 step 4).
void main() {
  late Directory folder;
  final started = <({String executable, List<String> arguments})>[];

  setUp(() {
    started.clear();
    folder = Directory.systemTemp.createTempSync('alexandria_inst');
  });
  tearDown(() => folder.deleteSync(recursive: true));

  Future<void> record(String executable, List<String> arguments) async =>
      started.add((executable: executable, arguments: arguments));

  test(
    'GivenAFolderWithSpaces_WhenTheSetupIsStarted_ThenDirIsOneArgument',
    () async {
      final setup = File('${folder.path}/alexandria-setup-1.2.0.exe')
        ..writeAsStringSync('');

      await WindowsSetupInstaller(start: record).launch(
        package: setup,
        installLocation: r'C:\Program Files\Ålexandria',
        fromVersion: '1.1.0',
      );

      expect(started.single.executable, setup.path);
      expect(started.single.arguments, [
        '/SILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/UPDATE',
        r'/DIR=C:\Program Files\Ålexandria',
      ]);
    },
  );

  test(
    'GivenTheLinuxInstallerKind_WhenLaunched_ThenSetsidHelperWithInstallerMode',
    () async {
      final installer = File(
        '${folder.path}/alexandria-installer-1.2.0-linux-x64.sh',
      )..writeAsStringSync('');

      await LinuxHelperInstaller(
        start: record,
        appImage: false,
        processId: 4242,
        executable: '/home/me/My Apps/alexandria/alexandria',
      ).launch(
        package: installer,
        installLocation: '/home/me/My Apps/alexandria',
        fromVersion: '1.1.0',
      );

      final helper = '${folder.path}/update-helper.sh';
      expect(started.single.executable, 'setsid');
      expect(started.single.arguments, [
        'sh',
        helper,
        '4242',
        'installer',
        installer.path,
        '/home/me/My Apps/alexandria',
        '/home/me/My Apps/alexandria/alexandria',
      ]);
      expect(File(helper).readAsStringSync(), linuxUpdateHelperScript);
    },
  );

  test('GivenTheAppImageKind_WhenLaunched_ThenAppImageMode', () async {
    final image = File('${folder.path}/alexandria-1.2.0-linux-x86_64.AppImage')
      ..writeAsStringSync('');

    await LinuxHelperInstaller(
      start: record,
      appImage: true,
      processId: 7,
      executable: '/tmp/.mount_x/usr/bin/alexandria',
    ).launch(
      package: image,
      installLocation: '/home/me/Apps/Alexandria.AppImage',
      fromVersion: '1.1.0',
    );

    expect(started.single.arguments[3], 'appimage');
  });
}
