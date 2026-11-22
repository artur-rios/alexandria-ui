import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/domain/catalog_stats.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/run_priority.dart';

/// A [LibraryGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeLibraryGateway implements LibraryGateway {
  /// Creates a gateway holding [libraries].
  FakeLibraryGateway({List<Library>? libraries}) : libraries = [...?libraries];

  /// What a browse answers.
  final List<Library> libraries;

  /// What [browse] answers instead, when a test says so.
  LibraryBrowse? browseOutcome;

  /// What [read] answers, by library uuid then folder path.
  final Map<String, Map<String, LibraryRead>> reads = {};

  /// What [read] answers for a library, worked out at each read from the
  /// folder's path — ahead of [reads].
  ///
  /// For a folder whose contents come from somewhere a test changes as it
  /// goes, such as a fake catalog: the folder is read again after a write,
  /// as the real one is, and answers what is there now.
  final Map<String, LibraryRead Function(String path)> readers = {};

  /// What the next write answers, in order.
  final List<LibraryWrite> writeOutcomes = [];

  /// Every folder actually read, in order — the record a "the core is never
  /// asked again" assertion needs, which the stub map above cannot give.
  final List<({String uuid, String path})> readsMade = [];

  /// Every registration asked for, in order.
  final List<({String name, String rootPath})> registered = [];

  /// Every library removed, in order.
  final List<String> removed = [];

  /// Every move asked for, in order.
  final List<({String uuid, String rootPath})> moved = [];

  @override
  Future<LibraryBrowse> browse() async =>
      browseOutcome ?? LibraryBrowse.loaded(libraries: libraries);

  @override
  Future<LibraryRead> read({required String uuid, required String path}) async {
    readsMade.add((uuid: uuid, path: path));

    return readers[uuid]?.call(path) ??
        reads[uuid]?[path] ??
        LibraryRead.loaded(
          listing: LibraryListing(
            library: libraries.firstWhere(
              (library) => library.uuid == uuid,
              orElse: () => Library(uuid: uuid, name: '', rootPath: ''),
            ),
            path: path,
            folders: const [],
            files: const [],
          ),
        );
  }

  /// What the next registration answers, in order. Empty registers the
  /// library under the next `lib-N` uuid with the run [registeredRunId].
  final List<LibraryRegistration> registerOutcomes = [];

  /// The run id a successful registration answers.
  String registeredRunId = 'run-1';

  /// The priority each registration asked for, in order.
  final List<RunPriority?> registeredPriorities = [];

  @override
  Future<LibraryRegistration> register({
    required String name,
    required String rootPath,
    RunPriority? priority,
  }) async {
    registered.add((name: name, rootPath: rootPath));
    registeredPriorities.add(priority);
    if (registerOutcomes.isNotEmpty) return registerOutcomes.removeAt(0);
    // A queued write refusal still refuses a registration, so the tests
    // written against the old shape keep meaning what they said.
    if (writeOutcomes.isNotEmpty) {
      switch (writeOutcomes.removeAt(0)) {
        case LibraryWriteFailed(:final failure):
          return LibraryRegistration.failed(failure: failure);
        case LibraryWriteDone():
          break;
      }
    }

    final library = Library(
      uuid: 'lib-${libraries.length + 1}',
      name: name,
      rootPath: rootPath,
    );
    libraries.add(library);
    return LibraryRegistration.registered(
      library: library,
      runId: registeredRunId,
    );
  }

  @override
  Future<LibraryWrite> move({
    required String uuid,
    required String rootPath,
  }) async {
    moved.add((uuid: uuid, rootPath: rootPath));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final at = libraries.indexWhere((library) => library.uuid == uuid);
    if (at < 0) {
      return const LibraryWrite.failed(
        failure: Failure.notFound(family: CoreStatusFamily.library, code: 4),
      );
    }
    libraries[at] = libraries[at].copyWith(rootPath: rootPath);

    return const LibraryWrite.done();
  }

  @override
  Future<LibraryWrite> remove({required String uuid}) async {
    removed.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    libraries.removeWhere((library) => library.uuid == uuid);
    return const LibraryWrite.done();
  }

  /// Every pin change asked for, in order.
  final List<({String uuid, bool pinned})> pinnedCalls = [];

  /// Every favorite change asked for, in order.
  final List<({String uuid, bool favorite})> favoriteCalls = [];

  /// Every rename asked for, in order.
  final List<({String uuid, String name})> renamedCalls = [];

  @override
  Future<LibraryWrite> setPinned({
    required String uuid,
    required bool pinned,
  }) async {
    pinnedCalls.add((uuid: uuid, pinned: pinned));
    return _change(uuid, (library) => library.copyWith(pinned: pinned));
  }

  @override
  Future<LibraryWrite> setFavorite({
    required String uuid,
    required bool favorite,
  }) async {
    favoriteCalls.add((uuid: uuid, favorite: favorite));
    return _change(uuid, (library) => library.copyWith(favorite: favorite));
  }

  @override
  Future<LibraryWrite> rename({
    required String uuid,
    required String name,
  }) async {
    renamedCalls.add((uuid: uuid, name: name));
    return _change(uuid, (library) => library.copyWith(name: name));
  }

  /// Applies [change] to the library [uuid], unless a queued outcome refuses.
  LibraryWrite _change(String uuid, Library Function(Library) change) {
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final at = libraries.indexWhere((library) => library.uuid == uuid);
    if (at < 0) {
      return const LibraryWrite.failed(
        failure: Failure.notFound(family: CoreStatusFamily.library, code: 4),
      );
    }
    libraries[at] = change(libraries[at]);

    return const LibraryWrite.done();
  }

  /// What [stats] answers: an empty catalog, every type present and zero.
  CatalogStats statsOutcome = CatalogStats(
    libraries: 0,
    filesByType: {for (final type in FileType.values) type: 0},
  );

  /// What [stats] throws instead, when a test says so.
  Failure? statsFailure;

  /// How many times [stats] was asked.
  int statsReads = 0;

  @override
  Future<CatalogStats> stats() async {
    statsReads++;
    if (statsFailure case final failure?) throw failure;

    return statsOutcome;
  }
}
