import 'package:alexandria_ui/features/catalog/domain/file_size.dart';
import 'package:flutter_test/flutter_test.dart';

/// A byte count as an owner reads it (UC-13, FR-CT-05).
void main() {
  test('GivenAByteCount_WhenItIsUnderAKilobyte_ThenItIsShownInBytes', () {
    expect(formatFileSize(512), '512 B');
  });

  test('GivenAByteCount_WhenItIsLarger_ThenItUsesTheLargestUnitThatFits', () {
    expect(formatFileSize(4922880), '4.7 MB');
  });

  test('GivenAByteCount_WhenItIsExactlyAUnit_ThenNoFractionIsShown', () {
    expect(formatFileSize(1024), '1 KB');
  });

  test('GivenNoBytes_WhenItIsFormatted_ThenItReadsZero', () {
    // A zero-byte file is a real thing on disk, and "0 B" is the truth about
    // it — not an absent value.
    expect(formatFileSize(0), '0 B');
  });

  test('GivenOneByte_WhenItIsFormatted_ThenItIsShownInBytes', () {
    expect(formatFileSize(1), '1 B');
  });

  test(
    'GivenAByteCountOneUnderAKilobyte_WhenItIsFormatted_ThenItStaysInBytes',
    () {
      expect(formatFileSize(1023), '1023 B');
    },
  );

  test(
    'GivenAByteCountJustOverAKilobyte_WhenItIsFormatted_ThenItRoundsToOneKilobyte',
    () {
      expect(formatFileSize(1025), '1 KB');
    },
  );

  test(
    'GivenAByteCountThatRoundsUpToAWholeMegabyte_WhenItIsFormatted_ThenTheLargerUnitIsUsed',
    () {
      // 1048575 B divides to 1023.999... KB, under the 1024 threshold that
      // picks the unit — but rounded to zero decimals that is "1024", which
      // must not be printed next to "KB". A file manager beside it reads the
      // same file as 1.0 MB, so that is the reading chosen here too: the
      // printed unit always agrees with the printed number.
      expect(formatFileSize(1048575), '1 MB');
    },
  );

  test('GivenExactlyAMegabyte_WhenItIsFormatted_ThenNoFractionIsShown', () {
    expect(formatFileSize(1048576), '1 MB');
  });
}
