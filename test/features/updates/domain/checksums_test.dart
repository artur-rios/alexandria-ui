import 'package:alexandria_ui/features/updates/domain/checksums.dart';
import 'package:flutter_test/flutter_test.dart';

/// A release's `sha256sum` file (update-check design §4).
void main() {
  const sums = '''
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  a.exe
E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855  b.sh
0000000000000000000000000000000000000000000000000000000000000000  a.exe.sig
''';

  test('GivenSumsText_WhenAsked_ThenTheNamedLinesHex', () {
    expect(
      checksumFor(sums, 'a.exe'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('GivenUpperCaseHex_WhenAsked_ThenLowerCase', () {
    expect(
      checksumFor(sums, 'b.sh'),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('GivenNoLineForTheName_WhenAsked_ThenNull', () {
    expect(checksumFor(sums, 'c.AppImage'), isNull);
  });

  test('GivenASimilarName_WhenAsked_ThenOnlyTheExactName', () {
    expect(checksumFor(sums, 'a.ex'), isNull);
    expect(
      checksumFor(sums, 'a.exe.sig'),
      '0000000000000000000000000000000000000000000000000000000000000000',
    );
  });

  test('GivenABinaryModeLine_WhenAsked_ThenTheStarIsNotPartOfTheName', () {
    expect(
      checksumFor(
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad *a.exe\n',
        'a.exe',
      ),
      isNotNull,
    );
  });
}
