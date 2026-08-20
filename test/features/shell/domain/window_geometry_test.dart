import 'dart:ui';

import 'package:alexandria_desktop/features/shell/domain/window_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stored window geometry and the rule that decides whether it can still
/// be applied (FR-UX-03, UC-38 AF-02).
void main() {
  const geometry = WindowGeometry(left: 100, top: 50, width: 1440, height: 900);

  group('encoding', () {
    test(
      'GivenAGeometry_WhenItIsEncodedAndDecoded_ThenItSurvivesUnchanged',
      () {
        expect(WindowGeometry.decode(geometry.encode()), geometry);
      },
    );

    test('GivenNoStoredValue_WhenItIsDecoded_ThenThereIsNothingToRestore', () {
      expect(WindowGeometry.decode(null), isNull);
    });

    test('GivenAnEmptyValue_WhenItIsDecoded_ThenThereIsNothingToRestore', () {
      expect(WindowGeometry.decode(''), isNull);
    });

    test(
      'GivenTooFewParts_WhenTheValueIsDecoded_ThenThereIsNothingToRestore',
      () {
        expect(WindowGeometry.decode('100,50,1440'), isNull);
      },
    );

    test(
      'GivenTooManyParts_WhenTheValueIsDecoded_ThenThereIsNothingToRestore',
      () {
        expect(WindowGeometry.decode('100,50,1440,900,7'), isNull);
      },
    );

    test(
      'GivenAPartThatIsNotANumber_WhenItIsDecoded_ThenThereIsNothingToRestore',
      () {
        expect(WindowGeometry.decode('100,50,wide,900'), isNull);
      },
    );

    test('GivenANonFinitePart_WhenItIsDecoded_ThenThereIsNothingToRestore', () {
      expect(WindowGeometry.decode('100,50,Infinity,900'), isNull);
    });

    test('GivenAZeroWidth_WhenItIsDecoded_ThenThereIsNothingToRestore', () {
      expect(WindowGeometry.decode('100,50,0,900'), isNull);
    });

    test(
      'GivenANegativeHeight_WhenItIsDecoded_ThenThereIsNothingToRestore',
      () {
        expect(WindowGeometry.decode('100,50,1440,-900'), isNull);
      },
    );

    test('GivenANegativePosition_WhenItIsDecoded_ThenItIsRestored', () {
      // A window on a display arranged to the left of the primary one has a
      // negative x, which is an ordinary position rather than a bad value.
      expect(
        WindowGeometry.decode('-1820,50,1440,900'),
        const WindowGeometry(left: -1820, top: 50, width: 1440, height: 900),
      );
    });
  });

  group('visibility', () {
    const primary = Rect.fromLTWH(0, 0, 1920, 1080);
    const secondary = Rect.fromLTWH(1920, 0, 1920, 1080);

    test('GivenAnOriginOnADisplay_WhenItIsChecked_ThenItIsRestorable', () {
      expect(geometry.isVisibleOn(const [primary]), isTrue);
    });

    test(
      'GivenAnOriginOnASecondDisplay_WhenItIsChecked_ThenItIsRestorable',
      () {
        const onSecond = WindowGeometry(
          left: 2400,
          top: 100,
          width: 1440,
          height: 900,
        );

        expect(onSecond.isVisibleOn(const [primary, secondary]), isTrue);
      },
    );

    test(
      'GivenThatDisplayIsUnplugged_WhenItIsChecked_ThenItIsNotRestorable',
      () {
        const onSecond = WindowGeometry(
          left: 2400,
          top: 100,
          width: 1440,
          height: 900,
        );

        expect(onSecond.isVisibleOn(const [primary]), isFalse);
      },
    );

    test('GivenNoDisplaysCanBeRead_WhenItIsChecked_ThenItIsNotRestorable', () {
      expect(geometry.isVisibleOn(const []), isFalse);
    });

    test(
      'GivenAnOriginPastTheBottomEdge_WhenItIsChecked_ThenItIsNotRestorable',
      () {
        const below = WindowGeometry(
          left: 100,
          top: 2000,
          width: 1440,
          height: 900,
        );

        expect(below.isVisibleOn(const [primary]), isFalse);
      },
    );

    test(
      'GivenAWindowHangingOffTheRightEdge_WhenItIsChecked_ThenItIsRestorable',
      () {
        // The origin is on screen, so the owner can see and move it; the
        // window manager clamps the overhang.
        const hanging = WindowGeometry(
          left: 1800,
          top: 100,
          width: 1440,
          height: 900,
        );

        expect(hanging.isVisibleOn(const [primary]), isTrue);
      },
    );
  });

  test(
    'GivenAGeometry_WhenItsBoundsAreRead_ThenTheyDescribeTheSameRectangle',
    () {
      expect(geometry.bounds, const Rect.fromLTWH(100, 50, 1440, 900));
    },
  );
}
