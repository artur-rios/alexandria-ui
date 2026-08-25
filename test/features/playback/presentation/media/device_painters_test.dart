import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/case_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/cd_player_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/tape_deck_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/turntable_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The three devices and the three cases, painted (UC-21, FR-PL-07).
void main() {
  Widget painted(CustomPainter painter, Size size) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        child: CustomPaint(size: size, painter: painter),
      ),
    ),
  );

  const palette = AlbumPalette.standard;

  group('what the devices look like', () {
    // `closed: 0` is a device open and waiting — tonearm parked, door
    // racked up, lid standing open; `closed: 1` is the same device shut on
    // its medium. Task 5's stage drives the value between the two with a
    // curve; here each end is pinned on its own.
    for (final (name, painter) in [
      ('turntable-open', const TurntablePainter(palette: palette, closed: 0)),
      (
        'turntable-closed',
        const TurntablePainter(palette: palette, closed: 1),
      ),
      ('tape-deck-open', const TapeDeckPainter(palette: palette, closed: 0)),
      (
        'tape-deck-closed',
        const TapeDeckPainter(palette: palette, closed: 1),
      ),
      ('cd-player-open', const CdPlayerPainter(palette: palette, closed: 0)),
      (
        'cd-player-closed',
        const CdPlayerPainter(palette: palette, closed: 1),
      ),
    ]) {
      testWidgets(
        'GivenThe${_pascal(name)}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
        (tester) async {
          await tester.pumpWidget(painted(painter, const Size(320, 220)));

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/$name.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }
  });

  group('what the cases look like', () {
    for (final (name, medium) in [
      ('case-vinyl', AlbumMedium.vinyl),
      ('case-tape', AlbumMedium.tape),
      ('case-disc', AlbumMedium.disc),
    ]) {
      testWidgets(
        'GivenThe${_pascal(name)}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
        (tester) async {
          final painter = CasePainter(
            palette: palette,
            medium: medium,
            sleeve: palette.sleeveHues[2],
            title: 'A Very Long Album Title That Should Wrap Onto Two Lines',
            artist: 'The Example Artists',
            direction: TextDirection.ltr,
          );
          const width = 200.0;
          final height = width / CasePainter.aspectFor(medium);

          await tester.pumpWidget(painted(painter, Size(width, height)));

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/$name.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }
  });

  group('what closed means', () {
    test('GivenATurntablePainter_WhenOnlyClosedChanges_ThenItRepaints', () {
      const first = TurntablePainter(palette: palette, closed: 0);
      const second = TurntablePainter(palette: palette, closed: 1);

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenATapeDeckPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      const painter = TapeDeckPainter(palette: palette, closed: 0.5);

      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('GivenACdPlayerPainter_WhenOnlyClosedChanges_ThenItRepaints', () {
      const first = CdPlayerPainter(palette: palette, closed: 0);
      const second = CdPlayerPainter(palette: palette, closed: 0.3);

      expect(second.shouldRepaint(first), isTrue);
    });
  });

  group('what the case owes the text', () {
    test('GivenACasePainter_WhenOnlyTheTitleChanges_ThenItRepaints', () {
      const shared = (
        palette: palette,
        medium: AlbumMedium.vinyl,
        sleeve: Color(0xFF000000),
        artist: 'Artist',
        direction: TextDirection.ltr,
      );
      final first = CasePainter(
        palette: shared.palette,
        medium: shared.medium,
        sleeve: shared.sleeve,
        title: 'First Title',
        artist: shared.artist,
        direction: shared.direction,
      );
      final second = CasePainter(
        palette: shared.palette,
        medium: shared.medium,
        sleeve: shared.sleeve,
        title: 'Second Title',
        artist: shared.artist,
        direction: shared.direction,
      );

      expect(second.shouldRepaint(first), isTrue);
    });

    testWidgets(
      'GivenALongTitle_WhenTheCaseIsDrawn_ThenItDoesNotThrow',
      (tester) async {
        // maxLines: 2 with an ellipsis is what keeps a long title from
        // overflowing the jacket; a painter that ignored the caller's
        // TextDirection or omitted the ellipsis could still throw or
        // overflow, and this is the check that catches it.
        final painter = CasePainter(
          palette: palette,
          medium: AlbumMedium.disc,
          sleeve: palette.sleeveHues.first,
          title: 'ثلاثة أرباع الليل والقمر بعيد جداً عن هذا المكان الصغير',
          artist: 'فرقة تجريبية',
          direction: TextDirection.rtl,
        );

        await tester.pumpWidget(painted(painter, const Size(180, 200)));

        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// `dashed-name` to `DashedName`, for the readable half of a test name that
/// still identifies which golden it checks.
String _pascal(String dashed) => dashed
    .split('-')
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join();
