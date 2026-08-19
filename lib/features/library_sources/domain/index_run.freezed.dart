// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'index_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IndexRunCounts {

 int get scanned; int get indexed; int get skipped; int get failed;
/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunCountsCopyWith<IndexRunCounts> get copyWith => _$IndexRunCountsCopyWithImpl<IndexRunCounts>(this as IndexRunCounts, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunCounts&&(identical(other.scanned, scanned) || other.scanned == scanned)&&(identical(other.indexed, indexed) || other.indexed == indexed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,scanned,indexed,skipped,failed);

@override
String toString() {
  return 'IndexRunCounts(scanned: $scanned, indexed: $indexed, skipped: $skipped, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $IndexRunCountsCopyWith<$Res>  {
  factory $IndexRunCountsCopyWith(IndexRunCounts value, $Res Function(IndexRunCounts) _then) = _$IndexRunCountsCopyWithImpl;
@useResult
$Res call({
 int scanned, int indexed, int skipped, int failed
});




}
/// @nodoc
class _$IndexRunCountsCopyWithImpl<$Res>
    implements $IndexRunCountsCopyWith<$Res> {
  _$IndexRunCountsCopyWithImpl(this._self, this._then);

  final IndexRunCounts _self;
  final $Res Function(IndexRunCounts) _then;

/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scanned = null,Object? indexed = null,Object? skipped = null,Object? failed = null,}) {
  return _then(_self.copyWith(
scanned: null == scanned ? _self.scanned : scanned // ignore: cast_nullable_to_non_nullable
as int,indexed: null == indexed ? _self.indexed : indexed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IndexRunCounts].
extension IndexRunCountsPatterns on IndexRunCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndexRunCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndexRunCounts value)  $default,){
final _that = this;
switch (_that) {
case _IndexRunCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndexRunCounts value)?  $default,){
final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int scanned,  int indexed,  int skipped,  int failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
return $default(_that.scanned,_that.indexed,_that.skipped,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int scanned,  int indexed,  int skipped,  int failed)  $default,) {final _that = this;
switch (_that) {
case _IndexRunCounts():
return $default(_that.scanned,_that.indexed,_that.skipped,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int scanned,  int indexed,  int skipped,  int failed)?  $default,) {final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
return $default(_that.scanned,_that.indexed,_that.skipped,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRunCounts implements IndexRunCounts {
  const _IndexRunCounts({this.scanned = 0, this.indexed = 0, this.skipped = 0, this.failed = 0});
  

@override@JsonKey() final  int scanned;
@override@JsonKey() final  int indexed;
@override@JsonKey() final  int skipped;
@override@JsonKey() final  int failed;

/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexRunCountsCopyWith<_IndexRunCounts> get copyWith => __$IndexRunCountsCopyWithImpl<_IndexRunCounts>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRunCounts&&(identical(other.scanned, scanned) || other.scanned == scanned)&&(identical(other.indexed, indexed) || other.indexed == indexed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,scanned,indexed,skipped,failed);

@override
String toString() {
  return 'IndexRunCounts(scanned: $scanned, indexed: $indexed, skipped: $skipped, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$IndexRunCountsCopyWith<$Res> implements $IndexRunCountsCopyWith<$Res> {
  factory _$IndexRunCountsCopyWith(_IndexRunCounts value, $Res Function(_IndexRunCounts) _then) = __$IndexRunCountsCopyWithImpl;
@override @useResult
$Res call({
 int scanned, int indexed, int skipped, int failed
});




}
/// @nodoc
class __$IndexRunCountsCopyWithImpl<$Res>
    implements _$IndexRunCountsCopyWith<$Res> {
  __$IndexRunCountsCopyWithImpl(this._self, this._then);

  final _IndexRunCounts _self;
  final $Res Function(_IndexRunCounts) _then;

/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scanned = null,Object? indexed = null,Object? skipped = null,Object? failed = null,}) {
  return _then(_IndexRunCounts(
scanned: null == scanned ? _self.scanned : scanned // ignore: cast_nullable_to_non_nullable
as int,indexed: null == indexed ? _self.indexed : indexed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$IndexRun {

/// The identifier the core returned when the run was started.
 String get runId;/// The folder being scanned.
 String get root;/// Where the run is.
 IndexRunStatus get status;/// What it counted, once it has finished.
 IndexRunCounts? get counts;/// Why it failed, when it did.
 String? get error;
/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunCopyWith<IndexRun> get copyWith => _$IndexRunCopyWithImpl<IndexRun>(this as IndexRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.root, root) || other.root == root)&&(identical(other.status, status) || other.status == status)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,root,status,counts,error);

@override
String toString() {
  return 'IndexRun(runId: $runId, root: $root, status: $status, counts: $counts, error: $error)';
}


}

/// @nodoc
abstract mixin class $IndexRunCopyWith<$Res>  {
  factory $IndexRunCopyWith(IndexRun value, $Res Function(IndexRun) _then) = _$IndexRunCopyWithImpl;
@useResult
$Res call({
 String runId, String root, IndexRunStatus status, IndexRunCounts? counts, String? error
});


$IndexRunCountsCopyWith<$Res>? get counts;

}
/// @nodoc
class _$IndexRunCopyWithImpl<$Res>
    implements $IndexRunCopyWith<$Res> {
  _$IndexRunCopyWithImpl(this._self, this._then);

  final IndexRun _self;
  final $Res Function(IndexRun) _then;

/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? root = null,Object? status = null,Object? counts = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IndexRunStatus,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as IndexRunCounts?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCountsCopyWith<$Res>? get counts {
    if (_self.counts == null) {
    return null;
  }

  return $IndexRunCountsCopyWith<$Res>(_self.counts!, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}


/// Adds pattern-matching-related methods to [IndexRun].
extension IndexRunPatterns on IndexRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndexRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndexRun value)  $default,){
final _that = this;
switch (_that) {
case _IndexRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndexRun value)?  $default,){
final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String root,  IndexRunStatus status,  IndexRunCounts? counts,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
return $default(_that.runId,_that.root,_that.status,_that.counts,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String root,  IndexRunStatus status,  IndexRunCounts? counts,  String? error)  $default,) {final _that = this;
switch (_that) {
case _IndexRun():
return $default(_that.runId,_that.root,_that.status,_that.counts,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String root,  IndexRunStatus status,  IndexRunCounts? counts,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
return $default(_that.runId,_that.root,_that.status,_that.counts,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRun extends IndexRun {
  const _IndexRun({required this.runId, required this.root, required this.status, this.counts, this.error}): super._();
  

/// The identifier the core returned when the run was started.
@override final  String runId;
/// The folder being scanned.
@override final  String root;
/// Where the run is.
@override final  IndexRunStatus status;
/// What it counted, once it has finished.
@override final  IndexRunCounts? counts;
/// Why it failed, when it did.
@override final  String? error;

/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexRunCopyWith<_IndexRun> get copyWith => __$IndexRunCopyWithImpl<_IndexRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.root, root) || other.root == root)&&(identical(other.status, status) || other.status == status)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,root,status,counts,error);

@override
String toString() {
  return 'IndexRun(runId: $runId, root: $root, status: $status, counts: $counts, error: $error)';
}


}

/// @nodoc
abstract mixin class _$IndexRunCopyWith<$Res> implements $IndexRunCopyWith<$Res> {
  factory _$IndexRunCopyWith(_IndexRun value, $Res Function(_IndexRun) _then) = __$IndexRunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String root, IndexRunStatus status, IndexRunCounts? counts, String? error
});


@override $IndexRunCountsCopyWith<$Res>? get counts;

}
/// @nodoc
class __$IndexRunCopyWithImpl<$Res>
    implements _$IndexRunCopyWith<$Res> {
  __$IndexRunCopyWithImpl(this._self, this._then);

  final _IndexRun _self;
  final $Res Function(_IndexRun) _then;

/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? root = null,Object? status = null,Object? counts = freezed,Object? error = freezed,}) {
  return _then(_IndexRun(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IndexRunStatus,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as IndexRunCounts?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IndexRunCountsCopyWith<$Res>? get counts {
    if (_self.counts == null) {
    return null;
  }

  return $IndexRunCountsCopyWith<$Res>(_self.counts!, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}

// dart format on
