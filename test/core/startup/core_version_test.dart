import 'package:alexandria_ui/core/startup/core_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// IR-06: the version must be one the application supports.
void main() {
  test('GivenTheMinimumVersion_WhenItIsChecked_ThenItIsSupported', () {
    expect(CoreVersionRange.supports(CoreVersionRange.minimum), isTrue);
  });

  test('GivenAPatchAboveTheMinimum_WhenItIsChecked_ThenItIsSupported', () {
    expect(CoreVersionRange.supports('0.2.7'), isTrue);
  });

  test('GivenTheExclusiveMaximum_WhenItIsChecked_ThenItIsNotSupported', () {
    expect(
      CoreVersionRange.supports(CoreVersionRange.exclusiveMaximum),
      isFalse,
      reason:
          'the core is pre-1.0, so a minor bump is a breaking change and the '
          'next minor line is the first this build has not been checked '
          'against',
    );
  });

  test('GivenAVersionBelowTheMinimum_WhenItIsChecked_ThenItIsNotSupported', () {
    expect(CoreVersionRange.supports('0.0.9'), isFalse);
  });

  test('GivenThePreviousMinorLine_WhenItIsChecked_ThenItIsNotSupported', () {
    // The case this check earned its keep on: an owner who rebuilt one
    // repository and not the other ran a core whose metadata stamp and
    // lyrics fallback did not exist, and saw two features quietly do
    // nothing. Refused at startup, by name and version, it is a sentence
    // instead of a mystery.
    expect(CoreVersionRange.supports('0.1.0'), isFalse);
  });

  test('GivenAMuchLaterVersion_WhenItIsChecked_ThenItIsNotSupported', () {
    expect(CoreVersionRange.supports('1.0.0'), isFalse);
  });

  test('GivenAPreReleaseSuffix_WhenItIsChecked_ThenTheSuffixIsIgnored', () {
    expect(CoreVersionRange.supports('0.2.0-rc.1'), isTrue);
    expect(CoreVersionRange.supports('0.2.0+build.5'), isTrue);
  });

  group('a core that will not say what it is', () {
    // Not supported, deliberately. Treating an unreadable version as acceptable
    // would let through exactly the case this check exists to catch.
    for (final version in [null, '', 'unknown', '0.2', '0.2.x', '-1.0.0']) {
      test(
        'Given${version == null ? 'NoVersion' : 'TheVersion"$version"'}_WhenItIsChecked_ThenItIsNotSupported',
        () => expect(CoreVersionRange.supports(version), isFalse),
      );
    }
  });

  test('GivenTheRange_WhenItIsDescribed_ThenBothBoundsAreNamed', () {
    expect(CoreVersionRange.description, contains(CoreVersionRange.minimum));
    expect(
      CoreVersionRange.description,
      contains(CoreVersionRange.exclusiveMaximum),
    );
  });
}
