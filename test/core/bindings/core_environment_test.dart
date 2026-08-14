import 'package:alexandria_desktop/core/bindings/core_environment.dart';
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
        shouldSetAuthMode(const {'ALEXANDRIA_LOG_LEVEL': 'debug'}),
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
  test(
    'GivenTheModeIsBlank_WhenItIsChecked_ThenTheApplicationSetsIt',
    () {
      expect(shouldSetAuthMode(const {coreAuthModeVariable: ''}), isTrue);
    },
  );

  test(
    'GivenTheModeIsOnlyWhitespace_WhenItIsChecked_ThenTheApplicationSetsIt',
    () {
      expect(shouldSetAuthMode(const {coreAuthModeVariable: '   '}), isTrue);
    },
  );
}
