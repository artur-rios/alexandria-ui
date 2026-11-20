// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'index_runs_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IndexRunsState {

/// The latest observation of each followed run, by library uuid.
 Map<String, IndexRun> get runs;/// The libraries whose run is being started right now.
 Set<String> get starting;/// The libraries whose followed run could no longer be read.
///
/// A run in here is not polled again: the core has stopped answering for
/// it, and asking every second would only repeat the failure.
 Map<String, Failure> get failures;/// Whether a refresh is being started right now.
 bool get refreshStarting;/// The refresh this session started, while it runs and once it settles.
 IndexRun? get refreshRun;/// Why the last refresh was not started, when it was refused here.
 RefreshRefusal? get refreshRefusal;/// Why the last refresh failed, when the core refused or failed it.
 Failure? get refreshFailure;
/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunsStateCopyWith<IndexRunsState> get copyWith => _$IndexRunsStateCopyWithImpl<IndexRunsState>(this as IndexRunsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunsState&&const DeepCollectionEquality().equals(other.runs, runs)&&const DeepCollectionEquality().equals(other.starting, starting)&&const DeepCollectionEquality().equals(other.failures, failures)&&(identical(other.refreshStarting, refreshStarting) || other.refreshStarting == refreshStarting)&&(identical(other.refreshRun, refreshRun) || other.refreshRun == refreshRun)&&(identical(other.refreshRefusal, refreshRefusal) || other.refreshRefusal == refreshRefusal)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(runs),const DeepCollectionEquality().hash(starting),const DeepCollectionEquality().hash(failures),refreshStarting,refreshRun,refreshRefusal,refreshFailure);

@override
String toString() {
  return 'IndexRunsState(runs: $runs, starting: $starting, failures: $failures, refreshStarting: $refreshStarting, refreshRun: $refreshRun, refreshRefusal: $refreshRefusal, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class $IndexRunsStateCopyWith<$Res>  {
  factory $IndexRunsStateCopyWith(IndexRunsState value, $Res Function(IndexRunsState) _then) = _$IndexRunsStateCopyWithImpl;
@useResult
$Res call({
 Map<String, IndexRun> runs, Set<String> starting, Map<String, Failure> failures, bool refreshStarting, IndexRun? refreshRun, RefreshRefusal? refreshRefusal, Failure? refreshFailure
});


$IndexRunCopyWith<$Res>? get refreshRun;$FailureCopyWith<$Res>? get refreshFailure;

}
/// @nodoc
class _$IndexRunsStateCopyWithImpl<$Res>
    implements $IndexRunsStateCopyWith<$Res> {
  _$IndexRunsStateCopyWithImpl(this._self, this._then);

  final IndexRunsState _self;
  final $Res Function(IndexRunsState) _then;

/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runs = null,Object? starting = null,Object? failures = null,Object? refreshStarting = null,Object? refreshRun = freezed,Object? refreshRefusal = freezed,Object? refreshFailure = freezed,}) {
  return _then(_self.copyWith(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, IndexRun>,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as Set<String>,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as Map<String, Failure>,refreshStarting: null == refreshStarting ? _self.refreshStarting : refreshStarting // ignore: cast_nullable_to_non_nullable
as bool,refreshRun: freezed == refreshRun ? _self.refreshRun : refreshRun // ignore: cast_nullable_to_non_nullable
as IndexRun?,refreshRefusal: freezed == refreshRefusal ? _self.refreshRefusal : refreshRefusal // ignore: cast_nullable_to_non_nullable
as RefreshRefusal?,refreshFailure: freezed == refreshFailure ? _self.refreshFailure : refreshFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCopyWith<$Res>? get refreshRun {
    if (_self.refreshRun == null) {
    return null;
  }

  return $IndexRunCopyWith<$Res>(_self.refreshRun!, (value) {
    return _then(_self.copyWith(refreshRun: value));
  });
}/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get refreshFailure {
    if (_self.refreshFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.refreshFailure!, (value) {
    return _then(_self.copyWith(refreshFailure: value));
  });
}
}


/// Adds pattern-matching-related methods to [IndexRunsState].
extension IndexRunsStatePatterns on IndexRunsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndexRunsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndexRunsState value)  $default,){
final _that = this;
switch (_that) {
case _IndexRunsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndexRunsState value)?  $default,){
final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
return $default(_that.runs,_that.starting,_that.failures,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)  $default,) {final _that = this;
switch (_that) {
case _IndexRunsState():
return $default(_that.runs,_that.starting,_that.failures,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)?  $default,) {final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
return $default(_that.runs,_that.starting,_that.failures,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRunsState extends IndexRunsState {
  const _IndexRunsState({final  Map<String, IndexRun> runs = const <String, IndexRun>{}, final  Set<String> starting = const <String>{}, final  Map<String, Failure> failures = const <String, Failure>{}, this.refreshStarting = false, this.refreshRun, this.refreshRefusal, this.refreshFailure}): _runs = runs,_starting = starting,_failures = failures,super._();
  

/// The latest observation of each followed run, by library uuid.
 final  Map<String, IndexRun> _runs;
/// The latest observation of each followed run, by library uuid.
@override@JsonKey() Map<String, IndexRun> get runs {
  if (_runs is EqualUnmodifiableMapView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runs);
}

/// The libraries whose run is being started right now.
 final  Set<String> _starting;
/// The libraries whose run is being started right now.
@override@JsonKey() Set<String> get starting {
  if (_starting is EqualUnmodifiableSetView) return _starting;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_starting);
}

/// The libraries whose followed run could no longer be read.
///
/// A run in here is not polled again: the core has stopped answering for
/// it, and asking every second would only repeat the failure.
 final  Map<String, Failure> _failures;
/// The libraries whose followed run could no longer be read.
///
/// A run in here is not polled again: the core has stopped answering for
/// it, and asking every second would only repeat the failure.
@override@JsonKey() Map<String, Failure> get failures {
  if (_failures is EqualUnmodifiableMapView) return _failures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_failures);
}

/// Whether a refresh is being started right now.
@override@JsonKey() final  bool refreshStarting;
/// The refresh this session started, while it runs and once it settles.
@override final  IndexRun? refreshRun;
/// Why the last refresh was not started, when it was refused here.
@override final  RefreshRefusal? refreshRefusal;
/// Why the last refresh failed, when the core refused or failed it.
@override final  Failure? refreshFailure;

/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexRunsStateCopyWith<_IndexRunsState> get copyWith => __$IndexRunsStateCopyWithImpl<_IndexRunsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRunsState&&const DeepCollectionEquality().equals(other._runs, _runs)&&const DeepCollectionEquality().equals(other._starting, _starting)&&const DeepCollectionEquality().equals(other._failures, _failures)&&(identical(other.refreshStarting, refreshStarting) || other.refreshStarting == refreshStarting)&&(identical(other.refreshRun, refreshRun) || other.refreshRun == refreshRun)&&(identical(other.refreshRefusal, refreshRefusal) || other.refreshRefusal == refreshRefusal)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_runs),const DeepCollectionEquality().hash(_starting),const DeepCollectionEquality().hash(_failures),refreshStarting,refreshRun,refreshRefusal,refreshFailure);

@override
String toString() {
  return 'IndexRunsState(runs: $runs, starting: $starting, failures: $failures, refreshStarting: $refreshStarting, refreshRun: $refreshRun, refreshRefusal: $refreshRefusal, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class _$IndexRunsStateCopyWith<$Res> implements $IndexRunsStateCopyWith<$Res> {
  factory _$IndexRunsStateCopyWith(_IndexRunsState value, $Res Function(_IndexRunsState) _then) = __$IndexRunsStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, IndexRun> runs, Set<String> starting, Map<String, Failure> failures, bool refreshStarting, IndexRun? refreshRun, RefreshRefusal? refreshRefusal, Failure? refreshFailure
});


@override $IndexRunCopyWith<$Res>? get refreshRun;@override $FailureCopyWith<$Res>? get refreshFailure;

}
/// @nodoc
class __$IndexRunsStateCopyWithImpl<$Res>
    implements _$IndexRunsStateCopyWith<$Res> {
  __$IndexRunsStateCopyWithImpl(this._self, this._then);

  final _IndexRunsState _self;
  final $Res Function(_IndexRunsState) _then;

/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runs = null,Object? starting = null,Object? failures = null,Object? refreshStarting = null,Object? refreshRun = freezed,Object? refreshRefusal = freezed,Object? refreshFailure = freezed,}) {
  return _then(_IndexRunsState(
runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, IndexRun>,starting: null == starting ? _self._starting : starting // ignore: cast_nullable_to_non_nullable
as Set<String>,failures: null == failures ? _self._failures : failures // ignore: cast_nullable_to_non_nullable
as Map<String, Failure>,refreshStarting: null == refreshStarting ? _self.refreshStarting : refreshStarting // ignore: cast_nullable_to_non_nullable
as bool,refreshRun: freezed == refreshRun ? _self.refreshRun : refreshRun // ignore: cast_nullable_to_non_nullable
as IndexRun?,refreshRefusal: freezed == refreshRefusal ? _self.refreshRefusal : refreshRefusal // ignore: cast_nullable_to_non_nullable
as RefreshRefusal?,refreshFailure: freezed == refreshFailure ? _self.refreshFailure : refreshFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCopyWith<$Res>? get refreshRun {
    if (_self.refreshRun == null) {
    return null;
  }

  return $IndexRunCopyWith<$Res>(_self.refreshRun!, (value) {
    return _then(_self.copyWith(refreshRun: value));
  });
}/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get refreshFailure {
    if (_self.refreshFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.refreshFailure!, (value) {
    return _then(_self.copyWith(refreshFailure: value));
  });
}
}

// dart format on
