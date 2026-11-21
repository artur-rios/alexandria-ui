import 'dart:io';

import 'package:alexandria_ui/features/updates/data/linux_update_helper.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell helper that installs after the application has exited
/// (update-check design §3 step 4), run for real with `sh`.
///
/// Skipped on Windows, where the suite also runs: the helper only ever runs on
/// Linux, and Git's sh there has no executable bit and no Linux process IDs.
/// Marked per test rather than with `@TestOn`, which ci/unit-suite.sh's
/// bundles would drop.
void main() {
  final onlyOnLinux = Platform.isWindows
      ? 'the Linux update helper runs only on Linux'
      : null;

  late Directory root;
  late Directory work;
  late String helper;

  setUp(() {
    root = Directory.systemTemp.createTempSync('alexandria helper');
    work = Directory('${root.path}/work')..createSync();
    helper = '${work.path}/update-helper.sh';
    File(helper).writeAsStringSync(linuxUpdateHelperScript);
  });
  tearDown(() => root.deleteSync(recursive: true));

  /// A program that writes [marker] into [root] when run.
  String program(String name, String marker, {int exitCode = 0}) {
    final path = '${root.path}/$name';
    File(path).writeAsStringSync(
      '#!/bin/sh\necho "\$@" > "${root.path}/$marker"\nexit $exitCode\n',
    );
    Process.runSync('chmod', ['+x', path]);
    return path;
  }

  /// Runs the helper as the application would, and waits for it.
  Future<void> runHelper(List<String> arguments) async {
    final result = await Process.run('sh', [helper, ...arguments]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    // The relaunch is started in the background; give it a moment.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  test(
    'GivenASucceedingInstaller_WhenTheHelperRuns_ThenItWaitsInstallsRelaunchesAndCleansUp',
    () async {
      final waiting = await Process.start('sleep', ['1']);
      final installer = program('installer.sh', 'installed');
      final executable = program('alexandria', 'relaunched');
      final location = '${root.path}/My Apps';
      final started = DateTime.now();

      await runHelper([
        '${waiting.pid}',
        'installer',
        installer,
        location,
        executable,
      ]);

      expect(
        DateTime.now().difference(started),
        greaterThan(const Duration(milliseconds: 700)),
        reason: 'it did not wait for the application to exit',
      );
      expect(
        File('${root.path}/installed').readAsStringSync().trim(),
        '--yes --prefix $location',
      );
      expect(File('${root.path}/relaunched').existsSync(), isTrue);
      expect(work.existsSync(), isFalse, reason: 'its folder was left behind');
    },
    skip: onlyOnLinux,
  );

  test(
    'GivenAFailingInstaller_WhenTheHelperRuns_ThenTheOldExecutableIsRelaunched',
    () async {
      final installer = program('installer.sh', 'installed', exitCode: 1);
      final executable = program('alexandria', 'relaunched');

      await runHelper([
        '999999',
        'installer',
        installer,
        '${root.path}/app',
        executable,
      ]);

      expect(File('${root.path}/relaunched').existsSync(), isTrue);
    },
    skip: onlyOnLinux,
  );

  test(
    'GivenAnAppImageMode_WhenTheHelperRuns_ThenTheFileIsReplacedAndExecutable',
    () async {
      final current = program('Alexandria.AppImage', 'old-ran');
      final next = '${work.path}/new.AppImage';
      File(
        next,
      ).writeAsStringSync('#!/bin/sh\necho new > "${root.path}/relaunched"\n');

      await runHelper(['999999', 'appimage', next, current, current]);

      expect(File(current).readAsStringSync(), contains('echo new'));
      expect(
        (File(current).statSync().mode & 0x40) != 0,
        isTrue,
        reason: 'the new AppImage is not executable',
      );
      expect(File('${root.path}/relaunched').readAsStringSync().trim(), 'new');
    },
    skip: onlyOnLinux,
  );
}
