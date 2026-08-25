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
}
