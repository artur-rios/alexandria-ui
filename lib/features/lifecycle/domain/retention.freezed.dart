// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retention.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RetentionWindow {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetentionWindow);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RetentionWindow()';
}


}

/// @nodoc
class $RetentionWindowCopyWith<$Res>  {
$RetentionWindowCopyWith(RetentionWindow _, $Res Function(RetentionWindow) __);
}


/// Adds pattern-matching-related methods to [RetentionWindow].
extension RetentionWindowPatterns on RetentionWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RetentionWindowLoaded value)?  loaded,TResult Function( RetentionWindowFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RetentionWindowLoaded() when loaded != null:
return loaded(_that);case RetentionWindowFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RetentionWindowLoaded value)  loaded,required TResult Function( RetentionWindowFailed value)  failed,}){
final _that = this;
switch (_that) {
case RetentionWindowLoaded():
return loaded(_that);case RetentionWindowFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RetentionWindowLoaded value)?  loaded,TResult? Function( RetentionWindowFailed value)?  failed,}){
final _that = this;
switch (_that) {
case RetentionWindowLoaded() when loaded != null:
return loaded(_that);case RetentionWindowFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int days)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RetentionWindowLoaded() when loaded != null:
return loaded(_that.days);case RetentionWindowFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int days)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case RetentionWindowLoaded():
return loaded(_that.days);case RetentionWindowFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int days)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case RetentionWindowLoaded() when loaded != null:
return loaded(_that.days);case RetentionWindowFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RetentionWindowLoaded implements RetentionWindow {
  const RetentionWindowLoaded({required this.days});
  

 final  int days;

/// Create a copy of RetentionWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetentionWindowLoadedCopyWith<RetentionWindowLoaded> get copyWith => _$RetentionWindowLoadedCopyWithImpl<RetentionWindowLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetentionWindowLoaded&&(identical(other.days, days) || other.days == days));
}


@override
int get hashCode => Object.hash(runtimeType,days);

@override
String toString() {
  return 'RetentionWindow.loaded(days: $days)';
}


}

/// @nodoc
abstract mixin class $RetentionWindowLoadedCopyWith<$Res> implements $RetentionWindowCopyWith<$Res> {
  factory $RetentionWindowLoadedCopyWith(RetentionWindowLoaded value, $Res Function(RetentionWindowLoaded) _then) = _$RetentionWindowLoadedCopyWithImpl;
@useResult
$Res call({
 int days
});




}
/// @nodoc
class _$RetentionWindowLoadedCopyWithImpl<$Res>
    implements $RetentionWindowLoadedCopyWith<$Res> {
  _$RetentionWindowLoadedCopyWithImpl(this._self, this._then);

  final RetentionWindowLoaded _self;
  final $Res Function(RetentionWindowLoaded) _then;

/// Create a copy of RetentionWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? days = null,}) {
  return _then(RetentionWindowLoaded(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RetentionWindowFailed implements RetentionWindow {
  const RetentionWindowFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of RetentionWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetentionWindowFailedCopyWith<RetentionWindowFailed> get copyWith => _$RetentionWindowFailedCopyWithImpl<RetentionWindowFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetentionWindowFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RetentionWindow.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RetentionWindowFailedCopyWith<$Res> implements $RetentionWindowCopyWith<$Res> {
  factory $RetentionWindowFailedCopyWith(RetentionWindowFailed value, $Res Function(RetentionWindowFailed) _then) = _$RetentionWindowFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RetentionWindowFailedCopyWithImpl<$Res>
    implements $RetentionWindowFailedCopyWith<$Res> {
  _$RetentionWindowFailedCopyWithImpl(this._self, this._then);

  final RetentionWindowFailed _self;
  final $Res Function(RetentionWindowFailed) _then;

/// Create a copy of RetentionWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RetentionWindowFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RetentionWindow
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
