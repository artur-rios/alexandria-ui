// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watchlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WatchProgress {

 String get watchlistUuid; String get videoUuid; WatchState get state; int? get currentEpisode; int? get totalEpisodes;
/// Create a copy of WatchProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchProgressCopyWith<WatchProgress> get copyWith => _$WatchProgressCopyWithImpl<WatchProgress>(this as WatchProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchProgress&&(identical(other.watchlistUuid, watchlistUuid) || other.watchlistUuid == watchlistUuid)&&(identical(other.videoUuid, videoUuid) || other.videoUuid == videoUuid)&&(identical(other.state, state) || other.state == state)&&(identical(other.currentEpisode, currentEpisode) || other.currentEpisode == currentEpisode)&&(identical(other.totalEpisodes, totalEpisodes) || other.totalEpisodes == totalEpisodes));
}


@override
int get hashCode => Object.hash(runtimeType,watchlistUuid,videoUuid,state,currentEpisode,totalEpisodes);

@override
String toString() {
  return 'WatchProgress(watchlistUuid: $watchlistUuid, videoUuid: $videoUuid, state: $state, currentEpisode: $currentEpisode, totalEpisodes: $totalEpisodes)';
}


}

/// @nodoc
abstract mixin class $WatchProgressCopyWith<$Res>  {
  factory $WatchProgressCopyWith(WatchProgress value, $Res Function(WatchProgress) _then) = _$WatchProgressCopyWithImpl;
@useResult
$Res call({
 String watchlistUuid, String videoUuid, WatchState state, int? currentEpisode, int? totalEpisodes
});




}
/// @nodoc
class _$WatchProgressCopyWithImpl<$Res>
    implements $WatchProgressCopyWith<$Res> {
  _$WatchProgressCopyWithImpl(this._self, this._then);

  final WatchProgress _self;
  final $Res Function(WatchProgress) _then;

/// Create a copy of WatchProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? watchlistUuid = null,Object? videoUuid = null,Object? state = null,Object? currentEpisode = freezed,Object? totalEpisodes = freezed,}) {
  return _then(_self.copyWith(
watchlistUuid: null == watchlistUuid ? _self.watchlistUuid : watchlistUuid // ignore: cast_nullable_to_non_nullable
as String,videoUuid: null == videoUuid ? _self.videoUuid : videoUuid // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as WatchState,currentEpisode: freezed == currentEpisode ? _self.currentEpisode : currentEpisode // ignore: cast_nullable_to_non_nullable
as int?,totalEpisodes: freezed == totalEpisodes ? _self.totalEpisodes : totalEpisodes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchProgress].
extension WatchProgressPatterns on WatchProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchProgress value)  $default,){
final _that = this;
switch (_that) {
case _WatchProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchProgress value)?  $default,){
final _that = this;
switch (_that) {
case _WatchProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String watchlistUuid,  String videoUuid,  WatchState state,  int? currentEpisode,  int? totalEpisodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchProgress() when $default != null:
return $default(_that.watchlistUuid,_that.videoUuid,_that.state,_that.currentEpisode,_that.totalEpisodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String watchlistUuid,  String videoUuid,  WatchState state,  int? currentEpisode,  int? totalEpisodes)  $default,) {final _that = this;
switch (_that) {
case _WatchProgress():
return $default(_that.watchlistUuid,_that.videoUuid,_that.state,_that.currentEpisode,_that.totalEpisodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String watchlistUuid,  String videoUuid,  WatchState state,  int? currentEpisode,  int? totalEpisodes)?  $default,) {final _that = this;
switch (_that) {
case _WatchProgress() when $default != null:
return $default(_that.watchlistUuid,_that.videoUuid,_that.state,_that.currentEpisode,_that.totalEpisodes);case _:
  return null;

}
}

}

/// @nodoc


class _WatchProgress extends WatchProgress {
  const _WatchProgress({required this.watchlistUuid, required this.videoUuid, required this.state, this.currentEpisode, this.totalEpisodes}): super._();
  

@override final  String watchlistUuid;
@override final  String videoUuid;
@override final  WatchState state;
@override final  int? currentEpisode;
@override final  int? totalEpisodes;

/// Create a copy of WatchProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchProgressCopyWith<_WatchProgress> get copyWith => __$WatchProgressCopyWithImpl<_WatchProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchProgress&&(identical(other.watchlistUuid, watchlistUuid) || other.watchlistUuid == watchlistUuid)&&(identical(other.videoUuid, videoUuid) || other.videoUuid == videoUuid)&&(identical(other.state, state) || other.state == state)&&(identical(other.currentEpisode, currentEpisode) || other.currentEpisode == currentEpisode)&&(identical(other.totalEpisodes, totalEpisodes) || other.totalEpisodes == totalEpisodes));
}


@override
int get hashCode => Object.hash(runtimeType,watchlistUuid,videoUuid,state,currentEpisode,totalEpisodes);

@override
String toString() {
  return 'WatchProgress(watchlistUuid: $watchlistUuid, videoUuid: $videoUuid, state: $state, currentEpisode: $currentEpisode, totalEpisodes: $totalEpisodes)';
}


}

/// @nodoc
abstract mixin class _$WatchProgressCopyWith<$Res> implements $WatchProgressCopyWith<$Res> {
  factory _$WatchProgressCopyWith(_WatchProgress value, $Res Function(_WatchProgress) _then) = __$WatchProgressCopyWithImpl;
@override @useResult
$Res call({
 String watchlistUuid, String videoUuid, WatchState state, int? currentEpisode, int? totalEpisodes
});




}
/// @nodoc
class __$WatchProgressCopyWithImpl<$Res>
    implements _$WatchProgressCopyWith<$Res> {
  __$WatchProgressCopyWithImpl(this._self, this._then);

  final _WatchProgress _self;
  final $Res Function(_WatchProgress) _then;

/// Create a copy of WatchProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? watchlistUuid = null,Object? videoUuid = null,Object? state = null,Object? currentEpisode = freezed,Object? totalEpisodes = freezed,}) {
  return _then(_WatchProgress(
watchlistUuid: null == watchlistUuid ? _self.watchlistUuid : watchlistUuid // ignore: cast_nullable_to_non_nullable
as String,videoUuid: null == videoUuid ? _self.videoUuid : videoUuid // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as WatchState,currentEpisode: freezed == currentEpisode ? _self.currentEpisode : currentEpisode // ignore: cast_nullable_to_non_nullable
as int?,totalEpisodes: freezed == totalEpisodes ? _self.totalEpisodes : totalEpisodes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$Watchlist {

 String get uuid; String get name; List<WatchProgress> get items;
/// Create a copy of Watchlist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchlistCopyWith<Watchlist> get copyWith => _$WatchlistCopyWithImpl<Watchlist>(this as Watchlist, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Watchlist&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'Watchlist(uuid: $uuid, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class $WatchlistCopyWith<$Res>  {
  factory $WatchlistCopyWith(Watchlist value, $Res Function(Watchlist) _then) = _$WatchlistCopyWithImpl;
@useResult
$Res call({
 String uuid, String name, List<WatchProgress> items
});




}
/// @nodoc
class _$WatchlistCopyWithImpl<$Res>
    implements $WatchlistCopyWith<$Res> {
  _$WatchlistCopyWithImpl(this._self, this._then);

  final Watchlist _self;
  final $Res Function(Watchlist) _then;

/// Create a copy of Watchlist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? items = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<WatchProgress>,
  ));
}

}


/// Adds pattern-matching-related methods to [Watchlist].
extension WatchlistPatterns on Watchlist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Watchlist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Watchlist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Watchlist value)  $default,){
final _that = this;
switch (_that) {
case _Watchlist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Watchlist value)?  $default,){
final _that = this;
switch (_that) {
case _Watchlist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name,  List<WatchProgress> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Watchlist() when $default != null:
return $default(_that.uuid,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name,  List<WatchProgress> items)  $default,) {final _that = this;
switch (_that) {
case _Watchlist():
return $default(_that.uuid,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name,  List<WatchProgress> items)?  $default,) {final _that = this;
switch (_that) {
case _Watchlist() when $default != null:
return $default(_that.uuid,_that.name,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _Watchlist extends Watchlist {
  const _Watchlist({required this.uuid, required this.name, final  List<WatchProgress> items = const <WatchProgress>[]}): _items = items,super._();
  

@override final  String uuid;
@override final  String name;
 final  List<WatchProgress> _items;
@override@JsonKey() List<WatchProgress> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of Watchlist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchlistCopyWith<_Watchlist> get copyWith => __$WatchlistCopyWithImpl<_Watchlist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Watchlist&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'Watchlist(uuid: $uuid, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class _$WatchlistCopyWith<$Res> implements $WatchlistCopyWith<$Res> {
  factory _$WatchlistCopyWith(_Watchlist value, $Res Function(_Watchlist) _then) = __$WatchlistCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name, List<WatchProgress> items
});




}
/// @nodoc
class __$WatchlistCopyWithImpl<$Res>
    implements _$WatchlistCopyWith<$Res> {
  __$WatchlistCopyWithImpl(this._self, this._then);

  final _Watchlist _self;
  final $Res Function(_Watchlist) _then;

/// Create a copy of Watchlist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? items = null,}) {
  return _then(_Watchlist(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<WatchProgress>,
  ));
}


}

// dart format on
