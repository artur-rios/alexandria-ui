import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/playback/domain/music_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

/// The groupings the music area browses by (UC-46, FR-CT-13).
void main() {
  /// An entry whose file name is deliberately unlike its title: a grouping
  /// that fell back to the file name would be visible in the assertions.
  MusicEntry entry({
    required String uuid,
    String? title,
    String? artist,
    String? album,
    int? track,
  }) => MusicEntry(
    file: CatalogFile(
      uuid: uuid,
      name: 'zzz-$uuid.flac',
      path: 'C:/library/zzz-$uuid.flac',
      type: LibraryType.audio,
    ),
    metadata: MusicMetadata(
      title: title,
      artist: artist,
      album: album,
      track: track,
    ),
  );

  final tagged = [
    entry(uuid: '1', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
    entry(uuid: '2', title: 'Karma', artist: 'Radiohead', album: 'OK', track: 2),
    entry(uuid: '3', title: 'Roads', artist: 'Portishead', album: 'Dummy', track: 1),
  ];

  group('artists', () {
    test(
      'GivenATaggedLibrary_WhenArtistsAreListed_ThenEachAppearsOnceAlphabetically',
      () {
        final artists = artistsIn(tagged);

        expect([for (final group in artists) group.name], [
          'Portishead',
          'Radiohead',
        ]);
      },
    );

    test('GivenAnArtist_WhenItIsListed_ThenItCarriesItsOwnTracks', () {
      final artists = artistsIn(tagged);

      expect(artists.first.entries.map((e) => e.title), ['Roads']);
    });

    test(
      'GivenAFileWithNoArtist_WhenArtistsAreListed_ThenItGroupsUnderNoNameLast',
      () {
        // The untagged files are the ones that need tagging: gathered, and out
        // of the way of a library that is mostly tagged.
        final artists = artistsIn([...tagged, entry(uuid: '4', title: 'Loose')]);

        expect(artists.last.name, isNull);
        expect(artists.last.entries.single.file.uuid, '4');
      },
    );

    test('GivenMixedCaseArtists_WhenTheyAreListed_ThenTheOrderIgnoresCase', () {
      // A library sorted with every capital first is not sorted the way
      // anyone reads.
      final artists = artistsIn([
        entry(uuid: '5', artist: 'aphex twin'),
        entry(uuid: '6', artist: 'Boards of Canada'),
      ]);

      expect([for (final group in artists) group.name], [
        'aphex twin',
        'Boards of Canada',
      ]);
    });
  });

  group('albums', () {
    test('GivenALibrary_WhenAlbumsAreListed_ThenEachAppearsOnce', () {
      expect([for (final group in albumsIn(tagged)) group.name], ['Dummy', 'OK']);
    });

    test(
      'GivenTwoArtistsSharingAnAlbumName_WhenAlbumsAreListed_ThenTheyStayApart',
      () {
        // Two different artists can name a record the same thing, and merging
        // them would put one artist's tracks inside another's album.
        final albums = albumsIn([
          entry(uuid: '7', artist: 'A', album: 'Home'),
          entry(uuid: '8', artist: 'B', album: 'Home'),
        ]);

        expect(albums.length, 2);
      },
    );

    test('GivenAnArtist_WhenTheirAlbumsAreListed_ThenOnlyTheirsAreReturned', () {
      final albums = albumsOfArtist('Radiohead', tagged);

      expect([for (final group in albums) group.name], ['OK']);
    });
  });

  group('tracks', () {
    test('GivenAnAlbum_WhenItsTracksAreListed_ThenTheyComeInTrackOrder', () {
      final tracks = tracksOfAlbum('OK', 'Radiohead', [
        entry(uuid: '9', title: 'Karma', artist: 'Radiohead', album: 'OK', track: 2),
        entry(uuid: '10', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
      ]);

      expect(tracks.map((e) => e.title), ['Airbag', 'Karma']);
    });

    test(
      'GivenTracksWithNoNumber_WhenTheAlbumIsListed_ThenNumberedOnesComeFirst',
      () {
        final tracks = tracksOfAlbum('OK', 'Radiohead', [
          entry(uuid: '11', title: 'Bonus', artist: 'Radiohead', album: 'OK'),
          entry(uuid: '12', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
        ]);

        expect(tracks.map((e) => e.title), ['Airbag', 'Bonus']);
      },
    );

    test('GivenALibrary_WhenSongsAreListed_ThenTheyAreAlphabeticalByTitle', () {
      expect(songsIn(tagged).map((e) => e.title), ['Airbag', 'Karma', 'Roads']);
    });

    test(
      'GivenAFileWithNoTitle_WhenSongsAreListed_ThenItSortsAfterTheTitledOnes',
      () {
        final songs = songsIn([...tagged, entry(uuid: '13')]);

        expect(songs.last.file.uuid, '13');
      },
    );
  });
}
