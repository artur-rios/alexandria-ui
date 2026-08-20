// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoMetadata {

 String? get title; int? get year; String? get resolution; MediaKind? get mediaKind;
/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoMetadataCopyWith<VideoMetadata> get copyWith => _$VideoMetadataCopyWithImpl<VideoMetadata>(this as VideoMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind));
}


@override
int get hashCode => Object.hash(runtimeType,title,year,resolution,mediaKind);

@override
String toString() {
  return 'VideoMetadata(title: $title, year: $year, resolution: $resolution, mediaKind: $mediaKind)';
}


}

/// @nodoc
abstract mixin class $VideoMetadataCopyWith<$Res>  {
  factory $VideoMetadataCopyWith(VideoMetadata value, $Res Function(VideoMetadata) _then) = _$VideoMetadataCopyWithImpl;
@useResult
$Res call({
 String? title, int? year, String? resolution, MediaKind? mediaKind
});




}
/// @nodoc
class _$VideoMetadataCopyWithImpl<$Res>
    implements $VideoMetadataCopyWith<$Res> {
  _$VideoMetadataCopyWithImpl(this._self, this._then);

  final VideoMetadata _self;
  final $Res Function(VideoMetadata) _then;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? year = freezed,Object? resolution = freezed,Object? mediaKind = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as MediaKind?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoMetadata].
extension VideoMetadataPatterns on VideoMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoMetadata value)  $default,){
final _that = this;
switch (_that) {
case _VideoMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  int? year,  String? resolution,  MediaKind? mediaKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that.title,_that.year,_that.resolution,_that.mediaKind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  int? year,  String? resolution,  MediaKind? mediaKind)  $default,) {final _that = this;
switch (_that) {
case _VideoMetadata():
return $default(_that.title,_that.year,_that.resolution,_that.mediaKind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  int? year,  String? resolution,  MediaKind? mediaKind)?  $default,) {final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that.title,_that.year,_that.resolution,_that.mediaKind);case _:
  return null;

}
}

}

/// @nodoc


class _VideoMetadata extends VideoMetadata {
  const _VideoMetadata({this.title, this.year, this.resolution, this.mediaKind}): super._();
  

@override final  String? title;
@override final  int? year;
@override final  String? resolution;
@override final  MediaKind? mediaKind;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoMetadataCopyWith<_VideoMetadata> get copyWith => __$VideoMetadataCopyWithImpl<_VideoMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind));
}


@override
int get hashCode => Object.hash(runtimeType,title,year,resolution,mediaKind);

@override
String toString() {
  return 'VideoMetadata(title: $title, year: $year, resolution: $resolution, mediaKind: $mediaKind)';
}


}

/// @nodoc
abstract mixin class _$VideoMetadataCopyWith<$Res> implements $VideoMetadataCopyWith<$Res> {
  factory _$VideoMetadataCopyWith(_VideoMetadata value, $Res Function(_VideoMetadata) _then) = __$VideoMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? title, int? year, String? resolution, MediaKind? mediaKind
});




}
/// @nodoc
class __$VideoMetadataCopyWithImpl<$Res>
    implements _$VideoMetadataCopyWith<$Res> {
  __$VideoMetadataCopyWithImpl(this._self, this._then);

  final _VideoMetadata _self;
  final $Res Function(_VideoMetadata) _then;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? year = freezed,Object? resolution = freezed,Object? mediaKind = freezed,}) {
  return _then(_VideoMetadata(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as MediaKind?,
  ));
}


}

// dart format on
