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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Session session,  List<String>? recoveryCodes)?  authenticated,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session,_that.recoveryCodes);case FailedOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Session session,  List<String>? recoveryCodes)  authenticated,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome():
return authenticated(_that.session,_that.recoveryCodes);case FailedOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Session session,  List<String>? recoveryCodes)?  authenticated,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AuthenticatedOutcome() when authenticated != null:
return authenticated(_that.session,_that.recoveryCodes);case FailedOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AuthenticatedOutcome implements AuthOutcome {
  const AuthenticatedOutcome({required this.session, final  List<String>? recoveryCodes}): _recoveryCodes = recoveryCodes;
  

 final  Session session;
 final  List<String>? _recoveryCodes;
 List<String>? get recoveryCodes {
  final value = _recoveryCodes;
  if (value == null) return null;
  if (_recoveryCodes is EqualUnmodifiableListView) return _recoveryCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AuthOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedOutcomeCopyWith<AuthenticatedOutcome> get copyWith => _$AuthenticatedOutcomeCopyWithImpl<AuthenticatedOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedOutcome&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other._recoveryCodes, _recoveryCodes));
}


@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(_recoveryCodes));

@override
String toString() {
  return 'AuthOutcome.authenticated(session: $session, recoveryCodes: $recoveryCodes)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedOutcomeCopyWith<$Res> implements $AuthOutcomeCopyWith<$Res> {
  factory $AuthenticatedOutcomeCopyWith(AuthenticatedOutcome value, $Res Function(AuthenticatedOutcome) _then) = _$AuthenticatedOutcomeCopyWithImpl;
@useResult
$Res call({
 Session session, List<String>? recoveryCodes
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
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? recoveryCodes = freezed,}) {
  return _then(AuthenticatedOutcome(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,recoveryCodes: freezed == recoveryCodes ? _self._recoveryCodes : recoveryCodes // ignore: cast_nullable_to_non_nullable
as List<String>?,
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

/// @nodoc
mixin _$RecoveryOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecoveryOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryOutcome()';
}


}

/// @nodoc
class $RecoveryOutcomeCopyWith<$Res>  {
$RecoveryOutcomeCopyWith(RecoveryOutcome _, $Res Function(RecoveryOutcome) __);
}


/// Adds pattern-matching-related methods to [RecoveryOutcome].
extension RecoveryOutcomePatterns on RecoveryOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecoveredOutcome value)?  recovered,TResult Function( FailedRecoveryOutcome value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecoveredOutcome() when recovered != null:
return recovered(_that);case FailedRecoveryOutcome() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecoveredOutcome value)  recovered,required TResult Function( FailedRecoveryOutcome value)  failed,}){
final _that = this;
switch (_that) {
case RecoveredOutcome():
return recovered(_that);case FailedRecoveryOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecoveredOutcome value)?  recovered,TResult? Function( FailedRecoveryOutcome value)?  failed,}){
final _that = this;
switch (_that) {
case RecoveredOutcome() when recovered != null:
return recovered(_that);case FailedRecoveryOutcome() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  recovered,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecoveredOutcome() when recovered != null:
return recovered();case FailedRecoveryOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  recovered,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case RecoveredOutcome():
return recovered();case FailedRecoveryOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  recovered,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case RecoveredOutcome() when recovered != null:
return recovered();case FailedRecoveryOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RecoveredOutcome implements RecoveryOutcome {
  const RecoveredOutcome();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecoveredOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryOutcome.recovered()';
}


}




/// @nodoc


class FailedRecoveryOutcome implements RecoveryOutcome {
  const FailedRecoveryOutcome({required this.failure});
  

 final  Failure failure;

/// Create a copy of RecoveryOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedRecoveryOutcomeCopyWith<FailedRecoveryOutcome> get copyWith => _$FailedRecoveryOutcomeCopyWithImpl<FailedRecoveryOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedRecoveryOutcome&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RecoveryOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FailedRecoveryOutcomeCopyWith<$Res> implements $RecoveryOutcomeCopyWith<$Res> {
  factory $FailedRecoveryOutcomeCopyWith(FailedRecoveryOutcome value, $Res Function(FailedRecoveryOutcome) _then) = _$FailedRecoveryOutcomeCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FailedRecoveryOutcomeCopyWithImpl<$Res>
    implements $FailedRecoveryOutcomeCopyWith<$Res> {
  _$FailedRecoveryOutcomeCopyWithImpl(this._self, this._then);

  final FailedRecoveryOutcome _self;
  final $Res Function(FailedRecoveryOutcome) _then;

/// Create a copy of RecoveryOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FailedRecoveryOutcome(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RecoveryOutcome
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
mixin _$AccountSummary {

/// The account's address, as the core holds it.
 String get email;/// How many recovery codes are still unspent, or `null` when the core did
/// not report it.
///
/// Nullable rather than defaulted to zero: zero means the account cannot
/// currently be recovered, which is a thing worth saying, and a core that
/// answered without the number must not be made to say it (`FR-AU-19`).
 int? get recoveryCodesRemaining;
/// Create a copy of AccountSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountSummaryCopyWith<AccountSummary> get copyWith => _$AccountSummaryCopyWithImpl<AccountSummary>(this as AccountSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountSummary&&(identical(other.email, email) || other.email == email)&&(identical(other.recoveryCodesRemaining, recoveryCodesRemaining) || other.recoveryCodesRemaining == recoveryCodesRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,email,recoveryCodesRemaining);

@override
String toString() {
  return 'AccountSummary(email: $email, recoveryCodesRemaining: $recoveryCodesRemaining)';
}


}

/// @nodoc
abstract mixin class $AccountSummaryCopyWith<$Res>  {
  factory $AccountSummaryCopyWith(AccountSummary value, $Res Function(AccountSummary) _then) = _$AccountSummaryCopyWithImpl;
@useResult
$Res call({
 String email, int? recoveryCodesRemaining
});




}
/// @nodoc
class _$AccountSummaryCopyWithImpl<$Res>
    implements $AccountSummaryCopyWith<$Res> {
  _$AccountSummaryCopyWithImpl(this._self, this._then);

  final AccountSummary _self;
  final $Res Function(AccountSummary) _then;

/// Create a copy of AccountSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? recoveryCodesRemaining = freezed,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,recoveryCodesRemaining: freezed == recoveryCodesRemaining ? _self.recoveryCodesRemaining : recoveryCodesRemaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountSummary].
extension AccountSummaryPatterns on AccountSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountSummary value)  $default,){
final _that = this;
switch (_that) {
case _AccountSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AccountSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  int? recoveryCodesRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountSummary() when $default != null:
return $default(_that.email,_that.recoveryCodesRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  int? recoveryCodesRemaining)  $default,) {final _that = this;
switch (_that) {
case _AccountSummary():
return $default(_that.email,_that.recoveryCodesRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  int? recoveryCodesRemaining)?  $default,) {final _that = this;
switch (_that) {
case _AccountSummary() when $default != null:
return $default(_that.email,_that.recoveryCodesRemaining);case _:
  return null;

}
}

}

/// @nodoc


class _AccountSummary implements AccountSummary {
  const _AccountSummary({required this.email, this.recoveryCodesRemaining});
  

/// The account's address, as the core holds it.
@override final  String email;
/// How many recovery codes are still unspent, or `null` when the core did
/// not report it.
///
/// Nullable rather than defaulted to zero: zero means the account cannot
/// currently be recovered, which is a thing worth saying, and a core that
/// answered without the number must not be made to say it (`FR-AU-19`).
@override final  int? recoveryCodesRemaining;

/// Create a copy of AccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountSummaryCopyWith<_AccountSummary> get copyWith => __$AccountSummaryCopyWithImpl<_AccountSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountSummary&&(identical(other.email, email) || other.email == email)&&(identical(other.recoveryCodesRemaining, recoveryCodesRemaining) || other.recoveryCodesRemaining == recoveryCodesRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,email,recoveryCodesRemaining);

@override
String toString() {
  return 'AccountSummary(email: $email, recoveryCodesRemaining: $recoveryCodesRemaining)';
}


}

/// @nodoc
abstract mixin class _$AccountSummaryCopyWith<$Res> implements $AccountSummaryCopyWith<$Res> {
  factory _$AccountSummaryCopyWith(_AccountSummary value, $Res Function(_AccountSummary) _then) = __$AccountSummaryCopyWithImpl;
@override @useResult
$Res call({
 String email, int? recoveryCodesRemaining
});




}
/// @nodoc
class __$AccountSummaryCopyWithImpl<$Res>
    implements _$AccountSummaryCopyWith<$Res> {
  __$AccountSummaryCopyWithImpl(this._self, this._then);

  final _AccountSummary _self;
  final $Res Function(_AccountSummary) _then;

/// Create a copy of AccountSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? recoveryCodesRemaining = freezed,}) {
  return _then(_AccountSummary(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,recoveryCodesRemaining: freezed == recoveryCodesRemaining ? _self.recoveryCodesRemaining : recoveryCodesRemaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$AccountOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountOutcome()';
}


}

/// @nodoc
class $AccountOutcomeCopyWith<$Res>  {
$AccountOutcomeCopyWith(AccountOutcome _, $Res Function(AccountOutcome) __);
}


/// Adds pattern-matching-related methods to [AccountOutcome].
extension AccountOutcomePatterns on AccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountRead value)?  read,TResult Function( AccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountRead() when read != null:
return read(_that);case AccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountRead value)  read,required TResult Function( AccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case AccountRead():
return read(_that);case AccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountRead value)?  read,TResult? Function( AccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AccountRead() when read != null:
return read(_that);case AccountFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AccountSummary account)?  read,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountRead() when read != null:
return read(_that.account);case AccountFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AccountSummary account)  read,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AccountRead():
return read(_that.account);case AccountFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AccountSummary account)?  read,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AccountRead() when read != null:
return read(_that.account);case AccountFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AccountRead implements AccountOutcome {
  const AccountRead({required this.account});
  

 final  AccountSummary account;

/// Create a copy of AccountOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountReadCopyWith<AccountRead> get copyWith => _$AccountReadCopyWithImpl<AccountRead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountRead&&(identical(other.account, account) || other.account == account));
}


@override
int get hashCode => Object.hash(runtimeType,account);

@override
String toString() {
  return 'AccountOutcome.read(account: $account)';
}


}

/// @nodoc
abstract mixin class $AccountReadCopyWith<$Res> implements $AccountOutcomeCopyWith<$Res> {
  factory $AccountReadCopyWith(AccountRead value, $Res Function(AccountRead) _then) = _$AccountReadCopyWithImpl;
@useResult
$Res call({
 AccountSummary account
});


$AccountSummaryCopyWith<$Res> get account;

}
/// @nodoc
class _$AccountReadCopyWithImpl<$Res>
    implements $AccountReadCopyWith<$Res> {
  _$AccountReadCopyWithImpl(this._self, this._then);

  final AccountRead _self;
  final $Res Function(AccountRead) _then;

/// Create a copy of AccountOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? account = null,}) {
  return _then(AccountRead(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountSummary,
  ));
}

/// Create a copy of AccountOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountSummaryCopyWith<$Res> get account {
  
  return $AccountSummaryCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

/// @nodoc


class AccountFailed implements AccountOutcome {
  const AccountFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of AccountOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountFailedCopyWith<AccountFailed> get copyWith => _$AccountFailedCopyWithImpl<AccountFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AccountOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AccountFailedCopyWith<$Res> implements $AccountOutcomeCopyWith<$Res> {
  factory $AccountFailedCopyWith(AccountFailed value, $Res Function(AccountFailed) _then) = _$AccountFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AccountFailedCopyWithImpl<$Res>
    implements $AccountFailedCopyWith<$Res> {
  _$AccountFailedCopyWithImpl(this._self, this._then);

  final AccountFailed _self;
  final $Res Function(AccountFailed) _then;

/// Create a copy of AccountOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AccountFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AccountOutcome
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
mixin _$RegenerateOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegenerateOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegenerateOutcome()';
}


}

/// @nodoc
class $RegenerateOutcomeCopyWith<$Res>  {
$RegenerateOutcomeCopyWith(RegenerateOutcome _, $Res Function(RegenerateOutcome) __);
}


/// Adds pattern-matching-related methods to [RegenerateOutcome].
extension RegenerateOutcomePatterns on RegenerateOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Regenerated value)?  regenerated,TResult Function( FailedRegenerateOutcome value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Regenerated() when regenerated != null:
return regenerated(_that);case FailedRegenerateOutcome() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Regenerated value)  regenerated,required TResult Function( FailedRegenerateOutcome value)  failed,}){
final _that = this;
switch (_that) {
case Regenerated():
return regenerated(_that);case FailedRegenerateOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Regenerated value)?  regenerated,TResult? Function( FailedRegenerateOutcome value)?  failed,}){
final _that = this;
switch (_that) {
case Regenerated() when regenerated != null:
return regenerated(_that);case FailedRegenerateOutcome() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<String> recoveryCodes)?  regenerated,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Regenerated() when regenerated != null:
return regenerated(_that.recoveryCodes);case FailedRegenerateOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<String> recoveryCodes)  regenerated,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case Regenerated():
return regenerated(_that.recoveryCodes);case FailedRegenerateOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<String> recoveryCodes)?  regenerated,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case Regenerated() when regenerated != null:
return regenerated(_that.recoveryCodes);case FailedRegenerateOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class Regenerated implements RegenerateOutcome {
  const Regenerated({required final  List<String> recoveryCodes}): _recoveryCodes = recoveryCodes;
  

 final  List<String> _recoveryCodes;
 List<String> get recoveryCodes {
  if (_recoveryCodes is EqualUnmodifiableListView) return _recoveryCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recoveryCodes);
}


/// Create a copy of RegenerateOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegeneratedCopyWith<Regenerated> get copyWith => _$RegeneratedCopyWithImpl<Regenerated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Regenerated&&const DeepCollectionEquality().equals(other._recoveryCodes, _recoveryCodes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recoveryCodes));

@override
String toString() {
  return 'RegenerateOutcome.regenerated(recoveryCodes: $recoveryCodes)';
}


}

/// @nodoc
abstract mixin class $RegeneratedCopyWith<$Res> implements $RegenerateOutcomeCopyWith<$Res> {
  factory $RegeneratedCopyWith(Regenerated value, $Res Function(Regenerated) _then) = _$RegeneratedCopyWithImpl;
@useResult
$Res call({
 List<String> recoveryCodes
});




}
/// @nodoc
class _$RegeneratedCopyWithImpl<$Res>
    implements $RegeneratedCopyWith<$Res> {
  _$RegeneratedCopyWithImpl(this._self, this._then);

  final Regenerated _self;
  final $Res Function(Regenerated) _then;

/// Create a copy of RegenerateOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recoveryCodes = null,}) {
  return _then(Regenerated(
recoveryCodes: null == recoveryCodes ? _self._recoveryCodes : recoveryCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class FailedRegenerateOutcome implements RegenerateOutcome {
  const FailedRegenerateOutcome({required this.failure});
  

 final  Failure failure;

/// Create a copy of RegenerateOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedRegenerateOutcomeCopyWith<FailedRegenerateOutcome> get copyWith => _$FailedRegenerateOutcomeCopyWithImpl<FailedRegenerateOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedRegenerateOutcome&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RegenerateOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FailedRegenerateOutcomeCopyWith<$Res> implements $RegenerateOutcomeCopyWith<$Res> {
  factory $FailedRegenerateOutcomeCopyWith(FailedRegenerateOutcome value, $Res Function(FailedRegenerateOutcome) _then) = _$FailedRegenerateOutcomeCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FailedRegenerateOutcomeCopyWithImpl<$Res>
    implements $FailedRegenerateOutcomeCopyWith<$Res> {
  _$FailedRegenerateOutcomeCopyWithImpl(this._self, this._then);

  final FailedRegenerateOutcome _self;
  final $Res Function(FailedRegenerateOutcome) _then;

/// Create a copy of RegenerateOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FailedRegenerateOutcome(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RegenerateOutcome
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
mixin _$CredentialChangeOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialChangeOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CredentialChangeOutcome()';
}


}

/// @nodoc
class $CredentialChangeOutcomeCopyWith<$Res>  {
$CredentialChangeOutcomeCopyWith(CredentialChangeOutcome _, $Res Function(CredentialChangeOutcome) __);
}


/// Adds pattern-matching-related methods to [CredentialChangeOutcome].
extension CredentialChangeOutcomePatterns on CredentialChangeOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChangedOutcome value)?  changed,TResult Function( FailedChangeOutcome value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChangedOutcome() when changed != null:
return changed(_that);case FailedChangeOutcome() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChangedOutcome value)  changed,required TResult Function( FailedChangeOutcome value)  failed,}){
final _that = this;
switch (_that) {
case ChangedOutcome():
return changed(_that);case FailedChangeOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChangedOutcome value)?  changed,TResult? Function( FailedChangeOutcome value)?  failed,}){
final _that = this;
switch (_that) {
case ChangedOutcome() when changed != null:
return changed(_that);case FailedChangeOutcome() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  changed,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChangedOutcome() when changed != null:
return changed();case FailedChangeOutcome() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  changed,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case ChangedOutcome():
return changed();case FailedChangeOutcome():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  changed,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case ChangedOutcome() when changed != null:
return changed();case FailedChangeOutcome() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ChangedOutcome implements CredentialChangeOutcome {
  const ChangedOutcome();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangedOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CredentialChangeOutcome.changed()';
}


}




/// @nodoc


class FailedChangeOutcome implements CredentialChangeOutcome {
  const FailedChangeOutcome({required this.failure});
  

 final  Failure failure;

/// Create a copy of CredentialChangeOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedChangeOutcomeCopyWith<FailedChangeOutcome> get copyWith => _$FailedChangeOutcomeCopyWithImpl<FailedChangeOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedChangeOutcome&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CredentialChangeOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FailedChangeOutcomeCopyWith<$Res> implements $CredentialChangeOutcomeCopyWith<$Res> {
  factory $FailedChangeOutcomeCopyWith(FailedChangeOutcome value, $Res Function(FailedChangeOutcome) _then) = _$FailedChangeOutcomeCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FailedChangeOutcomeCopyWithImpl<$Res>
    implements $FailedChangeOutcomeCopyWith<$Res> {
  _$FailedChangeOutcomeCopyWithImpl(this._self, this._then);

  final FailedChangeOutcome _self;
  final $Res Function(FailedChangeOutcome) _then;

/// Create a copy of CredentialChangeOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FailedChangeOutcome(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CredentialChangeOutcome
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
