import 'package:alexandria_ui/features/updates/domain/app_version.dart';
import 'package:alexandria_ui/features/updates/domain/install_kind.dart';
import 'package:alexandria_ui/features/updates/domain/release_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// The answer of GitHub's `releases/latest`, in the shape the 1.0.1 release
/// has (update-check design §2).
void main() {
  Map<String, dynamic> asset(String name) => {
    'name': name,
    'browser_download_url': 'https://example.test/$name',
    'size': 100,
  };

  Map<String, dynamic> latest({
    String tag = 'v1.2.0',
    List<String> names = const [
      'alexandria-1.2.0-downloads.md',
      'alexandria-1.2.0-linux-x64.tar.gz',
      'alexandria-1.2.0-linux-x86_64.AppImage',
      'alexandria-1.2.0-windows-x64.zip',
      'alexandria-1.2.0.flatpak',
      'alexandria-installer-1.2.0-linux-x64.sh',
      'alexandria-setup-1.2.0.exe',
      'alexandria.msix',
      'alexandria_ui-1.2.0+1-linux.deb',
      'alexandria-1.2.0-linux-SHA256SUMS',
      'alexandria-1.2.0-windows-SHA256SUMS',
    ],
  }) => {
    'tag_name': tag,
    'body': '### Added\n\n- A thing.',
    'html_url': 'https://github.com/artur-rios/alexandria-ui/releases/tag/$tag',
    'assets': [for (final name in names) asset(name)],
  };

  test('GivenGitHubLatestJson_WhenRead_ThenVersionNotesPageAndAssets', () {
    final release = ReleaseInfo.fromGitHubJson(latest())!;

    expect(release.version, const AppVersion(1, 2, 0));
    expect(release.notes, '### Added\n\n- A thing.');
    expect(
      release.pageUrl,
      'https://github.com/artur-rios/alexandria-ui/releases/tag/v1.2.0',
    );
    expect(release.assets, hasLength(11));
    expect(
      release.assets.first.url,
      'https://example.test/alexandria-1.2.0-downloads.md',
    );
    expect(release.assets.first.size, 100);
  });

  test('GivenAnUnparseableTag_WhenRead_ThenNull', () {
    expect(ReleaseInfo.fromGitHubJson(latest(tag: 'nightly')), isNull);
    expect(ReleaseInfo.fromGitHubJson(latest(tag: 'v1.3.0-rc.1')), isNull);
  });

  test('GivenEachKind_WhenThePackageIsChosen_ThenTheMatchingAssetName', () {
    final release = ReleaseInfo.fromGitHubJson(latest())!;

    expect(
      release.packageFor(InstallKind.windowsInstaller)?.name,
      'alexandria-setup-1.2.0.exe',
    );
    expect(
      release.packageFor(InstallKind.linuxInstaller)?.name,
      'alexandria-installer-1.2.0-linux-x64.sh',
    );
    expect(
      release.packageFor(InstallKind.appImage)?.name,
      'alexandria-1.2.0-linux-x86_64.AppImage',
    );
    expect(release.packageFor(InstallKind.flatpak), isNull);
    expect(release.packageFor(InstallKind.manual), isNull);

    expect(
      release.checksumsFor(InstallKind.windowsInstaller)?.name,
      'alexandria-1.2.0-windows-SHA256SUMS',
    );
    expect(
      release.checksumsFor(InstallKind.linuxInstaller)?.name,
      'alexandria-1.2.0-linux-SHA256SUMS',
    );
    expect(
      release.checksumsFor(InstallKind.appImage)?.name,
      'alexandria-1.2.0-linux-SHA256SUMS',
    );
  });

  test('GivenNoChecksumsAsset_WhenAsked_ThenNull', () {
    final release = ReleaseInfo.fromGitHubJson(
      latest(names: const ['alexandria-setup-1.2.0.exe']),
    )!;

    expect(release.checksumsFor(InstallKind.windowsInstaller), isNull);
  });
}
