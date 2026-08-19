// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileDetails {

/// The file itself, as a listing would show it.
 CatalogFile get file;/// The type-specific metadata, as labelled fields.
///
/// A map rather than a union per type, because this screen only reads it.
/// Editing is UC-15's and UC-16's, and they are the use cases that should
/// design the typed shape — building one here from a display would be
/// guessing at what an editor needs.
 Map<String, String> get metadata;/// The pixel width the core extracted, for an image.
 int? get width;/// The pixel height the core extracted, for an image.
 int? get height;/// The page count the core extracted, for a document or a comic.
 int? get pageCount;/// The duration in seconds the core extracted, for a video.
 double? get durationSeconds;/// Whether the core reports this record as soft-deleted (AF-02).
 bool get isDeleted;
/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileDetailsCopyWith<FileDetails> get copyWith => _$FileDetailsCopyWithImpl<FileDetails>(this as FileDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileDetails&&(identical(other.file, file) || other.file == file)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,file,const DeepCollectionEquality().hash(metadata),width,height,pageCount,durationSeconds,isDeleted);

@override
String toString() {
  return 'FileDetails(file: $file, metadata: $metadata, width: $width, height: $height, pageCount: $pageCount, durationSeconds: $durationSeconds, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $FileDetailsCopyWith<$Res>  {
  factory $FileDetailsCopyWith(FileDetails value, $Res Function(FileDetails) _then) = _$FileDetailsCopyWithImpl;
@useResult
$Res call({
 CatalogFile file, Map<String, String> metadata, int? width, int? height, int? pageCount, double? durationSeconds, bool isDeleted
});


$CatalogFileCopyWith<$Res> get file;

}
/// @nodoc
class _$FileDetailsCopyWithImpl<$Res>
    implements $FileDetailsCopyWith<$Res> {
  _$FileDetailsCopyWithImpl(this._self, this._then);

  final FileDetails _self;
  final $Res Function(FileDetails) _then;

/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? metadata = null,Object? width = freezed,Object? height = freezed,Object? pageCount = freezed,Object? durationSeconds = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as double?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// Adds pattern-matching-related methods to [FileDetails].
extension FileDetailsPatterns on FileDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileDetails value)  $default,){
final _that = this;
switch (_that) {
case _FileDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileDetails value)?  $default,){
final _that = this;
switch (_that) {
case _FileDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogFile file,  Map<String, String> metadata,  int? width,  int? height,  int? pageCount,  double? durationSeconds,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileDetails() when $default != null:
return $default(_that.file,_that.metadata,_that.width,_that.height,_that.pageCount,_that.durationSeconds,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogFile file,  Map<String, String> metadata,  int? width,  int? height,  int? pageCount,  double? durationSeconds,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _FileDetails():
return $default(_that.file,_that.metadata,_that.width,_that.height,_that.pageCount,_that.durationSeconds,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogFile file,  Map<String, String> metadata,  int? width,  int? height,  int? pageCount,  double? durationSeconds,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _FileDetails() when $default != null:
return $default(_that.file,_that.metadata,_that.width,_that.height,_that.pageCount,_that.durationSeconds,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc


class _FileDetails extends FileDetails {
  const _FileDetails({required this.file, final  Map<String, String> metadata = const <String, String>{}, this.width, this.height, this.pageCount, this.durationSeconds, this.isDeleted = false}): _metadata = metadata,super._();
  

/// The file itself, as a listing would show it.
@override final  CatalogFile file;
/// The type-specific metadata, as labelled fields.
///
/// A map rather than a union per type, because this screen only reads it.
/// Editing is UC-15's and UC-16's, and they are the use cases that should
/// design the typed shape — building one here from a display would be
/// guessing at what an editor needs.
 final  Map<String, String> _metadata;
/// The type-specific metadata, as labelled fields.
///
/// A map rather than a union per type, because this screen only reads it.
/// Editing is UC-15's and UC-16's, and they are the use cases that should
/// design the typed shape — building one here from a display would be
/// guessing at what an editor needs.
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

/// The pixel width the core extracted, for an image.
@override final  int? width;
/// The pixel height the core extracted, for an image.
@override final  int? height;
/// The page count the core extracted, for a document or a comic.
@override final  int? pageCount;
/// The duration in seconds the core extracted, for a video.
@override final  double? durationSeconds;
/// Whether the core reports this record as soft-deleted (AF-02).
@override@JsonKey() final  bool isDeleted;

/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileDetailsCopyWith<_FileDetails> get copyWith => __$FileDetailsCopyWithImpl<_FileDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileDetails&&(identical(other.file, file) || other.file == file)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,file,const DeepCollectionEquality().hash(_metadata),width,height,pageCount,durationSeconds,isDeleted);

@override
String toString() {
  return 'FileDetails(file: $file, metadata: $metadata, width: $width, height: $height, pageCount: $pageCount, durationSeconds: $durationSeconds, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$FileDetailsCopyWith<$Res> implements $FileDetailsCopyWith<$Res> {
  factory _$FileDetailsCopyWith(_FileDetails value, $Res Function(_FileDetails) _then) = __$FileDetailsCopyWithImpl;
@override @useResult
$Res call({
 CatalogFile file, Map<String, String> metadata, int? width, int? height, int? pageCount, double? durationSeconds, bool isDeleted
});


@override $CatalogFileCopyWith<$Res> get file;

}
/// @nodoc
class __$FileDetailsCopyWithImpl<$Res>
    implements _$FileDetailsCopyWith<$Res> {
  __$FileDetailsCopyWithImpl(this._self, this._then);

  final _FileDetails _self;
  final $Res Function(_FileDetails) _then;

/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? metadata = null,Object? width = freezed,Object? height = freezed,Object? pageCount = freezed,Object? durationSeconds = freezed,Object? isDeleted = null,}) {
  return _then(_FileDetails(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as double?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of FileDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}

// dart format on
