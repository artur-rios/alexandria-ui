// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watchlist_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WatchlistBrowse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistBrowse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistBrowse()';
}


}

/// @nodoc
class $WatchlistBrowseCopyWith<$Res>  {
$WatchlistBrowseCopyWith(WatchlistBrowse _, $Res Function(WatchlistBrowse) __);
}


/// Adds pattern-matching-related methods to [WatchlistBrowse].
extension WatchlistBrowsePatterns on WatchlistBrowse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WatchlistBrowseLoaded value)?  loaded,TResult Function( WatchlistBrowseFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WatchlistBrowseLoaded() when loaded != null:
return loaded(_that);case WatchlistBrowseFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WatchlistBrowseLoaded value)  loaded,required TResult Function( WatchlistBrowseFailed value)  failed,}){
final _that = this;
switch (_that) {
case WatchlistBrowseLoaded():
return loaded(_that);case WatchlistBrowseFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WatchlistBrowseLoaded value)?  loaded,TResult? Function( WatchlistBrowseFailed value)?  failed,}){
final _that = this;
switch (_that) {
case WatchlistBrowseLoaded() when loaded != null:
return loaded(_that);case WatchlistBrowseFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Watchlist> watchlists)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WatchlistBrowseLoaded() when loaded != null:
return loaded(_that.watchlists);case WatchlistBrowseFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Watchlist> watchlists)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case WatchlistBrowseLoaded():
return loaded(_that.watchlists);case WatchlistBrowseFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Watchlist> watchlists)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case WatchlistBrowseLoaded() when loaded != null:
return loaded(_that.watchlists);case WatchlistBrowseFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WatchlistBrowseLoaded implements WatchlistBrowse {
  const WatchlistBrowseLoaded({required final  List<Watchlist> watchlists}): _watchlists = watchlists;
  

 final  List<Watchlist> _watchlists;
 List<Watchlist> get watchlists {
  if (_watchlists is EqualUnmodifiableListView) return _watchlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_watchlists);
}


/// Create a copy of WatchlistBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchlistBrowseLoadedCopyWith<WatchlistBrowseLoaded> get copyWith => _$WatchlistBrowseLoadedCopyWithImpl<WatchlistBrowseLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistBrowseLoaded&&const DeepCollectionEquality().equals(other._watchlists, _watchlists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_watchlists));

@override
String toString() {
  return 'WatchlistBrowse.loaded(watchlists: $watchlists)';
}


}

/// @nodoc
abstract mixin class $WatchlistBrowseLoadedCopyWith<$Res> implements $WatchlistBrowseCopyWith<$Res> {
  factory $WatchlistBrowseLoadedCopyWith(WatchlistBrowseLoaded value, $Res Function(WatchlistBrowseLoaded) _then) = _$WatchlistBrowseLoadedCopyWithImpl;
@useResult
$Res call({
 List<Watchlist> watchlists
});




}
/// @nodoc
class _$WatchlistBrowseLoadedCopyWithImpl<$Res>
    implements $WatchlistBrowseLoadedCopyWith<$Res> {
  _$WatchlistBrowseLoadedCopyWithImpl(this._self, this._then);

  final WatchlistBrowseLoaded _self;
  final $Res Function(WatchlistBrowseLoaded) _then;

/// Create a copy of WatchlistBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? watchlists = null,}) {
  return _then(WatchlistBrowseLoaded(
watchlists: null == watchlists ? _self._watchlists : watchlists // ignore: cast_nullable_to_non_nullable
as List<Watchlist>,
  ));
}


}

/// @nodoc


class WatchlistBrowseFailed implements WatchlistBrowse {
  const WatchlistBrowseFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of WatchlistBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchlistBrowseFailedCopyWith<WatchlistBrowseFailed> get copyWith => _$WatchlistBrowseFailedCopyWithImpl<WatchlistBrowseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistBrowseFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WatchlistBrowse.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WatchlistBrowseFailedCopyWith<$Res> implements $WatchlistBrowseCopyWith<$Res> {
  factory $WatchlistBrowseFailedCopyWith(WatchlistBrowseFailed value, $Res Function(WatchlistBrowseFailed) _then) = _$WatchlistBrowseFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WatchlistBrowseFailedCopyWithImpl<$Res>
    implements $WatchlistBrowseFailedCopyWith<$Res> {
  _$WatchlistBrowseFailedCopyWithImpl(this._self, this._then);

  final WatchlistBrowseFailed _self;
  final $Res Function(WatchlistBrowseFailed) _then;

/// Create a copy of WatchlistBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WatchlistBrowseFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WatchlistBrowse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$WatchlistWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistWrite()';
}


}

/// @nodoc
class $WatchlistWriteCopyWith<$Res>  {
$WatchlistWriteCopyWith(WatchlistWrite _, $Res Function(WatchlistWrite) __);
}


/// Adds pattern-matching-related methods to [WatchlistWrite].
extension WatchlistWritePatterns on WatchlistWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WatchlistWriteDone value)?  done,TResult Function( WatchlistWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WatchlistWriteDone() when done != null:
return done(_that);case WatchlistWriteFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WatchlistWriteDone value)  done,required TResult Function( WatchlistWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case WatchlistWriteDone():
return done(_that);case WatchlistWriteFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WatchlistWriteDone value)?  done,TResult? Function( WatchlistWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case WatchlistWriteDone() when done != null:
return done(_that);case WatchlistWriteFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  done,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WatchlistWriteDone() when done != null:
return done();case WatchlistWriteFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  done,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case WatchlistWriteDone():
return done();case WatchlistWriteFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  done,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case WatchlistWriteDone() when done != null:
return done();case WatchlistWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WatchlistWriteDone implements WatchlistWrite {
  const WatchlistWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WatchlistWrite.done()';
}


}




/// @nodoc


class WatchlistWriteFailed implements WatchlistWrite {
  const WatchlistWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of WatchlistWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchlistWriteFailedCopyWith<WatchlistWriteFailed> get copyWith => _$WatchlistWriteFailedCopyWithImpl<WatchlistWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WatchlistWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WatchlistWriteFailedCopyWith<$Res> implements $WatchlistWriteCopyWith<$Res> {
  factory $WatchlistWriteFailedCopyWith(WatchlistWriteFailed value, $Res Function(WatchlistWriteFailed) _then) = _$WatchlistWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WatchlistWriteFailedCopyWithImpl<$Res>
    implements $WatchlistWriteFailedCopyWith<$Res> {
  _$WatchlistWriteFailedCopyWithImpl(this._self, this._then);

  final WatchlistWriteFailed _self;
  final $Res Function(WatchlistWriteFailed) _then;

/// Create a copy of WatchlistWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WatchlistWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WatchlistWrite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
