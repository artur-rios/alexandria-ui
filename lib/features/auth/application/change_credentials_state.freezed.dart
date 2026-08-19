// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_credentials_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChangeCredentialsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeCredentialsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangeCredentialsState()';
}


}

/// @nodoc
class $ChangeCredentialsStateCopyWith<$Res>  {
$ChangeCredentialsStateCopyWith(ChangeCredentialsState _, $Res Function(ChangeCredentialsState) __);
}


/// Adds pattern-matching-related methods to [ChangeCredentialsState].
extension ChangeCredentialsStatePatterns on ChangeCredentialsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChangeCredentialsEditing value)?  editing,TResult Function( ChangeCredentialsSubmitting value)?  submitting,TResult Function( ChangeCredentialsChanged value)?  changed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChangeCredentialsEditing() when editing != null:
return editing(_that);case ChangeCredentialsSubmitting() when submitting != null:
return submitting(_that);case ChangeCredentialsChanged() when changed != null:
return changed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChangeCredentialsEditing value)  editing,required TResult Function( ChangeCredentialsSubmitting value)  submitting,required TResult Function( ChangeCredentialsChanged value)  changed,}){
final _that = this;
switch (_that) {
case ChangeCredentialsEditing():
return editing(_that);case ChangeCredentialsSubmitting():
return submitting(_that);case ChangeCredentialsChanged():
return changed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChangeCredentialsEditing value)?  editing,TResult? Function( ChangeCredentialsSubmitting value)?  submitting,TResult? Function( ChangeCredentialsChanged value)?  changed,}){
final _that = this;
switch (_that) {
case ChangeCredentialsEditing() when editing != null:
return editing(_that);case ChangeCredentialsSubmitting() when submitting != null:
return submitting(_that);case ChangeCredentialsChanged() when changed != null:
return changed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  Failure? problem)?  editing,TResult Function()?  submitting,TResult Function()?  changed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChangeCredentialsEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case ChangeCredentialsSubmitting() when submitting != null:
return submitting();case ChangeCredentialsChanged() when changed != null:
return changed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  Failure? problem)  editing,required TResult Function()  submitting,required TResult Function()  changed,}) {final _that = this;
switch (_that) {
case ChangeCredentialsEditing():
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case ChangeCredentialsSubmitting():
return submitting();case ChangeCredentialsChanged():
return changed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LoginFieldError? emailError,  LoginFieldError? passwordError,  LoginFieldError? passwordConfirmationError,  Failure? problem)?  editing,TResult? Function()?  submitting,TResult? Function()?  changed,}) {final _that = this;
switch (_that) {
case ChangeCredentialsEditing() when editing != null:
return editing(_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.problem);case ChangeCredentialsSubmitting() when submitting != null:
return submitting();case ChangeCredentialsChanged() when changed != null:
return changed();case _:
  return null;

}
}

}

/// @nodoc


class ChangeCredentialsEditing implements ChangeCredentialsState {
  const ChangeCredentialsEditing({this.emailError, this.passwordError, this.passwordConfirmationError, this.problem});
  

 final  LoginFieldError? emailError;
 final  LoginFieldError? passwordError;
 final  LoginFieldError? passwordConfirmationError;
 final  Failure? problem;

/// Create a copy of ChangeCredentialsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeCredentialsEditingCopyWith<ChangeCredentialsEditing> get copyWith => _$ChangeCredentialsEditingCopyWithImpl<ChangeCredentialsEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeCredentialsEditing&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordConfirmationError, passwordConfirmationError) || other.passwordConfirmationError == passwordConfirmationError)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode => Object.hash(runtimeType,emailError,passwordError,passwordConfirmationError,problem);

@override
String toString() {
  return 'ChangeCredentialsState.editing(emailError: $emailError, passwordError: $passwordError, passwordConfirmationError: $passwordConfirmationError, problem: $problem)';
}


}

/// @nodoc
abstract mixin class $ChangeCredentialsEditingCopyWith<$Res> implements $ChangeCredentialsStateCopyWith<$Res> {
  factory $ChangeCredentialsEditingCopyWith(ChangeCredentialsEditing value, $Res Function(ChangeCredentialsEditing) _then) = _$ChangeCredentialsEditingCopyWithImpl;
@useResult
$Res call({
 LoginFieldError? emailError, LoginFieldError? passwordError, LoginFieldError? passwordConfirmationError, Failure? problem
});


$FailureCopyWith<$Res>? get problem;

}
/// @nodoc
class _$ChangeCredentialsEditingCopyWithImpl<$Res>
    implements $ChangeCredentialsEditingCopyWith<$Res> {
  _$ChangeCredentialsEditingCopyWithImpl(this._self, this._then);

  final ChangeCredentialsEditing _self;
  final $Res Function(ChangeCredentialsEditing) _then;

/// Create a copy of ChangeCredentialsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? emailError = freezed,Object? passwordError = freezed,Object? passwordConfirmationError = freezed,Object? problem = freezed,}) {
  return _then(ChangeCredentialsEditing(
emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,passwordConfirmationError: freezed == passwordConfirmationError ? _self.passwordConfirmationError : passwordConfirmationError // ignore: cast_nullable_to_non_nullable
as LoginFieldError?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ChangeCredentialsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get problem {
    if (_self.problem == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.problem!, (value) {
    return _then(_self.copyWith(problem: value));
  });
}
}

/// @nodoc


class ChangeCredentialsSubmitting implements ChangeCredentialsState {
  const ChangeCredentialsSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeCredentialsSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangeCredentialsState.submitting()';
}


}




/// @nodoc


class ChangeCredentialsChanged implements ChangeCredentialsState {
  const ChangeCredentialsChanged();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeCredentialsChanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangeCredentialsState.changed()';
}


}




// dart format on
