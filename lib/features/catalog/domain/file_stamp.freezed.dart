// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_stamp.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileStamp {

/// The file's size in bytes.
 int? get sizeBytes;/// When the file was last modified on disk.
 DateTime? get mtime;
/// Create a copy of FileStamp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileStampCopyWith<FileStamp> get copyWith => _$FileStampCopyWithImpl<FileStamp>(this as FileStamp, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileStamp&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mtime, mtime) || other.mtime == mtime));
}


@override
int get hashCode => Object.hash(runtimeType,sizeBytes,mtime);

@override
String toString() {
  return 'FileStamp(sizeBytes: $sizeBytes, mtime: $mtime)';
}


}

/// @nodoc
abstract mixin class $FileStampCopyWith<$Res>  {
  factory $FileStampCopyWith(FileStamp value, $Res Function(FileStamp) _then) = _$FileStampCopyWithImpl;
@useResult
$Res call({
 int? sizeBytes, DateTime? mtime
});




}
/// @nodoc
class _$FileStampCopyWithImpl<$Res>
    implements $FileStampCopyWith<$Res> {
  _$FileStampCopyWithImpl(this._self, this._then);

  final FileStamp _self;
  final $Res Function(FileStamp) _then;

/// Create a copy of FileStamp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sizeBytes = freezed,Object? mtime = freezed,}) {
  return _then(_self.copyWith(
sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,mtime: freezed == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileStamp].
extension FileStampPatterns on FileStamp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileStamp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileStamp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileStamp value)  $default,){
final _that = this;
switch (_that) {
case _FileStamp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileStamp value)?  $default,){
final _that = this;
switch (_that) {
case _FileStamp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? sizeBytes,  DateTime? mtime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileStamp() when $default != null:
return $default(_that.sizeBytes,_that.mtime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? sizeBytes,  DateTime? mtime)  $default,) {final _that = this;
switch (_that) {
case _FileStamp():
return $default(_that.sizeBytes,_that.mtime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? sizeBytes,  DateTime? mtime)?  $default,) {final _that = this;
switch (_that) {
case _FileStamp() when $default != null:
return $default(_that.sizeBytes,_that.mtime);case _:
  return null;

}
}

}

/// @nodoc


class _FileStamp extends FileStamp {
  const _FileStamp({this.sizeBytes, this.mtime}): super._();
  

/// The file's size in bytes.
@override final  int? sizeBytes;
/// When the file was last modified on disk.
@override final  DateTime? mtime;

/// Create a copy of FileStamp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileStampCopyWith<_FileStamp> get copyWith => __$FileStampCopyWithImpl<_FileStamp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileStamp&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.mtime, mtime) || other.mtime == mtime));
}


@override
int get hashCode => Object.hash(runtimeType,sizeBytes,mtime);

@override
String toString() {
  return 'FileStamp(sizeBytes: $sizeBytes, mtime: $mtime)';
}


}

/// @nodoc
abstract mixin class _$FileStampCopyWith<$Res> implements $FileStampCopyWith<$Res> {
  factory _$FileStampCopyWith(_FileStamp value, $Res Function(_FileStamp) _then) = __$FileStampCopyWithImpl;
@override @useResult
$Res call({
 int? sizeBytes, DateTime? mtime
});




}
/// @nodoc
class __$FileStampCopyWithImpl<$Res>
    implements _$FileStampCopyWith<$Res> {
  __$FileStampCopyWithImpl(this._self, this._then);

  final _FileStamp _self;
  final $Res Function(_FileStamp) _then;

/// Create a copy of FileStamp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sizeBytes = freezed,Object? mtime = freezed,}) {
  return _then(_FileStamp(
sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,mtime: freezed == mtime ? _self.mtime : mtime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
