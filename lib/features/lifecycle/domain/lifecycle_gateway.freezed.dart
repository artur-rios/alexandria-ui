// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lifecycle_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LifecycleWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LifecycleWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LifecycleWrite()';
}


}

/// @nodoc
class $LifecycleWriteCopyWith<$Res>  {
$LifecycleWriteCopyWith(LifecycleWrite _, $Res Function(LifecycleWrite) __);
}


/// Adds pattern-matching-related methods to [LifecycleWrite].
extension LifecycleWritePatterns on LifecycleWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LifecycleWriteDone value)?  done,TResult Function( LifecycleWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LifecycleWriteDone() when done != null:
return done(_that);case LifecycleWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LifecycleWriteDone value)  done,required TResult Function( LifecycleWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case LifecycleWriteDone():
return done(_that);case LifecycleWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LifecycleWriteDone value)?  done,TResult? Function( LifecycleWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case LifecycleWriteDone() when done != null:
return done(_that);case LifecycleWriteFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  done,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LifecycleWriteDone() when done != null:
return done();case LifecycleWriteFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  done,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case LifecycleWriteDone():
return done();case LifecycleWriteFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  done,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case LifecycleWriteDone() when done != null:
return done();case LifecycleWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class LifecycleWriteDone implements LifecycleWrite {
  const LifecycleWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LifecycleWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LifecycleWrite.done()';
}


}




/// @nodoc


class LifecycleWriteFailed implements LifecycleWrite {
  const LifecycleWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of LifecycleWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LifecycleWriteFailedCopyWith<LifecycleWriteFailed> get copyWith => _$LifecycleWriteFailedCopyWithImpl<LifecycleWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LifecycleWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LifecycleWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LifecycleWriteFailedCopyWith<$Res> implements $LifecycleWriteCopyWith<$Res> {
  factory $LifecycleWriteFailedCopyWith(LifecycleWriteFailed value, $Res Function(LifecycleWriteFailed) _then) = _$LifecycleWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LifecycleWriteFailedCopyWithImpl<$Res>
    implements $LifecycleWriteFailedCopyWith<$Res> {
  _$LifecycleWriteFailedCopyWithImpl(this._self, this._then);

  final LifecycleWriteFailed _self;
  final $Res Function(LifecycleWriteFailed) _then;

/// Create a copy of LifecycleWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(LifecycleWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LifecycleWrite
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
