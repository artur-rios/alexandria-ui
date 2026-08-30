import 'package:freezed_annotation/freezed_annotation.dart';

import '../../catalog/domain/file_type.dart';

part 'library_source.freezed.dart';
part 'library_source.g.dart';

/// A folder on disk the owner has registered as a source of files to index
/// (System Requirements §4.7, FR-LB-01, FR-LB-03).
///
/// Application-owned, not a projection: the core indexes what it is pointed
/// at, and which folders those are is the application's to remember. Keyed by
/// [path], which is what naturally identifies a folder and what makes
/// "already registered" answerable without an identifier nobody assigned.
@freezed
abstract class LibrarySource with _$LibrarySource {
  const LibrarySource._();

  /// Creates a source.
  const factory LibrarySource({
    /// The absolute folder path. Also the key.
    required String path,

    /// The owner-supplied name, defaulting to the folder's own name.
    required String label,

    /// When it was registered.
    required DateTime registeredAt,

    /// The identifier of the most recent run over this folder (UC-06).
    String? lastRunId,

    /// Whether that run finished or failed (UC-06).
    String? lastRunOutcome,

    /// When that run finished (UC-06).
    DateTime? lastRunAt,

    /// What an index of this folder records, by [FileType.wireName].
    ///
    /// Empty means every type, which is exactly what the core reads an absent
    /// scope as — one meaning held the same way on both sides, so a folder
    /// registered before the scope existed keeps behaving as it did with no
    /// migration.
    ///
    /// Wire names rather than the enum, because this is what the core is told
    /// and what a stored record has to still mean after a type is renamed on
    /// this side of the boundary.
    @Default(<String>[]) List<String> scope,
  }) = _LibrarySource;

  /// Reads a source from the local settings store.
  factory LibrarySource.fromJson(Map<String, dynamic> json) =>
      _$LibrarySourceFromJson(json);

  /// [scope] as types, dropping any name this application does not know.
  ///
  /// Dropped rather than defaulted, on the same reasoning as
  /// [FileType.fromWire]: an unknown name is not any particular type, and
  /// guessing one would scope a run to something nobody chose.
  ///
  /// Read this with [scopeIsUnreadable]. On its own it cannot be trusted to
  /// mean "every type" when it is empty, because a stored scope of nothing but
  /// unknown names drops to empty too.
  List<FileType> get scopeTypes => [
    for (final name in scope) ?FileType.fromWire(name),
  ];

  /// Whether [scope] names something, but nothing this application knows.
  ///
  /// The one case where dropping unknown names is not enough. An empty scope
  /// already means *every type*, so a stored `["podcast"]` — a name from a
  /// newer core, or a type renamed on this side, which is the reason wire
  /// names are what get stored — would drop to empty and index everything.
  /// That is the exact bug the scope exists to prevent, and it would reach the
  /// core as a folder the owner had deliberately narrowed.
  ///
  /// So it is answered as its own condition and refused rather than run: the
  /// owner is told the folder covers something this version cannot read, and
  /// nothing is indexed. Refusing is the safe direction because it is the
  /// recoverable one — a run that is not started can be started later, once
  /// the name is understood again, where files wrongly catalogued have to be
  /// found and removed.
  bool get scopeIsUnreadable => scope.isNotEmpty && scopeTypes.isEmpty;
}
