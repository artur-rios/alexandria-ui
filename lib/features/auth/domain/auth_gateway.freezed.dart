// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthOutcome()';
}


}

/// @nodoc
class $AuthOutcomeCopyWith<$Res>  {
$AuthOutcomeCopyWith(AuthOutcome _, $Res Function(AuthOutcome) __);
}


/// Adds pattern-matching-related methods to [AuthOutcome].
extension AuthOutcomePatterns on AuthOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthenticatedOutcome value)?  authenticated,TResult Function( FailedOutcome value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that);case FailedOutcome() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthenticatedOutcome value)  authenticated,required TResult Function( FailedOutcome value)  failed,}){
final _that = this;
switch (_that) {
case AuthenticatedOutcome():
return authenticated(_that);case FailedOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthenticatedOutcome value)?  authenticated,TResult? Function( FailedOutcome value)?  failed,}){
final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that);case FailedOutcome() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Session session)?  authenticated,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session);case FailedOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Session session)  authenticated,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome():
return authenticated(_that.session);case FailedOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Session session)?  authenticated,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session);case FailedOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AuthenticatedOutcome implements AuthOutcome {
  const AuthenticatedOutcome({required this.session});
  

 final  Session session;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedOutcomeCopyWith<AuthenticatedOutcome> get copyWith => _$AuthenticatedOutcomeCopyWithImpl<AuthenticatedOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedOutcome&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'AuthOutcome.authenticated(session: $session)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedOutcomeCopyWith<$Res> implements $AuthOutcomeCopyWith<$Res> {
  factory $AuthenticatedOutcomeCopyWith(AuthenticatedOutcome value, $Res Function(AuthenticatedOutcome) _then) = _$AuthenticatedOutcomeCopyWithImpl;
@useResult
$Res call({
 Session session
});


$SessionCopyWith<$Res> get session;

}
/// @nodoc
class _$AuthenticatedOutcomeCopyWithImpl<$Res>
    implements $AuthenticatedOutcomeCopyWith<$Res> {
  _$AuthenticatedOutcomeCopyWithImpl(this._self, this._then);

  final AuthenticatedOutcome _self;
  final $Res Function(AuthenticatedOutcome) _then;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(AuthenticatedOutcome(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,
  ));
}

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class FailedOutcome implements AuthOutcome {
  const FailedOutcome({required this.failure});
  

 final  Failure failure;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedOutcomeCopyWith<FailedOutcome> get copyWith => _$FailedOutcomeCopyWithImpl<FailedOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedOutcome&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AuthOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FailedOutcomeCopyWith<$Res> implements $AuthOutcomeCopyWith<$Res> {
  factory $FailedOutcomeCopyWith(FailedOutcome value, $Res Function(FailedOutcome) _then) = _$FailedOutcomeCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FailedOutcomeCopyWithImpl<$Res>
    implements $FailedOutcomeCopyWith<$Res> {
  _$FailedOutcomeCopyWithImpl(this._self, this._then);

  final FailedOutcome _self;
  final $Res Function(FailedOutcome) _then;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FailedOutcome(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AuthOutcome
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
