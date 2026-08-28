// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistBrowse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistBrowse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistBrowse()';
}


}

/// @nodoc
class $PlaylistBrowseCopyWith<$Res>  {
$PlaylistBrowseCopyWith(PlaylistBrowse _, $Res Function(PlaylistBrowse) __);
}


/// Adds pattern-matching-related methods to [PlaylistBrowse].
extension PlaylistBrowsePatterns on PlaylistBrowse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistBrowseLoaded value)?  loaded,TResult Function( PlaylistBrowseFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistBrowseLoaded() when loaded != null:
return loaded(_that);case PlaylistBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistBrowseLoaded value)  loaded,required TResult Function( PlaylistBrowseFailed value)  failed,}){
final _that = this;
switch (_that) {
case PlaylistBrowseLoaded():
return loaded(_that);case PlaylistBrowseFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistBrowseLoaded value)?  loaded,TResult? Function( PlaylistBrowseFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PlaylistBrowseLoaded() when loaded != null:
return loaded(_that);case PlaylistBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Playlist> playlists)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistBrowseLoaded() when loaded != null:
return loaded(_that.playlists);case PlaylistBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Playlist> playlists)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case PlaylistBrowseLoaded():
return loaded(_that.playlists);case PlaylistBrowseFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Playlist> playlists)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case PlaylistBrowseLoaded() when loaded != null:
return loaded(_that.playlists);case PlaylistBrowseFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistBrowseLoaded implements PlaylistBrowse {
  const PlaylistBrowseLoaded({required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistBrowseLoadedCopyWith<PlaylistBrowseLoaded> get copyWith => _$PlaylistBrowseLoadedCopyWithImpl<PlaylistBrowseLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistBrowseLoaded&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistBrowse.loaded(playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PlaylistBrowseLoadedCopyWith<$Res> implements $PlaylistBrowseCopyWith<$Res> {
  factory $PlaylistBrowseLoadedCopyWith(PlaylistBrowseLoaded value, $Res Function(PlaylistBrowseLoaded) _then) = _$PlaylistBrowseLoadedCopyWithImpl;
@useResult
$Res call({
 List<Playlist> playlists
});




}
/// @nodoc
class _$PlaylistBrowseLoadedCopyWithImpl<$Res>
    implements $PlaylistBrowseLoadedCopyWith<$Res> {
  _$PlaylistBrowseLoadedCopyWithImpl(this._self, this._then);

  final PlaylistBrowseLoaded _self;
  final $Res Function(PlaylistBrowseLoaded) _then;

/// Create a copy of PlaylistBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlists = null,}) {
  return _then(PlaylistBrowseLoaded(
playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class PlaylistBrowseFailed implements PlaylistBrowse {
  const PlaylistBrowseFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of PlaylistBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistBrowseFailedCopyWith<PlaylistBrowseFailed> get copyWith => _$PlaylistBrowseFailedCopyWithImpl<PlaylistBrowseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistBrowseFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlaylistBrowse.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaylistBrowseFailedCopyWith<$Res> implements $PlaylistBrowseCopyWith<$Res> {
  factory $PlaylistBrowseFailedCopyWith(PlaylistBrowseFailed value, $Res Function(PlaylistBrowseFailed) _then) = _$PlaylistBrowseFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaylistBrowseFailedCopyWithImpl<$Res>
    implements $PlaylistBrowseFailedCopyWith<$Res> {
  _$PlaylistBrowseFailedCopyWithImpl(this._self, this._then);

  final PlaylistBrowseFailed _self;
  final $Res Function(PlaylistBrowseFailed) _then;

/// Create a copy of PlaylistBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaylistBrowseFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaylistBrowse
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
mixin _$PlaylistRead {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistRead);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistRead()';
}


}

/// @nodoc
class $PlaylistReadCopyWith<$Res>  {
$PlaylistReadCopyWith(PlaylistRead _, $Res Function(PlaylistRead) __);
}


/// Adds pattern-matching-related methods to [PlaylistRead].
extension PlaylistReadPatterns on PlaylistRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistReadLoaded value)?  loaded,TResult Function( PlaylistReadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistReadLoaded() when loaded != null:
return loaded(_that);case PlaylistReadFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistReadLoaded value)  loaded,required TResult Function( PlaylistReadFailed value)  failed,}){
final _that = this;
switch (_that) {
case PlaylistReadLoaded():
return loaded(_that);case PlaylistReadFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistReadLoaded value)?  loaded,TResult? Function( PlaylistReadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PlaylistReadLoaded() when loaded != null:
return loaded(_that);case PlaylistReadFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PlaylistView view)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistReadLoaded() when loaded != null:
return loaded(_that.view);case PlaylistReadFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PlaylistView view)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case PlaylistReadLoaded():
return loaded(_that.view);case PlaylistReadFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PlaylistView view)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case PlaylistReadLoaded() when loaded != null:
return loaded(_that.view);case PlaylistReadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistReadLoaded implements PlaylistRead {
  const PlaylistReadLoaded({required this.view});
  

 final  PlaylistView view;

/// Create a copy of PlaylistRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistReadLoadedCopyWith<PlaylistReadLoaded> get copyWith => _$PlaylistReadLoadedCopyWithImpl<PlaylistReadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistReadLoaded&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'PlaylistRead.loaded(view: $view)';
}


}

/// @nodoc
abstract mixin class $PlaylistReadLoadedCopyWith<$Res> implements $PlaylistReadCopyWith<$Res> {
  factory $PlaylistReadLoadedCopyWith(PlaylistReadLoaded value, $Res Function(PlaylistReadLoaded) _then) = _$PlaylistReadLoadedCopyWithImpl;
@useResult
$Res call({
 PlaylistView view
});


$PlaylistViewCopyWith<$Res> get view;

}
/// @nodoc
class _$PlaylistReadLoadedCopyWithImpl<$Res>
    implements $PlaylistReadLoadedCopyWith<$Res> {
  _$PlaylistReadLoadedCopyWithImpl(this._self, this._then);

  final PlaylistReadLoaded _self;
  final $Res Function(PlaylistReadLoaded) _then;

/// Create a copy of PlaylistRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(PlaylistReadLoaded(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as PlaylistView,
  ));
}

/// Create a copy of PlaylistRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistViewCopyWith<$Res> get view {
  
  return $PlaylistViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class PlaylistReadFailed implements PlaylistRead {
  const PlaylistReadFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of PlaylistRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistReadFailedCopyWith<PlaylistReadFailed> get copyWith => _$PlaylistReadFailedCopyWithImpl<PlaylistReadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistReadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlaylistRead.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaylistReadFailedCopyWith<$Res> implements $PlaylistReadCopyWith<$Res> {
  factory $PlaylistReadFailedCopyWith(PlaylistReadFailed value, $Res Function(PlaylistReadFailed) _then) = _$PlaylistReadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaylistReadFailedCopyWithImpl<$Res>
    implements $PlaylistReadFailedCopyWith<$Res> {
  _$PlaylistReadFailedCopyWithImpl(this._self, this._then);

  final PlaylistReadFailed _self;
  final $Res Function(PlaylistReadFailed) _then;

/// Create a copy of PlaylistRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaylistReadFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaylistRead
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
mixin _$PlaylistWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistWrite()';
}


}

/// @nodoc
class $PlaylistWriteCopyWith<$Res>  {
$PlaylistWriteCopyWith(PlaylistWrite _, $Res Function(PlaylistWrite) __);
}


/// Adds pattern-matching-related methods to [PlaylistWrite].
extension PlaylistWritePatterns on PlaylistWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistWriteDone value)?  done,TResult Function( PlaylistWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistWriteDone() when done != null:
return done(_that);case PlaylistWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistWriteDone value)  done,required TResult Function( PlaylistWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case PlaylistWriteDone():
return done(_that);case PlaylistWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistWriteDone value)?  done,TResult? Function( PlaylistWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PlaylistWriteDone() when done != null:
return done(_that);case PlaylistWriteFailed() when failed != null:
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
case PlaylistWriteDone() when done != null:
return done();case PlaylistWriteFailed() when failed != null:
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
case PlaylistWriteDone():
return done();case PlaylistWriteFailed():
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
case PlaylistWriteDone() when done != null:
return done();case PlaylistWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistWriteDone implements PlaylistWrite {
  const PlaylistWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistWrite.done()';
}


}




/// @nodoc


class PlaylistWriteFailed implements PlaylistWrite {
  const PlaylistWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of PlaylistWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistWriteFailedCopyWith<PlaylistWriteFailed> get copyWith => _$PlaylistWriteFailedCopyWithImpl<PlaylistWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlaylistWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaylistWriteFailedCopyWith<$Res> implements $PlaylistWriteCopyWith<$Res> {
  factory $PlaylistWriteFailedCopyWith(PlaylistWriteFailed value, $Res Function(PlaylistWriteFailed) _then) = _$PlaylistWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaylistWriteFailedCopyWithImpl<$Res>
    implements $PlaylistWriteFailedCopyWith<$Res> {
  _$PlaylistWriteFailedCopyWithImpl(this._self, this._then);

  final PlaylistWriteFailed _self;
  final $Res Function(PlaylistWriteFailed) _then;

/// Create a copy of PlaylistWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaylistWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaylistWrite
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
