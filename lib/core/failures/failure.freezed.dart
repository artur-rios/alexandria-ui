// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvalidInputFailure value)?  invalidInput,TResult Function( RejectedFailure value)?  rejected,TResult Function( RateLimitedFailure value)?  rateLimited,TResult Function( ServiceUnavailableFailure value)?  serviceUnavailable,TResult Function( UnauthorizedFailure value)?  unauthorized,TResult Function( NotInitializedFailure value)?  notInitialized,TResult Function( NotFoundFailure value)?  notFound,TResult Function( InvalidStateFailure value)?  invalidState,TResult Function( DiskFailure value)?  disk,TResult Function( IntegrityFailure value)?  integrity,TResult Function( ConfigurationFailure value)?  configuration,TResult Function( ConflictFailure value)?  conflict,TResult Function( UnexpectedFailure value)?  unexpected,TResult Function( CoreLibraryNotLoadedFailure value)?  coreLibraryNotLoaded,TResult Function( ApplicationDirectoryUnavailableFailure value)?  applicationDirectoryUnavailable,TResult Function( CoreInitializationFailedFailure value)?  coreInitializationFailed,TResult Function( CoreUnhealthyFailure value)?  coreUnhealthy,TResult Function( CoreVersionUnsupportedFailure value)?  coreVersionUnsupported,TResult Function( PreferencesUnreadableFailure value)?  preferencesUnreadable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvalidInputFailure() when invalidInput != null:
return invalidInput(_that);case RejectedFailure() when rejected != null:
return rejected(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case ServiceUnavailableFailure() when serviceUnavailable != null:
return serviceUnavailable(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case NotInitializedFailure() when notInitialized != null:
return notInitialized(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case InvalidStateFailure() when invalidState != null:
return invalidState(_that);case DiskFailure() when disk != null:
return disk(_that);case IntegrityFailure() when integrity != null:
return integrity(_that);case ConfigurationFailure() when configuration != null:
return configuration(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case CoreLibraryNotLoadedFailure() when coreLibraryNotLoaded != null:
return coreLibraryNotLoaded(_that);case ApplicationDirectoryUnavailableFailure() when applicationDirectoryUnavailable != null:
return applicationDirectoryUnavailable(_that);case CoreInitializationFailedFailure() when coreInitializationFailed != null:
return coreInitializationFailed(_that);case CoreUnhealthyFailure() when coreUnhealthy != null:
return coreUnhealthy(_that);case CoreVersionUnsupportedFailure() when coreVersionUnsupported != null:
return coreVersionUnsupported(_that);case PreferencesUnreadableFailure() when preferencesUnreadable != null:
return preferencesUnreadable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvalidInputFailure value)  invalidInput,required TResult Function( RejectedFailure value)  rejected,required TResult Function( RateLimitedFailure value)  rateLimited,required TResult Function( ServiceUnavailableFailure value)  serviceUnavailable,required TResult Function( UnauthorizedFailure value)  unauthorized,required TResult Function( NotInitializedFailure value)  notInitialized,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( InvalidStateFailure value)  invalidState,required TResult Function( DiskFailure value)  disk,required TResult Function( IntegrityFailure value)  integrity,required TResult Function( ConfigurationFailure value)  configuration,required TResult Function( ConflictFailure value)  conflict,required TResult Function( UnexpectedFailure value)  unexpected,required TResult Function( CoreLibraryNotLoadedFailure value)  coreLibraryNotLoaded,required TResult Function( ApplicationDirectoryUnavailableFailure value)  applicationDirectoryUnavailable,required TResult Function( CoreInitializationFailedFailure value)  coreInitializationFailed,required TResult Function( CoreUnhealthyFailure value)  coreUnhealthy,required TResult Function( CoreVersionUnsupportedFailure value)  coreVersionUnsupported,required TResult Function( PreferencesUnreadableFailure value)  preferencesUnreadable,}){
final _that = this;
switch (_that) {
case InvalidInputFailure():
return invalidInput(_that);case RejectedFailure():
return rejected(_that);case RateLimitedFailure():
return rateLimited(_that);case ServiceUnavailableFailure():
return serviceUnavailable(_that);case UnauthorizedFailure():
return unauthorized(_that);case NotInitializedFailure():
return notInitialized(_that);case NotFoundFailure():
return notFound(_that);case InvalidStateFailure():
return invalidState(_that);case DiskFailure():
return disk(_that);case IntegrityFailure():
return integrity(_that);case ConfigurationFailure():
return configuration(_that);case ConflictFailure():
return conflict(_that);case UnexpectedFailure():
return unexpected(_that);case CoreLibraryNotLoadedFailure():
return coreLibraryNotLoaded(_that);case ApplicationDirectoryUnavailableFailure():
return applicationDirectoryUnavailable(_that);case CoreInitializationFailedFailure():
return coreInitializationFailed(_that);case CoreUnhealthyFailure():
return coreUnhealthy(_that);case CoreVersionUnsupportedFailure():
return coreVersionUnsupported(_that);case PreferencesUnreadableFailure():
return preferencesUnreadable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvalidInputFailure value)?  invalidInput,TResult? Function( RejectedFailure value)?  rejected,TResult? Function( RateLimitedFailure value)?  rateLimited,TResult? Function( ServiceUnavailableFailure value)?  serviceUnavailable,TResult? Function( UnauthorizedFailure value)?  unauthorized,TResult? Function( NotInitializedFailure value)?  notInitialized,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( InvalidStateFailure value)?  invalidState,TResult? Function( DiskFailure value)?  disk,TResult? Function( IntegrityFailure value)?  integrity,TResult? Function( ConfigurationFailure value)?  configuration,TResult? Function( ConflictFailure value)?  conflict,TResult? Function( UnexpectedFailure value)?  unexpected,TResult? Function( CoreLibraryNotLoadedFailure value)?  coreLibraryNotLoaded,TResult? Function( ApplicationDirectoryUnavailableFailure value)?  applicationDirectoryUnavailable,TResult? Function( CoreInitializationFailedFailure value)?  coreInitializationFailed,TResult? Function( CoreUnhealthyFailure value)?  coreUnhealthy,TResult? Function( CoreVersionUnsupportedFailure value)?  coreVersionUnsupported,TResult? Function( PreferencesUnreadableFailure value)?  preferencesUnreadable,}){
final _that = this;
switch (_that) {
case InvalidInputFailure() when invalidInput != null:
return invalidInput(_that);case RejectedFailure() when rejected != null:
return rejected(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case ServiceUnavailableFailure() when serviceUnavailable != null:
return serviceUnavailable(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case NotInitializedFailure() when notInitialized != null:
return notInitialized(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case InvalidStateFailure() when invalidState != null:
return invalidState(_that);case DiskFailure() when disk != null:
return disk(_that);case IntegrityFailure() when integrity != null:
return integrity(_that);case ConfigurationFailure() when configuration != null:
return configuration(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case CoreLibraryNotLoadedFailure() when coreLibraryNotLoaded != null:
return coreLibraryNotLoaded(_that);case ApplicationDirectoryUnavailableFailure() when applicationDirectoryUnavailable != null:
return applicationDirectoryUnavailable(_that);case CoreInitializationFailedFailure() when coreInitializationFailed != null:
return coreInitializationFailed(_that);case CoreUnhealthyFailure() when coreUnhealthy != null:
return coreUnhealthy(_that);case CoreVersionUnsupportedFailure() when coreVersionUnsupported != null:
return coreVersionUnsupported(_that);case PreferencesUnreadableFailure() when preferencesUnreadable != null:
return preferencesUnreadable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CoreStatusFamily family,  int code)?  invalidInput,TResult Function( CoreStatusFamily family,  int code,  CoreRejection rejection)?  rejected,TResult Function( CoreStatusFamily family,  int code)?  rateLimited,TResult Function( CoreStatusFamily family,  int code)?  serviceUnavailable,TResult Function( CoreStatusFamily family,  int code)?  unauthorized,TResult Function( CoreStatusFamily family,  int code)?  notInitialized,TResult Function( CoreStatusFamily family,  int code)?  notFound,TResult Function( CoreStatusFamily family,  int code)?  invalidState,TResult Function( CoreStatusFamily family,  int code)?  disk,TResult Function( CoreStatusFamily family,  int code)?  integrity,TResult Function( CoreStatusFamily family,  int code)?  configuration,TResult Function( CoreStatusFamily family,  int code)?  conflict,TResult Function( CoreStatusFamily family,  int code)?  unexpected,TResult Function( String path)?  coreLibraryNotLoaded,TResult Function( String path)?  applicationDirectoryUnavailable,TResult Function( int code)?  coreInitializationFailed,TResult Function( int code)?  coreUnhealthy,TResult Function( String found,  String required)?  coreVersionUnsupported,TResult Function()?  preferencesUnreadable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvalidInputFailure() when invalidInput != null:
return invalidInput(_that.family,_that.code);case RejectedFailure() when rejected != null:
return rejected(_that.family,_that.code,_that.rejection);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.family,_that.code);case ServiceUnavailableFailure() when serviceUnavailable != null:
return serviceUnavailable(_that.family,_that.code);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that.family,_that.code);case NotInitializedFailure() when notInitialized != null:
return notInitialized(_that.family,_that.code);case NotFoundFailure() when notFound != null:
return notFound(_that.family,_that.code);case InvalidStateFailure() when invalidState != null:
return invalidState(_that.family,_that.code);case DiskFailure() when disk != null:
return disk(_that.family,_that.code);case IntegrityFailure() when integrity != null:
return integrity(_that.family,_that.code);case ConfigurationFailure() when configuration != null:
return configuration(_that.family,_that.code);case ConflictFailure() when conflict != null:
return conflict(_that.family,_that.code);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.family,_that.code);case CoreLibraryNotLoadedFailure() when coreLibraryNotLoaded != null:
return coreLibraryNotLoaded(_that.path);case ApplicationDirectoryUnavailableFailure() when applicationDirectoryUnavailable != null:
return applicationDirectoryUnavailable(_that.path);case CoreInitializationFailedFailure() when coreInitializationFailed != null:
return coreInitializationFailed(_that.code);case CoreUnhealthyFailure() when coreUnhealthy != null:
return coreUnhealthy(_that.code);case CoreVersionUnsupportedFailure() when coreVersionUnsupported != null:
return coreVersionUnsupported(_that.found,_that.required);case PreferencesUnreadableFailure() when preferencesUnreadable != null:
return preferencesUnreadable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CoreStatusFamily family,  int code)  invalidInput,required TResult Function( CoreStatusFamily family,  int code,  CoreRejection rejection)  rejected,required TResult Function( CoreStatusFamily family,  int code)  rateLimited,required TResult Function( CoreStatusFamily family,  int code)  serviceUnavailable,required TResult Function( CoreStatusFamily family,  int code)  unauthorized,required TResult Function( CoreStatusFamily family,  int code)  notInitialized,required TResult Function( CoreStatusFamily family,  int code)  notFound,required TResult Function( CoreStatusFamily family,  int code)  invalidState,required TResult Function( CoreStatusFamily family,  int code)  disk,required TResult Function( CoreStatusFamily family,  int code)  integrity,required TResult Function( CoreStatusFamily family,  int code)  configuration,required TResult Function( CoreStatusFamily family,  int code)  conflict,required TResult Function( CoreStatusFamily family,  int code)  unexpected,required TResult Function( String path)  coreLibraryNotLoaded,required TResult Function( String path)  applicationDirectoryUnavailable,required TResult Function( int code)  coreInitializationFailed,required TResult Function( int code)  coreUnhealthy,required TResult Function( String found,  String required)  coreVersionUnsupported,required TResult Function()  preferencesUnreadable,}) {final _that = this;
switch (_that) {
case InvalidInputFailure():
return invalidInput(_that.family,_that.code);case RejectedFailure():
return rejected(_that.family,_that.code,_that.rejection);case RateLimitedFailure():
return rateLimited(_that.family,_that.code);case ServiceUnavailableFailure():
return serviceUnavailable(_that.family,_that.code);case UnauthorizedFailure():
return unauthorized(_that.family,_that.code);case NotInitializedFailure():
return notInitialized(_that.family,_that.code);case NotFoundFailure():
return notFound(_that.family,_that.code);case InvalidStateFailure():
return invalidState(_that.family,_that.code);case DiskFailure():
return disk(_that.family,_that.code);case IntegrityFailure():
return integrity(_that.family,_that.code);case ConfigurationFailure():
return configuration(_that.family,_that.code);case ConflictFailure():
return conflict(_that.family,_that.code);case UnexpectedFailure():
return unexpected(_that.family,_that.code);case CoreLibraryNotLoadedFailure():
return coreLibraryNotLoaded(_that.path);case ApplicationDirectoryUnavailableFailure():
return applicationDirectoryUnavailable(_that.path);case CoreInitializationFailedFailure():
return coreInitializationFailed(_that.code);case CoreUnhealthyFailure():
return coreUnhealthy(_that.code);case CoreVersionUnsupportedFailure():
return coreVersionUnsupported(_that.found,_that.required);case PreferencesUnreadableFailure():
return preferencesUnreadable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CoreStatusFamily family,  int code)?  invalidInput,TResult? Function( CoreStatusFamily family,  int code,  CoreRejection rejection)?  rejected,TResult? Function( CoreStatusFamily family,  int code)?  rateLimited,TResult? Function( CoreStatusFamily family,  int code)?  serviceUnavailable,TResult? Function( CoreStatusFamily family,  int code)?  unauthorized,TResult? Function( CoreStatusFamily family,  int code)?  notInitialized,TResult? Function( CoreStatusFamily family,  int code)?  notFound,TResult? Function( CoreStatusFamily family,  int code)?  invalidState,TResult? Function( CoreStatusFamily family,  int code)?  disk,TResult? Function( CoreStatusFamily family,  int code)?  integrity,TResult? Function( CoreStatusFamily family,  int code)?  configuration,TResult? Function( CoreStatusFamily family,  int code)?  conflict,TResult? Function( CoreStatusFamily family,  int code)?  unexpected,TResult? Function( String path)?  coreLibraryNotLoaded,TResult? Function( String path)?  applicationDirectoryUnavailable,TResult? Function( int code)?  coreInitializationFailed,TResult? Function( int code)?  coreUnhealthy,TResult? Function( String found,  String required)?  coreVersionUnsupported,TResult? Function()?  preferencesUnreadable,}) {final _that = this;
switch (_that) {
case InvalidInputFailure() when invalidInput != null:
return invalidInput(_that.family,_that.code);case RejectedFailure() when rejected != null:
return rejected(_that.family,_that.code,_that.rejection);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.family,_that.code);case ServiceUnavailableFailure() when serviceUnavailable != null:
return serviceUnavailable(_that.family,_that.code);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that.family,_that.code);case NotInitializedFailure() when notInitialized != null:
return notInitialized(_that.family,_that.code);case NotFoundFailure() when notFound != null:
return notFound(_that.family,_that.code);case InvalidStateFailure() when invalidState != null:
return invalidState(_that.family,_that.code);case DiskFailure() when disk != null:
return disk(_that.family,_that.code);case IntegrityFailure() when integrity != null:
return integrity(_that.family,_that.code);case ConfigurationFailure() when configuration != null:
return configuration(_that.family,_that.code);case ConflictFailure() when conflict != null:
return conflict(_that.family,_that.code);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.family,_that.code);case CoreLibraryNotLoadedFailure() when coreLibraryNotLoaded != null:
return coreLibraryNotLoaded(_that.path);case ApplicationDirectoryUnavailableFailure() when applicationDirectoryUnavailable != null:
return applicationDirectoryUnavailable(_that.path);case CoreInitializationFailedFailure() when coreInitializationFailed != null:
return coreInitializationFailed(_that.code);case CoreUnhealthyFailure() when coreUnhealthy != null:
return coreUnhealthy(_that.code);case CoreVersionUnsupportedFailure() when coreVersionUnsupported != null:
return coreVersionUnsupported(_that.found,_that.required);case PreferencesUnreadableFailure() when preferencesUnreadable != null:
return preferencesUnreadable();case _:
  return null;

}
}

}

/// @nodoc


class InvalidInputFailure extends Failure {
  const InvalidInputFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidInputFailureCopyWith<InvalidInputFailure> get copyWith => _$InvalidInputFailureCopyWithImpl<InvalidInputFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidInputFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.invalidInput(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $InvalidInputFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $InvalidInputFailureCopyWith(InvalidInputFailure value, $Res Function(InvalidInputFailure) _then) = _$InvalidInputFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$InvalidInputFailureCopyWithImpl<$Res>
    implements $InvalidInputFailureCopyWith<$Res> {
  _$InvalidInputFailureCopyWithImpl(this._self, this._then);

  final InvalidInputFailure _self;
  final $Res Function(InvalidInputFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(InvalidInputFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RejectedFailure extends Failure {
  const RejectedFailure({required this.family, required this.code, required this.rejection}): super._();
  

 final  CoreStatusFamily family;
 final  int code;
 final  CoreRejection rejection;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RejectedFailureCopyWith<RejectedFailure> get copyWith => _$RejectedFailureCopyWithImpl<RejectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectedFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code)&&(identical(other.rejection, rejection) || other.rejection == rejection));
}


@override
int get hashCode => Object.hash(runtimeType,family,code,rejection);

@override
String toString() {
  return 'Failure.rejected(family: $family, code: $code, rejection: $rejection)';
}


}

/// @nodoc
abstract mixin class $RejectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $RejectedFailureCopyWith(RejectedFailure value, $Res Function(RejectedFailure) _then) = _$RejectedFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code, CoreRejection rejection
});


$CoreRejectionCopyWith<$Res> get rejection;

}
/// @nodoc
class _$RejectedFailureCopyWithImpl<$Res>
    implements $RejectedFailureCopyWith<$Res> {
  _$RejectedFailureCopyWithImpl(this._self, this._then);

  final RejectedFailure _self;
  final $Res Function(RejectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,Object? rejection = null,}) {
  return _then(RejectedFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,rejection: null == rejection ? _self.rejection : rejection // ignore: cast_nullable_to_non_nullable
as CoreRejection,
  ));
}

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoreRejectionCopyWith<$Res> get rejection {
  
  return $CoreRejectionCopyWith<$Res>(_self.rejection, (value) {
    return _then(_self.copyWith(rejection: value));
  });
}
}

/// @nodoc


class RateLimitedFailure extends Failure {
  const RateLimitedFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateLimitedFailureCopyWith<RateLimitedFailure> get copyWith => _$RateLimitedFailureCopyWithImpl<RateLimitedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitedFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.rateLimited(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $RateLimitedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $RateLimitedFailureCopyWith(RateLimitedFailure value, $Res Function(RateLimitedFailure) _then) = _$RateLimitedFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$RateLimitedFailureCopyWithImpl<$Res>
    implements $RateLimitedFailureCopyWith<$Res> {
  _$RateLimitedFailureCopyWithImpl(this._self, this._then);

  final RateLimitedFailure _self;
  final $Res Function(RateLimitedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(RateLimitedFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceUnavailableFailureCopyWith<ServiceUnavailableFailure> get copyWith => _$ServiceUnavailableFailureCopyWithImpl<ServiceUnavailableFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceUnavailableFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.serviceUnavailable(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $ServiceUnavailableFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ServiceUnavailableFailureCopyWith(ServiceUnavailableFailure value, $Res Function(ServiceUnavailableFailure) _then) = _$ServiceUnavailableFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$ServiceUnavailableFailureCopyWithImpl<$Res>
    implements $ServiceUnavailableFailureCopyWith<$Res> {
  _$ServiceUnavailableFailureCopyWithImpl(this._self, this._then);

  final ServiceUnavailableFailure _self;
  final $Res Function(ServiceUnavailableFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(ServiceUnavailableFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnauthorizedFailureCopyWith<UnauthorizedFailure> get copyWith => _$UnauthorizedFailureCopyWithImpl<UnauthorizedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.unauthorized(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $UnauthorizedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnauthorizedFailureCopyWith(UnauthorizedFailure value, $Res Function(UnauthorizedFailure) _then) = _$UnauthorizedFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$UnauthorizedFailureCopyWithImpl<$Res>
    implements $UnauthorizedFailureCopyWith<$Res> {
  _$UnauthorizedFailureCopyWithImpl(this._self, this._then);

  final UnauthorizedFailure _self;
  final $Res Function(UnauthorizedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(UnauthorizedFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class NotInitializedFailure extends Failure {
  const NotInitializedFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotInitializedFailureCopyWith<NotInitializedFailure> get copyWith => _$NotInitializedFailureCopyWithImpl<NotInitializedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotInitializedFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.notInitialized(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $NotInitializedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotInitializedFailureCopyWith(NotInitializedFailure value, $Res Function(NotInitializedFailure) _then) = _$NotInitializedFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$NotInitializedFailureCopyWithImpl<$Res>
    implements $NotInitializedFailureCopyWith<$Res> {
  _$NotInitializedFailureCopyWithImpl(this._self, this._then);

  final NotInitializedFailure _self;
  final $Res Function(NotInitializedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(NotInitializedFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotFoundFailureCopyWith<NotFoundFailure> get copyWith => _$NotFoundFailureCopyWithImpl<NotFoundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.notFound(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $NotFoundFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotFoundFailureCopyWith(NotFoundFailure value, $Res Function(NotFoundFailure) _then) = _$NotFoundFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$NotFoundFailureCopyWithImpl<$Res>
    implements $NotFoundFailureCopyWith<$Res> {
  _$NotFoundFailureCopyWithImpl(this._self, this._then);

  final NotFoundFailure _self;
  final $Res Function(NotFoundFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(NotFoundFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class InvalidStateFailure extends Failure {
  const InvalidStateFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidStateFailureCopyWith<InvalidStateFailure> get copyWith => _$InvalidStateFailureCopyWithImpl<InvalidStateFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidStateFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.invalidState(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $InvalidStateFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $InvalidStateFailureCopyWith(InvalidStateFailure value, $Res Function(InvalidStateFailure) _then) = _$InvalidStateFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$InvalidStateFailureCopyWithImpl<$Res>
    implements $InvalidStateFailureCopyWith<$Res> {
  _$InvalidStateFailureCopyWithImpl(this._self, this._then);

  final InvalidStateFailure _self;
  final $Res Function(InvalidStateFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(InvalidStateFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DiskFailure extends Failure {
  const DiskFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiskFailureCopyWith<DiskFailure> get copyWith => _$DiskFailureCopyWithImpl<DiskFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiskFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.disk(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $DiskFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $DiskFailureCopyWith(DiskFailure value, $Res Function(DiskFailure) _then) = _$DiskFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$DiskFailureCopyWithImpl<$Res>
    implements $DiskFailureCopyWith<$Res> {
  _$DiskFailureCopyWithImpl(this._self, this._then);

  final DiskFailure _self;
  final $Res Function(DiskFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(DiskFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class IntegrityFailure extends Failure {
  const IntegrityFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntegrityFailureCopyWith<IntegrityFailure> get copyWith => _$IntegrityFailureCopyWithImpl<IntegrityFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntegrityFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.integrity(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $IntegrityFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $IntegrityFailureCopyWith(IntegrityFailure value, $Res Function(IntegrityFailure) _then) = _$IntegrityFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$IntegrityFailureCopyWithImpl<$Res>
    implements $IntegrityFailureCopyWith<$Res> {
  _$IntegrityFailureCopyWithImpl(this._self, this._then);

  final IntegrityFailure _self;
  final $Res Function(IntegrityFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(IntegrityFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ConfigurationFailure extends Failure {
  const ConfigurationFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfigurationFailureCopyWith<ConfigurationFailure> get copyWith => _$ConfigurationFailureCopyWithImpl<ConfigurationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfigurationFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.configuration(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $ConfigurationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ConfigurationFailureCopyWith(ConfigurationFailure value, $Res Function(ConfigurationFailure) _then) = _$ConfigurationFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$ConfigurationFailureCopyWithImpl<$Res>
    implements $ConfigurationFailureCopyWith<$Res> {
  _$ConfigurationFailureCopyWithImpl(this._self, this._then);

  final ConfigurationFailure _self;
  final $Res Function(ConfigurationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(ConfigurationFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ConflictFailure extends Failure {
  const ConflictFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictFailureCopyWith<ConflictFailure> get copyWith => _$ConflictFailureCopyWithImpl<ConflictFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.conflict(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $ConflictFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ConflictFailureCopyWith(ConflictFailure value, $Res Function(ConflictFailure) _then) = _$ConflictFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$ConflictFailureCopyWithImpl<$Res>
    implements $ConflictFailureCopyWith<$Res> {
  _$ConflictFailureCopyWithImpl(this._self, this._then);

  final ConflictFailure _self;
  final $Res Function(ConflictFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(ConflictFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required this.family, required this.code}): super._();
  

 final  CoreStatusFamily family;
 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexpectedFailureCopyWith<UnexpectedFailure> get copyWith => _$UnexpectedFailureCopyWithImpl<UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexpectedFailure&&(identical(other.family, family) || other.family == family)&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,family,code);

@override
String toString() {
  return 'Failure.unexpected(family: $family, code: $code)';
}


}

/// @nodoc
abstract mixin class $UnexpectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexpectedFailureCopyWith(UnexpectedFailure value, $Res Function(UnexpectedFailure) _then) = _$UnexpectedFailureCopyWithImpl;
@useResult
$Res call({
 CoreStatusFamily family, int code
});




}
/// @nodoc
class _$UnexpectedFailureCopyWithImpl<$Res>
    implements $UnexpectedFailureCopyWith<$Res> {
  _$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final UnexpectedFailure _self;
  final $Res Function(UnexpectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? family = null,Object? code = null,}) {
  return _then(UnexpectedFailure(
family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as CoreStatusFamily,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CoreLibraryNotLoadedFailure extends Failure {
  const CoreLibraryNotLoadedFailure({required this.path}): super._();
  

 final  String path;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreLibraryNotLoadedFailureCopyWith<CoreLibraryNotLoadedFailure> get copyWith => _$CoreLibraryNotLoadedFailureCopyWithImpl<CoreLibraryNotLoadedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreLibraryNotLoadedFailure&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'Failure.coreLibraryNotLoaded(path: $path)';
}


}

/// @nodoc
abstract mixin class $CoreLibraryNotLoadedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CoreLibraryNotLoadedFailureCopyWith(CoreLibraryNotLoadedFailure value, $Res Function(CoreLibraryNotLoadedFailure) _then) = _$CoreLibraryNotLoadedFailureCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$CoreLibraryNotLoadedFailureCopyWithImpl<$Res>
    implements $CoreLibraryNotLoadedFailureCopyWith<$Res> {
  _$CoreLibraryNotLoadedFailureCopyWithImpl(this._self, this._then);

  final CoreLibraryNotLoadedFailure _self;
  final $Res Function(CoreLibraryNotLoadedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(CoreLibraryNotLoadedFailure(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApplicationDirectoryUnavailableFailure extends Failure {
  const ApplicationDirectoryUnavailableFailure({required this.path}): super._();
  

 final  String path;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicationDirectoryUnavailableFailureCopyWith<ApplicationDirectoryUnavailableFailure> get copyWith => _$ApplicationDirectoryUnavailableFailureCopyWithImpl<ApplicationDirectoryUnavailableFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplicationDirectoryUnavailableFailure&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'Failure.applicationDirectoryUnavailable(path: $path)';
}


}

/// @nodoc
abstract mixin class $ApplicationDirectoryUnavailableFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ApplicationDirectoryUnavailableFailureCopyWith(ApplicationDirectoryUnavailableFailure value, $Res Function(ApplicationDirectoryUnavailableFailure) _then) = _$ApplicationDirectoryUnavailableFailureCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$ApplicationDirectoryUnavailableFailureCopyWithImpl<$Res>
    implements $ApplicationDirectoryUnavailableFailureCopyWith<$Res> {
  _$ApplicationDirectoryUnavailableFailureCopyWithImpl(this._self, this._then);

  final ApplicationDirectoryUnavailableFailure _self;
  final $Res Function(ApplicationDirectoryUnavailableFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(ApplicationDirectoryUnavailableFailure(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CoreInitializationFailedFailure extends Failure {
  const CoreInitializationFailedFailure({required this.code}): super._();
  

 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreInitializationFailedFailureCopyWith<CoreInitializationFailedFailure> get copyWith => _$CoreInitializationFailedFailureCopyWithImpl<CoreInitializationFailedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreInitializationFailedFailure&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'Failure.coreInitializationFailed(code: $code)';
}


}

/// @nodoc
abstract mixin class $CoreInitializationFailedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CoreInitializationFailedFailureCopyWith(CoreInitializationFailedFailure value, $Res Function(CoreInitializationFailedFailure) _then) = _$CoreInitializationFailedFailureCopyWithImpl;
@useResult
$Res call({
 int code
});




}
/// @nodoc
class _$CoreInitializationFailedFailureCopyWithImpl<$Res>
    implements $CoreInitializationFailedFailureCopyWith<$Res> {
  _$CoreInitializationFailedFailureCopyWithImpl(this._self, this._then);

  final CoreInitializationFailedFailure _self;
  final $Res Function(CoreInitializationFailedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(CoreInitializationFailedFailure(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CoreUnhealthyFailure extends Failure {
  const CoreUnhealthyFailure({required this.code}): super._();
  

 final  int code;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreUnhealthyFailureCopyWith<CoreUnhealthyFailure> get copyWith => _$CoreUnhealthyFailureCopyWithImpl<CoreUnhealthyFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreUnhealthyFailure&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'Failure.coreUnhealthy(code: $code)';
}


}

/// @nodoc
abstract mixin class $CoreUnhealthyFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CoreUnhealthyFailureCopyWith(CoreUnhealthyFailure value, $Res Function(CoreUnhealthyFailure) _then) = _$CoreUnhealthyFailureCopyWithImpl;
@useResult
$Res call({
 int code
});




}
/// @nodoc
class _$CoreUnhealthyFailureCopyWithImpl<$Res>
    implements $CoreUnhealthyFailureCopyWith<$Res> {
  _$CoreUnhealthyFailureCopyWithImpl(this._self, this._then);

  final CoreUnhealthyFailure _self;
  final $Res Function(CoreUnhealthyFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(CoreUnhealthyFailure(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CoreVersionUnsupportedFailure extends Failure {
  const CoreVersionUnsupportedFailure({required this.found, required this.required}): super._();
  

 final  String found;
 final  String required;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoreVersionUnsupportedFailureCopyWith<CoreVersionUnsupportedFailure> get copyWith => _$CoreVersionUnsupportedFailureCopyWithImpl<CoreVersionUnsupportedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoreVersionUnsupportedFailure&&(identical(other.found, found) || other.found == found)&&(identical(other.required, required) || other.required == required));
}


@override
int get hashCode => Object.hash(runtimeType,found,required);

@override
String toString() {
  return 'Failure.coreVersionUnsupported(found: $found, required: $required)';
}


}

/// @nodoc
abstract mixin class $CoreVersionUnsupportedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CoreVersionUnsupportedFailureCopyWith(CoreVersionUnsupportedFailure value, $Res Function(CoreVersionUnsupportedFailure) _then) = _$CoreVersionUnsupportedFailureCopyWithImpl;
@useResult
$Res call({
 String found, String required
});




}
/// @nodoc
class _$CoreVersionUnsupportedFailureCopyWithImpl<$Res>
    implements $CoreVersionUnsupportedFailureCopyWith<$Res> {
  _$CoreVersionUnsupportedFailureCopyWithImpl(this._self, this._then);

  final CoreVersionUnsupportedFailure _self;
  final $Res Function(CoreVersionUnsupportedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? found = null,Object? required = null,}) {
  return _then(CoreVersionUnsupportedFailure(
found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PreferencesUnreadableFailure extends Failure {
  const PreferencesUnreadableFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreferencesUnreadableFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.preferencesUnreadable()';
}


}




// dart format on
