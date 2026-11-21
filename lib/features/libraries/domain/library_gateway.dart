import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../../indexing/domain/run_priority.dart';
import 'library.dart';

part 'library_gateway.freezed.dart';

/// What browsing the registered libraries produced.
@freezed
sealed class LibraryBrowse with _$LibraryBrowse {
  /// The core answered, possibly with nothing.
  const factory LibraryBrowse.loaded({required List<Library> libraries}) =
      LibraryBrowseLoaded;

  /// The core could not answer.
  const factory LibraryBrowse.failed({required Failure failure}) =
      LibraryBrowseFailed;
}

/// What reading one level of a library produced.
@freezed
sealed class LibraryRead with _$LibraryRead {
  /// The core answered with the folder's contents.
  const factory LibraryRead.loaded({required LibraryListing listing}) =
      LibraryReadLoaded;

  /// The core could not answer — including a library that is no longer
  /// registered.
  const factory LibraryRead.failed({required Failure failure}) =
      LibraryReadFailed;
}

/// What registering or removing a library produced.
@freezed
sealed class LibraryWrite with _$LibraryWrite {
  /// The core did it.
  const factory LibraryWrite.done() = LibraryWriteDone;

  /// The core refused.
  const factory LibraryWrite.failed({required Failure failure}) =
      LibraryWriteFailed;
}

/// What adding a library produced (core FR-FC-36).
@freezed
sealed class LibraryRegistration with _$LibraryRegistration {
  /// The core added [library] and started its first index run, [runId].
  const factory LibraryRegistration.registered({
    required Library library,
    required String runId,
  }) = LibraryRegistered;

  /// The core refused, storing nothing.
  const factory LibraryRegistration.failed({required Failure failure}) =
      LibraryRegistrationFailed;
}

/// The core's library operations (libraries design).
abstract interface class LibraryGateway {
  /// Every registered library.
  ///
  /// The read that makes the rest reachable: browsing addresses a uuid, and
  /// this is where those uuids come from.
  Future<LibraryBrowse> browse({required String credential});

  /// The folders and files directly inside [path] within [uuid].
  ///
  /// [path] is relative to the library's root; empty is the top.
  Future<LibraryRead> read({
    required String uuid,
    required String path,
    required String credential,
  });

  /// Adds [rootPath] as a library called [name], and starts indexing it.
  ///
  /// The core indexes nothing that is not a library (0.6.0), so this is how
  /// a folder gets into the catalog at all. The first run's id comes back
  /// with the library, so the caller can follow it; [priority] paces it, and
  /// null asks for the core's default. Refused — storing nothing — for a
  /// folder that does not exist, one outside the core's root, or one
  /// overlapping another library.
  Future<LibraryRegistration> register({
    required String name,
    required String rootPath,
    RunPriority? priority,
    required String credential,
  });

  /// Points [uuid] at [rootPath], the folder it moved to.
  ///
  /// A correction rather than a re-index: the files the library holds move
  /// with it and keep their uuids, so everything that points at them — a
  /// watchlist place, a reading position, a collection — still does. Walking
  /// the new location instead would mint new records and leave these to be
  /// found missing.
  Future<LibraryWrite> move({
    required String uuid,
    required String rootPath,
    required String credential,
  });

  /// Stops treating a folder as a library.
  ///
  /// The files are kept and return to the type panels. Marking a folder
  /// empties part of a panel, which is not visible until afterwards, so the
  /// way back has to restore rather than delete.
  Future<LibraryWrite> remove({
    required String uuid,
    required String credential,
  });
}
