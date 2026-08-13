// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginProblem {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginProblem()';
}


}

/// @nodoc
class $LoginProblemCopyWith<$Res>  {
$LoginProblemCopyWith(LoginProblem _, $Res Function(LoginProblem) __);
}


/// Adds pattern-matching-related methods to [LoginProblem].
extension LoginProblemPatterns on LoginProblem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RejectedProblem value)?  rejected,TResult Function( NoAccountProblem value)?  noAccount,TResult Function( CoreNotReadyProblem value)?  coreNotReady,TResult Function( OtherProblem value)?  other,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RejectedProblem() when rejected != null:
return rejected(_that);case NoAccountProblem() when noAccount != null:
return noAccount(_that);case CoreNotReadyProblem() when coreNotReady != null:
return coreNotReady(_that);case OtherProblem() when other != null:
return other(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RejectedProblem value)  rejected,required TResult Function( NoAccountProblem value)  noAccount,required TResult Function( CoreNotReadyProblem value)  coreNotReady,required TResult Function( OtherProblem value)  other,}){
final _that = this;
switch (_that) {
case RejectedProblem():
return rejected(_that);case NoAccountProblem():
return noAccount(_that);case CoreNotReadyProblem():
return coreNotReady(_that);case OtherProblem():
return other(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RejectedProblem value)?  rejected,TResult? Function( NoAccountProblem value)?  noAccount,TResult? Function( CoreNotReadyProblem value)?  coreNotReady,TResult? Function( OtherProblem value)?  other,}){
final _that = this;
switch (_that) {
case RejectedProblem() when rejected != null:
return rejected(_that);case NoAccountProblem() when noAccount != null:
return noAccount(_that);case CoreNotReadyProblem() when coreNotReady != null:
return coreNotReady(_that);case OtherProblem() when other != null:
return other(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  rejected,TResult Function()?  noAccount,TResult Function( Failure failure)?  coreNotReady,TResult Function( Failure failure)?  other,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RejectedProblem() when rejected != null:
return rejected();case NoAccountProblem() when noAccount != null:
return noAccount();case CoreNotReadyProblem() when coreNotReady != null:
return coreNotReady(_that.failure);case OtherProblem() when other != null:
return other(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  rejected,required TResult Function()  noAccount,required TResult Function( Failure failure)  coreNotReady,required TResult Function( Failure failure)  other,}) {final _that = this;
switch (_that) {
case RejectedProblem():
return rejected();case NoAccountProblem():
return noAccount();case CoreNotReadyProblem():
return coreNotReady(_that.failure);case OtherProblem():
return other(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  rejected,TResult? Function()?  noAccount,TResult? Function( Failure failure)?  coreNotReady,TResult? Function( Failure failure)?  other,}) {final _that = this;
switch (_that) {
case RejectedProblem() when rejected != null:
return rejected();case NoAccountProblem() when noAccount != null:
return noAccount();case CoreNotReadyProblem() when coreNotReady != null:
return coreNotReady(_that.failure);case OtherProblem() when other != null:
return other(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RejectedProblem implements LoginProblem {
  const RejectedProblem();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectedProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginProblem.rejected()';
}


}




/// @nodoc


class NoAccountProblem implements LoginProblem {
  const NoAccountProblem();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoAccountProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginProblem.noAccount()';
}


}




/// @nodoc


class CoreNotReadyProblem implements LoginProblem {
  const CoreNotReadyProblem({required this.failure});
  

 final  Failure failure;

/// Create a copy of LoginProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreNotReadyProblemCopyWith<CoreNotReadyProblem> get copyWith => _$CoreNotReadyProblemCopyWithImpl<CoreNotReadyProblem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreNotReadyProblem&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LoginProblem.coreNotReady(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CoreNotReadyProblemCopyWith<$Res> implements $LoginProblemCopyWith<$Res> {
  factory $CoreNotReadyProblemCopyWith(CoreNotReadyProblem value, $Res Function(CoreNotReadyProblem) _then) = _$CoreNotReadyProblemCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CoreNotReadyProblemCopyWithImpl<$Res>
    implements $CoreNotReadyProblemCopyWith<$Res> {
  _$CoreNotReadyProblemCopyWithImpl(this._self, this._then);

  final CoreNotReadyProblem _self;
  final $Res Function(CoreNotReadyProblem) _then;

/// Create a copy of LoginProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CoreNotReadyProblem(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LoginProblem
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


class OtherProblem implements LoginProblem {
  const OtherProblem({required this.failure});
  

 final  Failure failure;

/// Create a copy of LoginProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtherProblemCopyWith<OtherProblem> get copyWith => _$OtherProblemCopyWithImpl<OtherProblem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtherProblem&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LoginProblem.other(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OtherProblemCopyWith<$Res> implements $LoginProblemCopyWith<$Res> {
  factory $OtherProblemCopyWith(OtherProblem value, $Res Function(OtherProblem) _then) = _$OtherProblemCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$OtherProblemCopyWithImpl<$Res>
    implements $OtherProblemCopyWith<$Res> {
  _$OtherProblemCopyWithImpl(this._self, this._then);

  final OtherProblem _self;
  final $Res Function(OtherProblem) _then;

/// Create a copy of LoginProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(OtherProblem(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LoginProblem
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
mixin _$LoginState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginState()';
}


}

/// @nodoc
class $LoginStateCopyWith<$Res>  {
$LoginStateCopyWith(LoginState _, $Res Function(LoginState) __);
}


/// Adds pattern-matching-related methods to [LoginState].
extension LoginStatePatterns on LoginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoginEditing value)?  editing,TResult Function( LoginSubmitting value)?  submitting,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoginEditing() when editing != null:
return editing(_that);case LoginSubmitting() when submitting != null:
return submitting(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoginEditing value)  editing,required TResult Function( LoginSubmitting value)  submitting,}){
final _that = this;
switch (_that) {
case LoginEditing():
return editing(_that);case LoginSubmitting():
return submitting(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoginEditing value)?  editing,TResult? Function( LoginSubmitting value)?  submitting,}){
final _that = this;
switch (_that) {
case LoginEditing() when editing != null:
return editing(_that);case LoginSubmitting() when submitting != null:
return submitting(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginProblem? problem)?  editing,TResult Function()?  submitting,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoginEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.problem);case LoginSubmitting() when submitting != null:
return submitting();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginProblem? problem)  editing,required TResult Function()  submitting,}) {final _that = this;
switch (_that) {
case LoginEditing():
return editing(_that.emailError,_that.passwordError,_that.problem);case LoginSubmitting():
return submitting();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginProblem? problem)?  editing,TResult? Function()?  submitting,}) {final _that = this;
switch (_that) {
case LoginEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.problem);case LoginSubmitting() when submitting != null:
return submitting();case _:
  return null;

}
}

}

/// @nodoc


class LoginEditing implements LoginState {
  const LoginEditing({this.emailError, this.passwordError, this.problem});
  

 final  LoginFieldError? emailError;
 final  LoginFieldError? passwordError;
 final  LoginProblem? problem;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginEditingCopyWith<LoginEditing> get copyWith => _$LoginEditingCopyWithImpl<LoginEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEditing&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,emailError,passwordError,problem);

@override
String toString() {
  return 'LoginState.editing(emailError: $emailError, passwordError: $passwordError, problem: $problem)';
}


}

/// @nodoc
abstract mixin class $LoginEditingCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginEditingCopyWith(LoginEditing value, $Res Function(LoginEditing) _then) = _$LoginEditingCopyWithImpl;
@useResult
$Res call({
 LoginFieldError? emailError, LoginFieldError? passwordError, LoginProblem? problem
});


$LoginProblemCopyWith<$Res>? get problem;

}
/// @nodoc
class _$LoginEditingCopyWithImpl<$Res>
    implements $LoginEditingCopyWith<$Res> {
  _$LoginEditingCopyWithImpl(this._self, this._then);

  final LoginEditing _self;
  final $Res Function(LoginEditing) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? emailError = freezed,Object? passwordError = freezed,Object? problem = freezed,}) {
  return _then(LoginEditing(
emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as LoginProblem?,
  ));
}

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoginProblemCopyWith<$Res>? get problem {
    if (_self.problem == null) {
    return null;
  }

  return $LoginProblemCopyWith<$Res>(_self.problem!, (value) {
    return _then(_self.copyWith(problem: value));
  });
}
}

/// @nodoc


class LoginSubmitting implements LoginState {
  const LoginSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginState.submitting()';
}


}




// dart format on
