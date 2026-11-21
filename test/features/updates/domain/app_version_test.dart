import 'package:alexandria_ui/features/updates/domain/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// Release versions as tags and builds carry them (update-check design §2).
void main() {
  test('GivenVPrefixedTag_WhenParsed_ThenNumbersAreRead', () {
    expect(AppVersion.parse('v1.2.3'), const AppVersion(1, 2, 3));
  });

  test('GivenBuildSuffix_WhenParsed_ThenItIsIgnored', () {
    expect(AppVersion.parse('1.2.3+7'), const AppVersion(1, 2, 3));
  });

  test('GivenPreRelease_WhenParsed_ThenNull', () {
    expect(AppVersion.parse('1.2.0-rc.1'), isNull);
  });

  test('GivenGarbage_WhenParsed_ThenNull', () {
    for (final raw in ['latest', '1.2', '', 'v', '1.2.3.4', '1.-2.3']) {
      expect(AppVersion.parse(raw), isNull, reason: raw);
    }
  });

  test('GivenTwoVersions_WhenCompared_ThenNumericNotLexical', () {
    expect(
      AppVersion.parse('1.10.0')!.compareTo(AppVersion.parse('1.9.9')!),
      greaterThan(0),
    );
    expect(AppVersion.parse('2.0.0')! > AppVersion.parse('1.99.99')!, isTrue);
    expect(AppVersion.parse('1.0.0')! > AppVersion.parse('1.0.0')!, isFalse);
  });

  test('GivenAVersion_WhenPrinted_ThenDotted', () {
    expect(const AppVersion(1, 2, 3).toString(), '1.2.3');
  });
}
