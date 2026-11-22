import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_library_gateway.dart';

/// The registered libraries and what the owner marks on them.
void main() {
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: '/course');
  const refusal = LibraryWrite.failed(
    failure: Failure.notFound(family: CoreStatusFamily.library, code: 4),
  );

  Future<({ProviderContainer container, FakeLibraryGateway gateway})>
  open() async {
    final gateway = FakeLibraryGateway(libraries: const [course]);
    final container = ProviderContainer(
      overrides: [libraryGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    container.listen(librariesControllerProvider, (_, _) {});
    await container.read(librariesControllerProvider.future);

    return (container: container, gateway: gateway);
  }

  test(
    'GivenALibrary_WhenPinned_ThenTheCoreIsCalledAndTheListReloadsPinned',
    () async {
      final sut = await open();

      final failure = await sut.container
          .read(librariesControllerProvider.notifier)
          .setPinned('lib-1', true);

      expect(failure, isNull);
      expect(sut.gateway.pinnedCalls.single, (uuid: 'lib-1', pinned: true));
      expect(
        sut.container
            .read(librariesControllerProvider)
            .requireValue
            .single
            .pinned,
        isTrue,
      );
    },
  );

  test('GivenALibrary_WhenFavorited_ThenTheListReloadsFavorite', () async {
    final sut = await open();

    final failure = await sut.container
        .read(librariesControllerProvider.notifier)
        .setFavorite('lib-1', true);

    expect(failure, isNull);
    expect(sut.gateway.favoriteCalls.single, (uuid: 'lib-1', favorite: true));
    expect(
      sut.container
          .read(librariesControllerProvider)
          .requireValue
          .single
          .favorite,
      isTrue,
    );
  });

  test(
    'GivenTheCoreRefuses_WhenFavorited_ThenTheFailureIsReturnedAndTheListIsUnchanged',
    () async {
      final sut = await open();
      sut.gateway.writeOutcomes.add(refusal);

      final failure = await sut.container
          .read(librariesControllerProvider.notifier)
          .setFavorite('lib-1', true);

      expect(failure, isA<NotFoundFailure>());
      expect(
        sut.container.read(librariesControllerProvider).requireValue,
        const [course],
      );
    },
  );

  test('GivenTheCoreRefuses_WhenPinned_ThenTheListIsUnchanged', () async {
    final sut = await open();
    sut.gateway.writeOutcomes.add(refusal);

    final failure = await sut.container
        .read(librariesControllerProvider.notifier)
        .setPinned('lib-1', true);

    expect(failure, isA<NotFoundFailure>());
    expect(sut.container.read(librariesControllerProvider).requireValue, const [
      course,
    ]);
  });

  test('GivenALibrary_WhenRenamed_ThenTheListReloadsWithTheNewName', () async {
    final sut = await open();

    final failure = await sut.container
        .read(librariesControllerProvider.notifier)
        .rename('lib-1', 'Rust course');

    expect(failure, isNull);
    expect(sut.gateway.renamedCalls.single, (
      uuid: 'lib-1',
      name: 'Rust course',
    ));
    expect(
      sut.container.read(librariesControllerProvider).requireValue.single.name,
      'Rust course',
    );
  });

  test('GivenTheCoreRefuses_WhenRenamed_ThenTheFailureIsReturned', () async {
    final sut = await open();
    sut.gateway.writeOutcomes.add(refusal);

    final failure = await sut.container
        .read(librariesControllerProvider.notifier)
        .rename('lib-1', 'X');

    expect(failure, isA<NotFoundFailure>());
    expect(
      sut.container.read(librariesControllerProvider).requireValue.single.name,
      'Course',
    );
  });
}
