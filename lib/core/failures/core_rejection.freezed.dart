// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'core_rejection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoreRejection {

/// The stable identifier, e.g. `password_too_short`.
 String get code;/// The values behind the code, e.g. `{'min': '12'}` — the bound that was
/// violated, so the message can state it rather than hardcode a number
/// this application does not own.
 Map<String, String> get params;/// The core's own English sentence. For the log and for a report; the
/// screen uses [code].
 String? get message;
/// Create a copy of CoreRejection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreRejectionCopyWith<CoreRejection> get copyWith => _$CoreRejectionCopyWithImpl<CoreRejection>(this as CoreRejection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreRejection&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.params, params)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,const DeepCollectionEquality().hash(params),message);

@override
String toString() {
  return 'CoreRejection(code: $code, params: $params, message: $message)';
}


}

/// @nodoc
abstract mixin class $CoreRejectionCopyWith<$Res>  {
  factory $CoreRejectionCopyWith(CoreRejection value, $Res Function(CoreRejection) _then) = _$CoreRejectionCopyWithImpl;
@useResult
$Res call({
 String code, Map<String, String> params, String? message
});




}
/// @nodoc
class _$CoreRejectionCopyWithImpl<$Res>
    implements $CoreRejectionCopyWith<$Res> {
  _$CoreRejectionCopyWithImpl(this._self, this._then);

  final CoreRejection _self;
  final $Res Function(CoreRejection) _then;

/// Create a copy of CoreRejection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? params = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoreRejection].
extension CoreRejectionPatterns on CoreRejection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoreRejection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoreRejection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoreRejection value)  $default,){
final _that = this;
switch (_that) {
case _CoreRejection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoreRejection value)?  $default,){
final _that = this;
switch (_that) {
case _CoreRejection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  Map<String, String> params,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoreRejection() when $default != null:
return $default(_that.code,_that.params,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  Map<String, String> params,  String? message)  $default,) {final _that = this;
switch (_that) {
case _CoreRejection():
return $default(_that.code,_that.params,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  Map<String, String> params,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _CoreRejection() when $default != null:
return $default(_that.code,_that.params,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _CoreRejection implements CoreRejection {
  const _CoreRejection({required this.code, final  Map<String, String> params = const <String, String>{}, this.message}): _params = params;
  

/// The stable identifier, e.g. `password_too_short`.
@override final  String code;
/// The values behind the code, e.g. `{'min': '12'}` — the bound that was
/// violated, so the message can state it rather than hardcode a number
/// this application does not own.
 final  Map<String, String> _params;
/// The values behind the code, e.g. `{'min': '12'}` — the bound that was
/// violated, so the message can state it rather than hardcode a number
/// this application does not own.
@override@JsonKey() Map<String, String> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}

/// The core's own English sentence. For the log and for a report; the
/// screen uses [code].
@override final  String? message;

/// Create a copy of CoreRejection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoreRejectionCopyWith<_CoreRejection> get copyWith => __$CoreRejectionCopyWithImpl<_CoreRejection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoreRejection&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other._params, _params)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,const DeepCollectionEquality().hash(_params),message);

@override
String toString() {
  return 'CoreRejection(code: $code, params: $params, message: $message)';
}


}

/// @nodoc
abstract mixin class _$CoreRejectionCopyWith<$Res> implements $CoreRejectionCopyWith<$Res> {
  factory _$CoreRejectionCopyWith(_CoreRejection value, $Res Function(_CoreRejection) _then) = __$CoreRejectionCopyWithImpl;
@override @useResult
$Res call({
 String code, Map<String, String> params, String? message
});




}
/// @nodoc
class __$CoreRejectionCopyWithImpl<$Res>
    implements _$CoreRejectionCopyWith<$Res> {
  __$CoreRejectionCopyWithImpl(this._self, this._then);

  final _CoreRejection _self;
  final $Res Function(_CoreRejection) _then;

/// Create a copy of CoreRejection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? params = null,Object? message = freezed,}) {
  return _then(_CoreRejection(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
