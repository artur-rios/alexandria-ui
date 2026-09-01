import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/bindings/core_isolate.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/startup/startup_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_core_client.dart';
import '../../support/in_memory_settings_store.dart';
import '../../support/test_container.dart';

/// The startup sequence in Operations & Infrastructure Document §5.1 (IR-06).
void main() {
  Future<StartupState> runStartup({
    CoreClient? core,
    Future<CoreClient> Function(String)? loadCore,
    Future<SettingsStore> Function()? loadSettings,
    String? libraryPath,
  }) async {
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(
        core: core,
        loadCore: loadCore,
        loadSettings: loadSettings,
        libraryPath: libraryPath,
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    return container.read(startupControllerProvider);
  }

  test(
    'GivenAHealthySupportedCore_WhenStartupRuns_ThenItReachesReady',
    () async {
      final state = await runStartup(core: FakeCoreClient());

      expect(state, isA<StartupReady>());
      expect((state as StartupReady).coreVersion, '0.1.0');
      expect(state.warning, isNull);
    },
  );

  test(
    'GivenAHealthyCore_WhenStartupRuns_ThenTheDatabasePathIsPassedToIt',
    () async {
      final core = FakeCoreClient();

      await runStartup(core: core);

      expect(core.initializedWith, hasLength(1));
      expect(core.initializedWith.single, endsWith('catalog.db'));
    },
  );

  group('step 1 — loading the shared library', () {
    test(
      'GivenNoLibraryOnDisk_WhenStartupRuns_ThenItFailsNamingThePathsTried',
      () async {
        final state = await runStartup(
          libraryPath: '/definitely/not/here/alexandria_ffi.dll',
        );

        expect(state, isA<StartupFailed>());
        final failed = state as StartupFailed;
        expect(failed.step, StartupStep.loadingCore);
        expect(failed.failure, isA<CoreLibraryNotLoadedFailure>());
        expect(
          (failed.failure as CoreLibraryNotLoadedFailure).path,
          contains('alexandria_ffi.dll'),
          reason:
              'the path attempted is the only thing that makes this actionable',
        );
      },
    );

    test(
      'GivenTheLibraryWillNotLoad_WhenStartupRuns_ThenItFailsAtStepOne',
      () async {
        final state = await runStartup(
          loadCore: (_) async =>
              throw const CoreCallException('bad image format'),
        );

        expect((state as StartupFailed).step, StartupStep.loadingCore);
        expect(state.failure, isA<CoreLibraryNotLoadedFailure>());
      },
    );
  });

  group('step 4 — initializing the core', () {
    test(
      'GivenTheCoreRejectsTheDatabase_WhenStartupRuns_ThenItFailsAtStepThree',
      () async {
        final state = await runStartup(
          core: FakeCoreClient(
            initializeResult: 3, // INDEX_ERR_NOT_INITIALIZED
          ),
        );

        expect((state as StartupFailed).step, StartupStep.initializingCore);
        expect(state.failure, isA<CoreInitializationFailedFailure>());
        expect(state.failure.coreStatusCode, 3);
      },
    );
  });

  group('step 5 — verifying health and version', () {
    test(
      'GivenAnUnhealthyCore_WhenStartupRuns_ThenItFailsAtStepFour',
      () async {
        final state = await runStartup(core: FakeCoreClient(healthResult: 503));

        expect((state as StartupFailed).step, StartupStep.verifyingCore);
        expect(state.failure, isA<CoreUnhealthyFailure>());
        expect(state.failure.coreStatusCode, 503);
      },
    );

    test(
      'GivenTheCoreReportsZeroForHealth_WhenStartupRuns_ThenItIsTreatedAsUnhealthy',
      () async {
        // The *_OK convention is zero, but health is HTTP-shaped. A core
        // answering 0 here is not healthy, and reading it as success would let
        // an unusable core through the one check that exists to stop it.
        final state = await runStartup(core: FakeCoreClient(healthResult: 0));

        expect(state, isA<StartupFailed>());
        expect((state as StartupFailed).failure, isA<CoreUnhealthyFailure>());
      },
    );

    test(
      'GivenAnUnsupportedVersion_WhenStartupRuns_ThenItFailsAtStepFour',
      () async {
        final state = await runStartup(
          core: FakeCoreClient(versionResult: '0.9.0'),
        );

        expect((state as StartupFailed).step, StartupStep.verifyingCore);
        final failure = state.failure as CoreVersionUnsupportedFailure;
        expect(failure.found, '0.9.0');
        expect(failure.required, contains('0.1.0'));
      },
    );

    test(
      'GivenACoreThatReportsNoVersion_WhenStartupRuns_ThenItIsUnsupported',
      () async {
        final state = await runStartup(
          core: FakeCoreClient(versionResult: null),
        );

        expect(
          (state as StartupFailed).failure,
          isA<CoreVersionUnsupportedFailure>(),
        );
      },
    );
  });

  group('step 3 — loading preferences', () {
    test(
      'GivenUnreadablePreferences_WhenStartupRuns_ThenItStillReachesReady',
      () async {
        final state = await runStartup(
          loadSettings: () async => throw const FileSystemFailure(),
        );

        expect(
          state,
          isA<StartupReady>(),
          reason:
              'step 3 falls back to the system theme and language; it does not '
              'fail the launch',
        );
        expect(
          (state as StartupReady).warning,
          isA<PreferencesUnreadableFailure>(),
        );
      },
    );

    test(
      'GivenReadablePreferences_WhenStartupRuns_ThenTheyAreAvailable',
      () async {
        final settings = InMemorySettingsStore();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(settings: settings),
        );

        await container.read(startupControllerProvider.notifier).start();

        expect(
          container.read(startupControllerProvider.notifier).settings,
          same(settings),
        );
      },
    );
  });

  group('music lookup (music enrichment design)', () {
    test(
      'GivenTheShippedDefaults_WhenStartupRuns_ThenTheCoreIsInitializedWithLookupOn',
      () async {
        // The complaint this answers: the feature could not be switched on
        // from anywhere in the application, because nothing ever told the
        // core about it. The core's own default is off, so a core
        // initialized with nothing said is a core that refuses every lookup.
        final core = FakeCoreClient();

        await runStartup(core: core);

        expect(core.musicLookupsInitializedWith, hasLength(1));
        final lookup = core.musicLookupsInitializedWith.single;
        expect(lookup.enabled, isTrue);
        expect(lookup.contact, defaultMusicLookupContact);
        expect(
          lookup.isAvailable,
          isTrue,
          reason: 'a contact is half of what makes a lookup possible at all',
        );
      },
    );

    test(
      'GivenTheOwnerSwitchedItOff_WhenStartupRuns_ThenTheCoreIsInitializedWithItOff',
      () async {
        final core = FakeCoreClient();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(
            core: core,
            settings: InMemorySettingsStore(musicLookupEnabled: false),
          ),
        );

        await container.read(startupControllerProvider.notifier).start();

        expect(core.musicLookupsInitializedWith.single.enabled, isFalse);
      },
    );

    test(
      'GivenTheOwnersOwnContact_WhenStartupRuns_ThenTheCoreIsGivenIt',
      () async {
        final core = FakeCoreClient();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(
            core: core,
            settings: InMemorySettingsStore(
              musicLookupContact: 'someone@example.com',
            ),
          ),
        );

        await container.read(startupControllerProvider.notifier).start();

        expect(
          core.musicLookupsInitializedWith.single.contact,
          'someone@example.com',
        );
      },
    );

    test(
      'GivenUnreadablePreferences_WhenStartupRuns_ThenTheCoreStillGetsTheDefaults',
      () async {
        // Step 3 failing must not take the lookup down with it: the store is
        // where the *choice* lives, and an owner who has never made one gets
        // the shipped default either way.
        final core = FakeCoreClient();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(
            core: core,
            loadSettings: () async => throw const FileSystemFailure(),
          ),
        );

        await container.read(startupControllerProvider.notifier).start();

        expect(core.musicLookupsInitializedWith.single.enabled, isTrue);
      },
    );

    test(
      'GivenTheLookupIsSwitchedOffAfterStartup_WhenItIsApplied_ThenTheCoreIsInitializedAgain',
      () async {
        // The core reads this setting once, at initialization. Applying a
        // change is re-initializing it, or the owner would be told the
        // feature is switched off for this installation by a core still
        // running last launch's configuration.
        final core = FakeCoreClient();
        final settings = InMemorySettingsStore();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(core: core, settings: settings),
        );
        final startup = container.read(startupControllerProvider.notifier);
        await startup.start();

        await settings.setMusicLookupEnabled(false);
        await startup.applyMusicLookup();

        expect(core.initializedWith, hasLength(2));
        expect(core.initializedWith.last, core.initializedWith.first);
        expect(core.musicLookupsInitializedWith.last.enabled, isFalse);
      },
    );

    test(
      'GivenNothingChanged_WhenTheLookupIsApplied_ThenTheCoreIsLeftAlone',
      () async {
        final core = FakeCoreClient();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(core: core),
        );
        final startup = container.read(startupControllerProvider.notifier);
        await startup.start();

        await startup.applyMusicLookup();

        expect(
          core.initializedWith,
          hasLength(1),
          reason:
              're-initializing the core for a preference that did not move '
              'would rebuild its services for nothing',
        );
      },
    );

    test(
      'GivenTheCoreRefusesTheChange_WhenTheLookupIsApplied_ThenStartupStaysReady',
      () async {
        final core = FakeCoreClient();
        final settings = InMemorySettingsStore();
        final container = buildTestContainer(
          overrides: fakeCoreOverrides(core: core, settings: settings),
        );
        final startup = container.read(startupControllerProvider.notifier);
        await startup.start();

        core.failOnInitialize = true;
        await settings.setMusicLookupEnabled(false);
        await startup.applyMusicLookup();

        expect(
          container.read(startupControllerProvider),
          isA<StartupReady>(),
          reason:
              'a preference that could not be handed to the core is not a '
              'reason to take the application back to a startup screen',
        );
      },
    );
  });

  group('retry', () {
    test('GivenAFailedStartup_WhenRetryRuns_ThenItStartsFromStepOne', () async {
      var attempt = 0;
      final container = buildTestContainer(
        overrides: fakeCoreOverrides(
          loadCore: (_) async {
            attempt++;
            if (attempt == 1) {
              throw const CoreCallException('first attempt fails');
            }
            return FakeCoreClient();
          },
        ),
      );
      final controller = container.read(startupControllerProvider.notifier);

      await controller.start();
      expect(container.read(startupControllerProvider), isA<StartupFailed>());

      await controller.retry();

      expect(container.read(startupControllerProvider), isA<StartupReady>());
      expect(attempt, 2, reason: 'the retry re-runs the sequence from step 1');
    });

    test(
      'GivenALoadedCore_WhenRetryRuns_ThenThePreviousCoreIsDisposed',
      () async {
        final first = FakeCoreClient(healthResult: 503);
        final cores = <FakeCoreClient>[first, FakeCoreClient()];
        var index = 0;

        final container = buildTestContainer(
          overrides: fakeCoreOverrides(loadCore: (_) async => cores[index++]),
        );
        final controller = container.read(startupControllerProvider.notifier);

        await controller.start();
        await controller.retry();

        expect(
          first.disposeCount,
          greaterThanOrEqualTo(1),
          reason:
              'a retry that left the previous core loaded would leak a worker '
              'isolate and a shared-library handle on every attempt',
        );
      },
    );
  });

  test('GivenTheIndexFamily_WhenSuccessIsChecked_ThenZeroIsTheSuccessCode', () {
    expect(CoreStatusFamily.indexing.isOk(0), isTrue);
    expect(CoreStatusFamily.indexing.isOk(1), isFalse);
  });
}

/// Stands in for whatever `shared_preferences` throws when its backing file is
/// unreadable — the type does not matter to the controller, only that it throws.
class FileSystemFailure implements Exception {
  const FileSystemFailure();
}
