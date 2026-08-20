// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackSource {

 String get uuid; String get path; String? get mimeType; int? get sizeBytes;
/// Create a copy of PlaybackSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackSourceCopyWith<PlaybackSource> get copyWith => _$PlaybackSourceCopyWithImpl<PlaybackSource>(this as PlaybackSource, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackSource&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.path, path) || other.path == path)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,path,mimeType,sizeBytes);

@override
String toString() {
  return 'PlaybackSource(uuid: $uuid, path: $path, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $PlaybackSourceCopyWith<$Res>  {
  factory $PlaybackSourceCopyWith(PlaybackSource value, $Res Function(PlaybackSource) _then) = _$PlaybackSourceCopyWithImpl;
@useResult
$Res call({
 String uuid, String path, String? mimeType, int? sizeBytes
});




}
/// @nodoc
class _$PlaybackSourceCopyWithImpl<$Res>
    implements $PlaybackSourceCopyWith<$Res> {
  _$PlaybackSourceCopyWithImpl(this._self, this._then);

  final PlaybackSource _self;
  final $Res Function(PlaybackSource) _then;

/// Create a copy of PlaybackSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? path = null,Object? mimeType = freezed,Object? sizeBytes = freezed,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackSource].
extension PlaybackSourcePatterns on PlaybackSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackSource value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackSource value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String path,  String? mimeType,  int? sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackSource() when $default != null:
return $default(_that.uuid,_that.path,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String path,  String? mimeType,  int? sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _PlaybackSource():
return $default(_that.uuid,_that.path,_that.mimeType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String path,  String? mimeType,  int? sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackSource() when $default != null:
return $default(_that.uuid,_that.path,_that.mimeType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackSource implements PlaybackSource {
  const _PlaybackSource({required this.uuid, required this.path, this.mimeType, this.sizeBytes});
  

@override final  String uuid;
@override final  String path;
@override final  String? mimeType;
@override final  int? sizeBytes;

/// Create a copy of PlaybackSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackSourceCopyWith<_PlaybackSource> get copyWith => __$PlaybackSourceCopyWithImpl<_PlaybackSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackSource&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.path, path) || other.path == path)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,path,mimeType,sizeBytes);

@override
String toString() {
  return 'PlaybackSource(uuid: $uuid, path: $path, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$PlaybackSourceCopyWith<$Res> implements $PlaybackSourceCopyWith<$Res> {
  factory _$PlaybackSourceCopyWith(_PlaybackSource value, $Res Function(_PlaybackSource) _then) = __$PlaybackSourceCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String path, String? mimeType, int? sizeBytes
});




}
/// @nodoc
class __$PlaybackSourceCopyWithImpl<$Res>
    implements _$PlaybackSourceCopyWith<$Res> {
  __$PlaybackSourceCopyWithImpl(this._self, this._then);

  final _PlaybackSource _self;
  final $Res Function(_PlaybackSource) _then;

/// Create a copy of PlaybackSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? path = null,Object? mimeType = freezed,Object? sizeBytes = freezed,}) {
  return _then(_PlaybackSource(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$PlaybackSourceOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackSourceOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaybackSourceOutcome()';
}


}

/// @nodoc
class $PlaybackSourceOutcomeCopyWith<$Res>  {
$PlaybackSourceOutcomeCopyWith(PlaybackSourceOutcome _, $Res Function(PlaybackSourceOutcome) __);
}


/// Adds pattern-matching-related methods to [PlaybackSourceOutcome].
extension PlaybackSourceOutcomePatterns on PlaybackSourceOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaybackSourceResolved value)?  resolved,TResult Function( PlaybackSourceFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaybackSourceResolved() when resolved != null:
return resolved(_that);case PlaybackSourceFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaybackSourceResolved value)  resolved,required TResult Function( PlaybackSourceFailed value)  failed,}){
final _that = this;
switch (_that) {
case PlaybackSourceResolved():
return resolved(_that);case PlaybackSourceFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaybackSourceResolved value)?  resolved,TResult? Function( PlaybackSourceFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PlaybackSourceResolved() when resolved != null:
return resolved(_that);case PlaybackSourceFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PlaybackSource source)?  resolved,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaybackSourceResolved() when resolved != null:
return resolved(_that.source);case PlaybackSourceFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PlaybackSource source)  resolved,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case PlaybackSourceResolved():
return resolved(_that.source);case PlaybackSourceFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PlaybackSource source)?  resolved,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case PlaybackSourceResolved() when resolved != null:
return resolved(_that.source);case PlaybackSourceFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaybackSourceResolved implements PlaybackSourceOutcome {
  const PlaybackSourceResolved({required this.source});
  

 final  PlaybackSource source;

/// Create a copy of PlaybackSourceOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackSourceResolvedCopyWith<PlaybackSourceResolved> get copyWith => _$PlaybackSourceResolvedCopyWithImpl<PlaybackSourceResolved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackSourceResolved&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'PlaybackSourceOutcome.resolved(source: $source)';
}


}

/// @nodoc
abstract mixin class $PlaybackSourceResolvedCopyWith<$Res> implements $PlaybackSourceOutcomeCopyWith<$Res> {
  factory $PlaybackSourceResolvedCopyWith(PlaybackSourceResolved value, $Res Function(PlaybackSourceResolved) _then) = _$PlaybackSourceResolvedCopyWithImpl;
@useResult
$Res call({
 PlaybackSource source
});


$PlaybackSourceCopyWith<$Res> get source;

}
/// @nodoc
class _$PlaybackSourceResolvedCopyWithImpl<$Res>
    implements $PlaybackSourceResolvedCopyWith<$Res> {
  _$PlaybackSourceResolvedCopyWithImpl(this._self, this._then);

  final PlaybackSourceResolved _self;
  final $Res Function(PlaybackSourceResolved) _then;

/// Create a copy of PlaybackSourceOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(PlaybackSourceResolved(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PlaybackSource,
  ));
}

/// Create a copy of PlaybackSourceOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackSourceCopyWith<$Res> get source {
  
  return $PlaybackSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc


class PlaybackSourceFailed implements PlaybackSourceOutcome {
  const PlaybackSourceFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of PlaybackSourceOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackSourceFailedCopyWith<PlaybackSourceFailed> get copyWith => _$PlaybackSourceFailedCopyWithImpl<PlaybackSourceFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackSourceFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PlaybackSourceOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaybackSourceFailedCopyWith<$Res> implements $PlaybackSourceOutcomeCopyWith<$Res> {
  factory $PlaybackSourceFailedCopyWith(PlaybackSourceFailed value, $Res Function(PlaybackSourceFailed) _then) = _$PlaybackSourceFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaybackSourceFailedCopyWithImpl<$Res>
    implements $PlaybackSourceFailedCopyWith<$Res> {
  _$PlaybackSourceFailedCopyWithImpl(this._self, this._then);

  final PlaybackSourceFailed _self;
  final $Res Function(PlaybackSourceFailed) _then;

/// Create a copy of PlaybackSourceOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaybackSourceFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaybackSourceOutcome
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
