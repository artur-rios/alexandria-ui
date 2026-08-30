// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryBrowse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryBrowse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryBrowse()';
}


}

/// @nodoc
class $LibraryBrowseCopyWith<$Res>  {
$LibraryBrowseCopyWith(LibraryBrowse _, $Res Function(LibraryBrowse) __);
}


/// Adds pattern-matching-related methods to [LibraryBrowse].
extension LibraryBrowsePatterns on LibraryBrowse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LibraryBrowseLoaded value)?  loaded,TResult Function( LibraryBrowseFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LibraryBrowseLoaded() when loaded != null:
return loaded(_that);case LibraryBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LibraryBrowseLoaded value)  loaded,required TResult Function( LibraryBrowseFailed value)  failed,}){
final _that = this;
switch (_that) {
case LibraryBrowseLoaded():
return loaded(_that);case LibraryBrowseFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LibraryBrowseLoaded value)?  loaded,TResult? Function( LibraryBrowseFailed value)?  failed,}){
final _that = this;
switch (_that) {
case LibraryBrowseLoaded() when loaded != null:
return loaded(_that);case LibraryBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Library> libraries)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LibraryBrowseLoaded() when loaded != null:
return loaded(_that.libraries);case LibraryBrowseFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Library> libraries)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case LibraryBrowseLoaded():
return loaded(_that.libraries);case LibraryBrowseFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Library> libraries)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case LibraryBrowseLoaded() when loaded != null:
return loaded(_that.libraries);case LibraryBrowseFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class LibraryBrowseLoaded implements LibraryBrowse {
  const LibraryBrowseLoaded({required final  List<Library> libraries}): _libraries = libraries;
  

 final  List<Library> _libraries;
 List<Library> get libraries {
  if (_libraries is EqualUnmodifiableListView) return _libraries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_libraries);
}


/// Create a copy of LibraryBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryBrowseLoadedCopyWith<LibraryBrowseLoaded> get copyWith => _$LibraryBrowseLoadedCopyWithImpl<LibraryBrowseLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryBrowseLoaded&&const DeepCollectionEquality().equals(other._libraries, _libraries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_libraries));

@override
String toString() {
  return 'LibraryBrowse.loaded(libraries: $libraries)';
}


}

/// @nodoc
abstract mixin class $LibraryBrowseLoadedCopyWith<$Res> implements $LibraryBrowseCopyWith<$Res> {
  factory $LibraryBrowseLoadedCopyWith(LibraryBrowseLoaded value, $Res Function(LibraryBrowseLoaded) _then) = _$LibraryBrowseLoadedCopyWithImpl;
@useResult
$Res call({
 List<Library> libraries
});




}
/// @nodoc
class _$LibraryBrowseLoadedCopyWithImpl<$Res>
    implements $LibraryBrowseLoadedCopyWith<$Res> {
  _$LibraryBrowseLoadedCopyWithImpl(this._self, this._then);

  final LibraryBrowseLoaded _self;
  final $Res Function(LibraryBrowseLoaded) _then;

/// Create a copy of LibraryBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? libraries = null,}) {
  return _then(LibraryBrowseLoaded(
libraries: null == libraries ? _self._libraries : libraries // ignore: cast_nullable_to_non_nullable
as List<Library>,
  ));
}


}

/// @nodoc


class LibraryBrowseFailed implements LibraryBrowse {
  const LibraryBrowseFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of LibraryBrowse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryBrowseFailedCopyWith<LibraryBrowseFailed> get copyWith => _$LibraryBrowseFailedCopyWithImpl<LibraryBrowseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryBrowseFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LibraryBrowse.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LibraryBrowseFailedCopyWith<$Res> implements $LibraryBrowseCopyWith<$Res> {
  factory $LibraryBrowseFailedCopyWith(LibraryBrowseFailed value, $Res Function(LibraryBrowseFailed) _then) = _$LibraryBrowseFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LibraryBrowseFailedCopyWithImpl<$Res>
    implements $LibraryBrowseFailedCopyWith<$Res> {
  _$LibraryBrowseFailedCopyWithImpl(this._self, this._then);

  final LibraryBrowseFailed _self;
  final $Res Function(LibraryBrowseFailed) _then;

/// Create a copy of LibraryBrowse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(LibraryBrowseFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LibraryBrowse
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
mixin _$LibraryRead {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryRead);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryRead()';
}


}

/// @nodoc
class $LibraryReadCopyWith<$Res>  {
$LibraryReadCopyWith(LibraryRead _, $Res Function(LibraryRead) __);
}


/// Adds pattern-matching-related methods to [LibraryRead].
extension LibraryReadPatterns on LibraryRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LibraryReadLoaded value)?  loaded,TResult Function( LibraryReadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LibraryReadLoaded() when loaded != null:
return loaded(_that);case LibraryReadFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LibraryReadLoaded value)  loaded,required TResult Function( LibraryReadFailed value)  failed,}){
final _that = this;
switch (_that) {
case LibraryReadLoaded():
return loaded(_that);case LibraryReadFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LibraryReadLoaded value)?  loaded,TResult? Function( LibraryReadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case LibraryReadLoaded() when loaded != null:
return loaded(_that);case LibraryReadFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LibraryListing listing)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LibraryReadLoaded() when loaded != null:
return loaded(_that.listing);case LibraryReadFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LibraryListing listing)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case LibraryReadLoaded():
return loaded(_that.listing);case LibraryReadFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LibraryListing listing)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case LibraryReadLoaded() when loaded != null:
return loaded(_that.listing);case LibraryReadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class LibraryReadLoaded implements LibraryRead {
  const LibraryReadLoaded({required this.listing});
  

 final  LibraryListing listing;

/// Create a copy of LibraryRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryReadLoadedCopyWith<LibraryReadLoaded> get copyWith => _$LibraryReadLoadedCopyWithImpl<LibraryReadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryReadLoaded&&(identical(other.listing, listing) || other.listing == listing));
}


@override
int get hashCode => Object.hash(runtimeType,listing);

@override
String toString() {
  return 'LibraryRead.loaded(listing: $listing)';
}


}

/// @nodoc
abstract mixin class $LibraryReadLoadedCopyWith<$Res> implements $LibraryReadCopyWith<$Res> {
  factory $LibraryReadLoadedCopyWith(LibraryReadLoaded value, $Res Function(LibraryReadLoaded) _then) = _$LibraryReadLoadedCopyWithImpl;
@useResult
$Res call({
 LibraryListing listing
});


$LibraryListingCopyWith<$Res> get listing;

}
/// @nodoc
class _$LibraryReadLoadedCopyWithImpl<$Res>
    implements $LibraryReadLoadedCopyWith<$Res> {
  _$LibraryReadLoadedCopyWithImpl(this._self, this._then);

  final LibraryReadLoaded _self;
  final $Res Function(LibraryReadLoaded) _then;

/// Create a copy of LibraryRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? listing = null,}) {
  return _then(LibraryReadLoaded(
listing: null == listing ? _self.listing : listing // ignore: cast_nullable_to_non_nullable
as LibraryListing,
  ));
}

/// Create a copy of LibraryRead
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibraryListingCopyWith<$Res> get listing {
  
  return $LibraryListingCopyWith<$Res>(_self.listing, (value) {
    return _then(_self.copyWith(listing: value));
  });
}
}

/// @nodoc


class LibraryReadFailed implements LibraryRead {
  const LibraryReadFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of LibraryRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryReadFailedCopyWith<LibraryReadFailed> get copyWith => _$LibraryReadFailedCopyWithImpl<LibraryReadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryReadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LibraryRead.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LibraryReadFailedCopyWith<$Res> implements $LibraryReadCopyWith<$Res> {
  factory $LibraryReadFailedCopyWith(LibraryReadFailed value, $Res Function(LibraryReadFailed) _then) = _$LibraryReadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LibraryReadFailedCopyWithImpl<$Res>
    implements $LibraryReadFailedCopyWith<$Res> {
  _$LibraryReadFailedCopyWithImpl(this._self, this._then);

  final LibraryReadFailed _self;
  final $Res Function(LibraryReadFailed) _then;

/// Create a copy of LibraryRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(LibraryReadFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LibraryRead
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
mixin _$LibraryWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryWrite()';
}


}

/// @nodoc
class $LibraryWriteCopyWith<$Res>  {
$LibraryWriteCopyWith(LibraryWrite _, $Res Function(LibraryWrite) __);
}


/// Adds pattern-matching-related methods to [LibraryWrite].
extension LibraryWritePatterns on LibraryWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LibraryWriteDone value)?  done,TResult Function( LibraryWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LibraryWriteDone() when done != null:
return done(_that);case LibraryWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LibraryWriteDone value)  done,required TResult Function( LibraryWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case LibraryWriteDone():
return done(_that);case LibraryWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LibraryWriteDone value)?  done,TResult? Function( LibraryWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case LibraryWriteDone() when done != null:
return done(_that);case LibraryWriteFailed() when failed != null:
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
case LibraryWriteDone() when done != null:
return done();case LibraryWriteFailed() when failed != null:
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
case LibraryWriteDone():
return done();case LibraryWriteFailed():
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
case LibraryWriteDone() when done != null:
return done();case LibraryWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class LibraryWriteDone implements LibraryWrite {
  const LibraryWriteDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryWriteDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryWrite.done()';
}


}




/// @nodoc


class LibraryWriteFailed implements LibraryWrite {
  const LibraryWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of LibraryWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryWriteFailedCopyWith<LibraryWriteFailed> get copyWith => _$LibraryWriteFailedCopyWithImpl<LibraryWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LibraryWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LibraryWriteFailedCopyWith<$Res> implements $LibraryWriteCopyWith<$Res> {
  factory $LibraryWriteFailedCopyWith(LibraryWriteFailed value, $Res Function(LibraryWriteFailed) _then) = _$LibraryWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LibraryWriteFailedCopyWithImpl<$Res>
    implements $LibraryWriteFailedCopyWith<$Res> {
  _$LibraryWriteFailedCopyWithImpl(this._self, this._then);

  final LibraryWriteFailed _self;
  final $Res Function(LibraryWriteFailed) _then;

/// Create a copy of LibraryWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(LibraryWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LibraryWrite
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
