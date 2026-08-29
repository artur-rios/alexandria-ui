// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enrichment_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackEnrichmentRead {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackEnrichmentRead);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackEnrichmentRead()';
}


}

/// @nodoc
class $TrackEnrichmentReadCopyWith<$Res>  {
$TrackEnrichmentReadCopyWith(TrackEnrichmentRead _, $Res Function(TrackEnrichmentRead) __);
}


/// Adds pattern-matching-related methods to [TrackEnrichmentRead].
extension TrackEnrichmentReadPatterns on TrackEnrichmentRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackEnrichmentReadLoaded value)?  loaded,TResult Function( TrackEnrichmentReadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded() when loaded != null:
return loaded(_that);case TrackEnrichmentReadFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackEnrichmentReadLoaded value)  loaded,required TResult Function( TrackEnrichmentReadFailed value)  failed,}){
final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded():
return loaded(_that);case TrackEnrichmentReadFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackEnrichmentReadLoaded value)?  loaded,TResult? Function( TrackEnrichmentReadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded() when loaded != null:
return loaded(_that);case TrackEnrichmentReadFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TrackEnrichment enrichment)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded() when loaded != null:
return loaded(_that.enrichment);case TrackEnrichmentReadFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TrackEnrichment enrichment)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded():
return loaded(_that.enrichment);case TrackEnrichmentReadFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TrackEnrichment enrichment)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case TrackEnrichmentReadLoaded() when loaded != null:
return loaded(_that.enrichment);case TrackEnrichmentReadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TrackEnrichmentReadLoaded implements TrackEnrichmentRead {
  const TrackEnrichmentReadLoaded({required this.enrichment});
  

 final  TrackEnrichment enrichment;

/// Create a copy of TrackEnrichmentRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackEnrichmentReadLoadedCopyWith<TrackEnrichmentReadLoaded> get copyWith => _$TrackEnrichmentReadLoadedCopyWithImpl<TrackEnrichmentReadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackEnrichmentReadLoaded&&(identical(other.enrichment, enrichment) || other.enrichment == enrichment));
}


@override
int get hashCode => Object.hash(runtimeType,enrichment);

@override
String toString() {
  return 'TrackEnrichmentRead.loaded(enrichment: $enrichment)';
}


}

/// @nodoc
abstract mixin class $TrackEnrichmentReadLoadedCopyWith<$Res> implements $TrackEnrichmentReadCopyWith<$Res> {
  factory $TrackEnrichmentReadLoadedCopyWith(TrackEnrichmentReadLoaded value, $Res Function(TrackEnrichmentReadLoaded) _then) = _$TrackEnrichmentReadLoadedCopyWithImpl;
@useResult
$Res call({
 TrackEnrichment enrichment
});


$TrackEnrichmentCopyWith<$Res> get enrichment;

}
/// @nodoc
class _$TrackEnrichmentReadLoadedCopyWithImpl<$Res>
    implements $TrackEnrichmentReadLoadedCopyWith<$Res> {
  _$TrackEnrichmentReadLoadedCopyWithImpl(this._self, this._then);

  final TrackEnrichmentReadLoaded _self;
  final $Res Function(TrackEnrichmentReadLoaded) _then;

/// Create a copy of TrackEnrichmentRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? enrichment = null,}) {
  return _then(TrackEnrichmentReadLoaded(
enrichment: null == enrichment ? _self.enrichment : enrichment // ignore: cast_nullable_to_non_nullable
as TrackEnrichment,
  ));
}

/// Create a copy of TrackEnrichmentRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackEnrichmentCopyWith<$Res> get enrichment {
  
  return $TrackEnrichmentCopyWith<$Res>(_self.enrichment, (value) {
    return _then(_self.copyWith(enrichment: value));
  });
}
}

/// @nodoc


class TrackEnrichmentReadFailed implements TrackEnrichmentRead {
  const TrackEnrichmentReadFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of TrackEnrichmentRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackEnrichmentReadFailedCopyWith<TrackEnrichmentReadFailed> get copyWith => _$TrackEnrichmentReadFailedCopyWithImpl<TrackEnrichmentReadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackEnrichmentReadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TrackEnrichmentRead.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TrackEnrichmentReadFailedCopyWith<$Res> implements $TrackEnrichmentReadCopyWith<$Res> {
  factory $TrackEnrichmentReadFailedCopyWith(TrackEnrichmentReadFailed value, $Res Function(TrackEnrichmentReadFailed) _then) = _$TrackEnrichmentReadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TrackEnrichmentReadFailedCopyWithImpl<$Res>
    implements $TrackEnrichmentReadFailedCopyWith<$Res> {
  _$TrackEnrichmentReadFailedCopyWithImpl(this._self, this._then);

  final TrackEnrichmentReadFailed _self;
  final $Res Function(TrackEnrichmentReadFailed) _then;

/// Create a copy of TrackEnrichmentRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TrackEnrichmentReadFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TrackEnrichmentRead
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
mixin _$EnrichmentRunOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrichmentRunOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EnrichmentRunOutcome()';
}


}

/// @nodoc
class $EnrichmentRunOutcomeCopyWith<$Res>  {
$EnrichmentRunOutcomeCopyWith(EnrichmentRunOutcome _, $Res Function(EnrichmentRunOutcome) __);
}


/// Adds pattern-matching-related methods to [EnrichmentRunOutcome].
extension EnrichmentRunOutcomePatterns on EnrichmentRunOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EnrichmentRunDone value)?  done,TResult Function( EnrichmentRunFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EnrichmentRunDone() when done != null:
return done(_that);case EnrichmentRunFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EnrichmentRunDone value)  done,required TResult Function( EnrichmentRunFailed value)  failed,}){
final _that = this;
switch (_that) {
case EnrichmentRunDone():
return done(_that);case EnrichmentRunFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EnrichmentRunDone value)?  done,TResult? Function( EnrichmentRunFailed value)?  failed,}){
final _that = this;
switch (_that) {
case EnrichmentRunDone() when done != null:
return done(_that);case EnrichmentRunFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EnrichmentReport report)?  done,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EnrichmentRunDone() when done != null:
return done(_that.report);case EnrichmentRunFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EnrichmentReport report)  done,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case EnrichmentRunDone():
return done(_that.report);case EnrichmentRunFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EnrichmentReport report)?  done,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case EnrichmentRunDone() when done != null:
return done(_that.report);case EnrichmentRunFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EnrichmentRunDone implements EnrichmentRunOutcome {
  const EnrichmentRunDone({required this.report});
  

 final  EnrichmentReport report;

/// Create a copy of EnrichmentRunOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrichmentRunDoneCopyWith<EnrichmentRunDone> get copyWith => _$EnrichmentRunDoneCopyWithImpl<EnrichmentRunDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrichmentRunDone&&(identical(other.report, report) || other.report == report));
}


@override
int get hashCode => Object.hash(runtimeType,report);

@override
String toString() {
  return 'EnrichmentRunOutcome.done(report: $report)';
}


}

/// @nodoc
abstract mixin class $EnrichmentRunDoneCopyWith<$Res> implements $EnrichmentRunOutcomeCopyWith<$Res> {
  factory $EnrichmentRunDoneCopyWith(EnrichmentRunDone value, $Res Function(EnrichmentRunDone) _then) = _$EnrichmentRunDoneCopyWithImpl;
@useResult
$Res call({
 EnrichmentReport report
});


$EnrichmentReportCopyWith<$Res> get report;

}
/// @nodoc
class _$EnrichmentRunDoneCopyWithImpl<$Res>
    implements $EnrichmentRunDoneCopyWith<$Res> {
  _$EnrichmentRunDoneCopyWithImpl(this._self, this._then);

  final EnrichmentRunDone _self;
  final $Res Function(EnrichmentRunDone) _then;

/// Create a copy of EnrichmentRunOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? report = null,}) {
  return _then(EnrichmentRunDone(
report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as EnrichmentReport,
  ));
}

/// Create a copy of EnrichmentRunOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrichmentReportCopyWith<$Res> get report {
  
  return $EnrichmentReportCopyWith<$Res>(_self.report, (value) {
    return _then(_self.copyWith(report: value));
  });
}
}

/// @nodoc


class EnrichmentRunFailed implements EnrichmentRunOutcome {
  const EnrichmentRunFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of EnrichmentRunOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrichmentRunFailedCopyWith<EnrichmentRunFailed> get copyWith => _$EnrichmentRunFailedCopyWithImpl<EnrichmentRunFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrichmentRunFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EnrichmentRunOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EnrichmentRunFailedCopyWith<$Res> implements $EnrichmentRunOutcomeCopyWith<$Res> {
  factory $EnrichmentRunFailedCopyWith(EnrichmentRunFailed value, $Res Function(EnrichmentRunFailed) _then) = _$EnrichmentRunFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EnrichmentRunFailedCopyWithImpl<$Res>
    implements $EnrichmentRunFailedCopyWith<$Res> {
  _$EnrichmentRunFailedCopyWithImpl(this._self, this._then);

  final EnrichmentRunFailed _self;
  final $Res Function(EnrichmentRunFailed) _then;

/// Create a copy of EnrichmentRunOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EnrichmentRunFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EnrichmentRunOutcome
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
