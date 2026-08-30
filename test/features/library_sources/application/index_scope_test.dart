import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/library_sources/application/index_runs_state.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';

/// Choosing what a folder is for, and indexing it accordingly (UC-05, UC-06).
///
/// The scope belongs to the folder rather than to the run: it is answered once,
/// when the folder is registered, and every later index of that folder uses the
/// same answer.
void main() {
  const music = '/home/owner/music';
  final now = DateTime.utc(2026, 8, 27, 9);

  ({
    ProviderContainer ref,
    FakeIndexGateway gateway,
    InMemoryLibrarySourceStore store,
    FakeFolderPicker picker,
  })
  build({
    String? picked = music,
    bool exists = true,
    bool readable = true,
    InMemoryLibrarySourceStore? store,
    FakeIndexGateway? gateway,
  }) {
    final picker = FakeFolderPicker(path: picked);
    final sources = store ?? InMemoryLibrarySourceStore();
    final indexGateway = gateway ?? FakeIndexGateway();

    final container = ProviderContainer(
      overrides: [
        folderPickerProvider.overrideWithValue(picker),
        folderProbeProvider.overrideWithValue(
          FakeFolderProbe(existing: exists, readable: readable),
        ),
        librarySourceStoreProvider.overrideWithValue(sources),
        indexGatewayProvider.overrideWithValue(indexGateway),
        clockProvider.overrideWithValue(() => now),
        // Long enough that no timer fires during a test: nothing here waits
        // on a poll.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);

    // Off before the session is established, so FR-LB-21's own re-check does
    // not start a run of its own and race the one each test drives.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (
      ref: container,
      gateway: indexGateway,
      store: sources,
      picker: picker,
    );
  }

  /// Registers the picked folder, accepting any overlap and answering the
  /// scope question with [scope]. `null` is the owner cancelling it.
  Future<LibrarySource?> register(
    ProviderContainer ref, {
    List<FileType>? scope = const [],
  }) => ref
      .read(librarySourcesControllerProvider.notifier)
      .registerFolder(
        onOverlapConfirmed: (_, _) async => true,
        onScopeChosen: (_) async => scope,
      );

  group('the scope reaches the run', () {
    test(
      'GivenTheDefaultScope_WhenTheFolderIsIndexed_ThenEveryTypeIsRecorded',
      () async {
        final sut = build();

        await register(sut.ref);
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        // Empty is not "nothing": it is the absent scope the core reads as
        // every type, which is the same meaning on both sides of the
        // boundary.
        expect(sut.gateway.starts.single.types, isEmpty);
      },
    );

    test(
      'GivenAFolderScopedToMusic_WhenItIsIndexed_ThenTheCoverArtIsNotCataloged',
      () async {
        // The owner's actual symptom, as far as a fake can carry it: the
        // gateway computes what it catalogues from the `types` it was handed,
        // so the cover art being absent pins that a scope reached the gateway
        // and nothing more. It fails if the scope stops being passed; it
        // cannot fail for anything the *core* does with the argument, because
        // no core runs here.
        //
        // integration_test/catalog/index_scope_test.dart is where that half
        // is pinned: it runs a scoped index against the real core and asserts
        // the excluded type is absent from the catalog afterwards.
        final gateway = _ScanningGateway();
        final sut = build(gateway: gateway);

        await register(sut.ref, scope: const [FileType.audio]);
        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(gateway.cataloged, contains('Kind of Blue.flac'));
        expect(
          gateway.cataloged,
          isNot(contains('cover.jpg')),
          reason:
              'a folder scoped to music must not put its cover art in the '
              'image library',
        );
      },
    );

    test(
      'GivenAScopeChosenOnce_WhenTheFolderIsIndexedAfterARestart_ThenTheSameScopeIsUsed',
      () async {
        // The store is what survives the restart, so the second container
        // reads back exactly what the first one wrote — no second question,
        // and no argument carried between the two.
        final store = InMemoryLibrarySourceStore();
        final first = build(store: store);
        await register(first.ref, scope: const [FileType.document]);

        final second = build(store: store);
        await second.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(second.gateway.starts.single.types, [FileType.document]);
      },
    );

    test(
      'GivenASourceStoredBeforeScopesExisted_WhenItIsIndexed_ThenEveryTypeIsRecorded',
      () async {
        // Read the way the settings store reads it: a record written before
        // the scope existed carries no such key at all, and must keep
        // behaving exactly as it did rather than needing a migration.
        final stored = LibrarySource.fromJson({
          'path': music,
          'label': 'music',
          'registeredAt': now.toIso8601String(),
        });
        final sut = build(store: InMemoryLibrarySourceStore([stored]));

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(stored.scope, isEmpty);
        expect(sut.gateway.starts.single.types, isEmpty);
      },
    );
  });

  group('a scope this version cannot read is refused, never widened', () {
    /// A source stored with [names] as its scope, however unlikely.
    LibrarySource stored(List<String> names) => LibrarySource(
      path: music,
      label: 'music',
      registeredAt: now,
      scope: names,
    );

    test(
      'GivenAScopeOfUnknownNames_WhenTheFolderIsIndexed_ThenNothingIsIndexed',
      () async {
        // A name from a newer core, or a type renamed on this side — which is
        // the reason wire names are what get stored. Dropping it leaves no
        // types, and no types is how "every type" is spelled: without this
        // refusal the folder the owner narrowed to podcasts would index its
        // images, its videos and everything else.
        final sut = build(
          store: InMemoryLibrarySourceStore([
            stored(['podcast']),
          ]),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(
          sut.gateway.starts,
          isEmpty,
          reason: 'an unreadable scope must never reach the core as no scope',
        );
      },
    );

    test(
      'GivenAScopeOfUnknownNames_WhenTheFolderIsIndexed_ThenTheOwnerIsTold',
      () async {
        // Refused visibly, not quietly: a folder that silently never scans is
        // its own defect.
        final sut = build(
          store: InMemoryLibrarySourceStore([
            stored(['podcast']),
          ]),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(
          sut.ref.read(indexRunsControllerProvider).startRefusalFor(music),
          IndexStartRefusal.unreadableScope,
        );
      },
    );

    test(
      'GivenAScopeWithOneKnownName_WhenTheFolderIsIndexed_ThenItRunsNarrowed',
      () async {
        // Dropping an unknown name is still right when something known
        // remains: the run narrows to what is understood, which cannot widen
        // anything.
        final sut = build(
          store: InMemoryLibrarySourceStore([
            stored(['podcast', 'audio']),
          ]),
        );

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex(music);

        expect(sut.gateway.starts.single.types, [FileType.audio]);
      },
    );

    test(
      'GivenNoRegisteredFolder_WhenAnIndexIsStartedForThatPath_ThenNothingIsIndexed',
      () async {
        // An unregistered path has no scope to read, and reading that absence
        // as "every type" would let a stale row start the widest possible
        // scan.
        final sut = build(store: InMemoryLibrarySourceStore());

        await sut.ref
            .read(indexRunsControllerProvider.notifier)
            .startIndex('/home/owner/somewhere-else');

        expect(sut.gateway.starts, isEmpty);
        expect(
          sut.ref
              .read(indexRunsControllerProvider)
              .startRefusalFor('/home/owner/somewhere-else'),
          IndexStartRefusal.notRegistered,
        );
      },
    );
  });

  group('the store holds one spelling of "everything"', () {
    test(
      'GivenEverySingleTypeIsChosen_WhenTheFolderIsRegistered_ThenNoScopeIsStored',
      () async {
        // The dialog collapses this before it ever gets here, but the
        // guarantee is the controller's: a stored scope is either absent or a
        // real narrowing, whoever calls it.
        final sut = build();

        await register(sut.ref, scope: FileType.values);

        expect(sut.store.read().single.scope, isEmpty);
      },
    );
  });

  group('the owner cancels the scope question', () {
    test(
      'GivenTheScopeIsCancelled_WhenAFolderIsAdded_ThenNothingIsRegistered',
      () async {
        // A folder registered with a scope nobody chose is not what was asked
        // for, so cancelling abandons the registration entirely.
        final sut = build();

        final registered = await register(sut.ref, scope: null);

        expect(registered, isNull);
        expect(sut.store.writeCount, 0);
        expect(sut.ref.read(librarySourcesControllerProvider).sources, isEmpty);
      },
    );

    test(
      'GivenTheScopeIsCancelled_WhenAFolderIsAdded_ThenTheScreenIsNotLeftBusy',
      () async {
        final sut = build();

        await register(sut.ref, scope: null);

        expect(
          sut.ref.read(librarySourcesControllerProvider).registering,
          isFalse,
        );
      },
    );
  });

  group('a folder that is refused is never asked about', () {
    test(
      'GivenAMissingFolder_WhenItIsAdded_ThenTheScopeIsNeverAsked',
      () async {
        // Asking earlier in the flow would ask what a folder is for and then
        // refuse it for not being there.
        var asked = false;
        final sut = build(exists: false);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .registerFolder(
              onOverlapConfirmed: (_, _) async => true,
              onScopeChosen: (_) async {
                asked = true;
                return const [];
              },
            );

        expect(asked, isFalse);
      },
    );

    test(
      'GivenTheOwnerCancelsThePicker_WhenTheyAdd_ThenTheScopeIsNeverAsked',
      () async {
        var asked = false;
        final sut = build(picked: null);

        await sut.ref
            .read(librarySourcesControllerProvider.notifier)
            .registerFolder(
              onOverlapConfirmed: (_, _) async => true,
              onScopeChosen: (_) async {
                asked = true;
                return const [];
              },
            );

        expect(asked, isFalse);
      },
    );
  });

  group('a re-check is not scoped (UC-07, FR-LB-06)', () {
    test(
      'GivenAScopedFolder_WhenTheLibraryIsReChecked_ThenNoScopeIsSent',
      () async {
        // A re-check walks the catalog rather than the disk, so it revisits
        // what is already recorded and cannot pull in an excluded type. The
        // scoped call is `startIndex`, and a re-check must not reach it: a
        // re-check routed through it would carry some folder's scope, which is
        // neither the absent scope the core wants nor an empty one.
        final sut = build();
        await register(sut.ref, scope: const [FileType.audio]);

        await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();

        expect(sut.gateway.refreshStarts, hasLength(1));
        expect(
          sut.gateway.starts,
          isEmpty,
          reason: 'a re-check must not go through the scoped index-start call',
        );
      },
    );
  });
}

/// A gateway that models which files a scoped run would record.
///
/// The folder under test is a music folder with its cover art in it, which is
/// the case the scope exists for. An empty scope records everything, exactly
/// as the core reads an absent one.
///
/// This restates the argument rather than verifying it: what it catalogues is
/// derived from the `types` it was just given, so it can only show that a
/// scope arrived here intact. Whether the core agrees about what those names
/// mean is integration_test/catalog/index_scope_test.dart's question.
class _ScanningGateway extends FakeIndexGateway {
  static const _folder = <String, FileType>{
    'Kind of Blue.flac': FileType.audio,
    'So What.flac': FileType.audio,
    'cover.jpg': FileType.image,
  };

  /// The files the last run recorded.
  List<String> cataloged = [];

  @override
  Future<IndexStartOutcome> startIndex({
    required String root,
    RunPriority? priority,
    List<FileType> types = const [],
    required String credential,
  }) {
    cataloged = [
      for (final entry in _folder.entries)
        if (types.isEmpty || types.contains(entry.value)) entry.key,
    ];

    return super.startIndex(
      root: root,
      priority: priority,
      types: types,
      credential: credential,
    );
  }
}
