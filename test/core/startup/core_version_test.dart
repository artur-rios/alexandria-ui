import 'package:alexandria_ui/core/startup/core_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// IR-06: the version must be one the application supports.
void main() {
  test('GivenTheMinimumVersion_WhenItIsChecked_ThenItIsSupported', () {
    expect(CoreVersionRange.supports(CoreVersionRange.minimum), isTrue);
  });

  test('GivenAPatchAboveTheMinimum_WhenItIsChecked_ThenItIsSupported', () {
    expect(CoreVersionRange.supports('0.5.7'), isTrue);
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

  test('GivenTheFirstSupportedRelease_WhenItIsChecked_ThenItIsSupported', () {
    expect(CoreVersionRange.supports('0.5.0'), isTrue);
  });

  test('GivenThePreviousMinorLine_WhenItIsChecked_ThenItIsNotSupported', () {
    // The 0.4 core still serves playlists, plays and enrichment, and this
    // build no longer speaks to them. Its last patch is the nearest miss.
    expect(CoreVersionRange.supports('0.4.9'), isFalse);
    expect(CoreVersionRange.supports('0.3.0'), isFalse);
  });

  test('GivenTheNextMinorLine_WhenItIsChecked_ThenItIsNotSupported', () {
    expect(CoreVersionRange.supports('0.6.0'), isFalse);
  });

  test('GivenAMuchLaterVersion_WhenItIsChecked_ThenItIsNotSupported', () {
    expect(CoreVersionRange.supports('1.0.0'), isFalse);
  });

  test('GivenAPreReleaseSuffix_WhenItIsChecked_ThenTheSuffixIsIgnored', () {
    expect(CoreVersionRange.supports('0.5.0-rc.1'), isTrue);
    expect(CoreVersionRange.supports('0.5.0+build.5'), isTrue);
  });

  group('a core that will not say what it is', () {
    // Not supported, deliberately. Treating an unreadable version as acceptable
    // would let through exactly the case this check exists to catch.
    for (final version in [null, '', 'unknown', '0.5', '0.5.x', '-1.0.0']) {
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
