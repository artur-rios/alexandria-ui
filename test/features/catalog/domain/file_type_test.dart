import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core's file types (FR-CT-07, FR-CT-22).
void main() {
  group('FileType.fromWire', () {
    for (final type in FileType.values) {
      test(
        'GivenTheWireName${type.wireName}_WhenItIsRead_ThenItIsThe${type.name}Type',
        () {
          expect(FileType.fromWire(type.wireName), type);
        },
      );
    }

    test('GivenAnUnknownWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      // A core that grows a type must not have its files guessed into an
      // existing listing.
      expect(FileType.fromWire('hologram'), isNull);
    });

    test('GivenNoWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      expect(FileType.fromWire(null), isNull);
    });

    test('GivenADifferentlyCasedWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      // The core's names are lowercase; matching loosely would accept a
      // value the core never sends.
      expect(FileType.fromWire('Video'), isNull);
    });

    test('GivenEveryType_WhenTheirWireNamesAreListed_ThenNoneRepeats', () {
      final names = [for (final type in FileType.values) type.wireName];

      expect(names.toSet(), hasLength(names.length));
    });
  });
}
