import 'dart:io';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/updates/application/update_state.dart';
import 'package:alexandria_ui/features/updates/data/pending_update_store.dart';
import 'package:alexandria_ui/features/updates/domain/install_kind.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_updates.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// Checking for, downloading and verifying an update (update-check design
/// §2, §3).
void main() {
  late Directory support;

  setUp(() => support = Directory.systemTemp.createTempSync('alexandria_up'));
  tearDown(() => support.deleteSync(recursive: true));

  Future<
    ({
      ProviderContainer ref,
      FakeReleaseSource source,
      FakeDownloader downloader,
      InMemorySettingsStore settings,
    })
  >
  build({
    String running = '1.1.0',
    String? latest = '1.2.0',
    bool withChecksums = true,
    bool releaseBuild = true,
    InstallKind kind = InstallKind.linuxInstaller,
    InMemorySettingsStore? settings,
  }) async {
    final store = settings ?? InMemorySettingsStore();
    final source = FakeReleaseSource(
      latest == null ? null : aRelease(latest, withChecksums: withChecksums),
    );
    final downloader = FakeDownloader();
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(settings: store),
        appVersionProvider.overrideWithValue(running),
        isReleaseBuildProvider.overrideWithValue(releaseBuild),
        releaseSourceProvider.overrideWithValue(source),
        downloaderProvider.overrideWithValue(downloader),
        installKindProbeProvider.overrideWithValue(FakeInstallKindProbe(kind)),
        pendingUpdateStoreProvider.overrideWith(
          (ref) async => PendingUpdateStore(support),
        ),
      ],
    );
    await container.read(startupControllerProvider.notifier).start();
    // Held open, as the prompt host holds it in the application.
    container.listen(updateControllerProvider, (_, _) {});

    return (
      ref: container,
      source: source,
      downloader: downloader,
      settings: store,
    );
  }

  UpdateState state(ProviderContainer ref) =>
      ref.read(updateControllerProvider);

  group('at startup', () {
    test('GivenANewerRelease_WhenCheckedAtStartup_ThenAvailable', () async {
      final sut = await build();

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      final available = state(sut.ref) as UpdateAvailable;
      expect(available.release.version.toString(), '1.2.0');
      expect(available.kind, InstallKind.linuxInstaller);
      expect(available.canInstall, isTrue);
    });

    test('GivenTheSameRelease_WhenCheckedAtStartup_ThenIdle', () async {
      final sut = await build(latest: '1.1.0');

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(state(sut.ref), isA<UpdateIdle>());
    });

    test('GivenTheSkippedVersion_WhenCheckedAtStartup_ThenIdle', () async {
      final settings = InMemorySettingsStore(
        values: {'updates.skippedVersion': '1.2.0'},
      );
      final sut = await build(settings: settings);

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(state(sut.ref), isA<UpdateIdle>());
    });

    test('GivenANewerThanSkipped_WhenCheckedAtStartup_ThenAvailable', () async {
      final settings = InMemorySettingsStore(
        values: {'updates.skippedVersion': '1.2.0'},
      );
      final sut = await build(latest: '1.3.0', settings: settings);

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(state(sut.ref), isA<UpdateAvailable>());
    });

    test('GivenThePreferenceOff_WhenCheckedAtStartup_ThenNoRequest', () async {
      final settings = InMemorySettingsStore();
      await settings.setChecksForUpdates(false);
      final sut = await build(settings: settings);

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(sut.source.requests, 0);
      expect(state(sut.ref), isA<UpdateIdle>());
    });

    test('GivenADebugBuild_WhenCheckedAtStartup_ThenNoRequest', () async {
      final sut = await build(releaseBuild: false);

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(sut.source.requests, 0);
    });

    test('GivenFlatpak_WhenCheckedAtStartup_ThenNoRequest', () async {
      final sut = await build(kind: InstallKind.flatpak);

      await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

      expect(sut.source.requests, 0);
    });

    test(
      'GivenTheSourceThrows_WhenCheckedAtStartup_ThenIdleAndSilent',
      () async {
        final sut = await build(latest: null);

        await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

        expect(state(sut.ref), isA<UpdateIdle>());
      },
    );

    test(
      'GivenStartupReady_WhenTheControllerIsWatched_ThenItChecksOnce',
      () async {
        final sut = await build();
        sut.ref.listen(updateControllerProvider, (_, _) {});
        await pumpEventQueue();
        // Read again: the check is once per process, not per read.
        sut.ref.read(updateControllerProvider);
        await pumpEventQueue();

        expect(sut.source.requests, 1);
        expect(state(sut.ref), isA<UpdateAvailable>());
      },
    );
  });

  group('check now', () {
    test('GivenTheSameRelease_WhenCheckNow_ThenUpToDate', () async {
      final sut = await build(latest: '1.1.0');

      await sut.ref.read(updateControllerProvider.notifier).checkNow();

      expect(state(sut.ref), isA<UpdateUpToDate>());
    });

    test('GivenTheSkippedVersion_WhenCheckNow_ThenAvailable', () async {
      final settings = InMemorySettingsStore(
        values: {'updates.skippedVersion': '1.2.0'},
      );
      final sut = await build(settings: settings);

      await sut.ref.read(updateControllerProvider.notifier).checkNow();

      expect(state(sut.ref), isA<UpdateAvailable>());
    });

    test('GivenTheSourceThrows_WhenCheckNow_ThenFailed', () async {
      final sut = await build(latest: null);

      await sut.ref.read(updateControllerProvider.notifier).checkNow();

      expect(state(sut.ref), isA<UpdateCheckFailed>());
    });
  });

  group('skip and later', () {
    test('GivenAnAvailableRelease_WhenSkipped_ThenStoredAndIdle', () async {
      final sut = await build();
      final controller = sut.ref.read(updateControllerProvider.notifier);
      await controller.checkAtStartup();

      await controller.skip();

      expect(sut.settings.getString('updates.skippedVersion'), '1.2.0');
      expect(state(sut.ref), isA<UpdateIdle>());
    });

    test(
      'GivenAnAvailableRelease_WhenLater_ThenIdleAndNothingStored',
      () async {
        final sut = await build();
        final controller = sut.ref.read(updateControllerProvider.notifier);
        await controller.checkAtStartup();

        controller.later();

        expect(sut.settings.getString('updates.skippedVersion'), isNull);
        expect(state(sut.ref), isA<UpdateIdle>());
      },
    );
  });

  group('downloading and verifying', () {
    const package =
        'https://example.test/alexandria-installer-1.2.0-linux-x64.sh';
    const sums = 'https://example.test/alexandria-1.2.0-linux-SHA256SUMS';
    const abcSum =
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

    test('GivenMatchingChecksums_WhenDownloaded_ThenReadyToInstall', () async {
      final sut = await build();
      sut.downloader.contents
        ..[package] = 'abc'
        ..[sums] = '$abcSum  alexandria-installer-1.2.0-linux-x64.sh\n';
      final controller = sut.ref.read(updateControllerProvider.notifier);
      await controller.checkAtStartup();

      await controller.download();

      final ready = state(sut.ref) as UpdateReadyToInstall;
      expect(ready.package.readAsStringSync(), 'abc');
    });

    test(
      'GivenAMismatch_WhenDownloaded_ThenVerifyFailedAndTheFileDeleted',
      () async {
        final sut = await build();
        sut.downloader.contents
          ..[package] = 'abc'
          ..[sums] = '${'0' * 64}  alexandria-installer-1.2.0-linux-x64.sh\n';
        final controller = sut.ref.read(updateControllerProvider.notifier);
        await controller.checkAtStartup();

        await controller.download();

        expect(state(sut.ref), isA<UpdateVerifyFailed>());
        expect(
          sut.downloader.targets.first.existsSync(),
          isFalse,
          reason: 'an unverified package was left on disk',
        );
      },
    );

    test('GivenTheSumsLackTheLine_WhenDownloaded_ThenVerifyFailed', () async {
      final sut = await build();
      sut.downloader.contents
        ..[package] = 'abc'
        ..[sums] = '$abcSum  some-other-file\n';
      final controller = sut.ref.read(updateControllerProvider.notifier);
      await controller.checkAtStartup();

      await controller.download();

      expect(state(sut.ref), isA<UpdateVerifyFailed>());
    });

    test('GivenADownloadFailure_WhenDownloaded_ThenDownloadFailed', () async {
      final sut = await build();
      final controller = sut.ref.read(updateControllerProvider.notifier);
      await controller.checkAtStartup();

      await controller.download();

      expect(state(sut.ref), isA<UpdateDownloadFailed>());
    });

    test(
      'GivenNoChecksumsAsset_WhenAvailable_ThenItCannotInstallItself',
      () async {
        final sut = await build(withChecksums: false);

        await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

        expect((state(sut.ref) as UpdateAvailable).canInstall, isFalse);
      },
    );

    test(
      'GivenTheManualKind_WhenAvailable_ThenItCannotInstallItself',
      () async {
        final sut = await build(kind: InstallKind.manual);

        await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

        expect((state(sut.ref) as UpdateAvailable).canInstall, isFalse);
      },
    );
  });

  group('a previous update', () {
    test(
      'GivenAMarkerToTheRunningVersion_WhenEvaluated_ThenClearedAndNoNotice',
      () async {
        PendingUpdateStore(support).write(from: '1.0.0', to: '1.1.0');
        final sut = await build(latest: '1.1.0');

        await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

        expect(state(sut.ref), isA<UpdateIdle>());
        expect(PendingUpdateStore(support).read(), isNull);
      },
    );

    test(
      'GivenAMarkerFromTheRunningVersion_WhenEvaluated_ThenPreviousUpdateFailedAndCleared',
      () async {
        PendingUpdateStore(support).write(from: '1.1.0', to: '1.2.0');
        final sut = await build();

        await sut.ref.read(updateControllerProvider.notifier).checkAtStartup();

        expect(
          state(sut.ref),
          const UpdateState.previousUpdateFailed(to: '1.2.0'),
        );
        expect(PendingUpdateStore(support).read(), isNull);
      },
    );
  });
}
