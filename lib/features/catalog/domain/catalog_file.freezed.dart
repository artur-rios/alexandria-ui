// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogFile {

/// The public identifier passed on every call about this file.
 String get uuid;/// The file name on disk.
 String get name;/// The absolute on-disk path.
 String get path;/// What the core classified it as.
 LibraryType get type;/// The core's hash of the file's contents.
///
/// Read-only, and the only way to tell that a file changed on disk since
/// it was read: the editor compares it before it overwrites (UC-18
/// AF-05). Empty when the core answered without one, which reads as
/// "cannot tell" rather than as "unchanged".
 String get contentHash;/// When the core last indexed this file.
///
/// What a date sort orders on (UC-12, FR-CT-08). Nullable because a core
/// that answers without it must not make the listing unreadable.
 DateTime? get indexedAt;/// Whether the core reports the record as deleted.
///
/// The core's verdict and not this application's: a purge is offered for a
/// deleted record and refused for an active one (UC-35 AF-03), and the
/// answer to which it is has to come from the same listing the record did.
 bool get isDeleted;/// When the record was soft-deleted.
///
/// What the deleted view counts the retention window from (UC-34,
/// FR-LC-03). `null` on an active record, and on a deleted one the core
/// answered without a timestamp — which reads as "restorable, for an
/// unknown while" rather than as "not restorable".
 DateTime? get deletedAt;/// When re-indexing last found the on-disk file gone.
///
/// Orthogonal to the soft-delete lifecycle: a missing file is still an
/// active record, and UC-37 is what reviews them.
 DateTime? get missingAt;
/// Create a copy of CatalogFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<CatalogFile> get copyWith => _$CatalogFileCopyWithImpl<CatalogFile>(this as CatalogFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogFile&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.indexedAt, indexedAt) || other.indexedAt == indexedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.missingAt, missingAt) || other.missingAt == missingAt));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,path,type,contentHash,indexedAt,isDeleted,deletedAt,missingAt);

@override
String toString() {
  return 'CatalogFile(uuid: $uuid, name: $name, path: $path, type: $type, contentHash: $contentHash, indexedAt: $indexedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, missingAt: $missingAt)';
}


}

/// @nodoc
abstract mixin class $CatalogFileCopyWith<$Res>  {
  factory $CatalogFileCopyWith(CatalogFile value, $Res Function(CatalogFile) _then) = _$CatalogFileCopyWithImpl;
@useResult
$Res call({
 String uuid, String name, String path, LibraryType type, String contentHash, DateTime? indexedAt, bool isDeleted, DateTime? deletedAt, DateTime? missingAt
});




}
/// @nodoc
class _$CatalogFileCopyWithImpl<$Res>
    implements $CatalogFileCopyWith<$Res> {
  _$CatalogFileCopyWithImpl(this._self, this._then);

  final CatalogFile _self;
  final $Res Function(CatalogFile) _then;

/// Create a copy of CatalogFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? path = null,Object? type = null,Object? contentHash = null,Object? indexedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,Object? missingAt = freezed,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LibraryType,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,indexedAt: freezed == indexedAt ? _self.indexedAt : indexedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,missingAt: freezed == missingAt ? _self.missingAt : missingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogFile].
extension CatalogFilePatterns on CatalogFile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogFile value)  $default,){
final _that = this;
switch (_that) {
case _CatalogFile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogFile value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name,  String path,  LibraryType type,  String contentHash,  DateTime? indexedAt,  bool isDeleted,  DateTime? deletedAt,  DateTime? missingAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.contentHash,_that.indexedAt,_that.isDeleted,_that.deletedAt,_that.missingAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name,  String path,  LibraryType type,  String contentHash,  DateTime? indexedAt,  bool isDeleted,  DateTime? deletedAt,  DateTime? missingAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogFile():
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.contentHash,_that.indexedAt,_that.isDeleted,_that.deletedAt,_that.missingAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name,  String path,  LibraryType type,  String contentHash,  DateTime? indexedAt,  bool isDeleted,  DateTime? deletedAt,  DateTime? missingAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.contentHash,_that.indexedAt,_that.isDeleted,_that.deletedAt,_that.missingAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogFile extends CatalogFile {
  const _CatalogFile({required this.uuid, required this.name, required this.path, required this.type, this.contentHash = '', this.indexedAt, this.isDeleted = false, this.deletedAt, this.missingAt}): super._();
  

/// The public identifier passed on every call about this file.
@override final  String uuid;
/// The file name on disk.
@override final  String name;
/// The absolute on-disk path.
@override final  String path;
/// What the core classified it as.
@override final  LibraryType type;
/// The core's hash of the file's contents.
///
/// Read-only, and the only way to tell that a file changed on disk since
/// it was read: the editor compares it before it overwrites (UC-18
/// AF-05). Empty when the core answered without one, which reads as
/// "cannot tell" rather than as "unchanged".
@override@JsonKey() final  String contentHash;
/// When the core last indexed this file.
///
/// What a date sort orders on (UC-12, FR-CT-08). Nullable because a core
/// that answers without it must not make the listing unreadable.
@override final  DateTime? indexedAt;
/// Whether the core reports the record as deleted.
///
/// The core's verdict and not this application's: a purge is offered for a
/// deleted record and refused for an active one (UC-35 AF-03), and the
/// answer to which it is has to come from the same listing the record did.
@override@JsonKey() final  bool isDeleted;
/// When the record was soft-deleted.
///
/// What the deleted view counts the retention window from (UC-34,
/// FR-LC-03). `null` on an active record, and on a deleted one the core
/// answered without a timestamp — which reads as "restorable, for an
/// unknown while" rather than as "not restorable".
@override final  DateTime? deletedAt;
/// When re-indexing last found the on-disk file gone.
///
/// Orthogonal to the soft-delete lifecycle: a missing file is still an
/// active record, and UC-37 is what reviews them.
@override final  DateTime? missingAt;

/// Create a copy of CatalogFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogFileCopyWith<_CatalogFile> get copyWith => __$CatalogFileCopyWithImpl<_CatalogFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogFile&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.indexedAt, indexedAt) || other.indexedAt == indexedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.missingAt, missingAt) || other.missingAt == missingAt));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,path,type,contentHash,indexedAt,isDeleted,deletedAt,missingAt);

@override
String toString() {
  return 'CatalogFile(uuid: $uuid, name: $name, path: $path, type: $type, contentHash: $contentHash, indexedAt: $indexedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, missingAt: $missingAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogFileCopyWith<$Res> implements $CatalogFileCopyWith<$Res> {
  factory _$CatalogFileCopyWith(_CatalogFile value, $Res Function(_CatalogFile) _then) = __$CatalogFileCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name, String path, LibraryType type, String contentHash, DateTime? indexedAt, bool isDeleted, DateTime? deletedAt, DateTime? missingAt
});




}
/// @nodoc
class __$CatalogFileCopyWithImpl<$Res>
    implements _$CatalogFileCopyWith<$Res> {
  __$CatalogFileCopyWithImpl(this._self, this._then);

  final _CatalogFile _self;
  final $Res Function(_CatalogFile) _then;

/// Create a copy of CatalogFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? path = null,Object? type = null,Object? contentHash = null,Object? indexedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,Object? missingAt = freezed,}) {
  return _then(_CatalogFile(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LibraryType,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,indexedAt: freezed == indexedAt ? _self.indexedAt : indexedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,missingAt: freezed == missingAt ? _self.missingAt : missingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
