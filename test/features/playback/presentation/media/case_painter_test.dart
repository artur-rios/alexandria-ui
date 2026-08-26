import 'dart:ui' as ui;

import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/case_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// A small decoded image with no PNG or JPEG involved: two flat halves,
/// enough for a golden to show the case drawing something other than its
/// own flat [CasePainter.sleeve] fill, and enough for a `shouldRepaint`
/// test to have a real, disposable [ui.Image] to compare against `null`.
Future<ui.Image> _testCover({int width = 60, int height = 60}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = width.toDouble();
  final h = height.toDouble();
  canvas.drawRect(Rect.fromLTWH(0, 0, w / 2, h), Paint()..color = const Color(0xFFE0A030));
  canvas.drawRect(Rect.fromLTWH(w / 2, 0, w / 2, h), Paint()..color = const Color(0xFF3060C0));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

/// The case a medium comes out of and goes back into (UC-21, FR-PL-07) — a
/// case is not a device, so it is tested on its own rather than folded into
/// one of the three device-painter test files (Finding 7).
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

  group('what it looks like', () {
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

  group('what it draws when there is a cover', () {
    testWidgets(
      'GivenAFetchedCover_WhenTheCaseIsDrawn_ThenItMatchesItsGolden',
      (tester) async {
        final cover = await _testCover();
        addTearDown(cover.dispose);

        final painter = CasePainter(
          palette: palette,
          medium: AlbumMedium.vinyl,
          // A sleeve colour that would be unmistakable if the cover were
          // not actually drawn over it — the golden is what proves the
          // image won the sleeve, not the flat fill.
          sleeve: const Color(0xFF00FF00),
          title: 'A Very Long Album Title That Should Wrap Onto Two Lines',
          artist: 'The Example Artists',
          direction: TextDirection.ltr,
          cover: cover,
        );
        const width = 200.0;
        final height = width / CasePainter.aspectFor(AlbumMedium.vinyl);

        await tester.pumpWidget(painted(painter, Size(width, height)));

        await expectLater(
          find.byType(CustomPaint).last,
          matchesGoldenFile('goldens/case-vinyl-cover.png'),
        );
      },
      skip: !goldensAreComparable,
    );
  });

  group('what it owes the text', () {
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

    test(
      'GivenACasePainter_WhenACoverArrivesInPlaceOfNone_ThenItRepaints',
      () async {
        final cover = await _testCover();
        addTearDown(cover.dispose);

        const shared = (
          palette: palette,
          medium: AlbumMedium.vinyl,
          sleeve: Color(0xFF000000),
          title: 'Title',
          artist: 'Artist',
          direction: TextDirection.ltr,
        );
        final withoutCover = CasePainter(
          palette: shared.palette,
          medium: shared.medium,
          sleeve: shared.sleeve,
          title: shared.title,
          artist: shared.artist,
          direction: shared.direction,
        );
        final withCover = CasePainter(
          palette: shared.palette,
          medium: shared.medium,
          sleeve: shared.sleeve,
          title: shared.title,
          artist: shared.artist,
          direction: shared.direction,
          cover: cover,
        );

        expect(withCover.shouldRepaint(withoutCover), isTrue);
      },
    );

    test(
      'GivenACasePainter_WhenTheSameCoverInstanceIsRebuilt_ThenItDoesNotRepaint',
      () async {
        // The rule design section 4 cares about: the same decoded image,
        // held across a rebuild that has nothing to do with the cover — a
        // spin tick, a text change elsewhere — must not be read as a new
        // one and repainted for no reason.
        final cover = await _testCover();
        addTearDown(cover.dispose);

        const shared = (
          palette: palette,
          medium: AlbumMedium.vinyl,
          sleeve: Color(0xFF000000),
          title: 'Title',
          artist: 'Artist',
          direction: TextDirection.ltr,
        );
        final first = CasePainter(
          palette: shared.palette,
          medium: shared.medium,
          sleeve: shared.sleeve,
          title: shared.title,
          artist: shared.artist,
          direction: shared.direction,
          cover: cover,
        );
        final second = CasePainter(
          palette: shared.palette,
          medium: shared.medium,
          sleeve: shared.sleeve,
          title: shared.title,
          artist: shared.artist,
          direction: shared.direction,
          cover: cover,
        );

        expect(second.shouldRepaint(first), isFalse);
      },
    );

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
      // TextDirection or omitted the ellipsis could still throw or overflow,
      // and this is the check that catches it.
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
