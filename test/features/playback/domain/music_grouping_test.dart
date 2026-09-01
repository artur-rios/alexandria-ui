import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playback/domain/music_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Grouping an audio library into albums and artists (UC-20 main flow step 3,
/// FR-PL-06).
void main() {
  MusicEntry entry(
    String name, {
    String? album,
    String? artist,
    String? albumArtist,
    int? track,
  }) => MusicEntry(
    file: aFile(uuid: name, name: name),
    metadata: MusicMetadata(
      album: album,
      artist: artist,
      albumArtist: albumArtist,
      track: track,
    ),
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

  group('the album artist (UC-46)', () {
    test(
      'GivenNoAlbumArtistTag_WhenItIsRead_ThenItFallsBackToThePerformer',
      () {
        // The fallback most files take: a library tagged before the album
        // artist existed groups exactly as it did.
        expect(entry('a.flac', artist: 'Radiohead').albumArtist, 'Radiohead');
      },
    );

    test('GivenABlankAlbumArtistTag_WhenItIsRead_ThenItFallsBackToo', () {
      // A blank tag names nobody, so it is not a value to group by.
      expect(
        entry('a.flac', artist: 'Radiohead', albumArtist: '  ').albumArtist,
        'Radiohead',
      );
    });

    test('GivenAnAlbumArtistTag_WhenTheTrackIsRead_ThenItStillNamesItsOwn', () {
      // The two are different facts, and a track row shows the performer.
      final track = entry(
        'a.flac',
        artist: 'First Performer',
        albumArtist: 'Various Artists',
      );

      expect(track.artist, 'First Performer');
      expect(track.albumArtist, 'Various Artists');
    });

    test(
      'GivenAnUntaggedArtistsAlbum_WhenItIsQueued_ThenATaggedOnesStaysOut',
      () {
        // The list and the queue have to agree: `tracksOfAlbum` shows the
        // untagged group alone, so pressing play on one of its rows must not
        // pull in a properly tagged artist's record that happens to share the
        // title.
        final library = [
          entry('anon.flac', album: 'Greatest Hits'),
          entry('theirs.flac', album: 'Greatest Hits', artist: 'Someone'),
        ];

        expect(albumOf(library.first, library).map((file) => file.name), [
          'anon.flac',
        ]);
        // And the other way round, which the old permissive arm allowed only
        // in one direction.
        expect(albumOf(library.last, library).map((file) => file.name), [
          'theirs.flac',
        ]);
      },
    );

    test('GivenACompilation_WhenItIsQueued_ThenEveryPerformerIsInIt', () {
      // Keyed by the performer, pressing play on this album would queue only
      // the track started from — a subset of what the album listed.
      final library = [
        entry(
          'one.flac',
          album: "Now That's Music",
          artist: 'First Performer',
          albumArtist: 'Various Artists',
          track: 1,
        ),
        entry(
          'two.flac',
          album: "Now That's Music",
          artist: 'Second Performer',
          albumArtist: 'Various Artists',
          track: 2,
        ),
      ];

      expect(albumOf(library.first, library).map((file) => file.name), [
        'one.flac',
        'two.flac',
      ]);
    });

    test('GivenAGuestAppearance_WhenTheArtistIsQueued_ThenItIsIncluded', () {
      // The guest track is on the host's record, so an artist queue built
      // from the Artists list has to hold it.
      final library = [
        entry(
          'host.flac',
          album: 'Record',
          artist: 'Host',
          albumArtist: 'Host',
          track: 1,
        ),
        entry(
          'guest.flac',
          album: 'Record',
          artist: 'Guest',
          albumArtist: 'Host',
          track: 2,
        ),
      ];

      expect(artistOf(library.first, library).map((file) => file.name), [
        'host.flac',
        'guest.flac',
      ]);
    });
  });

  group('who a record is by (UC-46)', () {
    // The owner's own report: a rap album whose tracks name their guests
    // listed every guest in the artists area as though they had a record of
    // their own.
    test('GivenGuestsAndNoTag_WhenAskedWhoTheRecordIsBy_ThenItIsTheHost', () {
      final library = albumArtistsAcross([
        entry('1.flac', album: 'Get Rich', artist: '50 Cent'),
        entry('2.flac', album: 'Get Rich', artist: '50 Cent feat. Nate Dogg'),
        entry('3.flac', album: 'Get Rich', artist: '50 Cent'),
        entry('4.flac', album: 'Get Rich', artist: 'Eminem, 50 Cent'),
      ]);

      expect(
        library.map((entry) => entry.albumArtist).toSet(),
        {'50 Cent'},
        reason: 'one record, one artist, whatever each track names',
      );
    });

    // Half-tagged libraries are the norm: one editor writes the frame,
    // another does not.
    test('GivenOneTrackTagged_WhenAskedWhoTheRecordIsBy_ThenThatTagSettlesIt', () {
      final library = albumArtistsAcross([
        entry('1.flac', album: 'Kind of Blue', artist: 'Miles Davis'),
        entry(
          '2.flac',
          album: 'Kind of Blue',
          artist: 'John Coltrane',
          albumArtist: 'Miles Davis Sextet',
        ),
      ]);

      expect(
        library.map((entry) => entry.albumArtist).toSet(),
        {'Miles Davis Sextet'},
        reason: 'a tag on any track answers for the record, not just its own',
      );
    });

    test('GivenATrackWithItsOwnTag_WhenAsked_ThenItsOwnTagWins', () {
      // The owner's answer outranks anything inferred from its neighbours.
      final library = albumArtistsAcross([
        entry('1.flac', album: 'Split', artist: 'A', albumArtist: 'A'),
        entry('2.flac', album: 'Split', artist: 'B', albumArtist: 'B'),
      ]);

      expect(
        library.map((entry) => entry.albumArtist).toList(),
        ['A', 'B'],
      );
    });

    test('GivenNoAlbum_WhenAsked_ThenTheTrackAnswersForItself', () {
      // Two untitled files are not the same record, so nothing is inferred
      // across them.
      final library = albumArtistsAcross([
        entry('1.flac', artist: 'A'),
        entry('2.flac', artist: 'B'),
      ]);

      expect(library.map((entry) => entry.albumArtist).toList(), ['A', 'B']);
    });

    test('GivenTwoRecords_WhenAsked_ThenNeitherAnswersForTheOther', () {
      final library = albumArtistsAcross([
        entry('1.flac', album: 'One', artist: 'A'),
        entry('2.flac', album: 'One', artist: 'A feat. B'),
        entry('3.flac', album: 'Two', artist: 'C'),
      ]);

      expect(
        library.map((entry) => entry.albumArtist).toList(),
        ['A', 'A', 'C'],
      );
    });

    test('GivenATie_WhenAsked_ThenTheAnswerIsStable', () {
      // A library that reordered itself depending on which track the core
      // answered first would be a library that moves for no reason the owner
      // can see.
      final first = albumArtistsAcross([
        entry('1.flac', album: 'Split', artist: 'B'),
        entry('2.flac', album: 'Split', artist: 'A'),
      ]);
      final second = albumArtistsAcross([
        entry('2.flac', album: 'Split', artist: 'A'),
        entry('1.flac', album: 'Split', artist: 'B'),
      ]);

      expect(
        first.first.albumArtist,
        second.first.albumArtist,
      );
      expect(first.first.albumArtist, 'A');
    });
  });
}
