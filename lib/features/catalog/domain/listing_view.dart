import 'catalog_file.dart';

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
  indexed;

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
    };

    return view.direction == SortDirection.ascending ? order : -order;
  });

  return sorted;
}
