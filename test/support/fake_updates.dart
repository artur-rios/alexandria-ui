import 'dart:io';

import 'package:alexandria_ui/features/updates/data/pending_update_store.dart';
import 'package:alexandria_ui/features/updates/domain/app_version.dart';
import 'package:alexandria_ui/features/updates/domain/install_kind.dart';
import 'package:alexandria_ui/features/updates/domain/release_info.dart';
import 'package:alexandria_ui/features/updates/domain/update_ports.dart';

/// A release named [version] with the packages and checksums files the
/// release pipeline publishes, unless told to leave the checksums out.
ReleaseInfo aRelease(String version, {bool withChecksums = true}) =>
    ReleaseInfo(
      version: AppVersion.parse(version)!,
      notes: '### Added\n\n- Something new in $version.',
      pageUrl: 'https://example.test/releases/v$version',
      assets: [
        for (final name in [
          'alexandria-setup-$version.exe',
          'alexandria-installer-$version-linux-x64.sh',
          'alexandria-$version-linux-x86_64.AppImage',
          if (withChecksums) ...[
            'alexandria-$version-windows-SHA256SUMS',
            'alexandria-$version-linux-SHA256SUMS',
          ],
        ])
          ReleaseAsset(name: name, url: 'https://example.test/$name', size: 3),
      ],
    );

/// A [ReleaseSource] answering what a test says.
class FakeReleaseSource implements ReleaseSource {
  /// Creates the source answering [release], or throwing when it is null.
  FakeReleaseSource([this.release]);

  /// What [latest] answers; null makes it throw.
  ReleaseInfo? release;

  /// How many times it was asked.
  int requests = 0;

  @override
  Future<ReleaseInfo> latest() async {
    requests++;
    final answer = release;
    if (answer == null) throw const UpdateCheckException('offline');
    return answer;
  }
}

/// An [InstallKindProbe] answering a fixed kind.
class FakeInstallKindProbe implements InstallKindProbe {
  /// Creates the probe.
  FakeInstallKindProbe([
    this.kind = InstallKind.linuxInstaller,
    this.location = '/home/me/.local/opt/alexandria',
  ]);

  /// The kind it answers.
  final InstallKind kind;

  /// The location it answers.
  final String? location;

  @override
  InstallKind detect() => kind;

  @override
  String? installLocation() => kind.updatesItself ? location : null;
}

/// A [Downloader] that writes fixed contents per URL, without a network.
class FakeDownloader implements Downloader {
  /// The bytes written for each URL; a missing URL fails the download.
  final Map<String, String> contents = {};

  /// URLs downloaded, in order.
  final List<String> downloaded = [];

  /// Where each download was written, in order.
  final List<File> targets = [];

  @override
  Future<File> download(
    Uri url,
    File to, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  }) async {
    downloaded.add(url.toString());
    targets.add(to);
    final body = contents[url.toString()];
    if (body == null || (cancel?.isCancelled ?? false)) {
      throw HttpException('no such file', uri: url);
    }
    onProgress?.call(body.length, body.length);
    return to..writeAsStringSync(body);
  }

  @override
  Future<String> sha256Of(File file) async =>
      _known[file.readAsStringSync()] ?? 'unknown';

  /// SHA-256 of the few bodies tests use.
  static const Map<String, String> _known = {
    'abc': 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
  };
}

/// An [UpdateInstaller] that records what it was asked to install.
class FakeUpdateInstaller implements UpdateInstaller {
  /// Every launch, in order.
  final List<({String package, String location, String from})> launches = [];

  @override
  Future<void> launch({
    required File package,
    required String installLocation,
    required String fromVersion,
  }) async => launches.add((
    package: package.path,
    location: installLocation,
    from: fromVersion,
  ));
}

/// The pending-update record in [folder], for tests in the layers that may
/// not import the Data layer themselves.
PendingUpdateStore pendingStoreIn(Directory folder) =>
    PendingUpdateStore(folder);
