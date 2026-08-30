import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_library_sources.dart';

/// Marking a source folder as a library (libraries design, UC-24).
///
/// The mark is a property of the folder the owner registered, not a second
/// registration of its own: it is answered where the scope is answered, and
/// what the core is told has to agree with what the row says afterwards.
void main() {
  const course = '/home/owner/courses/rust';
  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  ({
    ProviderContainer ref,
    FakeLibraryGateway libraries,
    InMemoryLibrarySourceStore store,
  })
  build({List<LibrarySource>? registered, String? picked = course}) {
    final store = InMemoryLibrarySourceStore(registered);
    final libraries = FakeLibraryGateway();

    final container = ProviderContainer(
      overrides: [
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: picked)),
        folderProbeProvider.overrideWithValue(FakeFolderProbe()),
        librarySourceStoreProvider.overrideWithValue(store),
        libraryGatewayProvider.overrideWithValue(libraries),
        clockProvider.overrideWithValue(() => registeredAt),
      ],
    );
    addTearDown(container.dispose);

    // A credential, because every core call needs one and a controller with
    // no session answers without asking the gateway at all (FR-AU-07) —
    // which would make every assertion below pass for the wrong reason.
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, libraries: libraries, store: store);
  }

  Future<LibrarySource?> register(
    ProviderContainer ref, {
    String? libraryName,
  }) => ref
      .read(librarySourcesControllerProvider.notifier)
      .registerFolder(
        onOverlapConfirmed: (_, _) async => true,
        onScopeChosen: (_) async =>
            (types: const <FileType>[], libraryName: libraryName),
      );

  group('marking while registering', () {
    test(
      'GivenTheOwnerNamesALibrary_WhenTheFolderIsRegistered_ThenTheCoreIsTold',
      () async {
        final sut = build();

        await register(sut.ref, libraryName: 'Rust course');

        expect(sut.libraries.registered, [
          (name: 'Rust course', rootPath: course),
        ]);
      },
    );

    test(
      'GivenTheOwnerNamesALibrary_WhenTheFolderIsRegistered_ThenTheSourceHoldsTheName',
      () async {
        final sut = build();

        final source = await register(sut.ref, libraryName: 'Rust course');

        expect(source?.libraryName, 'Rust course');
        expect(source?.isLibrary, isTrue);
        expect(sut.store.read().single.libraryName, 'Rust course');
      },
    );

    test(
      'GivenTheOwnerNamesNoLibrary_WhenTheFolderIsRegistered_ThenTheCoreIsNotTold',
      () async {
        // The half that makes the test above mean something: a controller
        // that marked every folder would pass it.
        final sut = build();

        final source = await register(sut.ref);

        expect(sut.libraries.registered, isEmpty);
        expect(source?.isLibrary, isFalse);
      },
    );

    test(
      'GivenTheCoreRefusesTheLibrary_WhenTheFolderIsRegistered_ThenItIsRegisteredUnmarked',
      () async {
        // The folder overlaps a library the core already has. Registering is
        // still worth doing — the folder is indexable — but the row must not
        // claim a grouping the core does not hold, because the files it
        // promises to keep out of the type panels are still in them.
        final sut = build();
        sut.libraries.writeOutcomes.add(
          const LibraryWrite.failed(
            failure: Failure.conflict(
              family: CoreStatusFamily.library,
              code: 6,
            ),
          ),
        );

        final source = await register(sut.ref, libraryName: 'Rust course');

        expect(source, isNotNull, reason: 'the folder is still a source');
        expect(source?.libraryName, isNull);
        expect(sut.store.read().single.libraryName, isNull);
      },
    );
  });

  group('marking a folder already registered', () {
    test(
      'GivenARegisteredFolder_WhenItIsMarked_ThenTheCoreIsToldAndTheRowSaysSo',
      () async {
        // The way in for a folder registered before the question existed:
        // re-registering it to answer would mean un-registering it first.
        final sut = build(
          registered: [
            LibrarySource(
              path: course,
              label: defaultLabelFor(course),
              registeredAt: registeredAt,
            ),
          ],
        );

        final failure = await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .markAsLibrary(path: course, name: 'Rust course');

        expect(failure, isNull);
        expect(sut.libraries.registered, [
          (name: 'Rust course', rootPath: course),
        ]);
        expect(sut.store.read().single.libraryName, 'Rust course');
      },
    );

    test(
      'GivenTheCoreRefuses_WhenAFolderIsMarked_ThenNothingIsStoredAndTheRefusalIsAnswered',
      () async {
        final sut = build(
          registered: [
            LibrarySource(
              path: course,
              label: defaultLabelFor(course),
              registeredAt: registeredAt,
            ),
          ],
        );
        sut.libraries.writeOutcomes.add(
          const LibraryWrite.failed(
            failure: Failure.conflict(
              family: CoreStatusFamily.library,
              code: 6,
            ),
          ),
        );

        final failure = await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .markAsLibrary(path: course, name: 'Rust course');

        expect(failure, isA<ConflictFailure>());
        expect(sut.store.read().single.libraryName, isNull);
        expect(
          sut.store.writeCount,
          isZero,
          reason: 'a refused mark must not touch the stored set at all',
        );
      },
    );
  });

  test(
    'GivenAMarkedFolder_WhenTheLibraryIsRemoved_ThenTheRowStopsClaimingIt',
    () async {
      // Removal happens where the library is listed, because a library can
      // outlive its source folder. This is the folder's own record catching
      // up, and without it the row badges a library that is gone.
      final sut = build(
        registered: [
          LibrarySource(
            path: course,
            label: defaultLabelFor(course),
            registeredAt: registeredAt,
            libraryName: 'Rust course',
          ),
        ],
      );

      await sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .clearLibraryMark(course);

      expect(sut.store.read().single.isLibrary, isFalse);
      expect(
        sut.ref.read(librarySourcesControllerProvider).sources.single.isLibrary,
        isFalse,
      );
    },
  );

  test(
    'GivenAPathThatIsNotRegistered_WhenTheMarkIsCleared_ThenNothingIsWritten',
    () async {
      // The orphan case: the library outlived the folder's registration, and
      // removing it must not rewrite a set that does not mention it.
      final sut = build(registered: const []);

      await sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .clearLibraryMark(course);

      expect(sut.store.writeCount, isZero);
    },
  );

  test('GivenALibraryIsRegistered_WhenItIsBrowsed_ThenItIsListed', () async {
    // The end of the path this feature exists for: what the owner marked is
    // what the Libraries screen offers to open.
    final sut = build();

    await register(sut.ref, libraryName: 'Rust course');
    final libraries = await sut.ref.read(librariesControllerProvider.future);

    expect(libraries.map((library) => library.name), ['Rust course']);
    expect(libraries.single.rootPath, course);
  });
}
