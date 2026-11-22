import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import '../domain/app_version.dart';
import '../domain/checksums.dart';
import '../domain/install_kind.dart';
import '../domain/release_info.dart';
import '../domain/update_ports.dart';
import 'update_state.dart';

/// Checks for a newer release, and downloads and verifies it
/// (update-check design §2, §3).
///
/// The check runs once per process, when startup reaches ready. A failure
/// there is logged and nothing is shown: an owner offline, or a server that
/// answers badly, must never see startup slowed or an error they did not ask
/// for. "Check now" is the explicit request, and says what happened.
class UpdateController extends Notifier<UpdateState> {
  static final Logger _log = Logger('updates');

  /// Where the skipped version is stored.
  static const String skippedVersionKey = 'updates.skippedVersion';

  Future<void>? _atStartup;

  CancelToken? _download;

  @override
  UpdateState build() {
    ref.listen(startupControllerProvider, (_, next) {
      if (next is StartupReady) _startOnce();
    }, fireImmediately: true);

    return const UpdateState.idle();
  }

  void _startOnce() => unawaited(checkAtStartup());

  /// The check at startup: silent unless there is something to offer.
  ///
  /// Once per process: every caller shares the one run, so a second call can
  /// never override what the first found — a failed update's notice above
  /// all, whose record the first run has already cleared.
  Future<void> checkAtStartup() => _atStartup ??= _checkAtStartup();

  Future<void> _checkAtStartup() async {
    if (!ref.read(isReleaseBuildProvider)) return;

    // A failed update's notice wins over a new prompt this start — and is
    // given whether or not the startup check is on, since "Check now" updates
    // with it off.
    if (await _previousUpdateFailed() || !ref.mounted) return;

    if (!ref.read(preferencesControllerProvider).checksForUpdates) return;

    final kind = ref.read(installKindProbeProvider).detect();
    if (kind == InstallKind.flatpak) return;

    try {
      final release = await ref.read(releaseSourceProvider).latest();
      if (!ref.mounted || !_isNewer(release)) return;
      if (_settings?.getString(skippedVersionKey) ==
          release.version.toString()) {
        return;
      }
      state = _available(release, kind);
    } on Object catch (error) {
      _log.info('update check failed: $error');
    }
  }

  /// "Check now": says what it found, and offers a skipped version anyway.
  Future<void> checkNow() async {
    state = const UpdateState.checking();
    try {
      final release = await ref.read(releaseSourceProvider).latest();
      if (!ref.mounted) return;
      state = _isNewer(release)
          ? _available(release, ref.read(installKindProbeProvider).detect())
          : const UpdateState.upToDate();
    } on Object catch (error) {
      _log.info('update check failed: $error');
      if (ref.mounted) state = const UpdateState.checkFailed();
    }
  }

  /// Not now: asked again at the next start.
  void later() => state = const UpdateState.idle();

  /// Never this version: remembered, and a newer one is offered again.
  Future<void> skip() async {
    final current = state;
    state = const UpdateState.idle();
    if (current is UpdateAvailable) {
      await _settings?.setString(
        skippedVersionKey,
        current.release.version.toString(),
      );
    }
  }

  /// Downloads the offered package and verifies it against the release's
  /// checksums. Anything that does not verify is deleted, never run.
  Future<void> download() async {
    final offered = state;
    if (offered is! UpdateAvailable || !offered.canInstall) return;
    final release = offered.release;
    final package = release.packageFor(offered.kind)!;
    final sums = release.checksumsFor(offered.kind)!;
    final downloader = ref.read(downloaderProvider);
    final cancel = _download = CancelToken();

    final folder = Directory.systemTemp.createTempSync('alexandria-update');
    final target = File(
      '${folder.path}${Platform.pathSeparator}${package.name}',
    );
    state = UpdateState.downloading(
      release: release,
      received: 0,
      total: package.size,
    );

    try {
      await downloader.download(
        Uri.parse(package.url),
        target,
        cancel: cancel,
        onProgress: (received, total) {
          if (state is UpdateDownloading) {
            state = UpdateState.downloading(
              release: release,
              received: received,
              total: total > 0 ? total : package.size,
            );
          }
        },
      );
      final sumsFile = await downloader.download(
        Uri.parse(sums.url),
        File('${folder.path}${Platform.pathSeparator}${sums.name}'),
        cancel: cancel,
      );

      final expected = checksumFor(sumsFile.readAsStringSync(), package.name);
      final actual = await downloader.sha256Of(target);
      if (expected == null || expected != actual) {
        _log.warning('update ${release.version} did not verify');
        folder.deleteSync(recursive: true);
        state = UpdateState.verifyFailed(release: release);
        return;
      }

      state = UpdateState.readyToInstall(release: release, package: target);
    } on Object catch (error) {
      if (folder.existsSync()) folder.deleteSync(recursive: true);
      if (cancel.isCancelled) {
        state = offered;
        return;
      }
      _log.warning('update download failed: $error');
      state = UpdateState.downloadFailed(release: release);
    } finally {
      if (identical(_download, cancel)) _download = null;
    }
  }

  /// Stops a download in flight; the offer stands.
  void cancelDownload() => _download?.cancel();

  /// The installer could not be started: the package goes, and the owner is
  /// told and pointed at the release page.
  void installFailed() {
    final ready = state;
    if (ready is! UpdateReadyToInstall) return;
    final folder = ready.package.parent;
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    state = UpdateState.installFailed(release: ready.release);
  }

  /// Goes back to the offer when the owner stopped the close, deleting the
  /// downloaded package: a later Update now downloads it afresh.
  void abandonInstall() {
    final ready = state;
    if (ready is! UpdateReadyToInstall) return;
    final folder = ready.package.parent;
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    state = _available(
      ready.release,
      ref.read(installKindProbeProvider).detect(),
    );
  }

  /// Closes a notice or a failure.
  void dismiss() => state = const UpdateState.idle();

  /// Whether the last start's update did not complete, saying so when it
  /// did not. The record is cleared either way.
  Future<bool> _previousUpdateFailed() async {
    final store = await ref.read(pendingUpdateStoreProvider.future);
    final pending = store.read();
    if (pending == null) return false;
    store.clear();
    if (!ref.mounted) return true;

    final running = AppVersion.parse(ref.read(appVersionProvider));
    final target = AppVersion.parse(pending.to);
    if (running != null && target != null && running.compareTo(target) >= 0) {
      return false;
    }

    state = UpdateState.previousUpdateFailed(to: pending.to);
    return true;
  }

  bool _isNewer(ReleaseInfo release) {
    final running = AppVersion.parse(ref.read(appVersionProvider));
    return running != null && release.version > running;
  }

  UpdateAvailable _available(ReleaseInfo release, InstallKind kind) =>
      UpdateAvailable(
        release: release,
        kind: kind,
        canInstall:
            kind.updatesItself &&
            release.packageFor(kind) != null &&
            release.checksumsFor(kind) != null,
      );

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;
}
