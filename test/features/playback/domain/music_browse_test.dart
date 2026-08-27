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
    String? albumArtist,
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
      albumArtist: albumArtist,
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

  group('the album artist (UC-46)', () {
    /// A compilation: twelve performers, one record. Keyed by the performer
    /// this is twelve albums of one track and twelve artists; keyed by the
    /// record's own artist it is one of each.
    final compilation = [
      entry(
        uuid: 'c1',
        title: 'One',
        artist: 'First Performer',
        albumArtist: 'Various Artists',
        album: "Now That's Music",
        track: 1,
      ),
      entry(
        uuid: 'c2',
        title: 'Two',
        artist: 'Second Performer',
        albumArtist: 'Various Artists',
        album: "Now That's Music",
        track: 2,
      ),
    ];

    test(
      'GivenOneAlbumArtistOverManyPerformers_WhenArtistsAreListed_ThenTheyAreOneGroup',
      () {
        final artists = artistsIn(compilation);

        expect([for (final group in artists) group.name], ['Various Artists']);
        expect(artists.single.entries, hasLength(2));
      },
    );

    test(
      'GivenOneAlbumArtistOverManyPerformers_WhenAlbumsAreListed_ThenTheyAreOneAlbum',
      () {
        final albums = albumsIn(compilation);

        expect(albums, hasLength(1));
        expect(albums.single.entries.map((e) => e.title), ['One', 'Two']);
      },
    );

    test(
      'GivenACompilation_WhenTheArtistIsDrilledInto_ThenTheAlbumIsUnderThem',
      () {
        // What the row drills in with is the group's album artist, so this is
        // the pair the presentation actually passes.
        final albums = albumsOfArtist('Various Artists', compilation);
        final tracks = tracksOfAlbum(
          albums.single.name,
          albums.single.entries.first.albumArtist,
          compilation,
        );

        expect(tracks.map((e) => e.title), ['One', 'Two']);
      },
    );

    test('GivenABlankAlbumArtist_WhenArtistsAreListed_ThenItFallsBackToo', () {
      // A blank tag names nobody, so it is not a group of its own — it takes
      // the same fallback an absent one does.
      final artists = artistsIn([
        entry(uuid: 'b1', artist: 'Radiohead', albumArtist: '   '),
        ...tagged,
      ]);

      expect([for (final group in artists) group.name], [
        'Portishead',
        'Radiohead',
      ]);
      expect(artists.last.entries, hasLength(3));
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

    test(
      'GivenTwoArtistsSharingAnAlbumName_WhenAlbumsAreListed_ThenTheirOrderIsByArtist',
      () {
        // Same album title, so the primary sort key ties; nothing pinned the
        // tiebreak, which made the relative order between them whichever the
        // underlying map happened to iterate in — insertion order — rather
        // than anything predictable. Added in reverse-artist order so an
        // insertion-order tiebreak would fail this the other way around.
        final albums = albumsIn([
          entry(uuid: '7', artist: 'Zeta', album: 'Home'),
          entry(uuid: '8', artist: 'Alpha', album: 'Home'),
        ]);

        expect(
          [for (final group in albums) group.entries.first.artist],
          ['Alpha', 'Zeta'],
        );
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
