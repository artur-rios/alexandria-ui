import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/playback/application/music_library_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/test_container.dart';

/// Reading the library's metadata (UC-46 main flow step 1).
///
/// The core's listing now answers each row with the same metadata the
/// single-file call does, so the whole library — every track's album and
/// artist included — is known from one gateway call.
void main() {
  test(
    'GivenAudioFiles_WhenTheLibraryLoads_ThenEveryEntryCarriesItsMetadata',
    () async {
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead');
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries.length, 2);
      expect(library.entries.map((entry) => entry.title), ['Airbag', 'Karma']);
      expect(
        library.entries.every((entry) => entry.artist == 'Radiohead'),
        isTrue,
      );
    },
  );

  test(
    'GivenAudioFiles_WhenTheLibraryLoads_ThenTheGatewayIsCalledExactlyOnce',
    () async {
      // The whole point of the change this controller went through: listing
      // the audio files answers every row's metadata already, so there is no
      // second call per file to make. A regression back to reading each
      // file's details individually would be invisible to every assertion
      // about the resulting library — this is the one that catches it.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead')
        ..addAudio(uuid: '3', title: 'Nude', artist: 'Radiohead');
      final container = testContainer(gateway: gateway);

      await container.read(musicLibraryProvider.future);

      expect(gateway.listCalls, 1);
      expect(gateway.detailsRequested, isEmpty);
    },
  );

  test(
    'GivenARowWithNoMetadata_WhenTheLibraryLoads_ThenItJoinsWithNoTags',
    () async {
      // A file the core has nothing to say about is still a file the owner
      // has. It lands in the untagged group rather than vanishing.
      final gateway = FakeCatalogGateway(
        listings: {
          LibraryType.audio: loadedDetails([aFile(uuid: '1', name: 'a.flac')]),
        },
      );
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries.single.title, isNull);
      expect(library.entries.single.artist, isNull);
    },
  );

  test(
    'GivenAListingThatFails_WhenTheLibraryLoads_ThenTheFailureIsThrown',
    () async {
      // Thrown rather than swallowed into an empty library: every other
      // type's listing does the same (UC-09 AF-02), and "No audio files are
      // catalogued yet" would be a lie about a listing that never answered.
      final gateway = FakeCatalogGateway()..failListing();

      // Riverpod retries a failed provider automatically (exponential
      // backoff up to ten attempts) before it settles into `AsyncError` —
      // real time a widget test never waits out because its pumps run on a
      // fake clock, but a plain `test()` does. Retrying is disabled here so
      // this asserts the settled state without a ~35-second test.
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [catalogGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      // No startup ever runs over this container, so it is honest about
      // never having a core to re-check against: `establish`'s own
      // unawaited call to `begin()` (FR-LB-21) would otherwise reach for one
      // that was never loaded, over a scenario this test has nothing to do
      // with.
      await container
          .read(preferencesControllerProvider.notifier)
          .setRechecksAtStartup(false);
      container
          .read(sessionControllerProvider.notifier)
          .establish(FakeAuthGateway.defaultSession);

      // Watched rather than awaited through `.future`: the state this
      // becomes is `AsyncError`, and it is the state — what
      // `MusicLibraryView` actually reads — that this asserts on.
      final errorReported = Completer<Object>();
      container.listen(musicLibraryProvider, (previous, next) {
        if (next case AsyncError(:final error)) {
          if (!errorReported.isCompleted) errorReported.complete(error);
        }
      });
      container.read(musicLibraryProvider);

      final error = await errorReported.future;

      expect(error, isA<Failure>());
      expect(
        container.read(musicLibraryProvider),
        isA<AsyncError<MusicLibrary>>(),
      );
    },
  );

  test(
    'GivenNoAudioFiles_WhenTheLibraryLoads_ThenItIsEmptyRatherThanFailed',
    () async {
      // Distinguishing an empty library from a failed one is what the empty
      // and failure states of the browsing area depend on.
      final gateway = FakeCatalogGateway();
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries, isEmpty);
    },
  );
}
