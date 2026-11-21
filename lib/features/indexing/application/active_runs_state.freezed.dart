// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_runs_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveRunsState {

/// Every run the core reported as outstanding on the last successful
/// read — running or paused.
 List<IndexRun> get runs;/// Progress samples per run id, oldest first, used to estimate time
/// remaining ([estimateRemaining]).
///
/// Capped per run so a long scan does not grow this without bound; see
/// [ActiveRunsController].
 Map<String, List<RunSample>> get samples;/// A run that was outstanding on the previous read and is gone from this
/// one, read back for the status it ended on — the active list only ever
/// carries running and paused runs, so the outcome cannot come from
/// there.
///
/// One slot, and what stands in it is not simply the latest. A *failed*
/// run is held until the owner dismisses it and is not replaced by a
/// later outcome; anything else is replaced as soon as the next run
/// ends, because a completion clears itself anyway and a cancellation is
/// the owner's own doing. Null when the run's outcome could not be read.
 IndexRun? get justFinished;/// Why the last read failed, if it did.
///
/// [runs] is not cleared when this is set: a failed read is not evidence
/// that nothing is running, only that the core could not be asked.
 Failure? get failure;
/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveRunsStateCopyWith<ActiveRunsState> get copyWith => _$ActiveRunsStateCopyWithImpl<ActiveRunsState>(this as ActiveRunsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveRunsState&&const DeepCollectionEquality().equals(other.runs, runs)&&const DeepCollectionEquality().equals(other.samples, samples)&&(identical(other.justFinished, justFinished) || other.justFinished == justFinished)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(runs),const DeepCollectionEquality().hash(samples),justFinished,failure);

@override
String toString() {
  return 'ActiveRunsState(runs: $runs, samples: $samples, justFinished: $justFinished, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ActiveRunsStateCopyWith<$Res>  {
  factory $ActiveRunsStateCopyWith(ActiveRunsState value, $Res Function(ActiveRunsState) _then) = _$ActiveRunsStateCopyWithImpl;
@useResult
$Res call({
 List<IndexRun> runs, Map<String, List<RunSample>> samples, IndexRun? justFinished, Failure? failure
});


$IndexRunCopyWith<$Res>? get justFinished;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$ActiveRunsStateCopyWithImpl<$Res>
    implements $ActiveRunsStateCopyWith<$Res> {
  _$ActiveRunsStateCopyWithImpl(this._self, this._then);

  final ActiveRunsState _self;
  final $Res Function(ActiveRunsState) _then;

/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runs = null,Object? samples = null,Object? justFinished = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as List<IndexRun>,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as Map<String, List<RunSample>>,justFinished: freezed == justFinished ? _self.justFinished : justFinished // ignore: cast_nullable_to_non_nullable
as IndexRun?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCopyWith<$Res>? get justFinished {
    if (_self.justFinished == null) {
    return null;
  }

  return $IndexRunCopyWith<$Res>(_self.justFinished!, (value) {
    return _then(_self.copyWith(justFinished: value));
  });
}/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveRunsState].
extension ActiveRunsStatePatterns on ActiveRunsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveRunsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveRunsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveRunsState value)  $default,){
final _that = this;
switch (_that) {
case _ActiveRunsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveRunsState value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveRunsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<IndexRun> runs,  Map<String, List<RunSample>> samples,  IndexRun? justFinished,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveRunsState() when $default != null:
return $default(_that.runs,_that.samples,_that.justFinished,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<IndexRun> runs,  Map<String, List<RunSample>> samples,  IndexRun? justFinished,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _ActiveRunsState():
return $default(_that.runs,_that.samples,_that.justFinished,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<IndexRun> runs,  Map<String, List<RunSample>> samples,  IndexRun? justFinished,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _ActiveRunsState() when $default != null:
return $default(_that.runs,_that.samples,_that.justFinished,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveRunsState extends ActiveRunsState {
  const _ActiveRunsState({final  List<IndexRun> runs = const <IndexRun>[], final  Map<String, List<RunSample>> samples = const <String, List<RunSample>>{}, this.justFinished, this.failure}): _runs = runs,_samples = samples,super._();
  

/// Every run the core reported as outstanding on the last successful
/// read — running or paused.
 final  List<IndexRun> _runs;
/// Every run the core reported as outstanding on the last successful
/// read — running or paused.
@override@JsonKey() List<IndexRun> get runs {
  if (_runs is EqualUnmodifiableListView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_runs);
}

/// Progress samples per run id, oldest first, used to estimate time
/// remaining ([estimateRemaining]).
///
/// Capped per run so a long scan does not grow this without bound; see
/// [ActiveRunsController].
 final  Map<String, List<RunSample>> _samples;
/// Progress samples per run id, oldest first, used to estimate time
/// remaining ([estimateRemaining]).
///
/// Capped per run so a long scan does not grow this without bound; see
/// [ActiveRunsController].
@override@JsonKey() Map<String, List<RunSample>> get samples {
  if (_samples is EqualUnmodifiableMapView) return _samples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_samples);
}

/// A run that was outstanding on the previous read and is gone from this
/// one, read back for the status it ended on — the active list only ever
/// carries running and paused runs, so the outcome cannot come from
/// there.
///
/// One slot, and what stands in it is not simply the latest. A *failed*
/// run is held until the owner dismisses it and is not replaced by a
/// later outcome; anything else is replaced as soon as the next run
/// ends, because a completion clears itself anyway and a cancellation is
/// the owner's own doing. Null when the run's outcome could not be read.
@override final  IndexRun? justFinished;
/// Why the last read failed, if it did.
///
/// [runs] is not cleared when this is set: a failed read is not evidence
/// that nothing is running, only that the core could not be asked.
@override final  Failure? failure;

/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveRunsStateCopyWith<_ActiveRunsState> get copyWith => __$ActiveRunsStateCopyWithImpl<_ActiveRunsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveRunsState&&const DeepCollectionEquality().equals(other._runs, _runs)&&const DeepCollectionEquality().equals(other._samples, _samples)&&(identical(other.justFinished, justFinished) || other.justFinished == justFinished)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_runs),const DeepCollectionEquality().hash(_samples),justFinished,failure);

@override
String toString() {
  return 'ActiveRunsState(runs: $runs, samples: $samples, justFinished: $justFinished, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ActiveRunsStateCopyWith<$Res> implements $ActiveRunsStateCopyWith<$Res> {
  factory _$ActiveRunsStateCopyWith(_ActiveRunsState value, $Res Function(_ActiveRunsState) _then) = __$ActiveRunsStateCopyWithImpl;
@override @useResult
$Res call({
 List<IndexRun> runs, Map<String, List<RunSample>> samples, IndexRun? justFinished, Failure? failure
});


@override $IndexRunCopyWith<$Res>? get justFinished;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$ActiveRunsStateCopyWithImpl<$Res>
    implements _$ActiveRunsStateCopyWith<$Res> {
  __$ActiveRunsStateCopyWithImpl(this._self, this._then);

  final _ActiveRunsState _self;
  final $Res Function(_ActiveRunsState) _then;

/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runs = null,Object? samples = null,Object? justFinished = freezed,Object? failure = freezed,}) {
  return _then(_ActiveRunsState(
runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as List<IndexRun>,samples: null == samples ? _self._samples : samples // ignore: cast_nullable_to_non_nullable
as Map<String, List<RunSample>>,justFinished: freezed == justFinished ? _self.justFinished : justFinished // ignore: cast_nullable_to_non_nullable
as IndexRun?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCopyWith<$Res>? get justFinished {
    if (_self.justFinished == null) {
    return null;
  }

  return $IndexRunCopyWith<$Res>(_self.justFinished!, (value) {
    return _then(_self.copyWith(justFinished: value));
  });
}/// Create a copy of ActiveRunsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
