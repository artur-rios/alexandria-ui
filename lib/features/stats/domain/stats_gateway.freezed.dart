// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicStatsRead {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicStatsRead);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MusicStatsRead()';
}


}

/// @nodoc
class $MusicStatsReadCopyWith<$Res>  {
$MusicStatsReadCopyWith(MusicStatsRead _, $Res Function(MusicStatsRead) __);
}


/// Adds pattern-matching-related methods to [MusicStatsRead].
extension MusicStatsReadPatterns on MusicStatsRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MusicStatsReadLoaded value)?  loaded,TResult Function( MusicStatsReadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MusicStatsReadLoaded() when loaded != null:
return loaded(_that);case MusicStatsReadFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MusicStatsReadLoaded value)  loaded,required TResult Function( MusicStatsReadFailed value)  failed,}){
final _that = this;
switch (_that) {
case MusicStatsReadLoaded():
return loaded(_that);case MusicStatsReadFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MusicStatsReadLoaded value)?  loaded,TResult? Function( MusicStatsReadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case MusicStatsReadLoaded() when loaded != null:
return loaded(_that);case MusicStatsReadFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( MusicStats stats)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MusicStatsReadLoaded() when loaded != null:
return loaded(_that.stats);case MusicStatsReadFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( MusicStats stats)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case MusicStatsReadLoaded():
return loaded(_that.stats);case MusicStatsReadFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( MusicStats stats)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case MusicStatsReadLoaded() when loaded != null:
return loaded(_that.stats);case MusicStatsReadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class MusicStatsReadLoaded implements MusicStatsRead {
  const MusicStatsReadLoaded({required this.stats});
  

 final  MusicStats stats;

/// Create a copy of MusicStatsRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicStatsReadLoadedCopyWith<MusicStatsReadLoaded> get copyWith => _$MusicStatsReadLoadedCopyWithImpl<MusicStatsReadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicStatsReadLoaded&&(identical(other.stats, stats) || other.stats == stats));
}


@override
int get hashCode => Object.hash(runtimeType,stats);

@override
String toString() {
  return 'MusicStatsRead.loaded(stats: $stats)';
}


}

/// @nodoc
abstract mixin class $MusicStatsReadLoadedCopyWith<$Res> implements $MusicStatsReadCopyWith<$Res> {
  factory $MusicStatsReadLoadedCopyWith(MusicStatsReadLoaded value, $Res Function(MusicStatsReadLoaded) _then) = _$MusicStatsReadLoadedCopyWithImpl;
@useResult
$Res call({
 MusicStats stats
});


$MusicStatsCopyWith<$Res> get stats;

}
/// @nodoc
class _$MusicStatsReadLoadedCopyWithImpl<$Res>
    implements $MusicStatsReadLoadedCopyWith<$Res> {
  _$MusicStatsReadLoadedCopyWithImpl(this._self, this._then);

  final MusicStatsReadLoaded _self;
  final $Res Function(MusicStatsReadLoaded) _then;

/// Create a copy of MusicStatsRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stats = null,}) {
  return _then(MusicStatsReadLoaded(
stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as MusicStats,
  ));
}

/// Create a copy of MusicStatsRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicStatsCopyWith<$Res> get stats {
  
  return $MusicStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

/// @nodoc


class MusicStatsReadFailed implements MusicStatsRead {
  const MusicStatsReadFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of MusicStatsRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicStatsReadFailedCopyWith<MusicStatsReadFailed> get copyWith => _$MusicStatsReadFailedCopyWithImpl<MusicStatsReadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicStatsReadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'MusicStatsRead.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $MusicStatsReadFailedCopyWith<$Res> implements $MusicStatsReadCopyWith<$Res> {
  factory $MusicStatsReadFailedCopyWith(MusicStatsReadFailed value, $Res Function(MusicStatsReadFailed) _then) = _$MusicStatsReadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$MusicStatsReadFailedCopyWithImpl<$Res>
    implements $MusicStatsReadFailedCopyWith<$Res> {
  _$MusicStatsReadFailedCopyWithImpl(this._self, this._then);

  final MusicStatsReadFailed _self;
  final $Res Function(MusicStatsReadFailed) _then;

/// Create a copy of MusicStatsRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(MusicStatsReadFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of MusicStatsRead
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
mixin _$PlayRecorded {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayRecorded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlayRecorded()';
}


}

/// @nodoc
class $PlayRecordedCopyWith<$Res>  {
$PlayRecordedCopyWith(PlayRecorded _, $Res Function(PlayRecorded) __);
}


/// Adds pattern-matching-related methods to [PlayRecorded].
extension PlayRecordedPatterns on PlayRecorded {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlayRecordedDone value)?  done,TResult Function( PlayRecordedFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlayRecordedDone() when done != null:
return done(_that);case PlayRecordedFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlayRecordedDone value)  done,required TResult Function( PlayRecordedFailed value)  failed,}){
final _that = this;
switch (_that) {
case PlayRecordedDone():
return done(_that);case PlayRecordedFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlayRecordedDone value)?  done,TResult? Function( PlayRecordedFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PlayRecordedDone() when done != null:
return done(_that);case PlayRecordedFailed() when failed != null:
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
case PlayRecordedDone() when done != null:
return done();case PlayRecordedFailed() when failed != null:
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
case PlayRecordedDone():
return done();case PlayRecordedFailed():
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
case PlayRecordedDone() when done != null:
return done();case PlayRecordedFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlayRecordedDone implements PlayRecorded {
  const PlayRecordedDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayRecordedDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlayRecorded.done()';
}


}




/// @nodoc


class PlayRecordedFailed implements PlayRecorded {
  const PlayRecordedFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of PlayRecorded
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayRecordedFailedCopyWith<PlayRecordedFailed> get copyWith => _$PlayRecordedFailedCopyWithImpl<PlayRecordedFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayRecordedFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlayRecorded.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlayRecordedFailedCopyWith<$Res> implements $PlayRecordedCopyWith<$Res> {
  factory $PlayRecordedFailedCopyWith(PlayRecordedFailed value, $Res Function(PlayRecordedFailed) _then) = _$PlayRecordedFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlayRecordedFailedCopyWithImpl<$Res>
    implements $PlayRecordedFailedCopyWith<$Res> {
  _$PlayRecordedFailedCopyWithImpl(this._self, this._then);

  final PlayRecordedFailed _self;
  final $Res Function(PlayRecordedFailed) _then;

/// Create a copy of PlayRecorded
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlayRecordedFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlayRecorded
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
