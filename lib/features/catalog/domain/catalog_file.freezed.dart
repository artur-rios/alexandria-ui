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
 LibraryType get type;/// When the core last indexed this file.
///
/// What a date sort orders on (UC-12, FR-CT-08). Nullable because a core
/// that answers without it must not make the listing unreadable.
 DateTime? get indexedAt;/// When re-indexing last found the on-disk file gone.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogFile&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.indexedAt, indexedAt) || other.indexedAt == indexedAt)&&(identical(other.missingAt, missingAt) || other.missingAt == missingAt));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,path,type,indexedAt,missingAt);

@override
String toString() {
  return 'CatalogFile(uuid: $uuid, name: $name, path: $path, type: $type, indexedAt: $indexedAt, missingAt: $missingAt)';
}


}

/// @nodoc
abstract mixin class $CatalogFileCopyWith<$Res>  {
  factory $CatalogFileCopyWith(CatalogFile value, $Res Function(CatalogFile) _then) = _$CatalogFileCopyWithImpl;
@useResult
$Res call({
 String uuid, String name, String path, LibraryType type, DateTime? indexedAt, DateTime? missingAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? path = null,Object? type = null,Object? indexedAt = freezed,Object? missingAt = freezed,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LibraryType,indexedAt: freezed == indexedAt ? _self.indexedAt : indexedAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name,  String path,  LibraryType type,  DateTime? indexedAt,  DateTime? missingAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.indexedAt,_that.missingAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name,  String path,  LibraryType type,  DateTime? indexedAt,  DateTime? missingAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogFile():
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.indexedAt,_that.missingAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name,  String path,  LibraryType type,  DateTime? indexedAt,  DateTime? missingAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogFile() when $default != null:
return $default(_that.uuid,_that.name,_that.path,_that.type,_that.indexedAt,_that.missingAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogFile extends CatalogFile {
  const _CatalogFile({required this.uuid, required this.name, required this.path, required this.type, this.indexedAt, this.missingAt}): super._();
  

/// The public identifier passed on every call about this file.
@override final  String uuid;
/// The file name on disk.
@override final  String name;
/// The absolute on-disk path.
@override final  String path;
/// What the core classified it as.
@override final  LibraryType type;
/// When the core last indexed this file.
///
/// What a date sort orders on (UC-12, FR-CT-08). Nullable because a core
/// that answers without it must not make the listing unreadable.
@override final  DateTime? indexedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogFile&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.indexedAt, indexedAt) || other.indexedAt == indexedAt)&&(identical(other.missingAt, missingAt) || other.missingAt == missingAt));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,path,type,indexedAt,missingAt);

@override
String toString() {
  return 'CatalogFile(uuid: $uuid, name: $name, path: $path, type: $type, indexedAt: $indexedAt, missingAt: $missingAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogFileCopyWith<$Res> implements $CatalogFileCopyWith<$Res> {
  factory _$CatalogFileCopyWith(_CatalogFile value, $Res Function(_CatalogFile) _then) = __$CatalogFileCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name, String path, LibraryType type, DateTime? indexedAt, DateTime? missingAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? path = null,Object? type = null,Object? indexedAt = freezed,Object? missingAt = freezed,}) {
  return _then(_CatalogFile(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LibraryType,indexedAt: freezed == indexedAt ? _self.indexedAt : indexedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,missingAt: freezed == missingAt ? _self.missingAt : missingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
