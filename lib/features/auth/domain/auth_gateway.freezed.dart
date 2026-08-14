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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Session session,  ConfirmationDelivery? confirmation)?  authenticated,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session,_that.confirmation);case FailedOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Session session,  ConfirmationDelivery? confirmation)  authenticated,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome():
return authenticated(_that.session,_that.confirmation);case FailedOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Session session,  ConfirmationDelivery? confirmation)?  authenticated,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session,_that.confirmation);case FailedOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AuthenticatedOutcome implements AuthOutcome {
  const AuthenticatedOutcome({required this.session, this.confirmation});
  

 final  Session session;
 final  ConfirmationDelivery? confirmation;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedOutcomeCopyWith<AuthenticatedOutcome> get copyWith => _$AuthenticatedOutcomeCopyWithImpl<AuthenticatedOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedOutcome&&(identical(other.session, session) || other.session == session)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,session,confirmation);

@override
String toString() {
  return 'AuthOutcome.authenticated(session: $session, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedOutcomeCopyWith<$Res> implements $AuthOutcomeCopyWith<$Res> {
  factory $AuthenticatedOutcomeCopyWith(AuthenticatedOutcome value, $Res Function(AuthenticatedOutcome) _then) = _$AuthenticatedOutcomeCopyWithImpl;
@useResult
$Res call({
 Session session, ConfirmationDelivery? confirmation
});


$SessionCopyWith<$Res> get session;$ConfirmationDeliveryCopyWith<$Res>? get confirmation;

}
/// @nodoc
class _$AuthenticatedOutcomeCopyWithImpl<$Res>
    implements $AuthenticatedOutcomeCopyWith<$Res> {
  _$AuthenticatedOutcomeCopyWithImpl(this._self, this._then);

  final AuthenticatedOutcome _self;
  final $Res Function(AuthenticatedOutcome) _then;

/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? confirmation = freezed,}) {
  return _then(AuthenticatedOutcome(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as ConfirmationDelivery?,
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
}/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConfirmationDeliveryCopyWith<$Res>? get confirmation {
    if (_self.confirmation == null) {
    return null;
  }

  return $ConfirmationDeliveryCopyWith<$Res>(_self.confirmation!, (value) {
    return _then(_self.copyWith(confirmation: value));
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

/// @nodoc
mixin _$ConfirmationDelivery {

/// Whether the message reached a transport.
 bool get sent;/// Why it did not, as the core's stable reason code — today
/// `mail_not_configured`. Absent when [sent] is `true`.
 String? get reasonCode;
/// Create a copy of ConfirmationDelivery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfirmationDeliveryCopyWith<ConfirmationDelivery> get copyWith => _$ConfirmationDeliveryCopyWithImpl<ConfirmationDelivery>(this as ConfirmationDelivery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfirmationDelivery&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode));
}


@override
int get hashCode => Object.hash(runtimeType,sent,reasonCode);

@override
String toString() {
  return 'ConfirmationDelivery(sent: $sent, reasonCode: $reasonCode)';
}


}

/// @nodoc
abstract mixin class $ConfirmationDeliveryCopyWith<$Res>  {
  factory $ConfirmationDeliveryCopyWith(ConfirmationDelivery value, $Res Function(ConfirmationDelivery) _then) = _$ConfirmationDeliveryCopyWithImpl;
@useResult
$Res call({
 bool sent, String? reasonCode
});




}
/// @nodoc
class _$ConfirmationDeliveryCopyWithImpl<$Res>
    implements $ConfirmationDeliveryCopyWith<$Res> {
  _$ConfirmationDeliveryCopyWithImpl(this._self, this._then);

  final ConfirmationDelivery _self;
  final $Res Function(ConfirmationDelivery) _then;

/// Create a copy of ConfirmationDelivery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sent = null,Object? reasonCode = freezed,}) {
  return _then(_self.copyWith(
sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as bool,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfirmationDelivery].
extension ConfirmationDeliveryPatterns on ConfirmationDelivery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConfirmationDelivery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConfirmationDelivery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConfirmationDelivery value)  $default,){
final _that = this;
switch (_that) {
case _ConfirmationDelivery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConfirmationDelivery value)?  $default,){
final _that = this;
switch (_that) {
case _ConfirmationDelivery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool sent,  String? reasonCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConfirmationDelivery() when $default != null:
return $default(_that.sent,_that.reasonCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool sent,  String? reasonCode)  $default,) {final _that = this;
switch (_that) {
case _ConfirmationDelivery():
return $default(_that.sent,_that.reasonCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool sent,  String? reasonCode)?  $default,) {final _that = this;
switch (_that) {
case _ConfirmationDelivery() when $default != null:
return $default(_that.sent,_that.reasonCode);case _:
  return null;

}
}

}

/// @nodoc


class _ConfirmationDelivery implements ConfirmationDelivery {
  const _ConfirmationDelivery({required this.sent, this.reasonCode});
  

/// Whether the message reached a transport.
@override final  bool sent;
/// Why it did not, as the core's stable reason code — today
/// `mail_not_configured`. Absent when [sent] is `true`.
@override final  String? reasonCode;

/// Create a copy of ConfirmationDelivery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmationDeliveryCopyWith<_ConfirmationDelivery> get copyWith => __$ConfirmationDeliveryCopyWithImpl<_ConfirmationDelivery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmationDelivery&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode));
}


@override
int get hashCode => Object.hash(runtimeType,sent,reasonCode);

@override
String toString() {
  return 'ConfirmationDelivery(sent: $sent, reasonCode: $reasonCode)';
}


}

/// @nodoc
abstract mixin class _$ConfirmationDeliveryCopyWith<$Res> implements $ConfirmationDeliveryCopyWith<$Res> {
  factory _$ConfirmationDeliveryCopyWith(_ConfirmationDelivery value, $Res Function(_ConfirmationDelivery) _then) = __$ConfirmationDeliveryCopyWithImpl;
@override @useResult
$Res call({
 bool sent, String? reasonCode
});




}
/// @nodoc
class __$ConfirmationDeliveryCopyWithImpl<$Res>
    implements _$ConfirmationDeliveryCopyWith<$Res> {
  __$ConfirmationDeliveryCopyWithImpl(this._self, this._then);

  final _ConfirmationDelivery _self;
  final $Res Function(_ConfirmationDelivery) _then;

/// Create a copy of ConfirmationDelivery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sent = null,Object? reasonCode = freezed,}) {
  return _then(_ConfirmationDelivery(
sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as bool,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
