import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';

/// Listing the selected type's files (UC-09, FR-CT-02, FR-LB-04).
void main() {
  ({ProviderContainer ref, FakeCatalogGateway gateway}) build({
    Map<FileType, CatalogListing>? listings,
    bool signedIn = true,
    bool watchCounts = false,
  }) {
    final gateway = FakeCatalogGateway(listings: listings);

    final container = ProviderContainer(
      overrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    if (signedIn) {
      container
          .read(sessionControllerProvider.notifier)
          .establish(FakeAuthGateway.defaultSession);
    }

    // Providers are auto-disposed without a listener, and a listing read only
    // through its future would be torn down while it was still loading. The
    // screen holds these open; a test has to say so.
    container.listen(listingControllerProvider, (_, _) {});
    if (watchCounts) {
      container.listen(typeCountsControllerProvider, (_, _) {});
    }

    return (ref: container, gateway: gateway);
  }

  group('the main flow', () {
    test(
      'GivenTheOwnerSelectsAType_WhenItLoads_ThenThatTypeIsAskedFor',
      () async {
        final sut = build();
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        await sut.ref.read(listingControllerProvider.future);

        expect(sut.gateway.requested, contains(FileType.audio));
      },
    );

    test(
      'GivenTheCoreAnswers_WhenTheListingLoads_ThenItsFilesAreShown',
      () async {
        final sut = build(
          listings: {
            FileType.audio: loadedDetails([aFile()]),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        final files = await sut.ref.read(listingControllerProvider.future);

        expect(files, hasLength(1));
        expect(files.single.name, 'Kind of Blue.flac');
      },
    );

    test(
      'GivenVideos_WhenSelected_ThenTheCoresSingleVideoTypeIsAskedFor',
      () async {
        // The panel's one Videos entry maps to the core's one video type; the
        // movie and series distinction is a watchlist's, not the catalog's.
        final sut = build();
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.videos);

        await sut.ref.read(listingControllerProvider.future);

        expect(sut.gateway.requested, contains(FileType.video));
      },
    );

    test('GivenTheDashboard_WhenItIsSelected_ThenNoListingIsFetched', () async {
      // Home is UC-14's and bookmarks are UC-28's; neither is a file listing.
      final sut = build();

      final files = await sut.ref.read(listingControllerProvider.future);

      expect(files, isEmpty);
      expect(sut.gateway.requested, isEmpty);
    });

    test('GivenBookmarks_WhenSelected_ThenNoFileListingIsFetched', () async {
      final sut = build();
      sut.ref
          .read(shellControllerProvider.notifier)
          .go(ShellDestination.bookmarks);

      await sut.ref.read(listingControllerProvider.future);

      expect(sut.gateway.requested, isEmpty);
    });

    test(
      'GivenNoSession_WhenAListingIsRead_ThenTheCoreIsNeverCalled',
      () async {
        // FR-AU-07.
        final sut = build(signedIn: false);
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        await sut.ref.read(listingControllerProvider.future);

        expect(sut.gateway.requested, isEmpty);
      },
    );
  });

  group('the type is empty (AF-01)', () {
    test(
      'GivenATypeWithNoItems_WhenItLoads_ThenTheListingIsEmptyNotFailed',
      () async {
        final sut = build();
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        final files = await sut.ref.read(listingControllerProvider.future);

        expect(files, isEmpty);
        expect(sut.ref.read(listingControllerProvider).hasError, isFalse);
      },
    );
  });

  group('the core fails (AF-02)', () {
    test(
      'GivenTheCoreFails_WhenAListingLoads_ThenItSurfacesAsAnError',
      () async {
        // Thrown rather than returned empty, so "we could not ask" is never
        // mistaken for "there is nothing here".
        const failure = Failure.disk(family: CoreStatusFamily.file, code: 6);
        final sut = build(
          listings: {
            FileType.audio: const CatalogListing.failed(failure: failure),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        // The state rather than the future: the screen reads the state, and an
        // AsyncValue that settled into an error is exactly what AsyncStateView
        // renders as the failure and its retry.
        await pumpEventQueue();

        final state = sut.ref.read(listingControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.error, failure);
      },
    );

    test(
      'GivenAFailedType_WhenAnotherIsSelected_ThenItLoadsNormally',
      () async {
        // One type failing must not take the others down with it.
        final sut = build(
          listings: {
            FileType.audio: const CatalogListing.failed(
              failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
            ),
            FileType.image: loadedDetails([
              aFile(type: FileType.image, name: 'a.png'),
            ]),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);
        await pumpEventQueue();

        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.images);
        final files = await sut.ref.read(listingControllerProvider.future);

        expect(files, hasLength(1));
      },
    );
  });

  group('the core rejects the session (AF-04)', () {
    test(
      'GivenTheCoreRejectsTheSession_WhenAListingLoads_ThenTheOwnerSignsOut',
      () async {
        const failure = Failure.unauthorized(
          family: CoreStatusFamily.file,
          code: 2,
        );
        final sut = build(
          listings: {
            FileType.audio: const CatalogListing.failed(failure: failure),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);

        await pumpEventQueue();

        expect(sut.ref.read(listingControllerProvider).hasError, isTrue);
        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });

  group('the panel counts (FR-CT-01)', () {
    test(
      'GivenEveryType_WhenTheCountsLoad_ThenOneListingAnswersThemAll',
      () async {
        // One call with no type filter, not one call per type. Asking per
        // type serialized the whole catalog out of the core once for every
        // type in the panel, and again after every scan, purge and restore.
        final sut = build(watchCounts: true);

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(sut.gateway.requested, [null]);
        expect(counts.length, FileType.values.length);
      },
    );

    test(
      'GivenATypeWithFiles_WhenTheCountsLoad_ThenItsCountIsItsLength',
      () async {
        final sut = build(
          watchCounts: true,
          listings: {
            FileType.audio: loadedDetails([
              aFile(),
              aFile(uuid: 'b', name: 'b.flac'),
            ]),
          },
        );

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(counts[FileType.audio], 2);
      },
    );

    test(
      'GivenTheCountsCannotBeRead_WhenTheyLoad_ThenItFailsRatherThanReadsZero',
      () async {
        // A zero would read as "nothing here" about a query that never
        // answered, and an empty map is that lie told for every type at once.
        // The failure state is what puts the retry on screen.
        final sut = build(
          watchCounts: true,
          listings: {
            FileType.audio: const CatalogListing.failed(
              failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
            ),
          },
        );

        await pumpEventQueue();

        final counts = sut.ref.read(typeCountsControllerProvider);
        expect(counts.hasError, isTrue);
        expect(counts.error, isA<DiskFailure>());
      },
    );

    test(
      'GivenSeveralTypesWithFiles_WhenTheCountsLoad_ThenEachIsTalliedApart',
      () async {
        // The tally moved out of the core and into the controller, so the
        // split between types is now this code's job rather than the
        // filter's — and getting it wrong would put every file under one
        // heading.
        final sut = build(
          watchCounts: true,
          listings: {
            FileType.audio: loadedDetails([
              aFile(),
              aFile(uuid: 'b', name: 'b.flac'),
            ]),
            FileType.image: loadedDetails([
              aFile(uuid: 'c', name: 'c.png', type: FileType.image),
            ]),
          },
        );

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(counts[FileType.audio], 2);
        expect(counts[FileType.image], 1);
        expect(counts[FileType.video], 0);
      },
    );
  });
}
