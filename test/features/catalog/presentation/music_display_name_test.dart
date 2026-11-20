import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/presentation/music_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// A track has one name wherever it appears: its title, by its artist.
void main() {
  test('GivenATitle_WhenNamed_ThenTheTitleIsUsed', () {
    final file = aFile(
      name: '03 - song.flac',
      type: FileType.audio,
      tags: const MusicMetadata(title: 'Song'),
    );

    expect(displayName(file), 'Song');
  });

  test('GivenNoTitle_WhenNamed_ThenTheFileNameIsUsed', () {
    final file = aFile(name: '03 - song.flac', type: FileType.audio);

    expect(displayName(file), '03 - song.flac');
  });

  test('GivenWhitespaceTitle_WhenNamed_ThenTheFileNameIsUsed', () {
    final file = aFile(
      name: '03 - song.flac',
      type: FileType.audio,
      tags: const MusicMetadata(title: '   '),
    );

    expect(displayName(file), '03 - song.flac');
  });

  test('GivenAVideo_WhenNamed_ThenItsFileNameIsUsed', () {
    final file = aFile(name: 'talk.mkv', type: FileType.video);

    expect(displayName(file), 'talk.mkv');
  });

  test('GivenArtistAndAlbum_WhenBylined_ThenBothAreSaid', () {
    final file = aFile(
      type: FileType.audio,
      tags: const MusicMetadata(artist: 'Band', album: 'Record'),
    );

    expect(musicByline(file), 'Band · Record');
  });

  test('GivenArtistOnly_WhenBylined_ThenJustTheArtist', () {
    final file = aFile(
      type: FileType.audio,
      tags: const MusicMetadata(artist: 'Band'),
    );

    expect(musicByline(file), 'Band');
  });

  test('GivenNoArtistOrAlbum_WhenBylined_ThenThereIsNone', () {
    expect(musicByline(aFile(type: FileType.audio)), isNull);
  });

  test('GivenDurations_WhenFormatted_ThenMinutesAndSecondsOrHours', () {
    expect(formatDuration(5), '0:05');
    expect(formatDuration(245.6), '4:05');
    expect(formatDuration(3725), '1:02:05');
  });
}
