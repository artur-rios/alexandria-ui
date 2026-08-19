import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_desktop/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_library_sources.dart';

/// Registering a folder on disk (UC-05, FR-LB-01 … FR-LB-04).
void main() {
  final registeredAt = DateTime.utc(2026, 8, 19, 10, 30);

  LibrarySource source(String path) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: registeredAt,
  );

  ({
    ProviderContainer ref,
    FakeFolderPicker picker,
    FakeFolderProbe probe,
    InMemoryLibrarySourceStore store,
  })
  build({
    String? picked = '/home/owner/music',
    bool exists = true,
    bool readable = true,
    List<LibrarySource>? registered,
  }) {
    final picker = FakeFolderPicker(path: picked);
    final probe = FakeFolderProbe(existing: exists, readable: readable);
    final store = InMemoryLibrarySourceStore(registered);

    final container = ProviderContainer(
      overrides: [
        folderPickerProvider.overrideWithValue(picker),
        folderProbeProvider.overrideWithValue(probe),
        librarySourceStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => registeredAt),
      ],
    );
    addTearDown(container.dispose);

    return (ref: container, picker: picker, probe: probe, store: store);
  }

  /// Registers, accepting any overlap warning.
  Future<void> register(ProviderContainer ref, {bool confirmOverlap = true}) =>
      ref
          .read(librarySourcesControllerProvider.notifier)
          .registerFolder(onOverlapConfirmed: (_, _) async => confirmOverlap);

  group('the main flow', () {
    test('GivenNothingRegistered_WhenTheScreenOpens_ThenItIsEmpty', () {
      final sut = build();

      expect(sut.ref.read(librarySourcesControllerProvider).isEmpty, isTrue);
    });

    test('GivenStoredFolders_WhenTheScreenOpens_ThenTheyAreRestored', () {
      // FR-LB-03: they survive a restart.
      final sut = build(registered: [source('/home/owner/books')]);

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.sources, hasLength(1));
      expect(state.sources.single.path, '/home/owner/books');
    });

    test('GivenAFolderIsChosen_WhenItIsRegistered_ThenItIsListed', () async {
      final sut = build();

      await register(sut.ref);

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.sources, hasLength(1));
      expect(state.sources.single.path, '/home/owner/music');
    });

    test('GivenAFolderIsChosen_WhenItIsRegistered_ThenItsNameIsTheLabel',
        () async {
      final sut = build();

      await register(sut.ref);

      expect(
        sut.ref.read(librarySourcesControllerProvider).sources.single.label,
        'music',
      );
    });

    test('GivenAFolderIsChosen_WhenItIsRegistered_ThenItIsPersisted', () async {
      final sut = build();

      await register(sut.ref);

      expect(sut.store.writeCount, 1);
      expect(sut.store.read().single.path, '/home/owner/music');
    });

    test('GivenSeveralFolders_WhenEachIsRegistered_ThenAllAreKept', () async {
      // FR-LB-04: any number of folders.
      final sut = build(registered: [source('/home/owner/books')]);
      sut.picker.path = '/home/owner/music';

      await register(sut.ref);

      expect(sut.ref.read(librarySourcesControllerProvider).sources, hasLength(2));
    });
  });

  group('the owner cancels the picker (AF-01)', () {
    test('GivenTheOwnerCancels_WhenTheyAdd_ThenNothingIsRegistered', () async {
      final sut = build(picked: null);

      await register(sut.ref);

      expect(sut.ref.read(librarySourcesControllerProvider).isEmpty, isTrue);
      expect(sut.store.writeCount, 0);
    });

    test('GivenTheOwnerCancels_WhenTheyAdd_ThenTheFolderIsNeverProbed',
        () async {
      final sut = build(picked: null);

      await register(sut.ref);

      expect(sut.probe.readabilityChecks, isEmpty);
    });

    test('GivenANoticeIsShowing_WhenTheOwnerCancels_ThenItIsLeftAlone',
        () async {
      // The notice was about a different attempt, and cancelling this one does
      // not answer it.
      final sut = build(exists: false);
      await register(sut.ref);
      sut.picker.path = null;

      await register(sut.ref);

      expect(
        sut.ref.read(librarySourcesControllerProvider).refusal,
        FolderRegistrationVerdict.missing,
      );
    });
  });

  group('the folder is refused (AF-02, AF-03)', () {
    test('GivenAMissingFolder_WhenItIsChosen_ThenItIsRefusedAsMissing',
        () async {
      final sut = build(exists: false);

      await register(sut.ref);

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.refusal, FolderRegistrationVerdict.missing);
      expect(state.refusedPath, '/home/owner/music');
      expect(sut.store.writeCount, 0);
    });

    test('GivenAMissingFolder_WhenItIsChosen_ThenReadabilityIsNotAsked',
        () async {
      // Reporting "cannot be read" about a folder that is not there sends the
      // owner after the wrong problem (FR-LB-02).
      final sut = build(exists: false);

      await register(sut.ref);

      expect(sut.probe.readabilityChecks, isEmpty);
    });

    test('GivenAnUnreadableFolder_WhenItIsChosen_ThenItIsRefusedAsUnreadable',
        () async {
      final sut = build(readable: false);

      await register(sut.ref);

      expect(
        sut.ref.read(librarySourcesControllerProvider).refusal,
        FolderRegistrationVerdict.unreadable,
      );
      expect(sut.store.writeCount, 0);
    });

    test('GivenAnAlreadyRegisteredFolder_WhenItIsChosen_ThenItIsRefused',
        () async {
      final sut = build(registered: [source('/home/owner/music')]);

      await register(sut.ref);

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.refusal, FolderRegistrationVerdict.alreadyRegistered);
      expect(state.sources, hasLength(1));
      expect(sut.store.writeCount, 0);
    });

    test('GivenADuplicate_WhenItIsRefused_ThenTheExistingEntryIsNamed',
        () async {
      // AF-03 highlights the existing entry, which needs the entry itself.
      final sut = build(registered: [source('/home/owner/music')]);

      await register(sut.ref);

      expect(
        sut.ref
            .read(librarySourcesControllerProvider)
            .conflictingSource
            ?.path,
        '/home/owner/music',
      );
    });

    test('GivenARefusal_WhenTheOwnerAcknowledgesIt_ThenTheNoticeClears',
        () async {
      final sut = build(exists: false);
      await register(sut.ref);

      sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .acknowledgeRefusal();

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.refusal, isNull);
      expect(state.refusedPath, isNull);
      expect(state.conflictingSource, isNull);
    });
  });

  group('the folders overlap (AF-04)', () {
    test('GivenAnOverlap_WhenTheOwnerConfirms_ThenItIsRegistered', () async {
      final sut = build(registered: [source('/home/owner')]);

      await register(sut.ref, confirmOverlap: true);

      expect(sut.ref.read(librarySourcesControllerProvider).sources, hasLength(2));
      expect(sut.store.writeCount, 1);
    });

    test('GivenAnOverlap_WhenTheOwnerCancels_ThenNothingIsRegistered',
        () async {
      final sut = build(registered: [source('/home/owner')]);

      await register(sut.ref, confirmOverlap: false);

      expect(sut.ref.read(librarySourcesControllerProvider).sources, hasLength(1));
      expect(sut.store.writeCount, 0);
    });

    test('GivenAnOverlap_WhenTheOwnerCancels_ThenNoRefusalIsRecorded',
        () async {
      // Being asked and saying no is not an error.
      final sut = build(registered: [source('/home/owner')]);

      await register(sut.ref, confirmOverlap: false);

      final state = sut.ref.read(librarySourcesControllerProvider);
      expect(state.refusal, isNull);
      expect(state.registering, isFalse);
    });

    test('GivenNoOverlap_WhenAFolderIsRegistered_ThenNothingIsAsked', () async {
      var asked = false;
      final sut = build(registered: [source('/home/owner/books')]);

      await sut.ref
          .read(librarySourcesControllerProvider.notifier)
          .registerFolder(
            onOverlapConfirmed: (_, _) async {
              asked = true;
              return true;
            },
          );

      expect(asked, isFalse);
      expect(sut.ref.read(librarySourcesControllerProvider).sources, hasLength(2));
    });
  });

  test('GivenARegistrationInFlight_WhenAnotherStarts_ThenOnlyOneRuns',
      () async {
    final sut = build();
    final controller = sut.ref.read(
      librarySourcesControllerProvider.notifier,
    );

    final first = controller.registerFolder(
      onOverlapConfirmed: (_, _) async => true,
    );
    await controller.registerFolder(onOverlapConfirmed: (_, _) async => true);
    await first;

    expect(sut.ref.read(librarySourcesControllerProvider).sources, hasLength(1));
  });
}
