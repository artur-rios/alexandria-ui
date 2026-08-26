import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/catalog/application/listing_view_controller.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// Choosing filters and a sort per type (UC-12, FR-CT-07, FR-CT-08).
void main() {
  Future<({ProviderContainer ref, FakeCatalogGateway gateway})> started({
    SettingsStore? settings,
    Map<LibraryType, CatalogListing>? listings,
    Map<LibraryType, CatalogListing>? deleted,
  }) async {
    final gateway = FakeCatalogGateway(listings: listings, deleted: deleted);
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(settings: settings ?? InMemorySettingsStore()),
        catalogGatewayProvider.overrideWithValue(gateway),
      ],
    );
    await container.read(startupControllerProvider.notifier).start();
    // Off, so `establish`'s own unawaited call to `begin()` (FR-LB-21) does
    // not itself start a background refresh this suite has nothing to do
    // with, racing this container's own teardown.
    await container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);
    container.listen(listingControllerProvider, (_, _) {});

    return (ref: container, gateway: gateway);
  }

  group('applying a view', () {
    test(
      'GivenAChosenFilter_WhenItIsApplied_ThenTheCoreIsAskedForIt',
      () async {
        // Main flow step 2: the lifecycle filter is the one the core supports.
        final sut = await started();
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);
        await pumpEventQueue();

        await sut.ref
            .read(listingViewControllerProvider.notifier)
            .apply(
              LibraryType.audio,
              const ListingView(lifecycle: LifecycleFilter.deleted),
            );
        await pumpEventQueue();

        expect(sut.gateway.lifecycles, contains(LifecycleFilter.deleted));
      },
    );

    test(
      'GivenAChosenSort_WhenItIsApplied_ThenTheListingIsReordered',
      () async {
        final sut = await started(
          listings: {
            LibraryType.audio: loadedDetails([
              aFile(uuid: '1', name: 'zebra.flac'),
              aFile(uuid: '2', name: 'apple.flac'),
            ]),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);
        await pumpEventQueue();

        final ascending = sut.ref.read(listingControllerProvider).value!;
        expect(ascending.first.uuid, '2');

        await sut.ref
            .read(listingViewControllerProvider.notifier)
            .apply(
              LibraryType.audio,
              const ListingView(direction: SortDirection.descending),
            );
        await pumpEventQueue();

        expect(sut.ref.read(listingControllerProvider).value!.first.uuid, '1');
      },
    );

    test(
      'GivenTwoTypes_WhenEachIsGivenAView_ThenNeitherDisturbsTheOther',
      () async {
        final sut = await started();
        final controller = sut.ref.read(listingViewControllerProvider.notifier);

        await controller.apply(
          LibraryType.audio,
          const ListingView(sortField: SortField.indexed),
        );
        await controller.apply(
          LibraryType.image,
          const ListingView(lifecycle: LifecycleFilter.all),
        );

        final state = sut.ref.read(listingViewControllerProvider);
        expect(state.forType(LibraryType.audio).sortField, SortField.indexed);
        expect(state.forType(LibraryType.image).lifecycle, LifecycleFilter.all);
        expect(state.forType(LibraryType.text), ListingView.initial);
      },
    );
  });

  group('remembering it (main flow step 5)', () {
    test('GivenAView_WhenItIsApplied_ThenItIsWritten', () async {
      final settings = InMemorySettingsStore();
      final sut = await started(settings: settings);

      await sut.ref
          .read(listingViewControllerProvider.notifier)
          .apply(
            LibraryType.audio,
            const ListingView(sortField: SortField.indexed),
          );

      expect(
        settings.entries[ListingViewController.settingsKey],
        contains('indexed'),
      );
    });

    test(
      'GivenAStoredView_WhenTheApplicationStarts_ThenItIsRestored',
      () async {
        final sut = await started(
          settings: InMemorySettingsStore(
            values: {
              ListingViewController.settingsKey:
                  '{"audio":{"lifecycle":"all","sortField":"indexed",'
                  '"direction":"descending"}}',
            },
          ),
        );

        final view = sut.ref
            .read(listingViewControllerProvider)
            .forType(LibraryType.audio);
        expect(view.lifecycle, LifecycleFilter.all);
        expect(view.sortField, SortField.indexed);
        expect(view.direction, SortDirection.descending);
      },
    );

    test(
      'GivenAnUnreadableValue_WhenItIsRestored_ThenTheDefaultApplies',
      () async {
        final sut = await started(
          settings: InMemorySettingsStore(
            values: {ListingViewController.settingsKey: 'not json'},
          ),
        );

        expect(
          sut.ref
              .read(listingViewControllerProvider)
              .forType(LibraryType.audio),
          ListingView.initial,
        );
      },
    );
  });

  group('clearing the filters (AF-02)', () {
    test(
      'GivenAFilter_WhenItIsCleared_ThenTheUnfilteredListingReturns',
      () async {
        final sut = await started();
        final controller = sut.ref.read(listingViewControllerProvider.notifier);
        await controller.apply(
          LibraryType.audio,
          const ListingView(lifecycle: LifecycleFilter.deleted),
        );

        await controller.clearFilters(LibraryType.audio);

        expect(
          sut.ref
              .read(listingViewControllerProvider)
              .forType(LibraryType.audio)
              .lifecycle,
          LifecycleFilter.active,
        );
      },
    );

    test(
      'GivenASort_WhenTheFiltersAreCleared_ThenTheSortIsLeftAlone',
      () async {
        // Ordering hides nothing, so clearing the filters is not a reason to
        // un-order the listing.
        final sut = await started();
        final controller = sut.ref.read(listingViewControllerProvider.notifier);
        await controller.apply(
          LibraryType.audio,
          const ListingView(
            lifecycle: LifecycleFilter.deleted,
            sortField: SortField.indexed,
          ),
        );

        await controller.clearFilters(LibraryType.audio);

        expect(
          sut.ref
              .read(listingViewControllerProvider)
              .forType(LibraryType.audio)
              .sortField,
          SortField.indexed,
        );
      },
    );
  });

  group('the core refuses the filter (AF-04)', () {
    test(
      'GivenTheCoreRefuses_WhenAViewIsApplied_ThenThePreviousOneReturns',
      () async {
        // The refusal is on the lifecycle the filter asks for: the active
        // listing works, and it is the change that the core rejects.
        final sut = await started(
          listings: {
            LibraryType.audio: loadedDetails([aFile()]),
          },
          deleted: {
            LibraryType.audio: const CatalogListing.failed(
              failure: Failure.invalidInput(
                family: CoreStatusFamily.file,
                code: 1,
              ),
            ),
          },
        );
        sut.ref
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.music);
        await pumpEventQueue();

        await sut.ref
            .read(listingViewControllerProvider.notifier)
            .apply(
              LibraryType.audio,
              const ListingView(lifecycle: LifecycleFilter.deleted),
            );
        await pumpEventQueue();

        final state = sut.ref.read(listingViewControllerProvider);
        expect(
          state.forType(LibraryType.audio).lifecycle,
          LifecycleFilter.active,
        );
        expect(state.rejection, isA<InvalidInputFailure>());
      },
    );

    test(
      'GivenARejection_WhenTheOwnerAcknowledgesIt_ThenTheNoticeClears',
      () async {
        final sut = await started();
        final controller = sut.ref.read(listingViewControllerProvider.notifier);
        await controller.revert(
          LibraryType.audio,
          const Failure.invalidInput(family: CoreStatusFamily.file, code: 1),
        );

        controller.acknowledgeRejection();

        expect(sut.ref.read(listingViewControllerProvider).rejection, isNull);
      },
    );
  });
}
