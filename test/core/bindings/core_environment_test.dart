import 'dart:io';

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

  group('music lookup (music enrichment design)', () {
    test(
      'GivenNothingInTheEnvironment_WhenTheSwitchIsChecked_ThenTheApplicationSetsIt',
      () {
        expect(
          shouldSetCoreVariable(const {}, coreMetadataEnabledVariable),
          isTrue,
        );
      },
    );

    // A packager or a developer who configured the core deliberately keeps
    // what they configured — the same rule the auth mode follows, and the
    // reason this is one function rather than two.
    test(
      'GivenTheSwitchIsAlreadySet_WhenItIsChecked_ThenTheApplicationLeavesItAlone',
      () {
        expect(
          shouldSetCoreVariable(const {
            coreMetadataEnabledVariable: 'false',
          }, coreMetadataEnabledVariable),
          isFalse,
        );
      },
    );

    test('GivenTheSwitchIsBlank_WhenItIsChecked_ThenTheApplicationSetsIt', () {
      expect(
        shouldSetCoreVariable(const {
          coreMetadataEnabledVariable: '   ',
        }, coreMetadataEnabledVariable),
        isTrue,
      );
    });

    // The core refuses a switched-on lookup with no contact just as firmly
    // as a switched-off one, so an interface that read `enabled` alone would
    // offer a lookup that could never run.
    test('GivenNoContact_WhenTheLookupIsRead_ThenItIsNotAvailable', () {
      expect(
        const MusicLookup(enabled: true, contact: '  ').isAvailable,
        isFalse,
      );
    });

    test('GivenAContactAndTheSwitchOn_WhenItIsRead_ThenItIsAvailable', () {
      expect(
        const MusicLookup(
          enabled: true,
          contact: defaultMusicLookupContact,
        ).isAvailable,
        isTrue,
      );
    });

    test('GivenTheSwitchIsOff_WhenTheLookupIsRead_ThenItIsNotAvailable', () {
      expect(
        const MusicLookup(
          enabled: false,
          contact: defaultMusicLookupContact,
        ).isAvailable,
        isFalse,
      );
    });

    // What the application ships with, named here so a change to it is a
    // deliberate edit to a test rather than a silent one: an installation
    // with no contact cannot look anything up at all.
    test('GivenTheShippedContact_WhenItIsRead_ThenItIsNotEmpty', () {
      expect(defaultMusicLookupContact.trim(), isNotEmpty);
    });
  });

  group('the core\'s caches (music enrichment design)', () {
    // The defect this closes: both settings default to a *relative* path,
    // which the core resolves against the process's working directory. For
    // an installed application that is wherever the desktop started it — a
    // directory this application does not own and often cannot write to —
    // so an artist photograph was written somewhere nothing would look for
    // it again, and the player was handed `artist-images/….jpg` and found
    // nothing there.
    test('GivenTheCatalogsDirectory_WhenTheCachesArePlaced_ThenTheyAreBesideIt', () {
      final directories = cacheDirectoriesIn(
        '${Platform.pathSeparator}home${Platform.pathSeparator}owner',
      );

      expect(
        directories[coreImageCacheDirVariable],
        '${Platform.pathSeparator}home${Platform.pathSeparator}owner'
        '${Platform.pathSeparator}artist-images',
      );
      expect(
        directories[coreThumbnailCacheDirVariable],
        '${Platform.pathSeparator}home${Platform.pathSeparator}owner'
        '${Platform.pathSeparator}thumbnails',
      );
    });

    test('GivenAPathThatEndsInASeparator_WhenPlaced_ThenItIsNotDoubled', () {
      final directories = cacheDirectoriesIn(
        '${Platform.pathSeparator}data${Platform.pathSeparator}',
      );

      expect(
        directories[coreImageCacheDirVariable],
        '${Platform.pathSeparator}data'
        '${Platform.pathSeparator}artist-images',
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
    test('GivenAnImageDirIsAlreadySet_WhenChecked_ThenItIsLeftAlone', () {
      expect(
        shouldSetCoreVariable(const {
          coreImageCacheDirVariable: '/somewhere/else',
        }, coreImageCacheDirVariable),
        isFalse,
      );
    });
  });
}
