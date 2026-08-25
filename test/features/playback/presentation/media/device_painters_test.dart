import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/case_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/cd_player_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
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
    //
    // Each end is now two goldens rather than one: the stage paints a
    // device's [DeviceLayer.chassis] behind the medium and its
    // [DeviceLayer.foreground] — the tonearm, the door, the lid — in front
    // of it (Finding 2), so there is no longer a single call that draws
    // "the whole device" to golden in one shot. Checking both passes
    // separately is what actually proves the split: a chassis pass that
    // silently included the tonearm, or a foreground pass that came out
    // empty, would both still look right if recombined and wrong on its own.
    for (final (state, closed) in [('open', 0.0), ('closed', 1.0)]) {
      for (final layer in DeviceLayer.values) {
        for (final (device, painter) in [
          (
            'turntable',
            TurntablePainter(palette: palette, closed: closed, layer: layer),
          ),
          (
            'tape-deck',
            TapeDeckPainter(palette: palette, closed: closed, layer: layer),
          ),
          (
            'cd-player',
            CdPlayerPainter(palette: palette, closed: closed, layer: layer),
          ),
        ]) {
          final name = '$device-$state-${layer.name}';

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
      }
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
      const first = TurntablePainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TurntablePainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
      );

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenATapeDeckPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      // Two distinct instances with identical fields, not the same
      // instance compared to itself — the latter would pass even if `==`
      // were broken, since `identical(this, other)` alone would satisfy it.
      const first = TapeDeckPainter(
        palette: palette,
        closed: 0.5,
        layer: DeviceLayer.foreground,
      );
      const second = TapeDeckPainter(
        palette: palette,
        closed: 0.5,
        layer: DeviceLayer.foreground,
      );

      expect(second.shouldRepaint(first), isFalse);
    });

    test('GivenACdPlayerPainter_WhenOnlyClosedChanges_ThenItRepaints', () {
      const first = CdPlayerPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = CdPlayerPainter(
        palette: palette,
        closed: 0.3,
        layer: DeviceLayer.chassis,
      );

      expect(second.shouldRepaint(first), isTrue);
    });
  });

  // Finding 2: splitting a device painter into two passes is only safe if
  // each painter still repaints when the pass itself changes — a stage that
  // toggled `layer` between frames (it never does, but nothing stops a
  // future caller) must not have that change silently ignored the way a
  // `closed`-only `shouldRepaint` would.
  group('what layer means', () {
    test('GivenATurntablePainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = TurntablePainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TurntablePainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.foreground,
      );

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenATapeDeckPainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = TapeDeckPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TapeDeckPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.foreground,
      );

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenACdPlayerPainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = CdPlayerPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = CdPlayerPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.foreground,
      );

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
      'GivenAnEmptyTitleAndArtist_WhenTheCaseIsDrawn_ThenItDoesNotThrow',
      (tester) async {
        // An album with no title or artist yet is not a hypothetical here —
        // sleeveIndexFor already defines what an unnamed album's sleeve
        // colour is, and the case has to lay out that same album's (empty)
        // text without a TextPainter tripping over a zero-length string.
        final painter = CasePainter(
          palette: palette,
          medium: AlbumMedium.tape,
          sleeve: palette.sleeveHues.first,
          title: '',
          artist: '',
          direction: TextDirection.ltr,
        );

        await tester.pumpWidget(painted(painter, const Size(150, 220)));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('GivenALongTitle_WhenTheCaseIsDrawn_ThenItDoesNotThrow', (
      tester,
    ) async {
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
    });
  });
}

/// `dashed-name` to `DashedName`, for the readable half of a test name that
/// still identifies which golden it checks.
String _pascal(String dashed) => dashed
    .split('-')
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join();
