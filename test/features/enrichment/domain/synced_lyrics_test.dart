import 'package:alexandria_ui/features/enrichment/domain/synced_lyrics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading an LRC document, and finding the line being sung.
void main() {
  group('parsing', () {
    test('GivenTimestampedLines_WhenParsed_ThenEachCarriesItsMoment', () {
      final lines = parseLrc('[00:12.34]first line\n[01:05.00]second line');

      expect(lines, [
        const SyncedLyricLine(
          at: Duration(seconds: 12, milliseconds: 340),
          text: 'first line',
        ),
        const SyncedLyricLine(
          at: Duration(minutes: 1, seconds: 5),
          text: 'second line',
        ),
      ]);
    });

    test('GivenAFractionOfOneDigit_WhenParsed_ThenItIsTenths', () {
      // `.5` is five tenths. Read as a bare integer it would be five
      // milliseconds — a hundred times early, which across a song is the
      // difference between following and drifting.
      final lines = parseLrc('[00:12.5]a line');

      expect(lines.single.at, const Duration(seconds: 12, milliseconds: 500));
    });

    test('GivenNoFraction_WhenParsed_ThenTheSecondIsWhole', () {
      final lines = parseLrc('[00:12]a line');

      expect(lines.single.at, const Duration(seconds: 12));
    });

    test('GivenThreeDigits_WhenParsed_ThenTheyAreMilliseconds', () {
      final lines = parseLrc('[00:12.345]a line');

      expect(lines.single.at, const Duration(seconds: 12, milliseconds: 345));
    });

    test('GivenARepeatedChorus_WhenParsed_ThenItAppearsAtEachTime', () {
      // One line, several cues. A chorus is written once and sung three
      // times, and each time has to highlight.
      final lines = parseLrc('[00:30.00][01:30.00][02:30.00]the chorus');

      expect(lines, hasLength(3));
      expect(lines.map((line) => line.text).toSet(), {'the chorus'});
      expect(lines.map((line) => line.at.inSeconds), [30, 90, 150]);
    });

    test('GivenMetadataTags_WhenParsed_ThenTheyAreNotLines', () {
      // `[ar:…]` and `[length:…]` look like timestamps and are not. Read as
      // lines they would put the artist's name in the middle of the song.
      final lines = parseLrc(
        '[ar:Queen]\n[ti:A Song]\n[length:03:45]\n[00:12.00]a real line',
      );

      expect(lines, hasLength(1));
      expect(lines.single.text, 'a real line');
    });

    test('GivenAnUnstampedLine_WhenParsed_ThenItIsSkipped', () {
      final lines = parseLrc('just some words\n[00:12.00]a real line');

      expect(lines, hasLength(1));
    });

    test('GivenOutOfOrderCues_WhenParsed_ThenTheyComeBackInTimeOrder', () {
      // A repeated chorus arrives unsorted by nature, and a file is not
      // obliged to be in order either. Everything downstream assumes it is.
      final lines = parseLrc('[02:00.00]later\n[00:10.00]earlier');

      expect(lines.map((line) => line.text), ['earlier', 'later']);
    });

    test('GivenATimedGap_WhenParsed_ThenTheEmptyLineIsKept', () {
      // An instrumental break is a real marker: without it the last sung
      // line stays highlighted through a minute of solo.
      final lines = parseLrc('[00:10.00]a line\n[00:20.00]\n[01:00.00]after');

      expect(lines, hasLength(3));
      expect(lines[1].text, isEmpty);
    });

    test('GivenABracketInsideTheWords_WhenParsed_ThenItStaysInTheText', () {
      // Only the run of stamps at the start is a cue. A bracketed aside
      // belongs to the line.
      final lines = parseLrc('[00:12.00]a line [laughs] and more');

      expect(lines.single.text, 'a line [laughs] and more');
    });

    test('GivenNothingUsable_WhenParsed_ThenThereAreNoLines', () {
      expect(parseLrc(''), isEmpty);
      expect(parseLrc('not an lrc file at all'), isEmpty);
    });

    test('GivenAnHourLongRecording_WhenParsed_ThenTheMinutesAreNotCapped', () {
      // A live set runs past sixty minutes and the format simply keeps
      // counting.
      final lines = parseLrc('[75:30.00]a line');

      expect(lines.single.at, const Duration(minutes: 75, seconds: 30));
    });
  });

  group('following the music', () {
    final lyrics = SyncedLyrics(
      parseLrc('[00:10.00]first\n[00:20.00]second\n[00:30.00]third'),
    );

    test('GivenAPositionBeforeTheFirstCue_WhenAsked_ThenNothingIsActive', () {
      // A long intro has nothing to highlight, and highlighting the opening
      // line through all of it would be wrong.
      expect(lyrics.activeIndexAt(const Duration(seconds: 3)), isNull);
    });

    test('GivenAPositionOnACue_WhenAsked_ThenThatLineIsActive', () {
      expect(lyrics.activeIndexAt(const Duration(seconds: 20)), 1);
    });

    test('GivenAPositionBetweenCues_WhenAsked_ThenTheLastPassedIsActive', () {
      // The last line whose moment has come, never the nearest — the next
      // line has not been sung yet.
      expect(lyrics.activeIndexAt(const Duration(seconds: 29)), 1);
    });

    test('GivenAPositionPastTheEnd_WhenAsked_ThenTheFinalLineStays', () {
      expect(lyrics.activeIndexAt(const Duration(minutes: 5)), 2);
    });

    test('GivenNoLines_WhenAsked_ThenNothingIsActive', () {
      expect(
        const SyncedLyrics([]).activeIndexAt(const Duration(seconds: 5)),
        isNull,
      );
    });

    test('GivenEveryPosition_WhenAsked_ThenTheSearchAgreesWithAScan', () {
      // The lookup is a binary search, which is easy to get subtly wrong at
      // the boundaries. This checks it against the obvious implementation at
      // every second of the track rather than at the few points a
      // hand-written case would cover.
      final List<SyncedLyricLine> lines = parseLrc(
        List.generate(
          50,
          (i) => '[00:${(i * 1).toString().padLeft(2, '0')}.00]line $i',
        ).join('\n'),
      );
      final subject = SyncedLyrics(lines);

      int? byScan(Duration at) {
        int? found;
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].at <= at) found = i;
        }
        return found;
      }

      for (var second = 0; second < 60; second++) {
        final at = Duration(seconds: second);
        expect(
          subject.activeIndexAt(at),
          byScan(at),
          reason: 'disagreed with a plain scan at $at',
        );
      }
    });
  });
}
