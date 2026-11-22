import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/domain/catalog_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_library_gateway.dart';

/// The totals home shows: how many libraries, and how many files of each type.
void main() {
  ProviderContainer build(FakeLibraryGateway gateway) {
    final container = ProviderContainer(
      overrides: [libraryGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    container.listen(catalogStatsProvider, (_, _) {});

    return container;
  }

  test('GivenStats_WhenLoaded_ThenLibrariesAndEveryTypeArePresent', () async {
    final gateway = FakeLibraryGateway()
      ..statsOutcome = CatalogStats(
        libraries: 2,
        filesByType: {for (final type in FileType.values) type: type.index + 1},
      );
    final container = build(gateway);

    final stats = await container.read(catalogStatsProvider.future);

    expect(stats.libraries, 2);
    expect(stats.filesByType.keys, unorderedEquals(FileType.values));
    expect(stats.filesByType[FileType.image], FileType.image.index + 1);
  });

  test(
    'GivenAFailure_WhenLoaded_ThenTheStateIsAnErrorAndReloadRetries',
    () async {
      const failure = Failure.notInitialized(
        family: CoreStatusFamily.library,
        code: 3,
      );
      final gateway = FakeLibraryGateway()..statsFailure = failure;
      final container = build(gateway);

      await pumpEventQueue();

      final failed = container.read(catalogStatsProvider);
      expect(failed.hasError, isTrue);
      expect(failed.error, isA<NotInitializedFailure>());

      gateway.statsFailure = null;
      await container.read(catalogStatsProvider.notifier).reload();

      expect(container.read(catalogStatsProvider).hasValue, isTrue);
    },
  );
}
