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

/// The run for each folder, in flight or finished.
///
/// A finished run stays here until the owner dismisses it, which is what
/// keeps its outcome on screen (FR-LB-08).
 Map<String, IndexRun> get runs;/// Folders whose start is in flight but which have no run id yet.
 Set<String> get starting;/// Why a start was refused, per folder (AF-02, AF-03).
 Map<String, Failure> get failures;/// The folder a second run was refused for (AF-01), or `null`.
 String? get refusedSecondRunFor;/// Whether a refresh has been asked for but not yet answered (FR-UX-08).
 bool get refreshStarting;/// The catalog-wide refresh, in flight or finished (UC-07).
///
/// Its own field rather than an entry in [runs], because a refresh belongs
/// to no folder — keying it under one would make it look like that
/// folder's scan and would block UC-08 from removing an unrelated folder.
 IndexRun? get refreshRun;/// Why the last refresh was refused (UC-07 AF-01, AF-02), or `null`.
 RefreshRefusal? get refreshRefusal;/// Why the refresh failed, when the core refused the start.
 Failure? get refreshFailure;
/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunsStateCopyWith<IndexRunsState> get copyWith => _$IndexRunsStateCopyWithImpl<IndexRunsState>(this as IndexRunsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunsState&&const DeepCollectionEquality().equals(other.runs, runs)&&const DeepCollectionEquality().equals(other.starting, starting)&&const DeepCollectionEquality().equals(other.failures, failures)&&(identical(other.refusedSecondRunFor, refusedSecondRunFor) || other.refusedSecondRunFor == refusedSecondRunFor)&&(identical(other.refreshStarting, refreshStarting) || other.refreshStarting == refreshStarting)&&(identical(other.refreshRun, refreshRun) || other.refreshRun == refreshRun)&&(identical(other.refreshRefusal, refreshRefusal) || other.refreshRefusal == refreshRefusal)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(runs),const DeepCollectionEquality().hash(starting),const DeepCollectionEquality().hash(failures),refusedSecondRunFor,refreshStarting,refreshRun,refreshRefusal,refreshFailure);

@override
String toString() {
  return 'IndexRunsState(runs: $runs, starting: $starting, failures: $failures, refusedSecondRunFor: $refusedSecondRunFor, refreshStarting: $refreshStarting, refreshRun: $refreshRun, refreshRefusal: $refreshRefusal, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class $IndexRunsStateCopyWith<$Res>  {
  factory $IndexRunsStateCopyWith(IndexRunsState value, $Res Function(IndexRunsState) _then) = _$IndexRunsStateCopyWithImpl;
@useResult
$Res call({
 Map<String, IndexRun> runs, Set<String> starting, Map<String, Failure> failures, String? refusedSecondRunFor, bool refreshStarting, IndexRun? refreshRun, RefreshRefusal? refreshRefusal, Failure? refreshFailure
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
@pragma('vm:prefer-inline') @override $Res call({Object? runs = null,Object? starting = null,Object? failures = null,Object? refusedSecondRunFor = freezed,Object? refreshStarting = null,Object? refreshRun = freezed,Object? refreshRefusal = freezed,Object? refreshFailure = freezed,}) {
  return _then(_self.copyWith(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, IndexRun>,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as Set<String>,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as Map<String, Failure>,refusedSecondRunFor: freezed == refusedSecondRunFor ? _self.refusedSecondRunFor : refusedSecondRunFor // ignore: cast_nullable_to_non_nullable
as String?,refreshStarting: null == refreshStarting ? _self.refreshStarting : refreshStarting // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  String? refusedSecondRunFor,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
return $default(_that.runs,_that.starting,_that.failures,_that.refusedSecondRunFor,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  String? refusedSecondRunFor,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)  $default,) {final _that = this;
switch (_that) {
case _IndexRunsState():
return $default(_that.runs,_that.starting,_that.failures,_that.refusedSecondRunFor,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, IndexRun> runs,  Set<String> starting,  Map<String, Failure> failures,  String? refusedSecondRunFor,  bool refreshStarting,  IndexRun? refreshRun,  RefreshRefusal? refreshRefusal,  Failure? refreshFailure)?  $default,) {final _that = this;
switch (_that) {
case _IndexRunsState() when $default != null:
return $default(_that.runs,_that.starting,_that.failures,_that.refusedSecondRunFor,_that.refreshStarting,_that.refreshRun,_that.refreshRefusal,_that.refreshFailure);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRunsState extends IndexRunsState {
  const _IndexRunsState({final  Map<String, IndexRun> runs = const <String, IndexRun>{}, final  Set<String> starting = const <String>{}, final  Map<String, Failure> failures = const <String, Failure>{}, this.refusedSecondRunFor, this.refreshStarting = false, this.refreshRun, this.refreshRefusal, this.refreshFailure}): _runs = runs,_starting = starting,_failures = failures,super._();
  

/// The run for each folder, in flight or finished.
///
/// A finished run stays here until the owner dismisses it, which is what
/// keeps its outcome on screen (FR-LB-08).
 final  Map<String, IndexRun> _runs;
/// The run for each folder, in flight or finished.
///
/// A finished run stays here until the owner dismisses it, which is what
/// keeps its outcome on screen (FR-LB-08).
@override@JsonKey() Map<String, IndexRun> get runs {
  if (_runs is EqualUnmodifiableMapView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runs);
}

/// Folders whose start is in flight but which have no run id yet.
 final  Set<String> _starting;
/// Folders whose start is in flight but which have no run id yet.
@override@JsonKey() Set<String> get starting {
  if (_starting is EqualUnmodifiableSetView) return _starting;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_starting);
}

/// Why a start was refused, per folder (AF-02, AF-03).
 final  Map<String, Failure> _failures;
/// Why a start was refused, per folder (AF-02, AF-03).
@override@JsonKey() Map<String, Failure> get failures {
  if (_failures is EqualUnmodifiableMapView) return _failures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_failures);
}

/// The folder a second run was refused for (AF-01), or `null`.
@override final  String? refusedSecondRunFor;
/// Whether a refresh has been asked for but not yet answered (FR-UX-08).
@override@JsonKey() final  bool refreshStarting;
/// The catalog-wide refresh, in flight or finished (UC-07).
///
/// Its own field rather than an entry in [runs], because a refresh belongs
/// to no folder — keying it under one would make it look like that
/// folder's scan and would block UC-08 from removing an unrelated folder.
@override final  IndexRun? refreshRun;
/// Why the last refresh was refused (UC-07 AF-01, AF-02), or `null`.
@override final  RefreshRefusal? refreshRefusal;
/// Why the refresh failed, when the core refused the start.
@override final  Failure? refreshFailure;

/// Create a copy of IndexRunsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexRunsStateCopyWith<_IndexRunsState> get copyWith => __$IndexRunsStateCopyWithImpl<_IndexRunsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRunsState&&const DeepCollectionEquality().equals(other._runs, _runs)&&const DeepCollectionEquality().equals(other._starting, _starting)&&const DeepCollectionEquality().equals(other._failures, _failures)&&(identical(other.refusedSecondRunFor, refusedSecondRunFor) || other.refusedSecondRunFor == refusedSecondRunFor)&&(identical(other.refreshStarting, refreshStarting) || other.refreshStarting == refreshStarting)&&(identical(other.refreshRun, refreshRun) || other.refreshRun == refreshRun)&&(identical(other.refreshRefusal, refreshRefusal) || other.refreshRefusal == refreshRefusal)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_runs),const DeepCollectionEquality().hash(_starting),const DeepCollectionEquality().hash(_failures),refusedSecondRunFor,refreshStarting,refreshRun,refreshRefusal,refreshFailure);

@override
String toString() {
  return 'IndexRunsState(runs: $runs, starting: $starting, failures: $failures, refusedSecondRunFor: $refusedSecondRunFor, refreshStarting: $refreshStarting, refreshRun: $refreshRun, refreshRefusal: $refreshRefusal, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class _$IndexRunsStateCopyWith<$Res> implements $IndexRunsStateCopyWith<$Res> {
  factory _$IndexRunsStateCopyWith(_IndexRunsState value, $Res Function(_IndexRunsState) _then) = __$IndexRunsStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, IndexRun> runs, Set<String> starting, Map<String, Failure> failures, String? refusedSecondRunFor, bool refreshStarting, IndexRun? refreshRun, RefreshRefusal? refreshRefusal, Failure? refreshFailure
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
@override @pragma('vm:prefer-inline') $Res call({Object? runs = null,Object? starting = null,Object? failures = null,Object? refusedSecondRunFor = freezed,Object? refreshStarting = null,Object? refreshRun = freezed,Object? refreshRefusal = freezed,Object? refreshFailure = freezed,}) {
  return _then(_IndexRunsState(
runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, IndexRun>,starting: null == starting ? _self._starting : starting // ignore: cast_nullable_to_non_nullable
as Set<String>,failures: null == failures ? _self._failures : failures // ignore: cast_nullable_to_non_nullable
as Map<String, Failure>,refusedSecondRunFor: freezed == refusedSecondRunFor ? _self.refusedSecondRunFor : refusedSecondRunFor // ignore: cast_nullable_to_non_nullable
as String?,refreshStarting: null == refreshStarting ? _self.refreshStarting : refreshStarting // ignore: cast_nullable_to_non_nullable
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
