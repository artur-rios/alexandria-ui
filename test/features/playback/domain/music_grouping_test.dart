import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playback/domain/music_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Grouping an audio library into albums and artists (UC-20 main flow step 3,
/// FR-PL-06).
void main() {
  MusicEntry entry(String name, {String? album, String? artist, int? track}) =>
      MusicEntry(
        file: aFile(uuid: name, name: name),
        metadata: MusicMetadata(album: album, artist: artist, track: track),
      );

  group('an album', () {
    test('GivenAnAlbum_WhenItIsQueued_ThenItsTracksAreInTrackOrder', () {
      final library = [
        entry('c.flac', album: 'Kind of Blue', artist: 'Miles Davis', track: 3),
        entry('a.flac', album: 'Kind of Blue', artist: 'Miles Davis', track: 1),
        entry('b.flac', album: 'Kind of Blue', artist: 'Miles Davis', track: 2),
        entry('x.flac', album: 'Bitches Brew', artist: 'Miles Davis', track: 1),
      ];

      expect(albumOf(library[1], library).map((file) => file.name), [
        'a.flac',
        'b.flac',
        'c.flac',
      ]);
    });

    // Two artists can name an album the same thing.
    test(
      'GivenTwoAlbumsOfTheSameName_WhenOneIsQueued_ThenOnlyItsTracksAre',
      () {
        final library = [
          entry('mine.flac', album: 'Greatest Hits', artist: 'One', track: 1),
          entry('theirs.flac', album: 'Greatest Hits', artist: 'Two', track: 1),
        ];

        expect(albumOf(library.first, library).map((file) => file.name), [
          'mine.flac',
        ]);
      },
    );

    // A blank album is not a grouping key: two untitled files are not the same
    // record.
    test('GivenNoAlbum_WhenItIsQueued_ThenItIsAnAlbumOfOne', () {
      final library = [entry('loose.flac'), entry('other.flac')];

      expect(albumOf(library.first, library).map((file) => file.name), [
        'loose.flac',
      ]);
    });

    // An unnumbered rip still has to come out in some order.
    test('GivenTracksWithoutNumbers_WhenTheyAreQueued_ThenTheyAreByName', () {
      final library = [
        entry('b.flac', album: 'Demos'),
        entry('a.flac', album: 'Demos'),
      ];

      expect(albumOf(library.first, library).map((file) => file.name), [
        'a.flac',
        'b.flac',
      ]);
    });

    test('GivenSomeNumberedTracks_WhenTheyAreQueued_ThenNumberedComeFirst', () {
      final library = [
        entry('unnumbered.flac', album: 'Demos'),
        entry('second.flac', album: 'Demos', track: 2),
      ];

      expect(albumOf(library.last, library).map((file) => file.name), [
        'second.flac',
        'unnumbered.flac',
      ]);
    });
  });

  group('an artist', () {
    test('GivenAnArtist_WhenQueued_ThenEveryTrackIsThereAlbumByAlbum', () {
      final library = [
        entry('brew-1.flac', album: 'Bitches Brew', artist: 'Miles', track: 1),
        entry('blue-2.flac', album: 'Kind of Blue', artist: 'Miles', track: 2),
        entry('blue-1.flac', album: 'Kind of Blue', artist: 'Miles', track: 1),
        entry('other.flac', album: 'Giant Steps', artist: 'Coltrane'),
      ];

      expect(artistOf(library[1], library).map((file) => file.name), [
        'brew-1.flac',
        'blue-1.flac',
        'blue-2.flac',
      ]);
    });

    test('GivenNoArtist_WhenQueued_ThenItIsJustThatTrack', () {
      final library = [entry('loose.flac'), entry('other.flac')];

      expect(artistOf(library.first, library).map((file) => file.name), [
        'loose.flac',
      ]);
    });

    // Whitespace is not a name.
    test('GivenABlankArtist_WhenQueued_ThenItIsJustThatTrack', () {
      final library = [entry('a.flac', artist: '   '), entry('b.flac')];

      expect(artistOf(library.first, library), hasLength(1));
    });
  });
}
