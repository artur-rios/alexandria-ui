import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_core_client.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// Taking audio out of the stored tracked folders at sign-in, once audio is
/// no longer a type (remove-music design, "Stored index scopes").
///
/// At sign-in rather than at startup: removing a music-only folder's library
/// needs a credential, and the folder and its library go together.
void main() {
  final registeredAt = DateTime.utc(2026, 10, 21);

  final music = LibrarySource(
    path: '/music',
    label: 'music',
    registeredAt: registeredAt,
    scope: const ['audio'],
    libraryName: 'Music',
  );
  final mix = LibrarySource(
    path: '/mix',
    label: 'mix',
    registeredAt: registeredAt,
    scope: const ['audio', 'video'],
  );

  // The core's library list, naming the one made of the music folder.
  const musicLibrary =
      '[{"uuid":"music-library","name":"Music","rootPath":"/music"}]';

  /// Runs startup over [store] and [core], with nobody signed in yet, and the
  /// libraries answered by [gateway] instead of [core] when one is given.
  Future<ProviderContainer> started(
    InMemoryLibrarySourceStore store,
    FakeCoreClient core, {
    LibraryGateway? gateway,
  }) async {
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(
          core: core,
          // Off, so signing in starts no re-check this suite would have to
          // answer for.
          settings: InMemorySettingsStore(rechecksAtStartup: false),
        ),
        librarySourceStoreProvider.overrideWithValue(store),
        if (gateway != null) libraryGatewayProvider.overrideWithValue(gateway),
      ],
    );
    await container.read(startupControllerProvider.notifier).start();
    return container;
  }

  Future<void> signIn(ProviderContainer container) async {
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);
    await pumpEventQueue();
  }

  test(
    'GivenAStoredMusicOnlyFolder_WhenTheOwnerSignsIn_ThenItIsUnregisteredAndTheMixedOneLosesAudio',
    () async {
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_OK, json: musicLibrary);
      final container = await started(store, core);

      expect(
        store.writeCount,
        0,
        reason: 'startup has no credential, so the folders wait for sign-in',
      );

      await signIn(container);

      expect(store.read().map((source) => source.path), ['/mix']);
      expect(store.read().single.scope, ['video']);
      expect(core.libraryRemoveCalls.map((call) => call.uuid), [
        'music-library',
      ]);
      expect(store.writeCount, 1);
    },
  );

  test(
    'GivenALibraryRemovalFails_WhenTheOwnerSignsIn_ThenTheFolderIsKeptForTheNextSignIn',
    () async {
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_OK, json: musicLibrary)
        ..libraryRemoveResponse = (status: LIBRARY_ERR_OTHER, json: null);
      final container = await started(store, core);

      await signIn(container);

      expect(core.libraryRemoveCalls, hasLength(1));
      expect(
        store.read(),
        [
          music,
          mix.copyWith(scope: const ['video']),
        ],
        reason:
            'a folder whose library is still in the core stays as it was, '
            'where it was, so the next sign-in can retry it',
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionActive>(),
        reason: 'a cleanup that failed must not cost the owner the session',
      );

      // The next sign-in, with the core willing this time.
      core.libraryRemoveResponse = null;
      await signIn(container);

      expect(core.libraryRemoveCalls, hasLength(2));
      expect(store.read().map((source) => source.path), ['/mix']);
    },
  );

  test(
    'GivenTheLibrariesCannotBeListed_WhenTheOwnerSignsIn_ThenTheLibraryFolderIsKept',
    () async {
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_ERR_OTHER, json: null);
      final container = await started(store, core);

      await signIn(container);

      expect(core.libraryRemoveCalls, isEmpty);
      expect(store.read(), [
        music,
        mix.copyWith(scope: const ['video']),
      ]);
    },
  );

  test(
    'GivenAMusicOnlyFolderThatIsNoLibrary_WhenTheOwnerSignsIn_ThenItIsDroppedWithoutAskingTheCore',
    () async {
      final store = InMemoryLibrarySourceStore([
        music.copyWith(libraryName: null),
        mix,
      ]);
      final core = FakeCoreClient();
      final container = await started(store, core);

      await signIn(container);

      expect(store.read().map((source) => source.path), ['/mix']);
      expect(core.libraryRemoveCalls, isEmpty);
    },
  );

  test(
    'GivenALibraryAlreadyGoneFromTheCore_WhenTheOwnerSignsIn_ThenItsFolderIsDropped',
    () async {
      // Nothing is left to retry, so keeping the folder would keep it for
      // ever.
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient();
      final container = await started(store, core);

      await signIn(container);

      expect(core.libraryRemoveCalls, isEmpty);
      expect(store.read().map((source) => source.path), ['/mix']);
    },
  );

  test(
    'GivenCleanedData_WhenTheOwnerSignsInAgain_ThenNothingIsWritten',
    () async {
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_OK, json: musicLibrary);
      final container = await started(store, core);
      await signIn(container);
      expect(store.writeCount, 1);

      await signIn(container);

      expect(store.writeCount, 1);
      expect(core.libraryRemoveCalls, hasLength(1));
    },
  );

  test('GivenACleanStore_WhenTheOwnerSignsIn_ThenNothingIsWritten', () async {
    final store = InMemoryLibrarySourceStore([
      LibrarySource(
        path: '/films',
        label: 'films',
        registeredAt: registeredAt,
        scope: const ['video'],
      ),
    ]);
    final core = FakeCoreClient();
    final container = await started(store, core);

    await signIn(container);

    expect(store.writeCount, 0);
    expect(core.libraryRemoveCalls, isEmpty);
  });

  test(
    'GivenTheFoldersScreenWasBuiltEarlier_WhenTheOwnerSignsIn_ThenItShowsTheCleanedFolders',
    () async {
      // A folders controller built before the cleanup would otherwise keep
      // the old list, and its next write would put the music folder back.
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_OK, json: musicLibrary);
      final container = await started(store, core);
      expect(container.read(librarySourcesControllerProvider).sources, [
        music,
        mix,
      ]);

      await signIn(container);

      expect(
        container
            .read(librarySourcesControllerProvider)
            .sources
            .map((source) => source.path),
        ['/mix'],
      );
    },
  );

  test(
    'GivenTheLibrariesCallIsUnauthorized_WhenTheOwnerSignsIn_ThenTheSessionEndsAndTheFolderIsKept',
    () async {
      final store = InMemoryLibrarySourceStore([music, mix]);
      final core = FakeCoreClient()
        ..libraryResponse = (status: LIBRARY_ERR_UNAUTHORIZED, json: null);
      final container = await started(store, core);

      await signIn(container);

      expect(
        container.read(sessionControllerProvider),
        isNot(isA<SessionActive>()),
        reason:
            'a rejected credential returns the owner to login, as the '
            'Libraries screen does',
      );
      expect(core.libraryRemoveCalls, isEmpty);
      expect(store.read(), [
        music,
        mix.copyWith(scope: const ['video']),
      ]);
    },
  );

  test(
    'GivenTheFoldersChangeWhileTheCoreIsAsked_WhenTheOwnerSignsIn_ThenThoseChangesSurvive',
    () async {
      // The cleanup awaits the core between reading the folders and writing
      // them back. A run outcome recorded, or a folder registered, in that
      // window must not be overwritten by the folders as first read.
      final films = LibrarySource(
        path: '/films',
        label: 'films',
        registeredAt: registeredAt,
        scope: const ['video'],
      );
      final store = InMemoryLibrarySourceStore([music, mix]);
      final gateway = _WritingDuringBrowse(
        libraries: const [
          Library(uuid: 'music-library', name: 'Music', rootPath: '/music'),
        ],
        during: () => store.write([
          music,
          mix.copyWith(lastRunOutcome: 'complete'),
          films,
        ]),
      );
      final container = await started(
        store,
        FakeCoreClient(),
        gateway: gateway,
      );

      await signIn(container);

      expect(gateway.removed, ['music-library']);
      expect(store.read(), [
        mix.copyWith(scope: const ['video'], lastRunOutcome: 'complete'),
        films,
      ]);
    },
  );
}

/// A gateway that changes the stored folders while a browse is in flight,
/// the way another write landing during the cleanup's core calls would.
class _WritingDuringBrowse extends FakeLibraryGateway {
  _WritingDuringBrowse({super.libraries, required this.during});

  final Future<void> Function() during;

  @override
  Future<LibraryBrowse> browse({required String credential}) async {
    await during();
    return super.browse(credential: credential);
  }
}
