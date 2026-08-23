// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'index_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IndexStartOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexStartOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IndexStartOutcome()';
}


}

/// @nodoc
class $IndexStartOutcomeCopyWith<$Res>  {
$IndexStartOutcomeCopyWith(IndexStartOutcome _, $Res Function(IndexStartOutcome) __);
}


/// Adds pattern-matching-related methods to [IndexStartOutcome].
extension IndexStartOutcomePatterns on IndexStartOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IndexStarted value)?  started,TResult Function( IndexStartFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IndexStarted() when started != null:
return started(_that);case IndexStartFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IndexStarted value)  started,required TResult Function( IndexStartFailed value)  failed,}){
final _that = this;
switch (_that) {
case IndexStarted():
return started(_that);case IndexStartFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IndexStarted value)?  started,TResult? Function( IndexStartFailed value)?  failed,}){
final _that = this;
switch (_that) {
case IndexStarted() when started != null:
return started(_that);case IndexStartFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String runId)?  started,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IndexStarted() when started != null:
return started(_that.runId);case IndexStartFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String runId)  started,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case IndexStarted():
return started(_that.runId);case IndexStartFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String runId)?  started,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case IndexStarted() when started != null:
return started(_that.runId);case IndexStartFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class IndexStarted implements IndexStartOutcome {
  const IndexStarted({required this.runId});
  

 final  String runId;

/// Create a copy of IndexStartOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexStartedCopyWith<IndexStarted> get copyWith => _$IndexStartedCopyWithImpl<IndexStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexStarted&&(identical(other.runId, runId) || other.runId == runId));
}


@override
int get hashCode => Object.hash(runtimeType,runId);

@override
String toString() {
  return 'IndexStartOutcome.started(runId: $runId)';
}


}

/// @nodoc
abstract mixin class $IndexStartedCopyWith<$Res> implements $IndexStartOutcomeCopyWith<$Res> {
  factory $IndexStartedCopyWith(IndexStarted value, $Res Function(IndexStarted) _then) = _$IndexStartedCopyWithImpl;
@useResult
$Res call({
 String runId
});




}
/// @nodoc
class _$IndexStartedCopyWithImpl<$Res>
    implements $IndexStartedCopyWith<$Res> {
  _$IndexStartedCopyWithImpl(this._self, this._then);

  final IndexStarted _self;
  final $Res Function(IndexStarted) _then;

/// Create a copy of IndexStartOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? runId = null,}) {
  return _then(IndexStarted(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IndexStartFailed implements IndexStartOutcome {
  const IndexStartFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of IndexStartOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexStartFailedCopyWith<IndexStartFailed> get copyWith => _$IndexStartFailedCopyWithImpl<IndexStartFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexStartFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'IndexStartOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $IndexStartFailedCopyWith<$Res> implements $IndexStartOutcomeCopyWith<$Res> {
  factory $IndexStartFailedCopyWith(IndexStartFailed value, $Res Function(IndexStartFailed) _then) = _$IndexStartFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$IndexStartFailedCopyWithImpl<$Res>
    implements $IndexStartFailedCopyWith<$Res> {
  _$IndexStartFailedCopyWithImpl(this._self, this._then);

  final IndexStartFailed _self;
  final $Res Function(IndexStartFailed) _then;

/// Create a copy of IndexStartOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(IndexStartFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of IndexStartOutcome
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
mixin _$IndexRunOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IndexRunOutcome()';
}


}

/// @nodoc
class $IndexRunOutcomeCopyWith<$Res>  {
$IndexRunOutcomeCopyWith(IndexRunOutcome _, $Res Function(IndexRunOutcome) __);
}


/// Adds pattern-matching-related methods to [IndexRunOutcome].
extension IndexRunOutcomePatterns on IndexRunOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IndexRunRead value)?  read,TResult Function( IndexRunFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IndexRunRead() when read != null:
return read(_that);case IndexRunFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IndexRunRead value)  read,required TResult Function( IndexRunFailed value)  failed,}){
final _that = this;
switch (_that) {
case IndexRunRead():
return read(_that);case IndexRunFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IndexRunRead value)?  read,TResult? Function( IndexRunFailed value)?  failed,}){
final _that = this;
switch (_that) {
case IndexRunRead() when read != null:
return read(_that);case IndexRunFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( IndexRun run)?  read,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IndexRunRead() when read != null:
return read(_that.run);case IndexRunFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( IndexRun run)  read,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case IndexRunRead():
return read(_that.run);case IndexRunFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( IndexRun run)?  read,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case IndexRunRead() when read != null:
return read(_that.run);case IndexRunFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class IndexRunRead implements IndexRunOutcome {
  const IndexRunRead({required this.run});
  

 final  IndexRun run;

/// Create a copy of IndexRunOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunReadCopyWith<IndexRunRead> get copyWith => _$IndexRunReadCopyWithImpl<IndexRunRead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunRead&&(identical(other.run, run) || other.run == run));
}


@override
int get hashCode => Object.hash(runtimeType,run);

@override
String toString() {
  return 'IndexRunOutcome.read(run: $run)';
}


}

/// @nodoc
abstract mixin class $IndexRunReadCopyWith<$Res> implements $IndexRunOutcomeCopyWith<$Res> {
  factory $IndexRunReadCopyWith(IndexRunRead value, $Res Function(IndexRunRead) _then) = _$IndexRunReadCopyWithImpl;
@useResult
$Res call({
 IndexRun run
});


$IndexRunCopyWith<$Res> get run;

}
/// @nodoc
class _$IndexRunReadCopyWithImpl<$Res>
    implements $IndexRunReadCopyWith<$Res> {
  _$IndexRunReadCopyWithImpl(this._self, this._then);

  final IndexRunRead _self;
  final $Res Function(IndexRunRead) _then;

/// Create a copy of IndexRunOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? run = null,}) {
  return _then(IndexRunRead(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as IndexRun,
  ));
}

/// Create a copy of IndexRunOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCopyWith<$Res> get run {
  
  return $IndexRunCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}

/// @nodoc


class IndexRunFailed implements IndexRunOutcome {
  const IndexRunFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of IndexRunOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunFailedCopyWith<IndexRunFailed> get copyWith => _$IndexRunFailedCopyWithImpl<IndexRunFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'IndexRunOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $IndexRunFailedCopyWith<$Res> implements $IndexRunOutcomeCopyWith<$Res> {
  factory $IndexRunFailedCopyWith(IndexRunFailed value, $Res Function(IndexRunFailed) _then) = _$IndexRunFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$IndexRunFailedCopyWithImpl<$Res>
    implements $IndexRunFailedCopyWith<$Res> {
  _$IndexRunFailedCopyWithImpl(this._self, this._then);

  final IndexRunFailed _self;
  final $Res Function(IndexRunFailed) _then;

/// Create a copy of IndexRunOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(IndexRunFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of IndexRunOutcome
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
mixin _$RunControlOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunControlOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RunControlOutcome()';
}


}

/// @nodoc
class $RunControlOutcomeCopyWith<$Res>  {
$RunControlOutcomeCopyWith(RunControlOutcome _, $Res Function(RunControlOutcome) __);
}


/// Adds pattern-matching-related methods to [RunControlOutcome].
extension RunControlOutcomePatterns on RunControlOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RunControlOk value)?  ok,TResult Function( RunControlFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RunControlOk() when ok != null:
return ok(_that);case RunControlFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RunControlOk value)  ok,required TResult Function( RunControlFailed value)  failed,}){
final _that = this;
switch (_that) {
case RunControlOk():
return ok(_that);case RunControlFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RunControlOk value)?  ok,TResult? Function( RunControlFailed value)?  failed,}){
final _that = this;
switch (_that) {
case RunControlOk() when ok != null:
return ok(_that);case RunControlFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RunControlOk() when ok != null:
return ok();case RunControlFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case RunControlOk():
return ok();case RunControlFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case RunControlOk() when ok != null:
return ok();case RunControlFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RunControlOk implements RunControlOutcome {
  const RunControlOk();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunControlOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RunControlOutcome.ok()';
}


}




/// @nodoc


class RunControlFailed implements RunControlOutcome {
  const RunControlFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of RunControlOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunControlFailedCopyWith<RunControlFailed> get copyWith => _$RunControlFailedCopyWithImpl<RunControlFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunControlFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RunControlOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RunControlFailedCopyWith<$Res> implements $RunControlOutcomeCopyWith<$Res> {
  factory $RunControlFailedCopyWith(RunControlFailed value, $Res Function(RunControlFailed) _then) = _$RunControlFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RunControlFailedCopyWithImpl<$Res>
    implements $RunControlFailedCopyWith<$Res> {
  _$RunControlFailedCopyWithImpl(this._self, this._then);

  final RunControlFailed _self;
  final $Res Function(RunControlFailed) _then;

/// Create a copy of RunControlOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RunControlFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RunControlOutcome
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
mixin _$ActiveRunsOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveRunsOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActiveRunsOutcome()';
}


}

/// @nodoc
class $ActiveRunsOutcomeCopyWith<$Res>  {
$ActiveRunsOutcomeCopyWith(ActiveRunsOutcome _, $Res Function(ActiveRunsOutcome) __);
}


/// Adds pattern-matching-related methods to [ActiveRunsOutcome].
extension ActiveRunsOutcomePatterns on ActiveRunsOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ActiveRunsRead value)?  read,TResult Function( ActiveRunsFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ActiveRunsRead() when read != null:
return read(_that);case ActiveRunsFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ActiveRunsRead value)  read,required TResult Function( ActiveRunsFailed value)  failed,}){
final _that = this;
switch (_that) {
case ActiveRunsRead():
return read(_that);case ActiveRunsFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ActiveRunsRead value)?  read,TResult? Function( ActiveRunsFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ActiveRunsRead() when read != null:
return read(_that);case ActiveRunsFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<IndexRun> runs)?  read,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ActiveRunsRead() when read != null:
return read(_that.runs);case ActiveRunsFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<IndexRun> runs)  read,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case ActiveRunsRead():
return read(_that.runs);case ActiveRunsFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<IndexRun> runs)?  read,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case ActiveRunsRead() when read != null:
return read(_that.runs);case ActiveRunsFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ActiveRunsRead implements ActiveRunsOutcome {
  const ActiveRunsRead({required final  List<IndexRun> runs}): _runs = runs;
  

 final  List<IndexRun> _runs;
 List<IndexRun> get runs {
  if (_runs is EqualUnmodifiableListView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_runs);
}


/// Create a copy of ActiveRunsOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveRunsReadCopyWith<ActiveRunsRead> get copyWith => _$ActiveRunsReadCopyWithImpl<ActiveRunsRead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveRunsRead&&const DeepCollectionEquality().equals(other._runs, _runs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_runs));

@override
String toString() {
  return 'ActiveRunsOutcome.read(runs: $runs)';
}


}

/// @nodoc
abstract mixin class $ActiveRunsReadCopyWith<$Res> implements $ActiveRunsOutcomeCopyWith<$Res> {
  factory $ActiveRunsReadCopyWith(ActiveRunsRead value, $Res Function(ActiveRunsRead) _then) = _$ActiveRunsReadCopyWithImpl;
@useResult
$Res call({
 List<IndexRun> runs
});




}
/// @nodoc
class _$ActiveRunsReadCopyWithImpl<$Res>
    implements $ActiveRunsReadCopyWith<$Res> {
  _$ActiveRunsReadCopyWithImpl(this._self, this._then);

  final ActiveRunsRead _self;
  final $Res Function(ActiveRunsRead) _then;

/// Create a copy of ActiveRunsOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? runs = null,}) {
  return _then(ActiveRunsRead(
runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as List<IndexRun>,
  ));
}


}

/// @nodoc


class ActiveRunsFailed implements ActiveRunsOutcome {
  const ActiveRunsFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of ActiveRunsOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveRunsFailedCopyWith<ActiveRunsFailed> get copyWith => _$ActiveRunsFailedCopyWithImpl<ActiveRunsFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveRunsFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ActiveRunsOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ActiveRunsFailedCopyWith<$Res> implements $ActiveRunsOutcomeCopyWith<$Res> {
  factory $ActiveRunsFailedCopyWith(ActiveRunsFailed value, $Res Function(ActiveRunsFailed) _then) = _$ActiveRunsFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ActiveRunsFailedCopyWithImpl<$Res>
    implements $ActiveRunsFailedCopyWith<$Res> {
  _$ActiveRunsFailedCopyWithImpl(this._self, this._then);

  final ActiveRunsFailed _self;
  final $Res Function(ActiveRunsFailed) _then;

/// Create a copy of ActiveRunsOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ActiveRunsFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ActiveRunsOutcome
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
