import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Ordering a listing's files (UC-12, FR-CT-08).
void main() {
  group('ordering (FR-CT-08)', () {
    final files = [
      aFile(
        uuid: '1',
        name: 'giant squid.md',
        indexedAt: DateTime.utc(2026, 3),
      ),
      aFile(
        uuid: '2',
        name: 'Blue Planet.md',
        indexedAt: DateTime.utc(2026, 1),
      ),
      aFile(
        uuid: '3',
        name: 'Kelp Forest.md',
        indexedAt: DateTime.utc(2026, 2),
      ),
    ];

    test('GivenNameAscending_WhenSorted_ThenItIgnoresCase', () {
      // A library sorted with every capital first is not sorted the way
      // anyone reads.
      final sorted = sortFiles(files, const ListingView());

      expect(sorted.map((file) => file.uuid), ['2', '1', '3']);
    });

    test('GivenNameDescending_WhenSorted_ThenTheOrderReverses', () {
      final sorted = sortFiles(
        files,
        const ListingView(direction: SortDirection.descending),
      );

      expect(sorted.map((file) => file.uuid), ['3', '1', '2']);
    });

    test('GivenDateAscending_WhenSorted_ThenTheOldestIsFirst', () {
      final sorted = sortFiles(
        files,
        const ListingView(sortField: SortField.indexed),
      );

      expect(sorted.map((file) => file.uuid), ['2', '3', '1']);
    });

    test('GivenAFileWithNoDate_WhenSortedByDate_ThenItIsTheOldest', () {
      // Missing information, not a reason to refuse to sort.
      final undated = aFile(uuid: '4', name: 'undated.md');
      final sorted = sortFiles([
        ...files,
        undated,
      ], const ListingView(sortField: SortField.indexed));

      expect(sorted.first.uuid, '4');
    });

    test('GivenAListing_WhenItIsSorted_ThenTheOriginalIsNotDisturbed', () {
      final original = [...files];

      sortFiles(files, const ListingView());

      expect(files, original);
    });
  });

  group('the album order (Music)', () {
    CatalogFile track(
      String uuid, {
      String? albumArtist,
      String? artist,
      String? album,
      int? track,
      String? title,
      String name = 'x.flac',
    }) => aFile(
      uuid: uuid,
      name: name,
      type: FileType.audio,
      tags: MusicMetadata(
        albumArtist: albumArtist,
        artist: artist,
        album: album,
        track: track,
        title: title,
      ),
    );

    const album = ListingView(sortField: SortField.album);

    test(
      'GivenTracksOfTwoAlbums_WhenSortedByAlbum_ThenAlbumArtistAlbumTrackOrder',
      () {
        final sorted = sortFiles([
          track('a2-10', albumArtist: 'a2', album: 'One', track: 10),
          track('B-1', albumArtist: 'B', album: 'Two', track: 1),
          track('a2-2', albumArtist: 'a2', album: 'One', track: 2),
          track('a10-1', albumArtist: 'a10', album: 'Zed', track: 1),
        ], album);

        // Case-insensitive text, numeric track numbers.
        expect(sorted.map((file) => file.uuid), [
          'a10-1',
          'a2-2',
          'a2-10',
          'B-1',
        ]);
      },
    );

    test('GivenNoAlbumArtist_WhenSortedByAlbum_ThenArtistIsUsed', () {
      final sorted = sortFiles([
        track('z', albumArtist: 'Zed', album: 'A'),
        track('m', artist: 'Mid', album: 'A'),
      ], album);

      expect(sorted.map((file) => file.uuid), ['m', 'z']);
    });

    test('GivenUntaggedTracks_WhenSortedByAlbum_ThenTheySortLastByName', () {
      final sorted = sortFiles([
        track('untagged-b', name: 'b.flac'),
        track('tagged', albumArtist: 'Band', album: 'Record', track: 1),
        track('untagged-a', name: 'a.flac'),
        track('no-track', albumArtist: 'Band', album: 'Record'),
      ], album);

      expect(sorted.map((file) => file.uuid), [
        'tagged',
        'no-track',
        'untagged-a',
        'untagged-b',
      ]);
    });

    test('GivenAlbumDescending_WhenSorted_ThenTheOrderReverses', () {
      final sorted = sortFiles(
        [
          track('1', albumArtist: 'A', album: 'A', track: 1),
          track('2', albumArtist: 'A', album: 'A', track: 2),
        ],
        const ListingView(
          sortField: SortField.album,
          direction: SortDirection.descending,
        ),
      );

      expect(sorted.map((file) => file.uuid), ['2', '1']);
    });
  });
}
