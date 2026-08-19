// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_sources_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibrarySourcesState {

/// The registered folders, in registration order.
 List<LibrarySource> get sources;/// Whether a registration attempt is in flight (FR-UX-08).
///
/// Covers the probe as well as the write: checking a folder on a slow or
/// disconnected drive is exactly the perceptible operation that needs to
/// say it is working.
 bool get registering;/// Why the last attempt was refused, or `null` when there was none
/// (AF-02, AF-03).
 FolderRegistrationVerdict? get refusal;/// The path the last refusal was about, so the message can name it.
 String? get refusedPath;/// The folder whose unregistration was refused because a run is in flight
/// (UC-08 AF-02), or `null`.
 String? get unregisterRefusedFor;/// The already-registered folder the last attempt conflicted with.
///
/// AF-03 highlights this entry in the list, which is why the source is
/// carried rather than only the verdict.
 LibrarySource? get conflictingSource;
/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySourcesStateCopyWith<LibrarySourcesState> get copyWith => _$LibrarySourcesStateCopyWithImpl<LibrarySourcesState>(this as LibrarySourcesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySourcesState&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.registering, registering) || other.registering == registering)&&(identical(other.refusal, refusal) || other.refusal == refusal)&&(identical(other.refusedPath, refusedPath) || other.refusedPath == refusedPath)&&(identical(other.unregisterRefusedFor, unregisterRefusedFor) || other.unregisterRefusedFor == unregisterRefusedFor)&&(identical(other.conflictingSource, conflictingSource) || other.conflictingSource == conflictingSource));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sources),registering,refusal,refusedPath,unregisterRefusedFor,conflictingSource);

@override
String toString() {
  return 'LibrarySourcesState(sources: $sources, registering: $registering, refusal: $refusal, refusedPath: $refusedPath, unregisterRefusedFor: $unregisterRefusedFor, conflictingSource: $conflictingSource)';
}


}

/// @nodoc
abstract mixin class $LibrarySourcesStateCopyWith<$Res>  {
  factory $LibrarySourcesStateCopyWith(LibrarySourcesState value, $Res Function(LibrarySourcesState) _then) = _$LibrarySourcesStateCopyWithImpl;
@useResult
$Res call({
 List<LibrarySource> sources, bool registering, FolderRegistrationVerdict? refusal, String? refusedPath, String? unregisterRefusedFor, LibrarySource? conflictingSource
});


$LibrarySourceCopyWith<$Res>? get conflictingSource;

}
/// @nodoc
class _$LibrarySourcesStateCopyWithImpl<$Res>
    implements $LibrarySourcesStateCopyWith<$Res> {
  _$LibrarySourcesStateCopyWithImpl(this._self, this._then);

  final LibrarySourcesState _self;
  final $Res Function(LibrarySourcesState) _then;

/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sources = null,Object? registering = null,Object? refusal = freezed,Object? refusedPath = freezed,Object? unregisterRefusedFor = freezed,Object? conflictingSource = freezed,}) {
  return _then(_self.copyWith(
sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<LibrarySource>,registering: null == registering ? _self.registering : registering // ignore: cast_nullable_to_non_nullable
as bool,refusal: freezed == refusal ? _self.refusal : refusal // ignore: cast_nullable_to_non_nullable
as FolderRegistrationVerdict?,refusedPath: freezed == refusedPath ? _self.refusedPath : refusedPath // ignore: cast_nullable_to_non_nullable
as String?,unregisterRefusedFor: freezed == unregisterRefusedFor ? _self.unregisterRefusedFor : unregisterRefusedFor // ignore: cast_nullable_to_non_nullable
as String?,conflictingSource: freezed == conflictingSource ? _self.conflictingSource : conflictingSource // ignore: cast_nullable_to_non_nullable
as LibrarySource?,
  ));
}
/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibrarySourceCopyWith<$Res>? get conflictingSource {
    if (_self.conflictingSource == null) {
    return null;
  }

  return $LibrarySourceCopyWith<$Res>(_self.conflictingSource!, (value) {
    return _then(_self.copyWith(conflictingSource: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibrarySourcesState].
extension LibrarySourcesStatePatterns on LibrarySourcesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySourcesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySourcesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySourcesState value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySourcesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySourcesState value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySourcesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LibrarySource> sources,  bool registering,  FolderRegistrationVerdict? refusal,  String? refusedPath,  String? unregisterRefusedFor,  LibrarySource? conflictingSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySourcesState() when $default != null:
return $default(_that.sources,_that.registering,_that.refusal,_that.refusedPath,_that.unregisterRefusedFor,_that.conflictingSource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LibrarySource> sources,  bool registering,  FolderRegistrationVerdict? refusal,  String? refusedPath,  String? unregisterRefusedFor,  LibrarySource? conflictingSource)  $default,) {final _that = this;
switch (_that) {
case _LibrarySourcesState():
return $default(_that.sources,_that.registering,_that.refusal,_that.refusedPath,_that.unregisterRefusedFor,_that.conflictingSource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LibrarySource> sources,  bool registering,  FolderRegistrationVerdict? refusal,  String? refusedPath,  String? unregisterRefusedFor,  LibrarySource? conflictingSource)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySourcesState() when $default != null:
return $default(_that.sources,_that.registering,_that.refusal,_that.refusedPath,_that.unregisterRefusedFor,_that.conflictingSource);case _:
  return null;

}
}

}

/// @nodoc


class _LibrarySourcesState extends LibrarySourcesState {
  const _LibrarySourcesState({final  List<LibrarySource> sources = const <LibrarySource>[], this.registering = false, this.refusal, this.refusedPath, this.unregisterRefusedFor, this.conflictingSource}): _sources = sources,super._();
  

/// The registered folders, in registration order.
 final  List<LibrarySource> _sources;
/// The registered folders, in registration order.
@override@JsonKey() List<LibrarySource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

/// Whether a registration attempt is in flight (FR-UX-08).
///
/// Covers the probe as well as the write: checking a folder on a slow or
/// disconnected drive is exactly the perceptible operation that needs to
/// say it is working.
@override@JsonKey() final  bool registering;
/// Why the last attempt was refused, or `null` when there was none
/// (AF-02, AF-03).
@override final  FolderRegistrationVerdict? refusal;
/// The path the last refusal was about, so the message can name it.
@override final  String? refusedPath;
/// The folder whose unregistration was refused because a run is in flight
/// (UC-08 AF-02), or `null`.
@override final  String? unregisterRefusedFor;
/// The already-registered folder the last attempt conflicted with.
///
/// AF-03 highlights this entry in the list, which is why the source is
/// carried rather than only the verdict.
@override final  LibrarySource? conflictingSource;

/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySourcesStateCopyWith<_LibrarySourcesState> get copyWith => __$LibrarySourcesStateCopyWithImpl<_LibrarySourcesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySourcesState&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.registering, registering) || other.registering == registering)&&(identical(other.refusal, refusal) || other.refusal == refusal)&&(identical(other.refusedPath, refusedPath) || other.refusedPath == refusedPath)&&(identical(other.unregisterRefusedFor, unregisterRefusedFor) || other.unregisterRefusedFor == unregisterRefusedFor)&&(identical(other.conflictingSource, conflictingSource) || other.conflictingSource == conflictingSource));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sources),registering,refusal,refusedPath,unregisterRefusedFor,conflictingSource);

@override
String toString() {
  return 'LibrarySourcesState(sources: $sources, registering: $registering, refusal: $refusal, refusedPath: $refusedPath, unregisterRefusedFor: $unregisterRefusedFor, conflictingSource: $conflictingSource)';
}


}

/// @nodoc
abstract mixin class _$LibrarySourcesStateCopyWith<$Res> implements $LibrarySourcesStateCopyWith<$Res> {
  factory _$LibrarySourcesStateCopyWith(_LibrarySourcesState value, $Res Function(_LibrarySourcesState) _then) = __$LibrarySourcesStateCopyWithImpl;
@override @useResult
$Res call({
 List<LibrarySource> sources, bool registering, FolderRegistrationVerdict? refusal, String? refusedPath, String? unregisterRefusedFor, LibrarySource? conflictingSource
});


@override $LibrarySourceCopyWith<$Res>? get conflictingSource;

}
/// @nodoc
class __$LibrarySourcesStateCopyWithImpl<$Res>
    implements _$LibrarySourcesStateCopyWith<$Res> {
  __$LibrarySourcesStateCopyWithImpl(this._self, this._then);

  final _LibrarySourcesState _self;
  final $Res Function(_LibrarySourcesState) _then;

/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sources = null,Object? registering = null,Object? refusal = freezed,Object? refusedPath = freezed,Object? unregisterRefusedFor = freezed,Object? conflictingSource = freezed,}) {
  return _then(_LibrarySourcesState(
sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<LibrarySource>,registering: null == registering ? _self.registering : registering // ignore: cast_nullable_to_non_nullable
as bool,refusal: freezed == refusal ? _self.refusal : refusal // ignore: cast_nullable_to_non_nullable
as FolderRegistrationVerdict?,refusedPath: freezed == refusedPath ? _self.refusedPath : refusedPath // ignore: cast_nullable_to_non_nullable
as String?,unregisterRefusedFor: freezed == unregisterRefusedFor ? _self.unregisterRefusedFor : unregisterRefusedFor // ignore: cast_nullable_to_non_nullable
as String?,conflictingSource: freezed == conflictingSource ? _self.conflictingSource : conflictingSource // ignore: cast_nullable_to_non_nullable
as LibrarySource?,
  ));
}

/// Create a copy of LibrarySourcesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibrarySourceCopyWith<$Res>? get conflictingSource {
    if (_self.conflictingSource == null) {
    return null;
  }

  return $LibrarySourceCopyWith<$Res>(_self.conflictingSource!, (value) {
    return _then(_self.copyWith(conflictingSource: value));
  });
}
}

// dart format on
