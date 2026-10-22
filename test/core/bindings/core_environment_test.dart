import 'dart:io';
import 'dart:isolate';

import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

/// The decision half of putting the core into local auth mode.
///
/// Setting the variable is a platform call and cannot be observed from Dart —
/// `Platform.environment` is a snapshot taken before it runs — so what proves
/// the setting works is the integration suite, which drives the real core with
/// the variable deliberately absent. What is testable here is *when* the
/// application decides to set it, which is where the surprising behaviour would
/// be.
void main() {
  test(
    'GivenNothingInTheEnvironment_WhenTheModeIsChecked_ThenTheApplicationSetsIt',
    () {
      expect(shouldSetAuthMode(const {}), isTrue);
    },
  );

  test(
    'GivenAnUnrelatedVariable_WhenTheModeIsChecked_ThenTheApplicationSetsIt',
    () {
      expect(
        shouldSetAuthMode(const {'ALEXANDRIA_LOGGING_LEVEL': 'debug'}),
        isTrue,
      );
    },
  );

  // An explicit setting is deliberate, and overriding it would make a
  // configured run behave like an unconfigured one.
  test(
    'GivenTheModeIsAlreadyLocal_WhenItIsChecked_ThenTheApplicationLeavesItAlone',
    () {
      expect(
        shouldSetAuthMode(const {coreAuthModeVariable: localAuthMode}),
        isFalse,
      );
    },
  );

  // Including a mode this application cannot work in: whoever set it needs to
  // see the core refuse, not to have the setting quietly replaced.
  test(
    'GivenTheModeIsSetToExternal_WhenItIsChecked_ThenTheApplicationLeavesItAlone',
    () {
      expect(
        shouldSetAuthMode(const {coreAuthModeVariable: 'external'}),
        isFalse,
      );
    },
  );

  test(
    'GivenAModeTheCoreCannotParse_WhenItIsChecked_ThenTheApplicationLeavesItAlone',
    () {
      expect(
        shouldSetAuthMode(const {coreAuthModeVariable: 'nonsense'}),
        isFalse,
      );
    },
  );

  // A blank value is not a choice. The core would fail to parse it and fall
  // back to its own default, which is the state this exists to avoid.
  test('GivenTheModeIsBlank_WhenItIsChecked_ThenTheApplicationSetsIt', () {
    expect(shouldSetAuthMode(const {coreAuthModeVariable: ''}), isTrue);
  });

  test(
    'GivenTheModeIsOnlyWhitespace_WhenItIsChecked_ThenTheApplicationSetsIt',
    () {
      expect(shouldSetAuthMode(const {coreAuthModeVariable: '   '}), isTrue);
    },
  );

  group('the caches beside the catalog', () {
    // The defect this closes: the setting defaults to a *relative* path,
    // which the core resolves against the process's working directory. For
    // an installed application that is wherever the desktop started it — a
    // directory this application does not own and often cannot write to —
    // so a thumbnail was written somewhere nothing would look for it again.
    test(
      'GivenTheCatalogsDirectory_WhenTheCachesArePlaced_ThenTheyAreBesideIt',
      () {
        final directories = cacheDirectoriesIn(
          '${Platform.pathSeparator}home${Platform.pathSeparator}owner',
        );

        expect(
          directories[coreThumbnailCacheDirVariable],
          '${Platform.pathSeparator}home${Platform.pathSeparator}owner'
          '${Platform.pathSeparator}thumbnails',
        );
      },
    );

    test('GivenAPathThatEndsInASeparator_WhenPlaced_ThenItIsNotDoubled', () {
      final directories = cacheDirectoriesIn(
        '${Platform.pathSeparator}data${Platform.pathSeparator}',
      );

      expect(
        directories[coreThumbnailCacheDirVariable],
        '${Platform.pathSeparator}data'
        '${Platform.pathSeparator}thumbnails',
      );
    });

    test('GivenAnAbsoluteCatalog_WhenPlaced_ThenTheCachesAreAbsoluteToo', () {
      // The whole point: a relative answer is one the core resolves against
      // a working directory nobody chose.
      final directories = cacheDirectoriesIn(
        '${Platform.pathSeparator}var${Platform.pathSeparator}alexandria',
      );

      for (final path in directories.values) {
        expect(p.isAbsolute(path), isTrue, reason: path);
      }
    });

    // An explicit setting is deliberate, exactly as it is for the auth mode.
    test('GivenAThumbnailDirIsAlreadySet_WhenChecked_ThenItIsLeftAlone', () {
      expect(
        shouldSetCoreVariable(const {
          coreThumbnailCacheDirVariable: '/somewhere/else',
        }, coreThumbnailCacheDirVariable),
        isFalse,
      );
    });
  });

  // A retry spawns a fresh core worker, and a fresh isolate takes its own
  // snapshot of the environment — after the previous worker wrote these
  // variables. Read through that snapshot, the application's own earlier
  // write looked like an operator's, and the next change was skipped.
  // Each step runs in its own isolate here for exactly that reason: it is the
  // only way to observe what the process environment now holds.
  group('preparing the core again from a new worker', () {
    final launch = Map<String, String>.of(Platform.environment)
      ..remove(coreThumbnailCacheDirVariable);

    tearDown(() {
      // Blank counts as unset, for the core and for these rules alike.
      setProcessEnvironment(coreThumbnailCacheDirVariable, '');
    });

    Future<void> prepareInNewWorker(String directory) => Isolate.run(
      () => prepareCoreEnvironment(
        databaseDirectory: directory,
        launchEnvironment: launch,
      ),
    );

    Future<String?> readInNewWorker(String name) =>
        Isolate.run(() => Platform.environment[name]);

    test(
      'GivenAnEarlierWorkerSetTheCaches_WhenTheCatalogMoves_ThenTheChangeIsWritten',
      () async {
        final first = Directory.systemTemp.createTempSync('alexandria_env');
        final second = Directory.systemTemp.createTempSync('alexandria_env');
        addTearDown(() => first.deleteSync(recursive: true));
        addTearDown(() => second.deleteSync(recursive: true));

        await prepareInNewWorker(first.path);
        await prepareInNewWorker(second.path);

        expect(
          await readInNewWorker(coreThumbnailCacheDirVariable),
          '${second.path}${Platform.pathSeparator}thumbnails',
        );
      },
    );

    test(
      'GivenTheOperatorSetTheCacheBeforeLaunch_WhenTheCoreIsPrepared_ThenItIsLeftAlone',
      () async {
        final directory = Directory.systemTemp.createTempSync('alexandria_env');
        addTearDown(() => directory.deleteSync(recursive: true));
        setProcessEnvironment(coreThumbnailCacheDirVariable, '/operator/cache');
        final configured = {
          ...launch,
          coreThumbnailCacheDirVariable: '/operator/cache',
        };

        await Isolate.run(
          () => prepareCoreEnvironment(
            databaseDirectory: directory.path,
            launchEnvironment: configured,
          ),
        );

        expect(
          await readInNewWorker(coreThumbnailCacheDirVariable),
          '/operator/cache',
        );
      },
    );
  });
}
