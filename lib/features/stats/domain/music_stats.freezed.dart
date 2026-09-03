// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicStats {

/// Every play ever recorded, including tracks carrying no tags.
 int get totalPlays;/// How many distinct tracks those plays are spread across.
 int get distinctTracks;/// The oldest and newest play, so the screen can say what period the
/// numbers cover. Both null when nothing has been played.
 DateTime? get firstPlayedAt; DateTime? get lastPlayedAt; List<TrackPlays> get topTracks; List<ArtistPlays> get topArtists; List<AlbumPlays> get topAlbums; List<GenrePlays> get topGenres;
/// Create a copy of MusicStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicStatsCopyWith<MusicStats> get copyWith => _$MusicStatsCopyWithImpl<MusicStats>(this as MusicStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.distinctTracks, distinctTracks) || other.distinctTracks == distinctTracks)&&(identical(other.firstPlayedAt, firstPlayedAt) || other.firstPlayedAt == firstPlayedAt)&&(identical(other.lastPlayedAt, lastPlayedAt) || other.lastPlayedAt == lastPlayedAt)&&const DeepCollectionEquality().equals(other.topTracks, topTracks)&&const DeepCollectionEquality().equals(other.topArtists, topArtists)&&const DeepCollectionEquality().equals(other.topAlbums, topAlbums)&&const DeepCollectionEquality().equals(other.topGenres, topGenres));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlays,distinctTracks,firstPlayedAt,lastPlayedAt,const DeepCollectionEquality().hash(topTracks),const DeepCollectionEquality().hash(topArtists),const DeepCollectionEquality().hash(topAlbums),const DeepCollectionEquality().hash(topGenres));

@override
String toString() {
  return 'MusicStats(totalPlays: $totalPlays, distinctTracks: $distinctTracks, firstPlayedAt: $firstPlayedAt, lastPlayedAt: $lastPlayedAt, topTracks: $topTracks, topArtists: $topArtists, topAlbums: $topAlbums, topGenres: $topGenres)';
}


}

/// @nodoc
abstract mixin class $MusicStatsCopyWith<$Res>  {
  factory $MusicStatsCopyWith(MusicStats value, $Res Function(MusicStats) _then) = _$MusicStatsCopyWithImpl;
@useResult
$Res call({
 int totalPlays, int distinctTracks, DateTime? firstPlayedAt, DateTime? lastPlayedAt, List<TrackPlays> topTracks, List<ArtistPlays> topArtists, List<AlbumPlays> topAlbums, List<GenrePlays> topGenres
});




}
/// @nodoc
class _$MusicStatsCopyWithImpl<$Res>
    implements $MusicStatsCopyWith<$Res> {
  _$MusicStatsCopyWithImpl(this._self, this._then);

  final MusicStats _self;
  final $Res Function(MusicStats) _then;

/// Create a copy of MusicStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalPlays = null,Object? distinctTracks = null,Object? firstPlayedAt = freezed,Object? lastPlayedAt = freezed,Object? topTracks = null,Object? topArtists = null,Object? topAlbums = null,Object? topGenres = null,}) {
  return _then(_self.copyWith(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,distinctTracks: null == distinctTracks ? _self.distinctTracks : distinctTracks // ignore: cast_nullable_to_non_nullable
as int,firstPlayedAt: freezed == firstPlayedAt ? _self.firstPlayedAt : firstPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPlayedAt: freezed == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,topTracks: null == topTracks ? _self.topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<TrackPlays>,topArtists: null == topArtists ? _self.topArtists : topArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistPlays>,topAlbums: null == topAlbums ? _self.topAlbums : topAlbums // ignore: cast_nullable_to_non_nullable
as List<AlbumPlays>,topGenres: null == topGenres ? _self.topGenres : topGenres // ignore: cast_nullable_to_non_nullable
as List<GenrePlays>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicStats].
extension MusicStatsPatterns on MusicStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicStats value)  $default,){
final _that = this;
switch (_that) {
case _MusicStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicStats value)?  $default,){
final _that = this;
switch (_that) {
case _MusicStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalPlays,  int distinctTracks,  DateTime? firstPlayedAt,  DateTime? lastPlayedAt,  List<TrackPlays> topTracks,  List<ArtistPlays> topArtists,  List<AlbumPlays> topAlbums,  List<GenrePlays> topGenres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicStats() when $default != null:
return $default(_that.totalPlays,_that.distinctTracks,_that.firstPlayedAt,_that.lastPlayedAt,_that.topTracks,_that.topArtists,_that.topAlbums,_that.topGenres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalPlays,  int distinctTracks,  DateTime? firstPlayedAt,  DateTime? lastPlayedAt,  List<TrackPlays> topTracks,  List<ArtistPlays> topArtists,  List<AlbumPlays> topAlbums,  List<GenrePlays> topGenres)  $default,) {final _that = this;
switch (_that) {
case _MusicStats():
return $default(_that.totalPlays,_that.distinctTracks,_that.firstPlayedAt,_that.lastPlayedAt,_that.topTracks,_that.topArtists,_that.topAlbums,_that.topGenres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalPlays,  int distinctTracks,  DateTime? firstPlayedAt,  DateTime? lastPlayedAt,  List<TrackPlays> topTracks,  List<ArtistPlays> topArtists,  List<AlbumPlays> topAlbums,  List<GenrePlays> topGenres)?  $default,) {final _that = this;
switch (_that) {
case _MusicStats() when $default != null:
return $default(_that.totalPlays,_that.distinctTracks,_that.firstPlayedAt,_that.lastPlayedAt,_that.topTracks,_that.topArtists,_that.topAlbums,_that.topGenres);case _:
  return null;

}
}

}

/// @nodoc


class _MusicStats extends MusicStats {
  const _MusicStats({required this.totalPlays, required this.distinctTracks, this.firstPlayedAt, this.lastPlayedAt, final  List<TrackPlays> topTracks = const [], final  List<ArtistPlays> topArtists = const [], final  List<AlbumPlays> topAlbums = const [], final  List<GenrePlays> topGenres = const []}): _topTracks = topTracks,_topArtists = topArtists,_topAlbums = topAlbums,_topGenres = topGenres,super._();
  

/// Every play ever recorded, including tracks carrying no tags.
@override final  int totalPlays;
/// How many distinct tracks those plays are spread across.
@override final  int distinctTracks;
/// The oldest and newest play, so the screen can say what period the
/// numbers cover. Both null when nothing has been played.
@override final  DateTime? firstPlayedAt;
@override final  DateTime? lastPlayedAt;
 final  List<TrackPlays> _topTracks;
@override@JsonKey() List<TrackPlays> get topTracks {
  if (_topTracks is EqualUnmodifiableListView) return _topTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTracks);
}

 final  List<ArtistPlays> _topArtists;
@override@JsonKey() List<ArtistPlays> get topArtists {
  if (_topArtists is EqualUnmodifiableListView) return _topArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topArtists);
}

 final  List<AlbumPlays> _topAlbums;
@override@JsonKey() List<AlbumPlays> get topAlbums {
  if (_topAlbums is EqualUnmodifiableListView) return _topAlbums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topAlbums);
}

 final  List<GenrePlays> _topGenres;
@override@JsonKey() List<GenrePlays> get topGenres {
  if (_topGenres is EqualUnmodifiableListView) return _topGenres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topGenres);
}


/// Create a copy of MusicStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicStatsCopyWith<_MusicStats> get copyWith => __$MusicStatsCopyWithImpl<_MusicStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicStats&&(identical(other.totalPlays, totalPlays) || other.totalPlays == totalPlays)&&(identical(other.distinctTracks, distinctTracks) || other.distinctTracks == distinctTracks)&&(identical(other.firstPlayedAt, firstPlayedAt) || other.firstPlayedAt == firstPlayedAt)&&(identical(other.lastPlayedAt, lastPlayedAt) || other.lastPlayedAt == lastPlayedAt)&&const DeepCollectionEquality().equals(other._topTracks, _topTracks)&&const DeepCollectionEquality().equals(other._topArtists, _topArtists)&&const DeepCollectionEquality().equals(other._topAlbums, _topAlbums)&&const DeepCollectionEquality().equals(other._topGenres, _topGenres));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlays,distinctTracks,firstPlayedAt,lastPlayedAt,const DeepCollectionEquality().hash(_topTracks),const DeepCollectionEquality().hash(_topArtists),const DeepCollectionEquality().hash(_topAlbums),const DeepCollectionEquality().hash(_topGenres));

@override
String toString() {
  return 'MusicStats(totalPlays: $totalPlays, distinctTracks: $distinctTracks, firstPlayedAt: $firstPlayedAt, lastPlayedAt: $lastPlayedAt, topTracks: $topTracks, topArtists: $topArtists, topAlbums: $topAlbums, topGenres: $topGenres)';
}


}

/// @nodoc
abstract mixin class _$MusicStatsCopyWith<$Res> implements $MusicStatsCopyWith<$Res> {
  factory _$MusicStatsCopyWith(_MusicStats value, $Res Function(_MusicStats) _then) = __$MusicStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalPlays, int distinctTracks, DateTime? firstPlayedAt, DateTime? lastPlayedAt, List<TrackPlays> topTracks, List<ArtistPlays> topArtists, List<AlbumPlays> topAlbums, List<GenrePlays> topGenres
});




}
/// @nodoc
class __$MusicStatsCopyWithImpl<$Res>
    implements _$MusicStatsCopyWith<$Res> {
  __$MusicStatsCopyWithImpl(this._self, this._then);

  final _MusicStats _self;
  final $Res Function(_MusicStats) _then;

/// Create a copy of MusicStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalPlays = null,Object? distinctTracks = null,Object? firstPlayedAt = freezed,Object? lastPlayedAt = freezed,Object? topTracks = null,Object? topArtists = null,Object? topAlbums = null,Object? topGenres = null,}) {
  return _then(_MusicStats(
totalPlays: null == totalPlays ? _self.totalPlays : totalPlays // ignore: cast_nullable_to_non_nullable
as int,distinctTracks: null == distinctTracks ? _self.distinctTracks : distinctTracks // ignore: cast_nullable_to_non_nullable
as int,firstPlayedAt: freezed == firstPlayedAt ? _self.firstPlayedAt : firstPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPlayedAt: freezed == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,topTracks: null == topTracks ? _self._topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<TrackPlays>,topArtists: null == topArtists ? _self._topArtists : topArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistPlays>,topAlbums: null == topAlbums ? _self._topAlbums : topAlbums // ignore: cast_nullable_to_non_nullable
as List<AlbumPlays>,topGenres: null == topGenres ? _self._topGenres : topGenres // ignore: cast_nullable_to_non_nullable
as List<GenrePlays>,
  ));
}


}

/// @nodoc
mixin _$TrackPlays {

 String get fileUuid;/// Its title, or its filename when nothing tagged it — the core has
/// already made that substitution, so this is never empty.
 String get title; int get plays; DateTime get lastPlayedAt; String? get artist; String? get album;
/// Create a copy of TrackPlays
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPlaysCopyWith<TrackPlays> get copyWith => _$TrackPlaysCopyWithImpl<TrackPlays>(this as TrackPlays, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPlays&&(identical(other.fileUuid, fileUuid) || other.fileUuid == fileUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.lastPlayedAt, lastPlayedAt) || other.lastPlayedAt == lastPlayedAt)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album));
}


@override
int get hashCode => Object.hash(runtimeType,fileUuid,title,plays,lastPlayedAt,artist,album);

@override
String toString() {
  return 'TrackPlays(fileUuid: $fileUuid, title: $title, plays: $plays, lastPlayedAt: $lastPlayedAt, artist: $artist, album: $album)';
}


}

/// @nodoc
abstract mixin class $TrackPlaysCopyWith<$Res>  {
  factory $TrackPlaysCopyWith(TrackPlays value, $Res Function(TrackPlays) _then) = _$TrackPlaysCopyWithImpl;
@useResult
$Res call({
 String fileUuid, String title, int plays, DateTime lastPlayedAt, String? artist, String? album
});




}
/// @nodoc
class _$TrackPlaysCopyWithImpl<$Res>
    implements $TrackPlaysCopyWith<$Res> {
  _$TrackPlaysCopyWithImpl(this._self, this._then);

  final TrackPlays _self;
  final $Res Function(TrackPlays) _then;

/// Create a copy of TrackPlays
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileUuid = null,Object? title = null,Object? plays = null,Object? lastPlayedAt = null,Object? artist = freezed,Object? album = freezed,}) {
  return _then(_self.copyWith(
fileUuid: null == fileUuid ? _self.fileUuid : fileUuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,lastPlayedAt: null == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackPlays].
extension TrackPlaysPatterns on TrackPlays {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackPlays value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackPlays() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackPlays value)  $default,){
final _that = this;
switch (_that) {
case _TrackPlays():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackPlays value)?  $default,){
final _that = this;
switch (_that) {
case _TrackPlays() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileUuid,  String title,  int plays,  DateTime lastPlayedAt,  String? artist,  String? album)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackPlays() when $default != null:
return $default(_that.fileUuid,_that.title,_that.plays,_that.lastPlayedAt,_that.artist,_that.album);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileUuid,  String title,  int plays,  DateTime lastPlayedAt,  String? artist,  String? album)  $default,) {final _that = this;
switch (_that) {
case _TrackPlays():
return $default(_that.fileUuid,_that.title,_that.plays,_that.lastPlayedAt,_that.artist,_that.album);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileUuid,  String title,  int plays,  DateTime lastPlayedAt,  String? artist,  String? album)?  $default,) {final _that = this;
switch (_that) {
case _TrackPlays() when $default != null:
return $default(_that.fileUuid,_that.title,_that.plays,_that.lastPlayedAt,_that.artist,_that.album);case _:
  return null;

}
}

}

/// @nodoc


class _TrackPlays implements TrackPlays {
  const _TrackPlays({required this.fileUuid, required this.title, required this.plays, required this.lastPlayedAt, this.artist, this.album});
  

@override final  String fileUuid;
/// Its title, or its filename when nothing tagged it — the core has
/// already made that substitution, so this is never empty.
@override final  String title;
@override final  int plays;
@override final  DateTime lastPlayedAt;
@override final  String? artist;
@override final  String? album;

/// Create a copy of TrackPlays
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackPlaysCopyWith<_TrackPlays> get copyWith => __$TrackPlaysCopyWithImpl<_TrackPlays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackPlays&&(identical(other.fileUuid, fileUuid) || other.fileUuid == fileUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.lastPlayedAt, lastPlayedAt) || other.lastPlayedAt == lastPlayedAt)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album));
}


@override
int get hashCode => Object.hash(runtimeType,fileUuid,title,plays,lastPlayedAt,artist,album);

@override
String toString() {
  return 'TrackPlays(fileUuid: $fileUuid, title: $title, plays: $plays, lastPlayedAt: $lastPlayedAt, artist: $artist, album: $album)';
}


}

/// @nodoc
abstract mixin class _$TrackPlaysCopyWith<$Res> implements $TrackPlaysCopyWith<$Res> {
  factory _$TrackPlaysCopyWith(_TrackPlays value, $Res Function(_TrackPlays) _then) = __$TrackPlaysCopyWithImpl;
@override @useResult
$Res call({
 String fileUuid, String title, int plays, DateTime lastPlayedAt, String? artist, String? album
});




}
/// @nodoc
class __$TrackPlaysCopyWithImpl<$Res>
    implements _$TrackPlaysCopyWith<$Res> {
  __$TrackPlaysCopyWithImpl(this._self, this._then);

  final _TrackPlays _self;
  final $Res Function(_TrackPlays) _then;

/// Create a copy of TrackPlays
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileUuid = null,Object? title = null,Object? plays = null,Object? lastPlayedAt = null,Object? artist = freezed,Object? album = freezed,}) {
  return _then(_TrackPlays(
fileUuid: null == fileUuid ? _self.fileUuid : fileUuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,lastPlayedAt: null == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ArtistPlays {

 String get artist; int get plays;/// How many distinct tracks of theirs were played — what tells a deep
/// catalogue apart from one song on repeat.
 int get tracks;
/// Create a copy of ArtistPlays
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistPlaysCopyWith<ArtistPlays> get copyWith => _$ArtistPlaysCopyWithImpl<ArtistPlays>(this as ArtistPlays, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistPlays&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.tracks, tracks) || other.tracks == tracks));
}


@override
int get hashCode => Object.hash(runtimeType,artist,plays,tracks);

@override
String toString() {
  return 'ArtistPlays(artist: $artist, plays: $plays, tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class $ArtistPlaysCopyWith<$Res>  {
  factory $ArtistPlaysCopyWith(ArtistPlays value, $Res Function(ArtistPlays) _then) = _$ArtistPlaysCopyWithImpl;
@useResult
$Res call({
 String artist, int plays, int tracks
});




}
/// @nodoc
class _$ArtistPlaysCopyWithImpl<$Res>
    implements $ArtistPlaysCopyWith<$Res> {
  _$ArtistPlaysCopyWithImpl(this._self, this._then);

  final ArtistPlays _self;
  final $Res Function(ArtistPlays) _then;

/// Create a copy of ArtistPlays
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? plays = null,Object? tracks = null,}) {
  return _then(_self.copyWith(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistPlays].
extension ArtistPlaysPatterns on ArtistPlays {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistPlays value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistPlays() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistPlays value)  $default,){
final _that = this;
switch (_that) {
case _ArtistPlays():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistPlays value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistPlays() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String artist,  int plays,  int tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistPlays() when $default != null:
return $default(_that.artist,_that.plays,_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String artist,  int plays,  int tracks)  $default,) {final _that = this;
switch (_that) {
case _ArtistPlays():
return $default(_that.artist,_that.plays,_that.tracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String artist,  int plays,  int tracks)?  $default,) {final _that = this;
switch (_that) {
case _ArtistPlays() when $default != null:
return $default(_that.artist,_that.plays,_that.tracks);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistPlays implements ArtistPlays {
  const _ArtistPlays({required this.artist, required this.plays, required this.tracks});
  

@override final  String artist;
@override final  int plays;
/// How many distinct tracks of theirs were played — what tells a deep
/// catalogue apart from one song on repeat.
@override final  int tracks;

/// Create a copy of ArtistPlays
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistPlaysCopyWith<_ArtistPlays> get copyWith => __$ArtistPlaysCopyWithImpl<_ArtistPlays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistPlays&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.tracks, tracks) || other.tracks == tracks));
}


@override
int get hashCode => Object.hash(runtimeType,artist,plays,tracks);

@override
String toString() {
  return 'ArtistPlays(artist: $artist, plays: $plays, tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$ArtistPlaysCopyWith<$Res> implements $ArtistPlaysCopyWith<$Res> {
  factory _$ArtistPlaysCopyWith(_ArtistPlays value, $Res Function(_ArtistPlays) _then) = __$ArtistPlaysCopyWithImpl;
@override @useResult
$Res call({
 String artist, int plays, int tracks
});




}
/// @nodoc
class __$ArtistPlaysCopyWithImpl<$Res>
    implements _$ArtistPlaysCopyWith<$Res> {
  __$ArtistPlaysCopyWithImpl(this._self, this._then);

  final _ArtistPlays _self;
  final $Res Function(_ArtistPlays) _then;

/// Create a copy of ArtistPlays
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artist = null,Object? plays = null,Object? tracks = null,}) {
  return _then(_ArtistPlays(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AlbumPlays {

 String get album; int get plays;/// Whose album it is, when every played track that names an artist
/// agrees. Null for a compilation whose tracks disagree — there is no
/// single answer, and naming one of them would be picking arbitrarily.
 String? get artist;
/// Create a copy of AlbumPlays
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumPlaysCopyWith<AlbumPlays> get copyWith => _$AlbumPlaysCopyWithImpl<AlbumPlays>(this as AlbumPlays, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumPlays&&(identical(other.album, album) || other.album == album)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.artist, artist) || other.artist == artist));
}


@override
int get hashCode => Object.hash(runtimeType,album,plays,artist);

@override
String toString() {
  return 'AlbumPlays(album: $album, plays: $plays, artist: $artist)';
}


}

/// @nodoc
abstract mixin class $AlbumPlaysCopyWith<$Res>  {
  factory $AlbumPlaysCopyWith(AlbumPlays value, $Res Function(AlbumPlays) _then) = _$AlbumPlaysCopyWithImpl;
@useResult
$Res call({
 String album, int plays, String? artist
});




}
/// @nodoc
class _$AlbumPlaysCopyWithImpl<$Res>
    implements $AlbumPlaysCopyWith<$Res> {
  _$AlbumPlaysCopyWithImpl(this._self, this._then);

  final AlbumPlays _self;
  final $Res Function(AlbumPlays) _then;

/// Create a copy of AlbumPlays
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? plays = null,Object? artist = freezed,}) {
  return _then(_self.copyWith(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumPlays].
extension AlbumPlaysPatterns on AlbumPlays {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumPlays value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumPlays() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumPlays value)  $default,){
final _that = this;
switch (_that) {
case _AlbumPlays():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumPlays value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumPlays() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String album,  int plays,  String? artist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumPlays() when $default != null:
return $default(_that.album,_that.plays,_that.artist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String album,  int plays,  String? artist)  $default,) {final _that = this;
switch (_that) {
case _AlbumPlays():
return $default(_that.album,_that.plays,_that.artist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String album,  int plays,  String? artist)?  $default,) {final _that = this;
switch (_that) {
case _AlbumPlays() when $default != null:
return $default(_that.album,_that.plays,_that.artist);case _:
  return null;

}
}

}

/// @nodoc


class _AlbumPlays implements AlbumPlays {
  const _AlbumPlays({required this.album, required this.plays, this.artist});
  

@override final  String album;
@override final  int plays;
/// Whose album it is, when every played track that names an artist
/// agrees. Null for a compilation whose tracks disagree — there is no
/// single answer, and naming one of them would be picking arbitrarily.
@override final  String? artist;

/// Create a copy of AlbumPlays
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumPlaysCopyWith<_AlbumPlays> get copyWith => __$AlbumPlaysCopyWithImpl<_AlbumPlays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumPlays&&(identical(other.album, album) || other.album == album)&&(identical(other.plays, plays) || other.plays == plays)&&(identical(other.artist, artist) || other.artist == artist));
}


@override
int get hashCode => Object.hash(runtimeType,album,plays,artist);

@override
String toString() {
  return 'AlbumPlays(album: $album, plays: $plays, artist: $artist)';
}


}

/// @nodoc
abstract mixin class _$AlbumPlaysCopyWith<$Res> implements $AlbumPlaysCopyWith<$Res> {
  factory _$AlbumPlaysCopyWith(_AlbumPlays value, $Res Function(_AlbumPlays) _then) = __$AlbumPlaysCopyWithImpl;
@override @useResult
$Res call({
 String album, int plays, String? artist
});




}
/// @nodoc
class __$AlbumPlaysCopyWithImpl<$Res>
    implements _$AlbumPlaysCopyWith<$Res> {
  __$AlbumPlaysCopyWithImpl(this._self, this._then);

  final _AlbumPlays _self;
  final $Res Function(_AlbumPlays) _then;

/// Create a copy of AlbumPlays
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? album = null,Object? plays = null,Object? artist = freezed,}) {
  return _then(_AlbumPlays(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$GenrePlays {

 String get genre; int get plays;
/// Create a copy of GenrePlays
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenrePlaysCopyWith<GenrePlays> get copyWith => _$GenrePlaysCopyWithImpl<GenrePlays>(this as GenrePlays, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenrePlays&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.plays, plays) || other.plays == plays));
}


@override
int get hashCode => Object.hash(runtimeType,genre,plays);

@override
String toString() {
  return 'GenrePlays(genre: $genre, plays: $plays)';
}


}

/// @nodoc
abstract mixin class $GenrePlaysCopyWith<$Res>  {
  factory $GenrePlaysCopyWith(GenrePlays value, $Res Function(GenrePlays) _then) = _$GenrePlaysCopyWithImpl;
@useResult
$Res call({
 String genre, int plays
});




}
/// @nodoc
class _$GenrePlaysCopyWithImpl<$Res>
    implements $GenrePlaysCopyWith<$Res> {
  _$GenrePlaysCopyWithImpl(this._self, this._then);

  final GenrePlays _self;
  final $Res Function(GenrePlays) _then;

/// Create a copy of GenrePlays
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? genre = null,Object? plays = null,}) {
  return _then(_self.copyWith(
genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GenrePlays].
extension GenrePlaysPatterns on GenrePlays {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenrePlays value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenrePlays() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenrePlays value)  $default,){
final _that = this;
switch (_that) {
case _GenrePlays():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenrePlays value)?  $default,){
final _that = this;
switch (_that) {
case _GenrePlays() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String genre,  int plays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GenrePlays() when $default != null:
return $default(_that.genre,_that.plays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String genre,  int plays)  $default,) {final _that = this;
switch (_that) {
case _GenrePlays():
return $default(_that.genre,_that.plays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String genre,  int plays)?  $default,) {final _that = this;
switch (_that) {
case _GenrePlays() when $default != null:
return $default(_that.genre,_that.plays);case _:
  return null;

}
}

}

/// @nodoc


class _GenrePlays implements GenrePlays {
  const _GenrePlays({required this.genre, required this.plays});
  

@override final  String genre;
@override final  int plays;

/// Create a copy of GenrePlays
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenrePlaysCopyWith<_GenrePlays> get copyWith => __$GenrePlaysCopyWithImpl<_GenrePlays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenrePlays&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.plays, plays) || other.plays == plays));
}


@override
int get hashCode => Object.hash(runtimeType,genre,plays);

@override
String toString() {
  return 'GenrePlays(genre: $genre, plays: $plays)';
}


}

/// @nodoc
abstract mixin class _$GenrePlaysCopyWith<$Res> implements $GenrePlaysCopyWith<$Res> {
  factory _$GenrePlaysCopyWith(_GenrePlays value, $Res Function(_GenrePlays) _then) = __$GenrePlaysCopyWithImpl;
@override @useResult
$Res call({
 String genre, int plays
});




}
/// @nodoc
class __$GenrePlaysCopyWithImpl<$Res>
    implements _$GenrePlaysCopyWith<$Res> {
  __$GenrePlaysCopyWithImpl(this._self, this._then);

  final _GenrePlays _self;
  final $Res Function(_GenrePlays) _then;

/// Create a copy of GenrePlays
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? genre = null,Object? plays = null,}) {
  return _then(_GenrePlays(
genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
