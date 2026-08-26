import 'package:alexandria_ui/features/playback/domain/sleeve_design.dart';
import 'package:flutter_test/flutter_test.dart';

/// The jacket the case shows until the core carries cover art (UC-21).
void main() {
  test('GivenAnAlbum_WhenItsSleeveIsPicked_ThenTheSameAlbumAlwaysMatches', () {
    // The point of deriving it: a record that looked different every time it
    // was played would read as a bug, not as a design.
    expect(sleeveIndexFor('OK Computer', 8), sleeveIndexFor('OK Computer', 8));
  });

  test('GivenTwoAlbums_WhenTheirSleevesArePicked_ThenTheyDifferInGeneral', () {
    // Not a guarantee for any given pair — a hash into eight buckets will
    // collide — but a library whose every sleeve came out the same colour
    // would mean the derivation was not deriving anything.
    final indexes = {
      for (final album in [
        'OK Computer', 'Kind of Blue', 'Hounds of Love', 'Dummy',
        'In Rainbows', 'Blue Lines', 'Loveless', 'Spiderland',
      ])
        sleeveIndexFor(album, 8),
    };

    expect(indexes.length, greaterThan(1));
  });

  test('GivenNoAlbumName_WhenASleeveIsPicked_ThenItIsStillInRange', () {
    for (final album in [null, '', '   ']) {
      final index = sleeveIndexFor(album, 8);

      expect(index, inInclusiveRange(0, 7), reason: '$album');
    }
  });

  test('GivenAnyAlbum_WhenASleeveIsPicked_ThenItIsInRange', () {
    for (final album in ['a', 'Z', '日本語', '🎵', 'a' * 500]) {
      expect(sleeveIndexFor(album, 8), inInclusiveRange(0, 7), reason: album);
    }
  });
}
