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

// An index run's four (UC-06).
 int get scanned; int get indexed; int get skipped;/// Entries already in the catalog when the walk reached them. Distinct
/// from `skipped`, which is an unsupported file type: a resumed run
/// re-walks and meets everything an earlier segment indexed, and folding
/// the two together would report thousands of files as skipped.
 int get alreadyCataloged;// A refresh run's three, plus the shared failure count (UC-07).
 int get refreshed; int get markedMissing; int get unchanged; int get failed;
/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunCountsCopyWith<IndexRunCounts> get copyWith => _$IndexRunCountsCopyWithImpl<IndexRunCounts>(this as IndexRunCounts, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRunCounts&&(identical(other.scanned, scanned) || other.scanned == scanned)&&(identical(other.indexed, indexed) || other.indexed == indexed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.alreadyCataloged, alreadyCataloged) || other.alreadyCataloged == alreadyCataloged)&&(identical(other.refreshed, refreshed) || other.refreshed == refreshed)&&(identical(other.markedMissing, markedMissing) || other.markedMissing == markedMissing)&&(identical(other.unchanged, unchanged) || other.unchanged == unchanged)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,scanned,indexed,skipped,alreadyCataloged,refreshed,markedMissing,unchanged,failed);

@override
String toString() {
  return 'IndexRunCounts(scanned: $scanned, indexed: $indexed, skipped: $skipped, alreadyCataloged: $alreadyCataloged, refreshed: $refreshed, markedMissing: $markedMissing, unchanged: $unchanged, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $IndexRunCountsCopyWith<$Res>  {
  factory $IndexRunCountsCopyWith(IndexRunCounts value, $Res Function(IndexRunCounts) _then) = _$IndexRunCountsCopyWithImpl;
@useResult
$Res call({
 int scanned, int indexed, int skipped, int alreadyCataloged, int refreshed, int markedMissing, int unchanged, int failed
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
@pragma('vm:prefer-inline') @override $Res call({Object? scanned = null,Object? indexed = null,Object? skipped = null,Object? alreadyCataloged = null,Object? refreshed = null,Object? markedMissing = null,Object? unchanged = null,Object? failed = null,}) {
  return _then(_self.copyWith(
scanned: null == scanned ? _self.scanned : scanned // ignore: cast_nullable_to_non_nullable
as int,indexed: null == indexed ? _self.indexed : indexed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,alreadyCataloged: null == alreadyCataloged ? _self.alreadyCataloged : alreadyCataloged // ignore: cast_nullable_to_non_nullable
as int,refreshed: null == refreshed ? _self.refreshed : refreshed // ignore: cast_nullable_to_non_nullable
as int,markedMissing: null == markedMissing ? _self.markedMissing : markedMissing // ignore: cast_nullable_to_non_nullable
as int,unchanged: null == unchanged ? _self.unchanged : unchanged // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int scanned,  int indexed,  int skipped,  int alreadyCataloged,  int refreshed,  int markedMissing,  int unchanged,  int failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
return $default(_that.scanned,_that.indexed,_that.skipped,_that.alreadyCataloged,_that.refreshed,_that.markedMissing,_that.unchanged,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int scanned,  int indexed,  int skipped,  int alreadyCataloged,  int refreshed,  int markedMissing,  int unchanged,  int failed)  $default,) {final _that = this;
switch (_that) {
case _IndexRunCounts():
return $default(_that.scanned,_that.indexed,_that.skipped,_that.alreadyCataloged,_that.refreshed,_that.markedMissing,_that.unchanged,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int scanned,  int indexed,  int skipped,  int alreadyCataloged,  int refreshed,  int markedMissing,  int unchanged,  int failed)?  $default,) {final _that = this;
switch (_that) {
case _IndexRunCounts() when $default != null:
return $default(_that.scanned,_that.indexed,_that.skipped,_that.alreadyCataloged,_that.refreshed,_that.markedMissing,_that.unchanged,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRunCounts implements IndexRunCounts {
  const _IndexRunCounts({this.scanned = 0, this.indexed = 0, this.skipped = 0, this.alreadyCataloged = 0, this.refreshed = 0, this.markedMissing = 0, this.unchanged = 0, this.failed = 0});
  

// An index run's four (UC-06).
@override@JsonKey() final  int scanned;
@override@JsonKey() final  int indexed;
@override@JsonKey() final  int skipped;
/// Entries already in the catalog when the walk reached them. Distinct
/// from `skipped`, which is an unsupported file type: a resumed run
/// re-walks and meets everything an earlier segment indexed, and folding
/// the two together would report thousands of files as skipped.
@override@JsonKey() final  int alreadyCataloged;
// A refresh run's three, plus the shared failure count (UC-07).
@override@JsonKey() final  int refreshed;
@override@JsonKey() final  int markedMissing;
@override@JsonKey() final  int unchanged;
@override@JsonKey() final  int failed;

/// Create a copy of IndexRunCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexRunCountsCopyWith<_IndexRunCounts> get copyWith => __$IndexRunCountsCopyWithImpl<_IndexRunCounts>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRunCounts&&(identical(other.scanned, scanned) || other.scanned == scanned)&&(identical(other.indexed, indexed) || other.indexed == indexed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.alreadyCataloged, alreadyCataloged) || other.alreadyCataloged == alreadyCataloged)&&(identical(other.refreshed, refreshed) || other.refreshed == refreshed)&&(identical(other.markedMissing, markedMissing) || other.markedMissing == markedMissing)&&(identical(other.unchanged, unchanged) || other.unchanged == unchanged)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,scanned,indexed,skipped,alreadyCataloged,refreshed,markedMissing,unchanged,failed);

@override
String toString() {
  return 'IndexRunCounts(scanned: $scanned, indexed: $indexed, skipped: $skipped, alreadyCataloged: $alreadyCataloged, refreshed: $refreshed, markedMissing: $markedMissing, unchanged: $unchanged, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$IndexRunCountsCopyWith<$Res> implements $IndexRunCountsCopyWith<$Res> {
  factory _$IndexRunCountsCopyWith(_IndexRunCounts value, $Res Function(_IndexRunCounts) _then) = __$IndexRunCountsCopyWithImpl;
@override @useResult
$Res call({
 int scanned, int indexed, int skipped, int alreadyCataloged, int refreshed, int markedMissing, int unchanged, int failed
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
@override @pragma('vm:prefer-inline') $Res call({Object? scanned = null,Object? indexed = null,Object? skipped = null,Object? alreadyCataloged = null,Object? refreshed = null,Object? markedMissing = null,Object? unchanged = null,Object? failed = null,}) {
  return _then(_IndexRunCounts(
scanned: null == scanned ? _self.scanned : scanned // ignore: cast_nullable_to_non_nullable
as int,indexed: null == indexed ? _self.indexed : indexed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,alreadyCataloged: null == alreadyCataloged ? _self.alreadyCataloged : alreadyCataloged // ignore: cast_nullable_to_non_nullable
as int,refreshed: null == refreshed ? _self.refreshed : refreshed // ignore: cast_nullable_to_non_nullable
as int,markedMissing: null == markedMissing ? _self.markedMissing : markedMissing // ignore: cast_nullable_to_non_nullable
as int,unchanged: null == unchanged ? _self.unchanged : unchanged // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$IndexRun {

/// The identifier the core returned when the run was started.
 String get runId;/// The folder being scanned, or empty for a refresh, which covers the
/// whole catalog rather than one folder.
 String get root;/// Which operation opened this run.
 IndexRunKind get kind;/// Where the run is.
 IndexRunStatus get status;/// Which half of the run is executing, or null once it is terminal.
 IndexRunPhase? get phase;/// How many entries the run has to get through, once discovery has
/// counted them. Null while discovery is still counting.
 int? get total;/// How many entries the run has finished with. Null for a run that never
/// published progress.
 int? get processed;/// How long the run has spent *working* — elapsed time minus the time it
/// spent paused. The input to a remaining-time estimate; wall time would
/// overstate the work done by however long the owner left it paused.
 int get activeMillis;/// When the run was paused, for a run that is paused right now.
 DateTime? get pausedAt;/// What it counted, once it has finished.
 IndexRunCounts? get counts;/// Why it failed, when it did.
 String? get error;
/// Create a copy of IndexRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexRunCopyWith<IndexRun> get copyWith => _$IndexRunCopyWithImpl<IndexRun>(this as IndexRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.root, root) || other.root == root)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.total, total) || other.total == total)&&(identical(other.processed, processed) || other.processed == processed)&&(identical(other.activeMillis, activeMillis) || other.activeMillis == activeMillis)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,root,kind,status,phase,total,processed,activeMillis,pausedAt,counts,error);

@override
String toString() {
  return 'IndexRun(runId: $runId, root: $root, kind: $kind, status: $status, phase: $phase, total: $total, processed: $processed, activeMillis: $activeMillis, pausedAt: $pausedAt, counts: $counts, error: $error)';
}


}

/// @nodoc
abstract mixin class $IndexRunCopyWith<$Res>  {
  factory $IndexRunCopyWith(IndexRun value, $Res Function(IndexRun) _then) = _$IndexRunCopyWithImpl;
@useResult
$Res call({
 String runId, String root, IndexRunKind kind, IndexRunStatus status, IndexRunPhase? phase, int? total, int? processed, int activeMillis, DateTime? pausedAt, IndexRunCounts? counts, String? error
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
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? root = null,Object? kind = null,Object? status = null,Object? phase = freezed,Object? total = freezed,Object? processed = freezed,Object? activeMillis = null,Object? pausedAt = freezed,Object? counts = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as IndexRunKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IndexRunStatus,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as IndexRunPhase?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,processed: freezed == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as int?,activeMillis: null == activeMillis ? _self.activeMillis : activeMillis // ignore: cast_nullable_to_non_nullable
as int,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String root,  IndexRunKind kind,  IndexRunStatus status,  IndexRunPhase? phase,  int? total,  int? processed,  int activeMillis,  DateTime? pausedAt,  IndexRunCounts? counts,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
return $default(_that.runId,_that.root,_that.kind,_that.status,_that.phase,_that.total,_that.processed,_that.activeMillis,_that.pausedAt,_that.counts,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String root,  IndexRunKind kind,  IndexRunStatus status,  IndexRunPhase? phase,  int? total,  int? processed,  int activeMillis,  DateTime? pausedAt,  IndexRunCounts? counts,  String? error)  $default,) {final _that = this;
switch (_that) {
case _IndexRun():
return $default(_that.runId,_that.root,_that.kind,_that.status,_that.phase,_that.total,_that.processed,_that.activeMillis,_that.pausedAt,_that.counts,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String root,  IndexRunKind kind,  IndexRunStatus status,  IndexRunPhase? phase,  int? total,  int? processed,  int activeMillis,  DateTime? pausedAt,  IndexRunCounts? counts,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _IndexRun() when $default != null:
return $default(_that.runId,_that.root,_that.kind,_that.status,_that.phase,_that.total,_that.processed,_that.activeMillis,_that.pausedAt,_that.counts,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _IndexRun extends IndexRun {
  const _IndexRun({required this.runId, required this.root, this.kind = IndexRunKind.scan, required this.status, this.phase, this.total, this.processed, this.activeMillis = 0, this.pausedAt, this.counts, this.error}): super._();
  

/// The identifier the core returned when the run was started.
@override final  String runId;
/// The folder being scanned, or empty for a refresh, which covers the
/// whole catalog rather than one folder.
@override final  String root;
/// Which operation opened this run.
@override@JsonKey() final  IndexRunKind kind;
/// Where the run is.
@override final  IndexRunStatus status;
/// Which half of the run is executing, or null once it is terminal.
@override final  IndexRunPhase? phase;
/// How many entries the run has to get through, once discovery has
/// counted them. Null while discovery is still counting.
@override final  int? total;
/// How many entries the run has finished with. Null for a run that never
/// published progress.
@override final  int? processed;
/// How long the run has spent *working* — elapsed time minus the time it
/// spent paused. The input to a remaining-time estimate; wall time would
/// overstate the work done by however long the owner left it paused.
@override@JsonKey() final  int activeMillis;
/// When the run was paused, for a run that is paused right now.
@override final  DateTime? pausedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexRun&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.root, root) || other.root == root)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.total, total) || other.total == total)&&(identical(other.processed, processed) || other.processed == processed)&&(identical(other.activeMillis, activeMillis) || other.activeMillis == activeMillis)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,runId,root,kind,status,phase,total,processed,activeMillis,pausedAt,counts,error);

@override
String toString() {
  return 'IndexRun(runId: $runId, root: $root, kind: $kind, status: $status, phase: $phase, total: $total, processed: $processed, activeMillis: $activeMillis, pausedAt: $pausedAt, counts: $counts, error: $error)';
}


}

/// @nodoc
abstract mixin class _$IndexRunCopyWith<$Res> implements $IndexRunCopyWith<$Res> {
  factory _$IndexRunCopyWith(_IndexRun value, $Res Function(_IndexRun) _then) = __$IndexRunCopyWithImpl;
@override @useResult
$Res call({
 String runId, String root, IndexRunKind kind, IndexRunStatus status, IndexRunPhase? phase, int? total, int? processed, int activeMillis, DateTime? pausedAt, IndexRunCounts? counts, String? error
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
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? root = null,Object? kind = null,Object? status = null,Object? phase = freezed,Object? total = freezed,Object? processed = freezed,Object? activeMillis = null,Object? pausedAt = freezed,Object? counts = freezed,Object? error = freezed,}) {
  return _then(_IndexRun(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as IndexRunKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IndexRunStatus,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as IndexRunPhase?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,processed: freezed == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as int?,activeMillis: null == activeMillis ? _self.activeMillis : activeMillis // ignore: cast_nullable_to_non_nullable
as int,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
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

/// @nodoc
mixin _$RunFailure {

/// The file's path on disk, as the walk saw it.
 String get path;/// What went wrong, in the words the core's error carried.
///
/// Shown as it came rather than mapped to a message of this
/// application's own: the reasons are whatever the filesystem and the
/// database said, and a translation table here would be inventing a
/// taxonomy neither side keeps.
 String get reason;
/// Create a copy of RunFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunFailureCopyWith<RunFailure> get copyWith => _$RunFailureCopyWithImpl<RunFailure>(this as RunFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunFailure&&(identical(other.path, path) || other.path == path)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,path,reason);

@override
String toString() {
  return 'RunFailure(path: $path, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RunFailureCopyWith<$Res>  {
  factory $RunFailureCopyWith(RunFailure value, $Res Function(RunFailure) _then) = _$RunFailureCopyWithImpl;
@useResult
$Res call({
 String path, String reason
});




}
/// @nodoc
class _$RunFailureCopyWithImpl<$Res>
    implements $RunFailureCopyWith<$Res> {
  _$RunFailureCopyWithImpl(this._self, this._then);

  final RunFailure _self;
  final $Res Function(RunFailure) _then;

/// Create a copy of RunFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? reason = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RunFailure].
extension RunFailurePatterns on RunFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RunFailure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RunFailure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RunFailure value)  $default,){
final _that = this;
switch (_that) {
case _RunFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RunFailure value)?  $default,){
final _that = this;
switch (_that) {
case _RunFailure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RunFailure() when $default != null:
return $default(_that.path,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String reason)  $default,) {final _that = this;
switch (_that) {
case _RunFailure():
return $default(_that.path,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _RunFailure() when $default != null:
return $default(_that.path,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _RunFailure implements RunFailure {
  const _RunFailure({required this.path, required this.reason});
  

/// The file's path on disk, as the walk saw it.
@override final  String path;
/// What went wrong, in the words the core's error carried.
///
/// Shown as it came rather than mapped to a message of this
/// application's own: the reasons are whatever the filesystem and the
/// database said, and a translation table here would be inventing a
/// taxonomy neither side keeps.
@override final  String reason;

/// Create a copy of RunFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunFailureCopyWith<_RunFailure> get copyWith => __$RunFailureCopyWithImpl<_RunFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RunFailure&&(identical(other.path, path) || other.path == path)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,path,reason);

@override
String toString() {
  return 'RunFailure(path: $path, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$RunFailureCopyWith<$Res> implements $RunFailureCopyWith<$Res> {
  factory _$RunFailureCopyWith(_RunFailure value, $Res Function(_RunFailure) _then) = __$RunFailureCopyWithImpl;
@override @useResult
$Res call({
 String path, String reason
});




}
/// @nodoc
class __$RunFailureCopyWithImpl<$Res>
    implements _$RunFailureCopyWith<$Res> {
  __$RunFailureCopyWithImpl(this._self, this._then);

  final _RunFailure _self;
  final $Res Function(_RunFailure) _then;

/// Create a copy of RunFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? reason = null,}) {
  return _then(_RunFailure(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
