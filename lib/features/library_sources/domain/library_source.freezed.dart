// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibrarySource {

/// The absolute folder path. Also the key.
 String get path;/// The owner-supplied name, defaulting to the folder's own name.
 String get label;/// When it was registered.
 DateTime get registeredAt;/// The identifier of the most recent run over this folder (UC-06).
 String? get lastRunId;/// Whether that run finished or failed (UC-06).
 String? get lastRunOutcome;/// When that run finished (UC-06).
 DateTime? get lastRunAt;/// What an index of this folder records, by [FileType.wireName].
///
/// Empty means every type, which is exactly what the core reads an absent
/// scope as — one meaning held the same way on both sides, so a folder
/// registered before the scope existed keeps behaving as it did with no
/// migration.
///
/// Wire names rather than the enum, because this is what the core is told
/// and what a stored record has to still mean after a type is renamed on
/// this side of the boundary.
 List<String> get scope;/// The owner's name for this folder as a library, or `null` when it is
/// an ordinary source folder (libraries design).
///
/// The name rather than a flag: a library has to be called something,
/// and a separate `isLibrary` boolean beside a nullable name would make
/// "marked but unnamed" expressible when it is not a state that exists.
///
/// Kept here as well as in the core because this is where the owner
/// decides it — the core is told, and answers the library back with its
/// own uuid, but the *decision* belongs to the folder registration the
/// same way its scope does.
 String? get libraryName;
/// Create a copy of LibrarySource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySourceCopyWith<LibrarySource> get copyWith => _$LibrarySourceCopyWithImpl<LibrarySource>(this as LibrarySource, _$identity);

  /// Serializes this LibrarySource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySource&&(identical(other.path, path) || other.path == path)&&(identical(other.label, label) || other.label == label)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.lastRunOutcome, lastRunOutcome) || other.lastRunOutcome == lastRunOutcome)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.libraryName, libraryName) || other.libraryName == libraryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,label,registeredAt,lastRunId,lastRunOutcome,lastRunAt,const DeepCollectionEquality().hash(scope),libraryName);

@override
String toString() {
  return 'LibrarySource(path: $path, label: $label, registeredAt: $registeredAt, lastRunId: $lastRunId, lastRunOutcome: $lastRunOutcome, lastRunAt: $lastRunAt, scope: $scope, libraryName: $libraryName)';
}


}

/// @nodoc
abstract mixin class $LibrarySourceCopyWith<$Res>  {
  factory $LibrarySourceCopyWith(LibrarySource value, $Res Function(LibrarySource) _then) = _$LibrarySourceCopyWithImpl;
@useResult
$Res call({
 String path, String label, DateTime registeredAt, String? lastRunId, String? lastRunOutcome, DateTime? lastRunAt, List<String> scope, String? libraryName
});




}
/// @nodoc
class _$LibrarySourceCopyWithImpl<$Res>
    implements $LibrarySourceCopyWith<$Res> {
  _$LibrarySourceCopyWithImpl(this._self, this._then);

  final LibrarySource _self;
  final $Res Function(LibrarySource) _then;

/// Create a copy of LibrarySource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? label = null,Object? registeredAt = null,Object? lastRunId = freezed,Object? lastRunOutcome = freezed,Object? lastRunAt = freezed,Object? scope = null,Object? libraryName = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,lastRunOutcome: freezed == lastRunOutcome ? _self.lastRunOutcome : lastRunOutcome // ignore: cast_nullable_to_non_nullable
as String?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as List<String>,libraryName: freezed == libraryName ? _self.libraryName : libraryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySource].
extension LibrarySourcePatterns on LibrarySource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySource value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySource value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String label,  DateTime registeredAt,  String? lastRunId,  String? lastRunOutcome,  DateTime? lastRunAt,  List<String> scope,  String? libraryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySource() when $default != null:
return $default(_that.path,_that.label,_that.registeredAt,_that.lastRunId,_that.lastRunOutcome,_that.lastRunAt,_that.scope,_that.libraryName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String label,  DateTime registeredAt,  String? lastRunId,  String? lastRunOutcome,  DateTime? lastRunAt,  List<String> scope,  String? libraryName)  $default,) {final _that = this;
switch (_that) {
case _LibrarySource():
return $default(_that.path,_that.label,_that.registeredAt,_that.lastRunId,_that.lastRunOutcome,_that.lastRunAt,_that.scope,_that.libraryName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String label,  DateTime registeredAt,  String? lastRunId,  String? lastRunOutcome,  DateTime? lastRunAt,  List<String> scope,  String? libraryName)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySource() when $default != null:
return $default(_that.path,_that.label,_that.registeredAt,_that.lastRunId,_that.lastRunOutcome,_that.lastRunAt,_that.scope,_that.libraryName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySource extends LibrarySource {
  const _LibrarySource({required this.path, required this.label, required this.registeredAt, this.lastRunId, this.lastRunOutcome, this.lastRunAt, final  List<String> scope = const <String>[], this.libraryName}): _scope = scope,super._();
  factory _LibrarySource.fromJson(Map<String, dynamic> json) => _$LibrarySourceFromJson(json);

/// The absolute folder path. Also the key.
@override final  String path;
/// The owner-supplied name, defaulting to the folder's own name.
@override final  String label;
/// When it was registered.
@override final  DateTime registeredAt;
/// The identifier of the most recent run over this folder (UC-06).
@override final  String? lastRunId;
/// Whether that run finished or failed (UC-06).
@override final  String? lastRunOutcome;
/// When that run finished (UC-06).
@override final  DateTime? lastRunAt;
/// What an index of this folder records, by [FileType.wireName].
///
/// Empty means every type, which is exactly what the core reads an absent
/// scope as — one meaning held the same way on both sides, so a folder
/// registered before the scope existed keeps behaving as it did with no
/// migration.
///
/// Wire names rather than the enum, because this is what the core is told
/// and what a stored record has to still mean after a type is renamed on
/// this side of the boundary.
 final  List<String> _scope;
/// What an index of this folder records, by [FileType.wireName].
///
/// Empty means every type, which is exactly what the core reads an absent
/// scope as — one meaning held the same way on both sides, so a folder
/// registered before the scope existed keeps behaving as it did with no
/// migration.
///
/// Wire names rather than the enum, because this is what the core is told
/// and what a stored record has to still mean after a type is renamed on
/// this side of the boundary.
@override@JsonKey() List<String> get scope {
  if (_scope is EqualUnmodifiableListView) return _scope;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scope);
}

/// The owner's name for this folder as a library, or `null` when it is
/// an ordinary source folder (libraries design).
///
/// The name rather than a flag: a library has to be called something,
/// and a separate `isLibrary` boolean beside a nullable name would make
/// "marked but unnamed" expressible when it is not a state that exists.
///
/// Kept here as well as in the core because this is where the owner
/// decides it — the core is told, and answers the library back with its
/// own uuid, but the *decision* belongs to the folder registration the
/// same way its scope does.
@override final  String? libraryName;

/// Create a copy of LibrarySource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySourceCopyWith<_LibrarySource> get copyWith => __$LibrarySourceCopyWithImpl<_LibrarySource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySource&&(identical(other.path, path) || other.path == path)&&(identical(other.label, label) || other.label == label)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.lastRunOutcome, lastRunOutcome) || other.lastRunOutcome == lastRunOutcome)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&const DeepCollectionEquality().equals(other._scope, _scope)&&(identical(other.libraryName, libraryName) || other.libraryName == libraryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,label,registeredAt,lastRunId,lastRunOutcome,lastRunAt,const DeepCollectionEquality().hash(_scope),libraryName);

@override
String toString() {
  return 'LibrarySource(path: $path, label: $label, registeredAt: $registeredAt, lastRunId: $lastRunId, lastRunOutcome: $lastRunOutcome, lastRunAt: $lastRunAt, scope: $scope, libraryName: $libraryName)';
}


}

/// @nodoc
abstract mixin class _$LibrarySourceCopyWith<$Res> implements $LibrarySourceCopyWith<$Res> {
  factory _$LibrarySourceCopyWith(_LibrarySource value, $Res Function(_LibrarySource) _then) = __$LibrarySourceCopyWithImpl;
@override @useResult
$Res call({
 String path, String label, DateTime registeredAt, String? lastRunId, String? lastRunOutcome, DateTime? lastRunAt, List<String> scope, String? libraryName
});




}
/// @nodoc
class __$LibrarySourceCopyWithImpl<$Res>
    implements _$LibrarySourceCopyWith<$Res> {
  __$LibrarySourceCopyWithImpl(this._self, this._then);

  final _LibrarySource _self;
  final $Res Function(_LibrarySource) _then;

/// Create a copy of LibrarySource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? label = null,Object? registeredAt = null,Object? lastRunId = freezed,Object? lastRunOutcome = freezed,Object? lastRunAt = freezed,Object? scope = null,Object? libraryName = freezed,}) {
  return _then(_LibrarySource(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,lastRunOutcome: freezed == lastRunOutcome ? _self.lastRunOutcome : lastRunOutcome // ignore: cast_nullable_to_non_nullable
as String?,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scope: null == scope ? _self._scope : scope // ignore: cast_nullable_to_non_nullable
as List<String>,libraryName: freezed == libraryName ? _self.libraryName : libraryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
