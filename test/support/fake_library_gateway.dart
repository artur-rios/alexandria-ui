import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';

/// A [LibraryGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeLibraryGateway implements LibraryGateway {
  /// Creates a gateway holding [libraries].
  FakeLibraryGateway({List<Library>? libraries})
    : libraries = [...?libraries];

  /// What a browse answers.
  final List<Library> libraries;

  /// What [browse] answers instead, when a test says so.
  LibraryBrowse? browseOutcome;

  /// What [read] answers, by library uuid then folder path.
  final Map<String, Map<String, LibraryRead>> reads = {};

  /// What the next write answers, in order.
  final List<LibraryWrite> writeOutcomes = [];

  /// Every folder actually read, in order — the record a "the core is never
  /// asked again" assertion needs, which the stub map above cannot give.
  final List<({String uuid, String path})> readsMade = [];

  /// Every registration asked for, in order.
  final List<({String name, String rootPath})> registered = [];

  /// Every library removed, in order.
  final List<String> removed = [];

  @override
  Future<LibraryBrowse> browse({required String credential}) async =>
      browseOutcome ?? LibraryBrowse.loaded(libraries: libraries);

  @override
  Future<LibraryRead> read({
    required String uuid,
    required String path,
    required String credential,
  }) async {
    readsMade.add((uuid: uuid, path: path));

    return reads[uuid]?[path] ??
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

  @override
  Future<LibraryWrite> register({
    required String name,
    required String rootPath,
    required String credential,
  }) async {
    registered.add((name: name, rootPath: rootPath));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    libraries.add(
      Library(uuid: 'lib-${libraries.length + 1}', name: name, rootPath: rootPath),
    );
    return const LibraryWrite.done();
  }

  @override
  Future<LibraryWrite> remove({
    required String uuid,
    required String credential,
  }) async {
    removed.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    libraries.removeWhere((library) => library.uuid == uuid);
    return const LibraryWrite.done();
  }
}
