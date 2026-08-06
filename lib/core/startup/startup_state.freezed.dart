// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'startup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StartupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StartupState()';
}


}

/// @nodoc
class $StartupStateCopyWith<$Res>  {
$StartupStateCopyWith(StartupState _, $Res Function(StartupState) __);
}


/// Adds pattern-matching-related methods to [StartupState].
extension StartupStatePatterns on StartupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StartupIdle value)?  idle,TResult Function( StartupRunning value)?  running,TResult Function( StartupReady value)?  ready,TResult Function( StartupFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StartupIdle() when idle != null:
return idle(_that);case StartupRunning() when running != null:
return running(_that);case StartupReady() when ready != null:
return ready(_that);case StartupFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StartupIdle value)  idle,required TResult Function( StartupRunning value)  running,required TResult Function( StartupReady value)  ready,required TResult Function( StartupFailed value)  failed,}){
final _that = this;
switch (_that) {
case StartupIdle():
return idle(_that);case StartupRunning():
return running(_that);case StartupReady():
return ready(_that);case StartupFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StartupIdle value)?  idle,TResult? Function( StartupRunning value)?  running,TResult? Function( StartupReady value)?  ready,TResult? Function( StartupFailed value)?  failed,}){
final _that = this;
switch (_that) {
case StartupIdle() when idle != null:
return idle(_that);case StartupRunning() when running != null:
return running(_that);case StartupReady() when ready != null:
return ready(_that);case StartupFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( StartupStep step)?  running,TResult Function( String coreVersion,  String databasePath,  Failure? warning)?  ready,TResult Function( StartupStep step,  Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StartupIdle() when idle != null:
return idle();case StartupRunning() when running != null:
return running(_that.step);case StartupReady() when ready != null:
return ready(_that.coreVersion,_that.databasePath,_that.warning);case StartupFailed() when failed != null:
return failed(_that.step,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( StartupStep step)  running,required TResult Function( String coreVersion,  String databasePath,  Failure? warning)  ready,required TResult Function( StartupStep step,  Failure failure)  failed,}) {final _that = this;
switch (_that) {
case StartupIdle():
return idle();case StartupRunning():
return running(_that.step);case StartupReady():
return ready(_that.coreVersion,_that.databasePath,_that.warning);case StartupFailed():
return failed(_that.step,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( StartupStep step)?  running,TResult? Function( String coreVersion,  String databasePath,  Failure? warning)?  ready,TResult? Function( StartupStep step,  Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case StartupIdle() when idle != null:
return idle();case StartupRunning() when running != null:
return running(_that.step);case StartupReady() when ready != null:
return ready(_that.coreVersion,_that.databasePath,_that.warning);case StartupFailed() when failed != null:
return failed(_that.step,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StartupIdle implements StartupState {
  const StartupIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StartupState.idle()';
}


}




/// @nodoc


class StartupRunning implements StartupState {
  const StartupRunning({required this.step});
  

 final  StartupStep step;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartupRunningCopyWith<StartupRunning> get copyWith => _$StartupRunningCopyWithImpl<StartupRunning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupRunning&&(identical(other.step, step) || other.step == step));
}


@override
int get hashCode => Object.hash(runtimeType,step);

@override
String toString() {
  return 'StartupState.running(step: $step)';
}


}

/// @nodoc
abstract mixin class $StartupRunningCopyWith<$Res> implements $StartupStateCopyWith<$Res> {
  factory $StartupRunningCopyWith(StartupRunning value, $Res Function(StartupRunning) _then) = _$StartupRunningCopyWithImpl;
@useResult
$Res call({
 StartupStep step
});




}
/// @nodoc
class _$StartupRunningCopyWithImpl<$Res>
    implements $StartupRunningCopyWith<$Res> {
  _$StartupRunningCopyWithImpl(this._self, this._then);

  final StartupRunning _self;
  final $Res Function(StartupRunning) _then;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? step = null,}) {
  return _then(StartupRunning(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as StartupStep,
  ));
}


}

/// @nodoc


class StartupReady implements StartupState {
  const StartupReady({required this.coreVersion, required this.databasePath, this.warning});
  

 final  String coreVersion;
 final  String databasePath;
 final  Failure? warning;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartupReadyCopyWith<StartupReady> get copyWith => _$StartupReadyCopyWithImpl<StartupReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupReady&&(identical(other.coreVersion, coreVersion) || other.coreVersion == coreVersion)&&(identical(other.databasePath, databasePath) || other.databasePath == databasePath)&&(identical(other.warning, warning) || other.warning == warning));
}


@override
int get hashCode => Object.hash(runtimeType,coreVersion,databasePath,warning);

@override
String toString() {
  return 'StartupState.ready(coreVersion: $coreVersion, databasePath: $databasePath, warning: $warning)';
}


}

/// @nodoc
abstract mixin class $StartupReadyCopyWith<$Res> implements $StartupStateCopyWith<$Res> {
  factory $StartupReadyCopyWith(StartupReady value, $Res Function(StartupReady) _then) = _$StartupReadyCopyWithImpl;
@useResult
$Res call({
 String coreVersion, String databasePath, Failure? warning
});


$FailureCopyWith<$Res>? get warning;

}
/// @nodoc
class _$StartupReadyCopyWithImpl<$Res>
    implements $StartupReadyCopyWith<$Res> {
  _$StartupReadyCopyWithImpl(this._self, this._then);

  final StartupReady _self;
  final $Res Function(StartupReady) _then;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? coreVersion = null,Object? databasePath = null,Object? warning = freezed,}) {
  return _then(StartupReady(
coreVersion: null == coreVersion ? _self.coreVersion : coreVersion // ignore: cast_nullable_to_non_nullable
as String,databasePath: null == databasePath ? _self.databasePath : databasePath // ignore: cast_nullable_to_non_nullable
as String,warning: freezed == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get warning {
    if (_self.warning == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.warning!, (value) {
    return _then(_self.copyWith(warning: value));
  });
}
}

/// @nodoc


class StartupFailed implements StartupState {
  const StartupFailed({required this.step, required this.failure});
  

 final  StartupStep step;
 final  Failure failure;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartupFailedCopyWith<StartupFailed> get copyWith => _$StartupFailedCopyWithImpl<StartupFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupFailed&&(identical(other.step, step) || other.step == step)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,step,failure);

@override
String toString() {
  return 'StartupState.failed(step: $step, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StartupFailedCopyWith<$Res> implements $StartupStateCopyWith<$Res> {
  factory $StartupFailedCopyWith(StartupFailed value, $Res Function(StartupFailed) _then) = _$StartupFailedCopyWithImpl;
@useResult
$Res call({
 StartupStep step, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StartupFailedCopyWithImpl<$Res>
    implements $StartupFailedCopyWith<$Res> {
  _$StartupFailedCopyWithImpl(this._self, this._then);

  final StartupFailed _self;
  final $Res Function(StartupFailed) _then;

/// Create a copy of StartupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? step = null,Object? failure = null,}) {
  return _then(StartupFailed(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as StartupStep,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of StartupState
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
