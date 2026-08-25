import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playback/application/music_library_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
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
      // The progress read never touched: nothing was published before the
      // listing itself failed, so it still reads as "nothing yet" rather
      // than carrying a stale count from a run that never got started.
      expect(container.read(musicLibraryProgressProvider).total, 0);
    },
  );

  test(
    'GivenAScanInFlight_WhenBothProvidersAreInvalidated_ThenTheOrphanStops',
    () async {
      // Retry (music_library_view.dart) and sign-out
      // (catalog_session_activity.dart) both invalidate the pair mid-scan.
      // The running `build()` is not cancelled by that on its own; this
      // proves it notices and stops rather than racing the new scan's calls
      // on the single FIFO core isolate.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead')
        ..addAudio(uuid: '3', title: 'Nude', artist: 'Radiohead')
        ..holdDetailsFor('2');
      final container = testContainer(gateway: gateway);

      // An active listener, as `MusicLibraryView` keeps by watching it: only
      // a provider with one is rebuilt eagerly on `invalidate`, which is what
      // lets this test catch the orphan in the same shape the view's own
      // Retry does rather than one this test staged.
      container.listen(musicLibraryProvider, (previous, next) {});

      // Starts the scan; file 1 answers and publishes, then file 2's
      // `fileDetails` call is held in flight — this is the "details call
      // held" moment referred to below.
      await pumpEventQueue();
      expect(gateway.detailsRequested, ['1', '2']);

      // The retry/sign-out gesture: both halves of the pair go together,
      // while file 2's call is still held.
      container.invalidate(musicLibraryProvider);
      container.invalidate(musicLibraryProgressProvider);
      await pumpEventQueue();

      // Invalidating a non-autoDispose provider rebuilds it in place rather
      // than disposing the element outright, so the replacement scan starts
      // right away, in parallel with the orphan — it is what makes file 2's
      // details asked for a second time before either has answered.
      expect(gateway.detailsRequested, ['1', '2', '1', '2']);

      // Now let file 2's call answer — both the orphan and the replacement
      // are awaiting the very same held call, so this resumes both at once.
      // The orphan resumes right where the guard sits: this is what proves
      // the guard is actually reached, rather than the scan simply never
      // getting that far.
      gateway.releaseDetails('2');
      await pumpEventQueue();

      // No unhandled error: `publish` on the invalidated progress notifier's
      // stale run was never reached — pumpEventQueue would surface it as a
      // failed test otherwise. And exactly one run reaches file 3: the
      // orphan stopped at the guard instead of continuing past file 2, so
      // only the replacement scan's own request for it appears.
      expect(gateway.detailsRequested, ['1', '2', '1', '2', '3']);
    },
  );
}
