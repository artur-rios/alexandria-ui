// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CollectionBrowse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionBrowse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CollectionBrowse()';
}


}

/// @nodoc
class $CollectionBrowseCopyWith<$Res>  {
$CollectionBrowseCopyWith(CollectionBrowse _, $Res Function(CollectionBrowse) __);
}


/// Adds pattern-matching-related methods to [CollectionBrowse].
extension CollectionBrowsePatterns on CollectionBrowse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CollectionBrowseLoaded value)?  loaded,TResult Function( CollectionBrowseFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CollectionBrowseLoaded() when loaded != null:
return loaded(_that);case CollectionBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CollectionBrowseLoaded value)  loaded,required TResult Function( CollectionBrowseFailed value)  failed,}){
final _that = this;
switch (_that) {
case CollectionBrowseLoaded():
return loaded(_that);case CollectionBrowseFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CollectionBrowseLoaded value)?  loaded,TResult? Function( CollectionBrowseFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CollectionBrowseLoaded() when loaded != null:
return loaded(_that);case CollectionBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Collection> collections)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CollectionBrowseLoaded() when loaded != null:
return loaded(_that.collections);case CollectionBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Collection> collections)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case CollectionBrowseLoaded():
return loaded(_that.collections);case CollectionBrowseFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Collection> collections)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case CollectionBrowseLoaded() when loaded != null:
return loaded(_that.collections);case CollectionBrowseFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CollectionBrowseLoaded implements CollectionBrowse {
  const CollectionBrowseLoaded({required final  List<Collection> collections}): _collections = collections;
  

 final  List<Collection> _collections;
 List<Collection> get collections {
  if (_collections is EqualUnmodifiableListView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collections);
}


/// Create a copy of CollectionBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionBrowseLoadedCopyWith<CollectionBrowseLoaded> get copyWith => _$CollectionBrowseLoadedCopyWithImpl<CollectionBrowseLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionBrowseLoaded&&const DeepCollectionEquality().equals(other._collections, _collections));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_collections));

@override
String toString() {
  return 'CollectionBrowse.loaded(collections: $collections)';
}


}

/// @nodoc
abstract mixin class $CollectionBrowseLoadedCopyWith<$Res> implements $CollectionBrowseCopyWith<$Res> {
  factory $CollectionBrowseLoadedCopyWith(CollectionBrowseLoaded value, $Res Function(CollectionBrowseLoaded) _then) = _$CollectionBrowseLoadedCopyWithImpl;
@useResult
$Res call({
 List<Collection> collections
});




}
/// @nodoc
class _$CollectionBrowseLoadedCopyWithImpl<$Res>
    implements $CollectionBrowseLoadedCopyWith<$Res> {
  _$CollectionBrowseLoadedCopyWithImpl(this._self, this._then);

  final CollectionBrowseLoaded _self;
  final $Res Function(CollectionBrowseLoaded) _then;

/// Create a copy of CollectionBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? collections = null,}) {
  return _then(CollectionBrowseLoaded(
collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as List<Collection>,
  ));
}


}

/// @nodoc


class CollectionBrowseFailed implements CollectionBrowse {
  const CollectionBrowseFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of CollectionBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionBrowseFailedCopyWith<CollectionBrowseFailed> get copyWith => _$CollectionBrowseFailedCopyWithImpl<CollectionBrowseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionBrowseFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CollectionBrowse.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CollectionBrowseFailedCopyWith<$Res> implements $CollectionBrowseCopyWith<$Res> {
  factory $CollectionBrowseFailedCopyWith(CollectionBrowseFailed value, $Res Function(CollectionBrowseFailed) _then) = _$CollectionBrowseFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CollectionBrowseFailedCopyWithImpl<$Res>
    implements $CollectionBrowseFailedCopyWith<$Res> {
  _$CollectionBrowseFailedCopyWithImpl(this._self, this._then);

  final CollectionBrowseFailed _self;
  final $Res Function(CollectionBrowseFailed) _then;

/// Create a copy of CollectionBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CollectionBrowseFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CollectionBrowse
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
mixin _$CollectionWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CollectionWrite()';
}


}

/// @nodoc
class $CollectionWriteCopyWith<$Res>  {
$CollectionWriteCopyWith(CollectionWrite _, $Res Function(CollectionWrite) __);
}


/// Adds pattern-matching-related methods to [CollectionWrite].
extension CollectionWritePatterns on CollectionWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CollectionWriteDone value)?  done,TResult Function( CollectionWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CollectionWriteDone() when done != null:
return done(_that);case CollectionWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CollectionWriteDone value)  done,required TResult Function( CollectionWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case CollectionWriteDone():
return done(_that);case CollectionWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CollectionWriteDone value)?  done,TResult? Function( CollectionWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CollectionWriteDone() when done != null:
return done(_that);case CollectionWriteFailed() when failed != null:
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
case CollectionWriteDone() when done != null:
return done();case CollectionWriteFailed() when failed != null:
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
case CollectionWriteDone():
return done();case CollectionWriteFailed():
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
case CollectionWriteDone() when done != null:
return done();case CollectionWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CollectionWriteDone implements CollectionWrite {
  const CollectionWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CollectionWrite.done()';
}


}




/// @nodoc


class CollectionWriteFailed implements CollectionWrite {
  const CollectionWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of CollectionWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionWriteFailedCopyWith<CollectionWriteFailed> get copyWith => _$CollectionWriteFailedCopyWithImpl<CollectionWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CollectionWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CollectionWriteFailedCopyWith<$Res> implements $CollectionWriteCopyWith<$Res> {
  factory $CollectionWriteFailedCopyWith(CollectionWriteFailed value, $Res Function(CollectionWriteFailed) _then) = _$CollectionWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CollectionWriteFailedCopyWithImpl<$Res>
    implements $CollectionWriteFailedCopyWith<$Res> {
  _$CollectionWriteFailedCopyWithImpl(this._self, this._then);

  final CollectionWriteFailed _self;
  final $Res Function(CollectionWriteFailed) _then;

/// Create a copy of CollectionWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CollectionWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CollectionWrite
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
