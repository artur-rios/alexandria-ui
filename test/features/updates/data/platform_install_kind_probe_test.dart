import 'package:alexandria_ui/features/updates/data/platform_install_kind_probe.dart';
import 'package:alexandria_ui/features/updates/domain/install_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// How this copy was installed, from facts on disk (update-check design §1).
void main() {
  PlatformInstallKindProbe probe({
    bool isWindows = false,
    String executable = '/home/me/.local/opt/alexandria/alexandria',
    Map<String, String> environment = const {'HOME': '/home/me'},
    Map<String, String> files = const {},
    Set<String> writable = const {},
    String? registryLocation,
  }) => PlatformInstallKindProbe(
    isWindows: isWindows,
    executable: executable,
    environment: environment,
    exists: files.containsKey,
    isWritable: writable.contains,
    readFile: (path) => files[path],
    registryInstallLocation: () => registryLocation,
  );

  group('Windows', () {
    const exe = r'C:\Users\me\AppData\Local\Programs\Alexandria\alexandria.exe';
    const folder = r'C:\Users\me\AppData\Local\Programs\Alexandria';

    test(
      'GivenTheUninstallKeyMatchingAWritableExecutableFolder_WhenDetected_ThenWindowsInstaller',
      () {
        final sut = probe(
          isWindows: true,
          executable: exe,
          // Recorded with a trailing separator and in another case: the same
          // folder to Windows.
          registryLocation: r'c:\users\me\appdata\local\programs\alexandria\',
          writable: {folder},
        );

        expect(sut.detect(), InstallKind.windowsInstaller);
        expect(sut.installLocation(), folder);
      },
    );

    test('GivenTheKeyButAFolderTheUserCannotWrite_WhenDetected_ThenManual', () {
      final sut = probe(
        isWindows: true,
        executable: r'C:\Program Files\Alexandria\alexandria.exe',
        registryLocation: r'C:\Program Files\Alexandria',
      );

      expect(sut.detect(), InstallKind.manual);
      expect(sut.installLocation(), isNull);
    });

    test('GivenTheKeyForAnotherFolder_WhenDetected_ThenManual', () {
      final sut = probe(
        isWindows: true,
        executable: r'D:\portable\alexandria\alexandria.exe',
        registryLocation: folder,
        writable: {r'D:\portable\alexandria', folder},
      );

      expect(sut.detect(), InstallKind.manual);
    });

    test('GivenAWindowsAppsPath_WhenDetected_ThenManual', () {
      final sut = probe(
        isWindows: true,
        executable:
            r'C:\Program Files\WindowsApps\Alexandria_1.2.0.0_x64__abc\alexandria.exe',
      );

      expect(sut.detect(), InstallKind.manual);
    });
  });

  group('Linux', () {
    const prefix = '/home/me/.local/opt/alexandria';
    const userManifest = '/home/me/.local/state/alexandria/install.manifest';

    test(
      'GivenAUserManifestWhosePrefixHoldsTheExecutable_WhenDetected_ThenLinuxInstaller',
      () {
        final sut = probe(
          files: {userManifest: 'prefix=$prefix\nfile=$prefix/alexandria\n'},
          writable: {prefix},
        );

        expect(sut.detect(), InstallKind.linuxInstaller);
        expect(sut.installLocation(), prefix);
      },
    );

    test('GivenXdgStateHome_WhenDetected_ThenItsManifestIsRead', () {
      final sut = probe(
        environment: const {'HOME': '/home/me', 'XDG_STATE_HOME': '/state'},
        files: {'/state/alexandria/install.manifest': 'prefix=$prefix\n'},
        writable: {prefix},
      );

      expect(sut.detect(), InstallKind.linuxInstaller);
    });

    test('GivenARootManifestAndAnUnwritablePrefix_WhenDetected_ThenManual', () {
      final sut = probe(
        executable: '/opt/alexandria/alexandria',
        files: {
          '/var/lib/alexandria/install.manifest': 'prefix=/opt/alexandria\n',
        },
      );

      expect(sut.detect(), InstallKind.manual);
    });

    test('GivenAManifestForAnotherPrefix_WhenDetected_ThenManual', () {
      final sut = probe(
        executable: '/home/me/Downloads/alexandria/alexandria',
        files: {userManifest: 'prefix=$prefix\n'},
        writable: {prefix, '/home/me/Downloads/alexandria'},
      );

      expect(sut.detect(), InstallKind.manual);
    });

    test('GivenAppImageSetAndAWritableFolder_WhenDetected_ThenAppImage', () {
      final sut = probe(
        executable: '/tmp/.mount_abc/usr/bin/alexandria',
        environment: const {
          'HOME': '/home/me',
          'APPIMAGE': '/home/me/Apps/Alexandria.AppImage',
        },
        writable: {'/home/me/Apps'},
      );

      expect(sut.detect(), InstallKind.appImage);
      expect(sut.installLocation(), '/home/me/Apps/Alexandria.AppImage');
    });

    test(
      'GivenAppImageInAFolderTheUserCannotWrite_WhenDetected_ThenManual',
      () {
        final sut = probe(
          environment: const {
            'HOME': '/home/me',
            'APPIMAGE': '/opt/A.AppImage',
          },
        );

        expect(sut.detect(), InstallKind.manual);
      },
    );

    test('GivenFlatpakId_WhenDetected_ThenFlatpak', () {
      final sut = probe(
        executable: '/app/alexandria/alexandria',
        environment: const {'FLATPAK_ID': 'io.github.artur_rios.Alexandria'},
      );

      expect(sut.detect(), InstallKind.flatpak);
      expect(sut.installLocation(), isNull);
    });

    test('GivenUsrExecutable_WhenDetected_ThenManual', () {
      final sut = probe(executable: '/usr/share/alexandria_ui/alexandria');

      expect(sut.detect(), InstallKind.manual);
    });
  });
}
