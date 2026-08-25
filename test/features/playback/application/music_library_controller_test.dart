import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/test_container.dart';

/// Reading the library's metadata (UC-46 main flow step 1).
///
/// The core answers file records with no metadata and publishes no listing
/// that carries it, so the album a track belongs to is only knowable by
/// reading each file. These tests are about what the area can show while that
/// is still happening.
void main() {
  test(
    'GivenAudioFiles_WhenTheLibraryLoads_ThenItReportsHowManyAreExpected',
    () async {
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead');
      final container = testContainer(gateway: gateway);

      // musicLibraryProvider.future only ever resolves once, with the
      // complete library — this is the assertion that catches a regression
      // back to publishing partial state through it.
      final library = await container.read(musicLibraryProvider.future);

      expect(library.total, 2);
      expect(library.entries.length, 2);
      expect(library.isComplete, isTrue);
    },
  );

  test(
    'GivenMetadataStillArriving_WhenTheLibraryIsRead_ThenTheEntriesSoFarAreShown',
    () async {
      // The point of loading incrementally: the area shows artists while the
      // rest of the calls are still running, rather than sitting blank. The
      // second file's details never answer, so musicLibraryProvider.future
      // never resolves in this test — what is being read here is
      // musicLibraryProgressProvider, the one the browsing area watches while
      // a load is still in flight.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead')
        ..holdDetailsAfter(1);
      final container = testContainer(gateway: gateway);

      final firstPublish = Completer<void>();
      container.listen(musicLibraryProgressProvider, (previous, next) {
        if (!firstPublish.isCompleted) firstPublish.complete();
      });

      // Starts the load; deliberately not awaited — the second file's
      // details never answer, so the load itself never finishes.
      container.read(musicLibraryProvider);

      await firstPublish.future;
      final progress = container.read(musicLibraryProgressProvider);

      expect(progress.entries.length, 1);
      expect(progress.total, 2);
      expect(progress.isComplete, isFalse);
    },
  );

  test(
    'GivenAFileWhoseDetailsFail_WhenTheLibraryLoads_ThenItJoinsWithNoMetadata',
    () async {
      // A file the catalog cannot describe is still a file the owner has.
      // It lands in the untagged group rather than vanishing.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..failDetailsFor('1');
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries.single.artist, isNull);
      expect(library.isComplete, isTrue);
    },
  );

  test(
    'GivenAListingThatFails_WhenTheLibraryLoads_ThenItIsEmptyAndComplete',
    () async {
      final gateway = FakeCatalogGateway()..failListing();
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries, isEmpty);
      expect(library.total, 0);
      expect(library.isComplete, isTrue);
    },
  );
}
