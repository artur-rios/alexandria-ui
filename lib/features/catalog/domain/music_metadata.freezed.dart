// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicMetadata {

 String? get title; String? get artist; String? get album; int? get year; String? get genre; int? get track;
/// Create a copy of MusicMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicMetadataCopyWith<MusicMetadata> get copyWith => _$MusicMetadataCopyWithImpl<MusicMetadata>(this as MusicMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.track, track) || other.track == track));
}


@override
int get hashCode => Object.hash(runtimeType,title,artist,album,year,genre,track);

@override
String toString() {
  return 'MusicMetadata(title: $title, artist: $artist, album: $album, year: $year, genre: $genre, track: $track)';
}


}

/// @nodoc
abstract mixin class $MusicMetadataCopyWith<$Res>  {
  factory $MusicMetadataCopyWith(MusicMetadata value, $Res Function(MusicMetadata) _then) = _$MusicMetadataCopyWithImpl;
@useResult
$Res call({
 String? title, String? artist, String? album, int? year, String? genre, int? track
});




}
/// @nodoc
class _$MusicMetadataCopyWithImpl<$Res>
    implements $MusicMetadataCopyWith<$Res> {
  _$MusicMetadataCopyWithImpl(this._self, this._then);

  final MusicMetadata _self;
  final $Res Function(MusicMetadata) _then;

/// Create a copy of MusicMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? artist = freezed,Object? album = freezed,Object? year = freezed,Object? genre = freezed,Object? track = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicMetadata].
extension MusicMetadataPatterns on MusicMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicMetadata value)  $default,){
final _that = this;
switch (_that) {
case _MusicMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _MusicMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? artist,  String? album,  int? year,  String? genre,  int? track)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicMetadata() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.year,_that.genre,_that.track);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? artist,  String? album,  int? year,  String? genre,  int? track)  $default,) {final _that = this;
switch (_that) {
case _MusicMetadata():
return $default(_that.title,_that.artist,_that.album,_that.year,_that.genre,_that.track);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? artist,  String? album,  int? year,  String? genre,  int? track)?  $default,) {final _that = this;
switch (_that) {
case _MusicMetadata() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.year,_that.genre,_that.track);case _:
  return null;

}
}

}

/// @nodoc


class _MusicMetadata extends MusicMetadata {
  const _MusicMetadata({this.title, this.artist, this.album, this.year, this.genre, this.track}): super._();
  

@override final  String? title;
@override final  String? artist;
@override final  String? album;
@override final  int? year;
@override final  String? genre;
@override final  int? track;

/// Create a copy of MusicMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicMetadataCopyWith<_MusicMetadata> get copyWith => __$MusicMetadataCopyWithImpl<_MusicMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicMetadata&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.track, track) || other.track == track));
}


@override
int get hashCode => Object.hash(runtimeType,title,artist,album,year,genre,track);

@override
String toString() {
  return 'MusicMetadata(title: $title, artist: $artist, album: $album, year: $year, genre: $genre, track: $track)';
}


}

/// @nodoc
abstract mixin class _$MusicMetadataCopyWith<$Res> implements $MusicMetadataCopyWith<$Res> {
  factory _$MusicMetadataCopyWith(_MusicMetadata value, $Res Function(_MusicMetadata) _then) = __$MusicMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? artist, String? album, int? year, String? genre, int? track
});




}
/// @nodoc
class __$MusicMetadataCopyWithImpl<$Res>
    implements _$MusicMetadataCopyWith<$Res> {
  __$MusicMetadataCopyWithImpl(this._self, this._then);

  final _MusicMetadata _self;
  final $Res Function(_MusicMetadata) _then;

/// Create a copy of MusicMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? artist = freezed,Object? album = freezed,Object? year = freezed,Object? genre = freezed,Object? track = freezed,}) {
  return _then(_MusicMetadata(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
