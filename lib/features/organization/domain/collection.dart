import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection.freezed.dart';

/// What a collection holds (System Requirements §4.4, FR-OG-01).
///
/// Fixed at creation and never changed: it decides which items the collection
/// will accept, and a collection that changed kind would be one holding items
/// it now refuses.
enum CollectionKind {
  /// Catalog files.
  file('file'),

  /// Bookmarks.
  bookmark('bookmark');

  const CollectionKind(this.wireName);

  /// The string the core uses.
  final String wireName;

  /// The kind [wireName] names, or `null` when the core answers one this
  /// application does not know.
  static CollectionKind? fromWireName(String? wireName) {
    for (final kind in CollectionKind.values) {
      if (kind.wireName == wireName) return kind;
    }
    return null;
  }
}

/// A collection, as the application consumes it (System Requirements §4.4).
///
/// Flat: the core's model has no parent, and `FR-OG-07` fixes the present
/// depth of the hierarchy at one. Navigation is built against that model
/// rather than around it, so nesting becomes a change of data rather than of
/// interface.
@freezed
abstract class Collection with _$Collection {
  /// Creates a collection.
  const factory Collection({
    /// The public identifier passed on every call about it.
    required String uuid,

    /// What it is called.
    required String name,

    /// What it holds.
    required CollectionKind kind,

    /// How many items it currently holds, as the core counts them.
    ///
    /// Derived by the core from the rows that point at the collection, never
    /// stored and never computed here — so it cannot drift from the membership
    /// UC-27 lists.
    @Default(0) int itemCount,
  }) = _Collection;
}

/// Why a collection name cannot be sent (UC-26 AF-01, FR-OG-01).
enum CollectionNameError {
  /// Blank after trimming.
  empty,
}

/// What is wrong with [name], or `null` when it can be sent (AF-01).
///
/// Only the check the core would make anyway, made here so an attempt that
/// cannot succeed never becomes one. Everything else about the name is the
/// core's verdict (BR-02).
CollectionNameError? validateCollectionName(String name) =>
    name.trim().isEmpty ? CollectionNameError.empty : null;
