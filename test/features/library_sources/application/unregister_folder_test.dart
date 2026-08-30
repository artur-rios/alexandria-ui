import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';

/// Unregistering a library folder (UC-08, FR-LB-10).
void main() {
  const music = '/home/owner/music';
  const books = '/home/owner/books';
  final registeredAt = DateTime.utc(2026, 8, 19, 11);

  LibrarySource source(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
  );

  ({
    ProviderContainer ref,
    InMemoryLibrarySourceStore store,
    FakeIndexGateway gateway,
  })
  build({List<LibrarySource>? registered, FakeIndexGateway? gateway}) {
    final store = InMemoryLibrarySourceStore(registered ?? [source(music)]);
    final indexGateway = gateway ?? FakeIndexGateway();

    final container = ProviderContainer(
      overrides: [
        librarySourceStoreProvider.overrideWithValue(store),
        folderPickerProvider.overrideWithValue(FakeFolderPicker(path: music)),
        folderProbeProvider.overrideWithValue(FakeFolderProbe()),
        indexGatewayProvider.overrideWithValue(indexGateway),
        clockProvider.overrideWithValue(() => registeredAt),
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);

    // Turned off before the session is established: this suite has nothing
    // to do with a re-check, and `establish`'s own unawaited call to
    // `begin()` (FR-LB-21) would otherwise start one against a gateway this
    // suite never set up to expect it.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, store: store, gateway: indexGateway);
  }

  group('the main flow', () {
    test('GivenARegisteredFolder_WhenItIsUnregistered_ThenItIsGone', () async {
      final sut = build(registered: [source(music), source(books)]);

      await sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .unregisterFolder(music);

      final sources = sut.ref.read(librarySourcesControllerProvider).sources;
      expect(sources, hasLength(1));
      expect(sources.single.path, books);
    });

    test(
      'GivenAFolderIsUnregistered_WhenItSettles_ThenItIsPersisted',
      () async {
        // FR-LB-03: what survives a restart is what was written.
        final sut = build(registered: [source(music), source(books)]);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(music);

        expect(sut.store.read().single.path, books);
      },
    );

    test('GivenAnUnknownPath_WhenItIsUnregistered_ThenNothingIsLost', () async {
      final sut = build(registered: [source(music)]);

      await sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .unregisterFolder('/somewhere/else');

      expect(
        sut.ref.read(librarySourcesControllerProvider).sources,
        hasLength(1),
      );
    });
  });

  group('the last folder (AF-03)', () {
    test(
      'GivenTheOnlyFolder_WhenItIsUnregistered_ThenGuidanceReturns',
      () async {
        final sut = build(registered: [source(music)]);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(music);

        // An empty list is what puts the first-run guidance back (FR-LB-11), so
        // AF-03 needs nothing of its own.
        expect(sut.ref.read(librarySourcesControllerProvider).isEmpty, isTrue);
      },
    );

    test(
      'GivenTheOnlyFolder_WhenItIsUnregistered_ThenItCanBeAddedAgain',
      () async {
        // The catalog is untouched, and so is the owner's ability to point at
        // the same folder again.
        final sut = build(registered: [source(music)]);
        final controller = sut.ref.read(
          librarySourcesControllerProvider.notifier,
        );
        await controller.unregisterFolder(music);

        await controller.registerFolder(
          onOverlapConfirmed: (_, _) async => true,
          onScopeChosen: (_) async =>
              (types: const <FileType>[], libraryName: null),
        );

        expect(
          sut.ref.read(librarySourcesControllerProvider).sources,
          hasLength(1),
        );
      },
    );
  });

  group('a run is in flight (AF-02)', () {
    test(
      'GivenAFolderBeingScanned_WhenItIsUnregistered_ThenItIsRefused',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(music);

        expect(
          sut.ref.read(librarySourcesControllerProvider).sources,
          hasLength(1),
        );
        expect(
          sut.ref.read(librarySourcesControllerProvider).unregisterRefusedFor,
          music,
        );
      },
    );

    test(
      'GivenAFolderBeingScanned_WhenItIsRefused_ThenNothingIsWritten',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);
        final writesBefore = sut.store.writeCount;

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(music);

        expect(sut.store.writeCount, writesBefore);
      },
    );

    test(
      'GivenAnotherFolderIsScanned_WhenThisOneIsUnregistered_ThenItGoes',
      () async {
        // The refusal is about the folder being scanned, not about any scan.
        final sut = build(
          registered: [source(music), source(books)],
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(books);

        expect(
          sut.ref.read(librarySourcesControllerProvider).sources,
          hasLength(1),
        );
        expect(
          sut.ref.read(librarySourcesControllerProvider).sources.single.path,
          music,
        );
      },
    );

    test(
      'GivenTheRunFinished_WhenTheFolderIsUnregistered_ThenItGoes',
      () async {
        // "Until the run settles" — a finished run is settled.
        final sut = build();
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .unregisterFolder(music);

        expect(sut.ref.read(librarySourcesControllerProvider).isEmpty, isTrue);
      },
    );

    test(
      'GivenARefusal_WhenTheOwnerAcknowledgesIt_ThenTheNoticeClears',
      () async {
        final sut = build(
          gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
        );
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);
        final controller = sut.ref.read(
          librarySourcesControllerProvider.notifier,
        );
        await controller.unregisterFolder(music);

        controller.acknowledgeUnregisterRefusal();

        expect(
          sut.ref.read(librarySourcesControllerProvider).unregisterRefusedFor,
          isNull,
        );
      },
    );
  });
}
