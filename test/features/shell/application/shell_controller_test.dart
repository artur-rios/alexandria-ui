import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_library_gateway.dart';

/// Which area of the shell the owner is in (UC-38 main flow step 2).
void main() {
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: '/course');
  const films = Library(uuid: 'lib-2', name: 'Films', rootPath: '/films');

  ProviderContainer container({FakeLibraryGateway? gateway}) {
    final created = ProviderContainer(
      overrides: [
        libraryGatewayProvider.overrideWithValue(
          gateway ?? FakeLibraryGateway(libraries: const [course, films]),
        ),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  /// A shell over [gateway]'s libraries, loaded, showing `lib-1`.
  Future<ProviderContainer> showingCourse(FakeLibraryGateway gateway) async {
    final ref = container(gateway: gateway);
    // Kept alive the way the left menu keeps it alive in the application.
    ref.listen(librariesControllerProvider, (_, _) {});
    await ref.read(librariesControllerProvider.future);
    ref
        .read(shellControllerProvider.notifier)
        .go(const LibraryDestination('lib-1'));

    return ref;
  }

  test('GivenAFreshShell_WhenItIsBuilt_ThenItOpensOnHome', () {
    // UC-14 main flow step 1: the application opens the dashboard.
    expect(container().read(shellControllerProvider), const HomeDestination());
  });

  test('GivenHome_WhenALibraryIsPicked_ThenItIsShown', () {
    final ref = container();

    ref
        .read(shellControllerProvider.notifier)
        .go(const LibraryDestination('lib-1'));

    expect(
      ref.read(shellControllerProvider),
      const LibraryDestination('lib-1'),
    );
  });

  test('GivenADestination_WhenItIsPickedAgain_ThenTheStateIsNotReplaced', () {
    final ref = container();
    var notifications = 0;
    ref.listen(shellControllerProvider, (_, _) => notifications++);

    // Two separate instances: a library destination is the library it names,
    // so picking the same entry twice is one move, not two.
    final uuid = ['lib', '1'].join('-');
    ref.read(shellControllerProvider.notifier).go(LibraryDestination(uuid));
    ref.read(shellControllerProvider.notifier).go(LibraryDestination(uuid));

    expect(notifications, 1);
  });

  test(
    'GivenEveryKindOfDestination_WhenEachIsPicked_ThenEachBecomesCurrent',
    () {
      final ref = container();

      for (final destination in const <ShellDestination>[
        BookmarksDestination(),
        LibraryDestination('lib-2'),
        HomeDestination(),
      ]) {
        ref.read(shellControllerProvider.notifier).go(destination);
        expect(ref.read(shellControllerProvider), destination);
      }
    },
  );

  group('a library that goes away (spec §3)', () {
    test(
      'GivenTheSelectedLibraryIsRemoved_WhenTheListReloads_ThenTheDestinationIsHome',
      () async {
        final gateway = FakeLibraryGateway(libraries: const [course, films]);
        final ref = await showingCourse(gateway);

        gateway.libraries.removeWhere((library) => library.uuid == 'lib-1');
        await ref.read(librariesControllerProvider.notifier).reload();

        expect(ref.read(shellControllerProvider), const HomeDestination());
      },
    );

    test(
      'GivenAnotherLibraryIsRemoved_WhenTheListReloads_ThenTheDestinationStays',
      () async {
        final gateway = FakeLibraryGateway(libraries: const [course, films]);
        final ref = await showingCourse(gateway);

        gateway.libraries.removeWhere((library) => library.uuid == 'lib-2');
        await ref.read(librariesControllerProvider.notifier).reload();

        expect(
          ref.read(shellControllerProvider),
          const LibraryDestination('lib-1'),
        );
      },
    );

    test(
      'GivenTheListFailsToReload_WhenALibraryIsShown_ThenTheDestinationStays',
      () async {
        // A failed read says nothing about which libraries exist: sending the
        // owner home over it would read "we could not ask" as "it is gone".
        final gateway = FakeLibraryGateway(libraries: const [course]);
        final ref = await showingCourse(gateway);

        gateway.browseOutcome = const LibraryBrowse.failed(
          failure: Failure.unexpected(
            family: CoreStatusFamily.library,
            code: 9,
          ),
        );
        await ref.read(librariesControllerProvider.notifier).reload();

        expect(
          ref.read(shellControllerProvider),
          const LibraryDestination('lib-1'),
        );
      },
    );
  });
}
