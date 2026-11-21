import 'app_version.dart';
import 'install_kind.dart';

/// One file published with a release.
class ReleaseAsset {
  /// Creates the asset.
  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.size,
  });

  /// The file's name, which says what it is (the release's naming).
  final String name;

  /// Where it downloads from.
  final String url;

  /// Its size in bytes.
  final int size;
}

/// The latest release, as GitHub's `releases/latest` answers it.
class ReleaseInfo {
  /// Creates the release.
  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    required this.assets,
  });

  /// Its version, from the tag.
  final AppVersion version;

  /// Its notes: the changelog section, in Markdown.
  final String notes;

  /// The release's page, for the owner to download by hand.
  final String pageUrl;

  /// Every file published with it.
  final List<ReleaseAsset> assets;

  /// The release [json] describes, or null when its tag is not a plain
  /// release version.
  static ReleaseInfo? fromGitHubJson(Map<String, dynamic> json) {
    final version = AppVersion.parse(json['tag_name'] as String? ?? '');
    if (version == null) return null;

    return ReleaseInfo(
      version: version,
      notes: json['body'] as String? ?? '',
      pageUrl: json['html_url'] as String? ?? '',
      assets: [
        for (final raw in json['assets'] as List<dynamic>? ?? const [])
          if (raw case {
            'name': final String name,
            'browser_download_url': final String url,
            'size': final int size,
          })
            ReleaseAsset(name: name, url: url, size: size),
      ],
    );
  }

  /// The package that updates a [kind] installation, or null when the
  /// application cannot update that kind itself or the release lacks it.
  ReleaseAsset? packageFor(InstallKind kind) => switch (kind) {
    InstallKind.windowsInstaller => _named('alexandria-setup-$version.exe'),
    InstallKind.linuxInstaller => _named(
      'alexandria-installer-$version-linux-x64.sh',
    ),
    InstallKind.appImage => _named('alexandria-$version-linux-x86_64.AppImage'),
    InstallKind.flatpak || InstallKind.manual => null,
  };

  /// The checksums file covering [kind]'s package, or null when the release
  /// publishes none.
  ReleaseAsset? checksumsFor(InstallKind kind) => switch (kind) {
    InstallKind.windowsInstaller => _named(
      'alexandria-$version-windows-SHA256SUMS',
    ),
    InstallKind.linuxInstaller ||
    InstallKind.appImage => _named('alexandria-$version-linux-SHA256SUMS'),
    InstallKind.flatpak || InstallKind.manual => null,
  };

  ReleaseAsset? _named(String name) {
    for (final asset in assets) {
      if (asset.name == name) return asset;
    }
    return null;
  }
}
