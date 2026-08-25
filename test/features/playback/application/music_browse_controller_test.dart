import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/music_browse_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/test_container.dart';

/// Where the owner is in the music area (UC-46 main flow steps 2 and 3).
void main() {
  // The controller reads nothing from the catalog, but testContainer needs a
  // gateway to build — an empty fake is enough, as it is for every other
  // controller test in this directory.
  ProviderContainer buildContainer() => testContainer(gateway: FakeCatalogGateway());

  test('GivenAFreshArea_WhenItOpens_ThenItShowsArtistsAtTheTop', () {
    final container = buildContainer();

    final state = container.read(musicBrowseControllerProvider);

    expect(state.view, MusicView.artists);
    expect(state.inArtist, isFalse);
  });

  test('GivenTheArtistsView_WhenAnArtistIsOpened_ThenTheirAlbumsAreShown', () {
    final container = buildContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inArtist, isTrue);
    expect(state.artist, 'Radiohead');
    expect(state.inAlbum, isFalse);
  });

  test('GivenTheUntaggedGroup_WhenItIsOpened_ThenItIsADrillNotADeselection', () {
    // A null artist is a real group — the files that name none — so it cannot
    // double as "nothing selected".
    final container = buildContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist(null);

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inArtist, isTrue);
    expect(state.artist, isNull);
  });

  test('GivenAnAlbumIsOpen_WhenTheOwnerGoesUp_ThenTheArtistRemains', () {
    final container = buildContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');
    controller.openAlbum('OK', 'Radiohead');
    controller.upToArtist();

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inAlbum, isFalse);
    expect(state.artist, 'Radiohead');
  });

  test('GivenADrilledInOwner_WhenTheViewChanges_ThenTheDrillIsForgotten', () {
    // Switching to Albums from inside an artist's record should land on the
    // albums list, not inside whatever was open in the other view.
    final container = buildContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');
    controller.openAlbum('OK', 'Radiohead');
    controller.show(MusicView.albums);

    final state = container.read(musicBrowseControllerProvider);
    expect(state.view, MusicView.albums);
    expect(state.inArtist, isFalse);
    expect(state.inAlbum, isFalse);
  });

  test(
    'GivenTheAlbumsView_WhenAnAlbumIsOpenedDirectly_ThenNoArtistCrumbShows',
    () {
      // Opening an album straight from the Albums view is a one-level drill:
      // no artist was opened on the way there, so the breadcrumb should not
      // claim one was.
      final container = buildContainer();
      final controller = container.read(
        musicBrowseControllerProvider.notifier,
      );

      controller.show(MusicView.albums);
      controller.openAlbum('OK', 'Radiohead');

      final state = container.read(musicBrowseControllerProvider);
      expect(state.inArtist, isFalse);
      expect(state.inAlbum, isTrue);
      expect(state.artist, 'Radiohead');
    },
  );
}
