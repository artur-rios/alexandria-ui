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

/// @nodoc
mixin _$CollectionMember {

 String get uuid; String get name;
/// Create a copy of CollectionMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionMemberCopyWith<CollectionMember> get copyWith => _$CollectionMemberCopyWithImpl<CollectionMember>(this as CollectionMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMember&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name);

@override
String toString() {
  return 'CollectionMember(uuid: $uuid, name: $name)';
}


}

/// @nodoc
abstract mixin class $CollectionMemberCopyWith<$Res>  {
  factory $CollectionMemberCopyWith(CollectionMember value, $Res Function(CollectionMember) _then) = _$CollectionMemberCopyWithImpl;
@useResult
$Res call({
 String uuid, String name
});




}
/// @nodoc
class _$CollectionMemberCopyWithImpl<$Res>
    implements $CollectionMemberCopyWith<$Res> {
  _$CollectionMemberCopyWithImpl(this._self, this._then);

  final CollectionMember _self;
  final $Res Function(CollectionMember) _then;

/// Create a copy of CollectionMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionMember].
extension CollectionMemberPatterns on CollectionMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionMember value)  $default,){
final _that = this;
switch (_that) {
case _CollectionMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionMember value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionMember() when $default != null:
return $default(_that.uuid,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name)  $default,) {final _that = this;
switch (_that) {
case _CollectionMember():
return $default(_that.uuid,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name)?  $default,) {final _that = this;
switch (_that) {
case _CollectionMember() when $default != null:
return $default(_that.uuid,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _CollectionMember implements CollectionMember {
  const _CollectionMember({required this.uuid, required this.name});
  

@override final  String uuid;
@override final  String name;

/// Create a copy of CollectionMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionMemberCopyWith<_CollectionMember> get copyWith => __$CollectionMemberCopyWithImpl<_CollectionMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionMember&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name);

@override
String toString() {
  return 'CollectionMember(uuid: $uuid, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CollectionMemberCopyWith<$Res> implements $CollectionMemberCopyWith<$Res> {
  factory _$CollectionMemberCopyWith(_CollectionMember value, $Res Function(_CollectionMember) _then) = __$CollectionMemberCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name
});




}
/// @nodoc
class __$CollectionMemberCopyWithImpl<$Res>
    implements _$CollectionMemberCopyWith<$Res> {
  __$CollectionMemberCopyWithImpl(this._self, this._then);

  final _CollectionMember _self;
  final $Res Function(_CollectionMember) _then;

/// Create a copy of CollectionMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,}) {
  return _then(_CollectionMember(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CollectionMembers {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMembers);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CollectionMembers()';
}


}

/// @nodoc
class $CollectionMembersCopyWith<$Res>  {
$CollectionMembersCopyWith(CollectionMembers _, $Res Function(CollectionMembers) __);
}


/// Adds pattern-matching-related methods to [CollectionMembers].
extension CollectionMembersPatterns on CollectionMembers {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CollectionMembersLoaded value)?  loaded,TResult Function( CollectionMembersFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CollectionMembersLoaded() when loaded != null:
return loaded(_that);case CollectionMembersFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CollectionMembersLoaded value)  loaded,required TResult Function( CollectionMembersFailed value)  failed,}){
final _that = this;
switch (_that) {
case CollectionMembersLoaded():
return loaded(_that);case CollectionMembersFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CollectionMembersLoaded value)?  loaded,TResult? Function( CollectionMembersFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CollectionMembersLoaded() when loaded != null:
return loaded(_that);case CollectionMembersFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CollectionKind kind,  List<CollectionMember> members)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CollectionMembersLoaded() when loaded != null:
return loaded(_that.kind,_that.members);case CollectionMembersFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CollectionKind kind,  List<CollectionMember> members)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case CollectionMembersLoaded():
return loaded(_that.kind,_that.members);case CollectionMembersFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CollectionKind kind,  List<CollectionMember> members)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case CollectionMembersLoaded() when loaded != null:
return loaded(_that.kind,_that.members);case CollectionMembersFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CollectionMembersLoaded implements CollectionMembers {
  const CollectionMembersLoaded({required this.kind, required final  List<CollectionMember> members}): _members = members;
  

 final  CollectionKind kind;
 final  List<CollectionMember> _members;
 List<CollectionMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of CollectionMembers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionMembersLoadedCopyWith<CollectionMembersLoaded> get copyWith => _$CollectionMembersLoadedCopyWithImpl<CollectionMembersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMembersLoaded&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._members, _members));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'CollectionMembers.loaded(kind: $kind, members: $members)';
}


}

/// @nodoc
abstract mixin class $CollectionMembersLoadedCopyWith<$Res> implements $CollectionMembersCopyWith<$Res> {
  factory $CollectionMembersLoadedCopyWith(CollectionMembersLoaded value, $Res Function(CollectionMembersLoaded) _then) = _$CollectionMembersLoadedCopyWithImpl;
@useResult
$Res call({
 CollectionKind kind, List<CollectionMember> members
});




}
/// @nodoc
class _$CollectionMembersLoadedCopyWithImpl<$Res>
    implements $CollectionMembersLoadedCopyWith<$Res> {
  _$CollectionMembersLoadedCopyWithImpl(this._self, this._then);

  final CollectionMembersLoaded _self;
  final $Res Function(CollectionMembersLoaded) _then;

/// Create a copy of CollectionMembers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? members = null,}) {
  return _then(CollectionMembersLoaded(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CollectionKind,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<CollectionMember>,
  ));
}


}

/// @nodoc


class CollectionMembersFailed implements CollectionMembers {
  const CollectionMembersFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of CollectionMembers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionMembersFailedCopyWith<CollectionMembersFailed> get copyWith => _$CollectionMembersFailedCopyWithImpl<CollectionMembersFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionMembersFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CollectionMembers.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CollectionMembersFailedCopyWith<$Res> implements $CollectionMembersCopyWith<$Res> {
  factory $CollectionMembersFailedCopyWith(CollectionMembersFailed value, $Res Function(CollectionMembersFailed) _then) = _$CollectionMembersFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CollectionMembersFailedCopyWithImpl<$Res>
    implements $CollectionMembersFailedCopyWith<$Res> {
  _$CollectionMembersFailedCopyWithImpl(this._self, this._then);

  final CollectionMembersFailed _self;
  final $Res Function(CollectionMembersFailed) _then;

/// Create a copy of CollectionMembers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CollectionMembersFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CollectionMembers
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
mixin _$ItemAddition {

 String get itemUuid; bool get added;/// Why it was not, when it was not. `null` when the core named a reason
/// this version does not know — the item still reads as not added.
 ItemRejection? get reason;
/// Create a copy of ItemAddition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemAdditionCopyWith<ItemAddition> get copyWith => _$ItemAdditionCopyWithImpl<ItemAddition>(this as ItemAddition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemAddition&&(identical(other.itemUuid, itemUuid) || other.itemUuid == itemUuid)&&(identical(other.added, added) || other.added == added)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,itemUuid,added,reason);

@override
String toString() {
  return 'ItemAddition(itemUuid: $itemUuid, added: $added, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ItemAdditionCopyWith<$Res>  {
  factory $ItemAdditionCopyWith(ItemAddition value, $Res Function(ItemAddition) _then) = _$ItemAdditionCopyWithImpl;
@useResult
$Res call({
 String itemUuid, bool added, ItemRejection? reason
});




}
/// @nodoc
class _$ItemAdditionCopyWithImpl<$Res>
    implements $ItemAdditionCopyWith<$Res> {
  _$ItemAdditionCopyWithImpl(this._self, this._then);

  final ItemAddition _self;
  final $Res Function(ItemAddition) _then;

/// Create a copy of ItemAddition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemUuid = null,Object? added = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
itemUuid: null == itemUuid ? _self.itemUuid : itemUuid // ignore: cast_nullable_to_non_nullable
as String,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ItemRejection?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemAddition].
extension ItemAdditionPatterns on ItemAddition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemAddition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemAddition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemAddition value)  $default,){
final _that = this;
switch (_that) {
case _ItemAddition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemAddition value)?  $default,){
final _that = this;
switch (_that) {
case _ItemAddition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemUuid,  bool added,  ItemRejection? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemAddition() when $default != null:
return $default(_that.itemUuid,_that.added,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemUuid,  bool added,  ItemRejection? reason)  $default,) {final _that = this;
switch (_that) {
case _ItemAddition():
return $default(_that.itemUuid,_that.added,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemUuid,  bool added,  ItemRejection? reason)?  $default,) {final _that = this;
switch (_that) {
case _ItemAddition() when $default != null:
return $default(_that.itemUuid,_that.added,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _ItemAddition implements ItemAddition {
  const _ItemAddition({required this.itemUuid, required this.added, this.reason});
  

@override final  String itemUuid;
@override final  bool added;
/// Why it was not, when it was not. `null` when the core named a reason
/// this version does not know — the item still reads as not added.
@override final  ItemRejection? reason;

/// Create a copy of ItemAddition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemAdditionCopyWith<_ItemAddition> get copyWith => __$ItemAdditionCopyWithImpl<_ItemAddition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemAddition&&(identical(other.itemUuid, itemUuid) || other.itemUuid == itemUuid)&&(identical(other.added, added) || other.added == added)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,itemUuid,added,reason);

@override
String toString() {
  return 'ItemAddition(itemUuid: $itemUuid, added: $added, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ItemAdditionCopyWith<$Res> implements $ItemAdditionCopyWith<$Res> {
  factory _$ItemAdditionCopyWith(_ItemAddition value, $Res Function(_ItemAddition) _then) = __$ItemAdditionCopyWithImpl;
@override @useResult
$Res call({
 String itemUuid, bool added, ItemRejection? reason
});




}
/// @nodoc
class __$ItemAdditionCopyWithImpl<$Res>
    implements _$ItemAdditionCopyWith<$Res> {
  __$ItemAdditionCopyWithImpl(this._self, this._then);

  final _ItemAddition _self;
  final $Res Function(_ItemAddition) _then;

/// Create a copy of ItemAddition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemUuid = null,Object? added = null,Object? reason = freezed,}) {
  return _then(_ItemAddition(
itemUuid: null == itemUuid ? _self.itemUuid : itemUuid // ignore: cast_nullable_to_non_nullable
as String,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ItemRejection?,
  ));
}


}

/// @nodoc
mixin _$CollectionAdditions {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionAdditions);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CollectionAdditions()';
}


}

/// @nodoc
class $CollectionAdditionsCopyWith<$Res>  {
$CollectionAdditionsCopyWith(CollectionAdditions _, $Res Function(CollectionAdditions) __);
}


/// Adds pattern-matching-related methods to [CollectionAdditions].
extension CollectionAdditionsPatterns on CollectionAdditions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CollectionAdditionsReported value)?  reported,TResult Function( CollectionAdditionsFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CollectionAdditionsReported() when reported != null:
return reported(_that);case CollectionAdditionsFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CollectionAdditionsReported value)  reported,required TResult Function( CollectionAdditionsFailed value)  failed,}){
final _that = this;
switch (_that) {
case CollectionAdditionsReported():
return reported(_that);case CollectionAdditionsFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CollectionAdditionsReported value)?  reported,TResult? Function( CollectionAdditionsFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CollectionAdditionsReported() when reported != null:
return reported(_that);case CollectionAdditionsFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<ItemAddition> items)?  reported,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CollectionAdditionsReported() when reported != null:
return reported(_that.items);case CollectionAdditionsFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<ItemAddition> items)  reported,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case CollectionAdditionsReported():
return reported(_that.items);case CollectionAdditionsFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<ItemAddition> items)?  reported,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case CollectionAdditionsReported() when reported != null:
return reported(_that.items);case CollectionAdditionsFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CollectionAdditionsReported implements CollectionAdditions {
  const CollectionAdditionsReported({required final  List<ItemAddition> items}): _items = items;
  

 final  List<ItemAddition> _items;
 List<ItemAddition> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CollectionAdditions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionAdditionsReportedCopyWith<CollectionAdditionsReported> get copyWith => _$CollectionAdditionsReportedCopyWithImpl<CollectionAdditionsReported>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionAdditionsReported&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CollectionAdditions.reported(items: $items)';
}


}

/// @nodoc
abstract mixin class $CollectionAdditionsReportedCopyWith<$Res> implements $CollectionAdditionsCopyWith<$Res> {
  factory $CollectionAdditionsReportedCopyWith(CollectionAdditionsReported value, $Res Function(CollectionAdditionsReported) _then) = _$CollectionAdditionsReportedCopyWithImpl;
@useResult
$Res call({
 List<ItemAddition> items
});




}
/// @nodoc
class _$CollectionAdditionsReportedCopyWithImpl<$Res>
    implements $CollectionAdditionsReportedCopyWith<$Res> {
  _$CollectionAdditionsReportedCopyWithImpl(this._self, this._then);

  final CollectionAdditionsReported _self;
  final $Res Function(CollectionAdditionsReported) _then;

/// Create a copy of CollectionAdditions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(CollectionAdditionsReported(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItemAddition>,
  ));
}


}

/// @nodoc


class CollectionAdditionsFailed implements CollectionAdditions {
  const CollectionAdditionsFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of CollectionAdditions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionAdditionsFailedCopyWith<CollectionAdditionsFailed> get copyWith => _$CollectionAdditionsFailedCopyWithImpl<CollectionAdditionsFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionAdditionsFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CollectionAdditions.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CollectionAdditionsFailedCopyWith<$Res> implements $CollectionAdditionsCopyWith<$Res> {
  factory $CollectionAdditionsFailedCopyWith(CollectionAdditionsFailed value, $Res Function(CollectionAdditionsFailed) _then) = _$CollectionAdditionsFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CollectionAdditionsFailedCopyWithImpl<$Res>
    implements $CollectionAdditionsFailedCopyWith<$Res> {
  _$CollectionAdditionsFailedCopyWithImpl(this._self, this._then);

  final CollectionAdditionsFailed _self;
  final $Res Function(CollectionAdditionsFailed) _then;

/// Create a copy of CollectionAdditions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CollectionAdditionsFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CollectionAdditions
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
