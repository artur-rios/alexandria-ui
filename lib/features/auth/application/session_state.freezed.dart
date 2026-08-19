// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionState()';
}


}

/// @nodoc
class $SessionStateCopyWith<$Res>  {
$SessionStateCopyWith(SessionState _, $Res Function(SessionState) __);
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionAbsent value)?  absent,TResult Function( SessionActive value)?  active,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionAbsent() when absent != null:
return absent(_that);case SessionActive() when active != null:
return active(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionAbsent value)  absent,required TResult Function( SessionActive value)  active,}){
final _that = this;
switch (_that) {
case SessionAbsent():
return absent(_that);case SessionActive():
return active(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionAbsent value)?  absent,TResult? Function( SessionActive value)?  active,}){
final _that = this;
switch (_that) {
case SessionAbsent() when absent != null:
return absent(_that);case SessionActive() when active != null:
return active(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Failure? endedBecause,  bool indexRunContinues)?  absent,TResult Function( Session session,  ConfirmationDelivery? confirmation)?  active,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionAbsent() when absent != null:
return absent(_that.endedBecause,_that.indexRunContinues);case SessionActive() when active != null:
return active(_that.session,_that.confirmation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Failure? endedBecause,  bool indexRunContinues)  absent,required TResult Function( Session session,  ConfirmationDelivery? confirmation)  active,}) {final _that = this;
switch (_that) {
case SessionAbsent():
return absent(_that.endedBecause,_that.indexRunContinues);case SessionActive():
return active(_that.session,_that.confirmation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Failure? endedBecause,  bool indexRunContinues)?  absent,TResult? Function( Session session,  ConfirmationDelivery? confirmation)?  active,}) {final _that = this;
switch (_that) {
case SessionAbsent() when absent != null:
return absent(_that.endedBecause,_that.indexRunContinues);case SessionActive() when active != null:
return active(_that.session,_that.confirmation);case _:
  return null;

}
}

}

/// @nodoc


class SessionAbsent implements SessionState {
  const SessionAbsent({this.endedBecause, this.indexRunContinues = false});
  

 final  Failure? endedBecause;
@JsonKey() final  bool indexRunContinues;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionAbsentCopyWith<SessionAbsent> get copyWith => _$SessionAbsentCopyWithImpl<SessionAbsent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionAbsent&&(identical(other.endedBecause, endedBecause) || other.endedBecause == endedBecause)&&(identical(other.indexRunContinues, indexRunContinues) || other.indexRunContinues == indexRunContinues));
}


@override
int get hashCode => Object.hash(runtimeType,endedBecause,indexRunContinues);

@override
String toString() {
  return 'SessionState.absent(endedBecause: $endedBecause, indexRunContinues: $indexRunContinues)';
}


}

/// @nodoc
abstract mixin class $SessionAbsentCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionAbsentCopyWith(SessionAbsent value, $Res Function(SessionAbsent) _then) = _$SessionAbsentCopyWithImpl;
@useResult
$Res call({
 Failure? endedBecause, bool indexRunContinues
});


$FailureCopyWith<$Res>? get endedBecause;

}
/// @nodoc
class _$SessionAbsentCopyWithImpl<$Res>
    implements $SessionAbsentCopyWith<$Res> {
  _$SessionAbsentCopyWithImpl(this._self, this._then);

  final SessionAbsent _self;
  final $Res Function(SessionAbsent) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? endedBecause = freezed,Object? indexRunContinues = null,}) {
  return _then(SessionAbsent(
endedBecause: freezed == endedBecause ? _self.endedBecause : endedBecause // ignore: cast_nullable_to_non_nullable
as Failure?,indexRunContinues: null == indexRunContinues ? _self.indexRunContinues : indexRunContinues // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get endedBecause {
    if (_self.endedBecause == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.endedBecause!, (value) {
    return _then(_self.copyWith(endedBecause: value));
  });
}
}

/// @nodoc


class SessionActive implements SessionState {
  const SessionActive({required this.session, this.confirmation});
  

 final  Session session;
 final  ConfirmationDelivery? confirmation;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionActiveCopyWith<SessionActive> get copyWith => _$SessionActiveCopyWithImpl<SessionActive>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionActive&&(identical(other.session, session) || other.session == session)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation));
}


@override
int get hashCode => Object.hash(runtimeType,session,confirmation);

@override
String toString() {
  return 'SessionState.active(session: $session, confirmation: $confirmation)';
}


}

/// @nodoc
abstract mixin class $SessionActiveCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionActiveCopyWith(SessionActive value, $Res Function(SessionActive) _then) = _$SessionActiveCopyWithImpl;
@useResult
$Res call({
 Session session, ConfirmationDelivery? confirmation
});


$SessionCopyWith<$Res> get session;$ConfirmationDeliveryCopyWith<$Res>? get confirmation;

}
/// @nodoc
class _$SessionActiveCopyWithImpl<$Res>
    implements $SessionActiveCopyWith<$Res> {
  _$SessionActiveCopyWithImpl(this._self, this._then);

  final SessionActive _self;
  final $Res Function(SessionActive) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? confirmation = freezed,}) {
  return _then(SessionActive(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,confirmation: freezed == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as ConfirmationDelivery?,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of SessionState
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

// dart format on
