import 'catalog_file.dart';
import 'file_type.dart';
import 'music_metadata.dart';

/// Which lifecycle states a listing shows (FR-CT-07).
///
/// The core's own filter, passed straight through: it is the one filter the
/// core supports on a listing, and the application does not re-decide it.
enum LifecycleFilter {
  /// Only records the core calls active. The default a listing opens on.
  active('active'),

  /// Only soft-deleted records. UC-34's listing is the one built on this.
  deleted('deleted'),

  /// Both.
  all('all');

  const LifecycleFilter(this.wireName);

  /// The value the core's filter takes.
  final String wireName;

  /// The filter [name] names, or `null` when it names none.
  static LifecycleFilter? byName(String? name) {
    for (final filter in LifecycleFilter.values) {
      if (filter.name == name) return filter;
    }
    return null;
  }
}

/// What a listing is ordered by (FR-CT-08).
///
/// Name and date only. FR-CT-08 also asks for "the type-specific attributes
/// the core exposes", and the core's file projection exposes none — a listing
/// answers uuid, name, path, type, state and the indexed time, and nothing
/// about an album or an author. Those arrive when the catalog carries
/// metadata, and are absent here rather than sorted on a field that does not
/// exist.
enum SortField {
  /// The file's name.
  name,

  /// When the core last indexed it.
  indexed,

  /// A record's own order: album artist (or artist), album, track number,
  /// then title (Music only). What next and previous follow, so an album
  /// plays as it was made rather than in file-name order.
  album;

  /// The field [name] names, or `null` when it names none.
  static SortField? byName(String? name) {
    for (final field in SortField.values) {
      if (field.name == name) return field;
    }
    return null;
  }
}

/// Which way a sort runs.
enum SortDirection {
  /// A to Z, oldest first.
  ascending,

  /// Z to A, newest first.
  descending;

  /// The direction [name] names, or `null` when it names none.
  static SortDirection? byName(String? name) {
    for (final direction in SortDirection.values) {
      if (direction.name == name) return direction;
    }
    return null;
  }
}

/// How one type's listing is filtered and ordered (UC-12).
class ListingView {
  /// Creates a view.
  const ListingView({
    this.lifecycle = LifecycleFilter.active,
    this.sortField = SortField.name,
    this.direction = SortDirection.ascending,
  });

  /// Which lifecycle states are shown.
  final LifecycleFilter lifecycle;

  /// What the listing is ordered by.
  final SortField sortField;

  /// Which way the order runs.
  final SortDirection direction;

  /// The view a listing opens on before the owner has chosen anything.
  static const ListingView initial = ListingView();

  /// The view [type]'s listing opens on: albums in their own order for
  /// music, names for everything else.
  static ListingView initialFor(FileType type) => type == FileType.audio
      ? const ListingView(sortField: SortField.album)
      : initial;

  /// Whether anything has been narrowed away from the default.
  ///
  /// Only the lifecycle filter narrows; a sort reorders without hiding
  /// anything, which is why AF-01's "clear the filters" does not reset it.
  bool get isFiltered => lifecycle != LifecycleFilter.active;

  /// A copy with the given changes.
  ListingView copyWith({
    LifecycleFilter? lifecycle,
    SortField? sortField,
    SortDirection? direction,
  }) => ListingView(
    lifecycle: lifecycle ?? this.lifecycle,
    sortField: sortField ?? this.sortField,
    direction: direction ?? this.direction,
  );

  /// This view as the map the settings store holds.
  Map<String, String> toJson() => {
    'lifecycle': lifecycle.name,
    'sortField': sortField.name,
    'direction': direction.name,
  };

  /// The view [json] describes, falling back per field.
  ///
  /// Per field rather than all-or-nothing: a document written by another
  /// version may know one of these three and not the others, and the ones it
  /// does know are still the owner's choices.
  static ListingView fromJson(Map<String, dynamic> json) => ListingView(
    lifecycle:
        LifecycleFilter.byName(json['lifecycle'] as String?) ??
        LifecycleFilter.active,
    sortField: SortField.byName(json['sortField'] as String?) ?? SortField.name,
    direction:
        SortDirection.byName(json['direction'] as String?) ??
        SortDirection.ascending,
  );

  @override
  bool operator ==(Object other) =>
      other is ListingView &&
      other.lifecycle == lifecycle &&
      other.sortField == sortField &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(lifecycle, sortField, direction);
}

/// [files] in the order [view] asks for (main flow step 4).
///
/// Sorted here rather than by the core, which publishes no ordering on a
/// listing. The comparison is case-insensitive on names, because a library
/// sorted with every capital letter first is not sorted the way anyone reads.
List<CatalogFile> sortFiles(List<CatalogFile> files, ListingView view) {
  final sorted = [...files];

  sorted.sort((a, b) {
    final order = switch (view.sortField) {
      SortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      // A file the core has not dated sorts as the oldest rather than
      // throwing the order out: it is missing information, not a reason to
      // refuse to sort.
      SortField.indexed => (a.indexedAt ?? DateTime.utc(0)).compareTo(
        b.indexedAt ?? DateTime.utc(0),
      ),
      SortField.album => _albumOrder(a, b),
    };

    return view.direction == SortDirection.ascending ? order : -order;
  });

  return sorted;
}

/// [a] against [b] in a record's own order.
///
/// Album artist (falling back to the artist), album, track number, title,
/// and finally the file name, so the order is total and stable. A missing
/// value sorts after every present one, so untagged files gather at the end
/// rather than scattering through the albums.
int _albumOrder(CatalogFile a, CatalogFile b) {
  final ta = a.tags ?? const MusicMetadata();
  final tb = b.tags ?? const MusicMetadata();

  return _compareText(ta.albumArtist ?? ta.artist, tb.albumArtist ?? tb.artist)
      .orElse(() => _compareText(ta.album, tb.album))
      .orElse(() => _compareNumber(ta.track, tb.track))
      .orElse(() => _compareText(ta.title, tb.title))
      .orElse(() => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

int _compareText(String? a, String? b) {
  final left = a?.trim().toLowerCase() ?? '';
  final right = b?.trim().toLowerCase() ?? '';
  if (left.isEmpty || right.isEmpty) {
    return (left.isEmpty ? 1 : 0) - (right.isEmpty ? 1 : 0);
  }
  return left.compareTo(right);
}

int _compareNumber(int? a, int? b) {
  if (a == null || b == null) return (a == null ? 1 : 0) - (b == null ? 1 : 0);
  return a.compareTo(b);
}

extension on int {
  /// This comparison, or [next]'s when this one is a tie.
  int orElse(int Function() next) => this != 0 ? this : next();
}
