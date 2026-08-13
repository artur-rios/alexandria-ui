// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_up_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignUpProblem {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpProblem()';
}


}

/// @nodoc
class $SignUpProblemCopyWith<$Res>  {
$SignUpProblemCopyWith(SignUpProblem _, $Res Function(SignUpProblem) __);
}


/// Adds pattern-matching-related methods to [SignUpProblem].
extension SignUpProblemPatterns on SignUpProblem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignUpRejectedProblem value)?  rejected,TResult Function( AccountExistsProblem value)?  accountExists,TResult Function( SignUpConfigurationProblem value)?  configuration,TResult Function( SignUpOtherProblem value)?  other,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignUpRejectedProblem() when rejected != null:
return rejected(_that);case AccountExistsProblem() when accountExists != null:
return accountExists(_that);case SignUpConfigurationProblem() when configuration != null:
return configuration(_that);case SignUpOtherProblem() when other != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignUpRejectedProblem value)  rejected,required TResult Function( AccountExistsProblem value)  accountExists,required TResult Function( SignUpConfigurationProblem value)  configuration,required TResult Function( SignUpOtherProblem value)  other,}){
final _that = this;
switch (_that) {
case SignUpRejectedProblem():
return rejected(_that);case AccountExistsProblem():
return accountExists(_that);case SignUpConfigurationProblem():
return configuration(_that);case SignUpOtherProblem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignUpRejectedProblem value)?  rejected,TResult? Function( AccountExistsProblem value)?  accountExists,TResult? Function( SignUpConfigurationProblem value)?  configuration,TResult? Function( SignUpOtherProblem value)?  other,}){
final _that = this;
switch (_that) {
case SignUpRejectedProblem() when rejected != null:
return rejected(_that);case AccountExistsProblem() when accountExists != null:
return accountExists(_that);case SignUpConfigurationProblem() when configuration != null:
return configuration(_that);case SignUpOtherProblem() when other != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  rejected,TResult Function()?  accountExists,TResult Function( Failure failure)?  configuration,TResult Function( Failure failure)?  other,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignUpRejectedProblem() when rejected != null:
return rejected();case AccountExistsProblem() when accountExists != null:
return accountExists();case SignUpConfigurationProblem() when configuration != null:
return configuration(_that.failure);case SignUpOtherProblem() when other != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  rejected,required TResult Function()  accountExists,required TResult Function( Failure failure)  configuration,required TResult Function( Failure failure)  other,}) {final _that = this;
switch (_that) {
case SignUpRejectedProblem():
return rejected();case AccountExistsProblem():
return accountExists();case SignUpConfigurationProblem():
return configuration(_that.failure);case SignUpOtherProblem():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  rejected,TResult? Function()?  accountExists,TResult? Function( Failure failure)?  configuration,TResult? Function( Failure failure)?  other,}) {final _that = this;
switch (_that) {
case SignUpRejectedProblem() when rejected != null:
return rejected();case AccountExistsProblem() when accountExists != null:
return accountExists();case SignUpConfigurationProblem() when configuration != null:
return configuration(_that.failure);case SignUpOtherProblem() when other != null:
return other(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SignUpRejectedProblem implements SignUpProblem {
  const SignUpRejectedProblem();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpRejectedProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpProblem.rejected()';
}


}




/// @nodoc


class AccountExistsProblem implements SignUpProblem {
  const AccountExistsProblem();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountExistsProblem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpProblem.accountExists()';
}


}




/// @nodoc


class SignUpConfigurationProblem implements SignUpProblem {
  const SignUpConfigurationProblem({required this.failure});
  

 final  Failure failure;

/// Create a copy of SignUpProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpConfigurationProblemCopyWith<SignUpConfigurationProblem> get copyWith => _$SignUpConfigurationProblemCopyWithImpl<SignUpConfigurationProblem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpConfigurationProblem&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SignUpProblem.configuration(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SignUpConfigurationProblemCopyWith<$Res> implements $SignUpProblemCopyWith<$Res> {
  factory $SignUpConfigurationProblemCopyWith(SignUpConfigurationProblem value, $Res Function(SignUpConfigurationProblem) _then) = _$SignUpConfigurationProblemCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SignUpConfigurationProblemCopyWithImpl<$Res>
    implements $SignUpConfigurationProblemCopyWith<$Res> {
  _$SignUpConfigurationProblemCopyWithImpl(this._self, this._then);

  final SignUpConfigurationProblem _self;
  final $Res Function(SignUpConfigurationProblem) _then;

/// Create a copy of SignUpProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SignUpConfigurationProblem(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SignUpProblem
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


class SignUpOtherProblem implements SignUpProblem {
  const SignUpOtherProblem({required this.failure});
  

 final  Failure failure;

/// Create a copy of SignUpProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpOtherProblemCopyWith<SignUpOtherProblem> get copyWith => _$SignUpOtherProblemCopyWithImpl<SignUpOtherProblem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpOtherProblem&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SignUpProblem.other(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SignUpOtherProblemCopyWith<$Res> implements $SignUpProblemCopyWith<$Res> {
  factory $SignUpOtherProblemCopyWith(SignUpOtherProblem value, $Res Function(SignUpOtherProblem) _then) = _$SignUpOtherProblemCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SignUpOtherProblemCopyWithImpl<$Res>
    implements $SignUpOtherProblemCopyWith<$Res> {
  _$SignUpOtherProblemCopyWithImpl(this._self, this._then);

  final SignUpOtherProblem _self;
  final $Res Function(SignUpOtherProblem) _then;

/// Create a copy of SignUpProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SignUpOtherProblem(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SignUpProblem
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
mixin _$SignUpState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpState()';
}


}

/// @nodoc
class $SignUpStateCopyWith<$Res>  {
$SignUpStateCopyWith(SignUpState _, $Res Function(SignUpState) __);
}


/// Adds pattern-matching-related methods to [SignUpState].
extension SignUpStatePatterns on SignUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignUpEditing value)?  editing,TResult Function( SignUpSubmitting value)?  submitting,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignUpEditing() when editing != null:
return editing(_that);case SignUpSubmitting() when submitting != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignUpEditing value)  editing,required TResult Function( SignUpSubmitting value)  submitting,}){
final _that = this;
switch (_that) {
case SignUpEditing():
return editing(_that);case SignUpSubmitting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignUpEditing value)?  editing,TResult? Function( SignUpSubmitting value)?  submitting,}){
final _that = this;
switch (_that) {
case SignUpEditing() when editing != null:
return editing(_that);case SignUpSubmitting() when submitting != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  SignUpProblem? problem)?  editing,TResult Function()?  submitting,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignUpEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case SignUpSubmitting() when submitting != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  SignUpProblem? problem)  editing,required TResult Function()  submitting,}) {final _that = this;
switch (_that) {
case SignUpEditing():
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case SignUpSubmitting():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  SignUpProblem? problem)?  editing,TResult? Function()?  submitting,}) {final _that = this;
switch (_that) {
case SignUpEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case SignUpSubmitting() when submitting != null:
return submitting();case _:
  return null;

}
}

}

/// @nodoc


class SignUpEditing implements SignUpState {
  const SignUpEditing({this.emailError, this.passwordError, this.passwordConfirmationError, this.problem});
  

 final  LoginFieldError? emailError;
 final  LoginFieldError? passwordError;
 final  LoginFieldError? passwordConfirmationError;
 final  SignUpProblem? problem;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpEditingCopyWith<SignUpEditing> get copyWith => _$SignUpEditingCopyWithImpl<SignUpEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpEditing&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordConfirmationError, passwordConfirmationError) || other.passwordConfirmationError == passwordConfirmationError)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,emailError,passwordError,passwordConfirmationError,problem);

@override
String toString() {
  return 'SignUpState.editing(emailError: $emailError, passwordError: $passwordError, passwordConfirmationError: $passwordConfirmationError, problem: $problem)';
}


}

/// @nodoc
abstract mixin class $SignUpEditingCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory $SignUpEditingCopyWith(SignUpEditing value, $Res Function(SignUpEditing) _then) = _$SignUpEditingCopyWithImpl;
@useResult
$Res call({
 LoginFieldError? emailError, LoginFieldError? passwordError, LoginFieldError? passwordConfirmationError, SignUpProblem? problem
});


$SignUpProblemCopyWith<$Res>? get problem;

}
/// @nodoc
class _$SignUpEditingCopyWithImpl<$Res>
    implements $SignUpEditingCopyWith<$Res> {
  _$SignUpEditingCopyWithImpl(this._self, this._then);

  final SignUpEditing _self;
  final $Res Function(SignUpEditing) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? emailError = freezed,Object? passwordError = freezed,Object? passwordConfirmationError = freezed,Object? problem = freezed,}) {
  return _then(SignUpEditing(
emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,passwordConfirmationError: freezed == passwordConfirmationError ? _self.passwordConfirmationError : passwordConfirmationError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as SignUpProblem?,
  ));
}

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SignUpProblemCopyWith<$Res>? get problem {
    if (_self.problem == null) {
    return null;
  }

  return $SignUpProblemCopyWith<$Res>(_self.problem!, (value) {
    return _then(_self.copyWith(problem: value));
  });
}
}

/// @nodoc


class SignUpSubmitting implements SignUpState {
  const SignUpSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SignUpState.submitting()';
}


}




// dart format on
