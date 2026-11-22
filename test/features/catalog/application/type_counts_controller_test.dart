import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Every type's item count, for the dashboard (FR-CT-01).
void main() {
  ({ProviderContainer ref, FakeCatalogGateway gateway}) build({
    Map<FileType, CatalogListing>? listings,
  }) {
    final gateway = FakeCatalogGateway(listings: listings);

    final container = ProviderContainer(
      overrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    // Providers are auto-disposed without a listener, and counts read only
    // through their future would be torn down while still loading. The
    // dashboard holds them open; a test has to say so.
    container.listen(typeCountsControllerProvider, (_, _) {});

    return (ref: container, gateway: gateway);
  }

  group('the panel counts (FR-CT-01)', () {
    test(
      'GivenEveryType_WhenTheCountsLoad_ThenOneListingAnswersThemAll',
      () async {
        // One call with no type filter, not one call per type. Asking per
        // type serialized the whole catalog out of the core once for every
        // type in the panel, and again after every scan, purge and restore.
        final sut = build();

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(sut.gateway.requested, [null]);
        expect(counts.length, FileType.values.length);
      },
    );

    test(
      'GivenATypeWithFiles_WhenTheCountsLoad_ThenItsCountIsItsLength',
      () async {
        final sut = build(
          listings: {
            FileType.text: loadedDetails([
              aFile(),
              aFile(uuid: 'b', name: 'b.md'),
            ]),
          },
        );

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(counts[FileType.text], 2);
      },
    );

    test(
      'GivenTheCountsCannotBeRead_WhenTheyLoad_ThenItFailsRatherThanReadsZero',
      () async {
        // A zero would read as "nothing here" about a query that never
        // answered, and an empty map is that lie told for every type at once.
        // The failure state is what puts the retry on screen.
        final sut = build(
          listings: {
            FileType.text: const CatalogListing.failed(
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
          listings: {
            FileType.text: loadedDetails([
              aFile(),
              aFile(uuid: 'b', name: 'b.md'),
            ]),
            FileType.image: loadedDetails([
              aFile(uuid: 'c', name: 'c.png', type: FileType.image),
            ]),
          },
        );

        final counts = await sut.ref.read(typeCountsControllerProvider.future);

        expect(counts[FileType.text], 2);
        expect(counts[FileType.image], 1);
        expect(counts[FileType.video], 0);
      },
    );
  });
}
