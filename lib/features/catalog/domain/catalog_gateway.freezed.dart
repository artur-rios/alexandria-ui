// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogListing {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogListing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CatalogListing()';
}


}

/// @nodoc
class $CatalogListingCopyWith<$Res>  {
$CatalogListingCopyWith(CatalogListing _, $Res Function(CatalogListing) __);
}


/// Adds pattern-matching-related methods to [CatalogListing].
extension CatalogListingPatterns on CatalogListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CatalogListingLoaded value)?  loaded,TResult Function( CatalogListingFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CatalogListingLoaded() when loaded != null:
return loaded(_that);case CatalogListingFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CatalogListingLoaded value)  loaded,required TResult Function( CatalogListingFailed value)  failed,}){
final _that = this;
switch (_that) {
case CatalogListingLoaded():
return loaded(_that);case CatalogListingFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CatalogListingLoaded value)?  loaded,TResult? Function( CatalogListingFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CatalogListingLoaded() when loaded != null:
return loaded(_that);case CatalogListingFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<CatalogFile> files)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CatalogListingLoaded() when loaded != null:
return loaded(_that.files);case CatalogListingFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<CatalogFile> files)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case CatalogListingLoaded():
return loaded(_that.files);case CatalogListingFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<CatalogFile> files)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case CatalogListingLoaded() when loaded != null:
return loaded(_that.files);case CatalogListingFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CatalogListingLoaded implements CatalogListing {
  const CatalogListingLoaded({required final  List<CatalogFile> files}): _files = files;
  

 final  List<CatalogFile> _files;
 List<CatalogFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of CatalogListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogListingLoadedCopyWith<CatalogListingLoaded> get copyWith => _$CatalogListingLoadedCopyWithImpl<CatalogListingLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogListingLoaded&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'CatalogListing.loaded(files: $files)';
}


}

/// @nodoc
abstract mixin class $CatalogListingLoadedCopyWith<$Res> implements $CatalogListingCopyWith<$Res> {
  factory $CatalogListingLoadedCopyWith(CatalogListingLoaded value, $Res Function(CatalogListingLoaded) _then) = _$CatalogListingLoadedCopyWithImpl;
@useResult
$Res call({
 List<CatalogFile> files
});




}
/// @nodoc
class _$CatalogListingLoadedCopyWithImpl<$Res>
    implements $CatalogListingLoadedCopyWith<$Res> {
  _$CatalogListingLoadedCopyWithImpl(this._self, this._then);

  final CatalogListingLoaded _self;
  final $Res Function(CatalogListingLoaded) _then;

/// Create a copy of CatalogListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(CatalogListingLoaded(
files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<CatalogFile>,
  ));
}


}

/// @nodoc


class CatalogListingFailed implements CatalogListing {
  const CatalogListingFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of CatalogListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogListingFailedCopyWith<CatalogListingFailed> get copyWith => _$CatalogListingFailedCopyWithImpl<CatalogListingFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogListingFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CatalogListing.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CatalogListingFailedCopyWith<$Res> implements $CatalogListingCopyWith<$Res> {
  factory $CatalogListingFailedCopyWith(CatalogListingFailed value, $Res Function(CatalogListingFailed) _then) = _$CatalogListingFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CatalogListingFailedCopyWithImpl<$Res>
    implements $CatalogListingFailedCopyWith<$Res> {
  _$CatalogListingFailedCopyWithImpl(this._self, this._then);

  final CatalogListingFailed _self;
  final $Res Function(CatalogListingFailed) _then;

/// Create a copy of CatalogListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CatalogListingFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CatalogListing
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
