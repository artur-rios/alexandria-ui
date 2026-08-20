// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_list_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingListBrowse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListBrowse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingListBrowse()';
}


}

/// @nodoc
class $ReadingListBrowseCopyWith<$Res>  {
$ReadingListBrowseCopyWith(ReadingListBrowse _, $Res Function(ReadingListBrowse) __);
}


/// Adds pattern-matching-related methods to [ReadingListBrowse].
extension ReadingListBrowsePatterns on ReadingListBrowse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadingListBrowseLoaded value)?  loaded,TResult Function( ReadingListBrowseFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadingListBrowseLoaded() when loaded != null:
return loaded(_that);case ReadingListBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadingListBrowseLoaded value)  loaded,required TResult Function( ReadingListBrowseFailed value)  failed,}){
final _that = this;
switch (_that) {
case ReadingListBrowseLoaded():
return loaded(_that);case ReadingListBrowseFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadingListBrowseLoaded value)?  loaded,TResult? Function( ReadingListBrowseFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ReadingListBrowseLoaded() when loaded != null:
return loaded(_that);case ReadingListBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<ReadingList> readingLists)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadingListBrowseLoaded() when loaded != null:
return loaded(_that.readingLists);case ReadingListBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<ReadingList> readingLists)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case ReadingListBrowseLoaded():
return loaded(_that.readingLists);case ReadingListBrowseFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<ReadingList> readingLists)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case ReadingListBrowseLoaded() when loaded != null:
return loaded(_that.readingLists);case ReadingListBrowseFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ReadingListBrowseLoaded implements ReadingListBrowse {
  const ReadingListBrowseLoaded({required final  List<ReadingList> readingLists}): _readingLists = readingLists;
  

 final  List<ReadingList> _readingLists;
 List<ReadingList> get readingLists {
  if (_readingLists is EqualUnmodifiableListView) return _readingLists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readingLists);
}


/// Create a copy of ReadingListBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingListBrowseLoadedCopyWith<ReadingListBrowseLoaded> get copyWith => _$ReadingListBrowseLoadedCopyWithImpl<ReadingListBrowseLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListBrowseLoaded&&const DeepCollectionEquality().equals(other._readingLists, _readingLists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_readingLists));

@override
String toString() {
  return 'ReadingListBrowse.loaded(readingLists: $readingLists)';
}


}

/// @nodoc
abstract mixin class $ReadingListBrowseLoadedCopyWith<$Res> implements $ReadingListBrowseCopyWith<$Res> {
  factory $ReadingListBrowseLoadedCopyWith(ReadingListBrowseLoaded value, $Res Function(ReadingListBrowseLoaded) _then) = _$ReadingListBrowseLoadedCopyWithImpl;
@useResult
$Res call({
 List<ReadingList> readingLists
});




}
/// @nodoc
class _$ReadingListBrowseLoadedCopyWithImpl<$Res>
    implements $ReadingListBrowseLoadedCopyWith<$Res> {
  _$ReadingListBrowseLoadedCopyWithImpl(this._self, this._then);

  final ReadingListBrowseLoaded _self;
  final $Res Function(ReadingListBrowseLoaded) _then;

/// Create a copy of ReadingListBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? readingLists = null,}) {
  return _then(ReadingListBrowseLoaded(
readingLists: null == readingLists ? _self._readingLists : readingLists // ignore: cast_nullable_to_non_nullable
as List<ReadingList>,
  ));
}


}

/// @nodoc


class ReadingListBrowseFailed implements ReadingListBrowse {
  const ReadingListBrowseFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of ReadingListBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingListBrowseFailedCopyWith<ReadingListBrowseFailed> get copyWith => _$ReadingListBrowseFailedCopyWithImpl<ReadingListBrowseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListBrowseFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ReadingListBrowse.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ReadingListBrowseFailedCopyWith<$Res> implements $ReadingListBrowseCopyWith<$Res> {
  factory $ReadingListBrowseFailedCopyWith(ReadingListBrowseFailed value, $Res Function(ReadingListBrowseFailed) _then) = _$ReadingListBrowseFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ReadingListBrowseFailedCopyWithImpl<$Res>
    implements $ReadingListBrowseFailedCopyWith<$Res> {
  _$ReadingListBrowseFailedCopyWithImpl(this._self, this._then);

  final ReadingListBrowseFailed _self;
  final $Res Function(ReadingListBrowseFailed) _then;

/// Create a copy of ReadingListBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ReadingListBrowseFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ReadingListBrowse
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
mixin _$ReadingListWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingListWrite()';
}


}

/// @nodoc
class $ReadingListWriteCopyWith<$Res>  {
$ReadingListWriteCopyWith(ReadingListWrite _, $Res Function(ReadingListWrite) __);
}


/// Adds pattern-matching-related methods to [ReadingListWrite].
extension ReadingListWritePatterns on ReadingListWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadingListWriteDone value)?  done,TResult Function( ReadingListWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadingListWriteDone() when done != null:
return done(_that);case ReadingListWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadingListWriteDone value)  done,required TResult Function( ReadingListWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case ReadingListWriteDone():
return done(_that);case ReadingListWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadingListWriteDone value)?  done,TResult? Function( ReadingListWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ReadingListWriteDone() when done != null:
return done(_that);case ReadingListWriteFailed() when failed != null:
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
case ReadingListWriteDone() when done != null:
return done();case ReadingListWriteFailed() when failed != null:
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
case ReadingListWriteDone():
return done();case ReadingListWriteFailed():
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
case ReadingListWriteDone() when done != null:
return done();case ReadingListWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ReadingListWriteDone implements ReadingListWrite {
  const ReadingListWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingListWrite.done()';
}


}




/// @nodoc


class ReadingListWriteFailed implements ReadingListWrite {
  const ReadingListWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of ReadingListWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingListWriteFailedCopyWith<ReadingListWriteFailed> get copyWith => _$ReadingListWriteFailedCopyWithImpl<ReadingListWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingListWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ReadingListWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ReadingListWriteFailedCopyWith<$Res> implements $ReadingListWriteCopyWith<$Res> {
  factory $ReadingListWriteFailedCopyWith(ReadingListWriteFailed value, $Res Function(ReadingListWriteFailed) _then) = _$ReadingListWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ReadingListWriteFailedCopyWithImpl<$Res>
    implements $ReadingListWriteFailedCopyWith<$Res> {
  _$ReadingListWriteFailedCopyWithImpl(this._self, this._then);

  final ReadingListWriteFailed _self;
  final $Res Function(ReadingListWriteFailed) _then;

/// Create a copy of ReadingListWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ReadingListWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ReadingListWrite
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
