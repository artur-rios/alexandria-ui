// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookmarkListing {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkListing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookmarkListing()';
}


}

/// @nodoc
class $BookmarkListingCopyWith<$Res>  {
$BookmarkListingCopyWith(BookmarkListing _, $Res Function(BookmarkListing) __);
}


/// Adds pattern-matching-related methods to [BookmarkListing].
extension BookmarkListingPatterns on BookmarkListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BookmarkListingLoaded value)?  loaded,TResult Function( BookmarkListingFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BookmarkListingLoaded() when loaded != null:
return loaded(_that);case BookmarkListingFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BookmarkListingLoaded value)  loaded,required TResult Function( BookmarkListingFailed value)  failed,}){
final _that = this;
switch (_that) {
case BookmarkListingLoaded():
return loaded(_that);case BookmarkListingFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BookmarkListingLoaded value)?  loaded,TResult? Function( BookmarkListingFailed value)?  failed,}){
final _that = this;
switch (_that) {
case BookmarkListingLoaded() when loaded != null:
return loaded(_that);case BookmarkListingFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Bookmark> bookmarks)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BookmarkListingLoaded() when loaded != null:
return loaded(_that.bookmarks);case BookmarkListingFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Bookmark> bookmarks)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case BookmarkListingLoaded():
return loaded(_that.bookmarks);case BookmarkListingFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Bookmark> bookmarks)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case BookmarkListingLoaded() when loaded != null:
return loaded(_that.bookmarks);case BookmarkListingFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BookmarkListingLoaded implements BookmarkListing {
  const BookmarkListingLoaded({required final  List<Bookmark> bookmarks}): _bookmarks = bookmarks;
  

 final  List<Bookmark> _bookmarks;
 List<Bookmark> get bookmarks {
  if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookmarks);
}


/// Create a copy of BookmarkListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkListingLoadedCopyWith<BookmarkListingLoaded> get copyWith => _$BookmarkListingLoadedCopyWithImpl<BookmarkListingLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkListingLoaded&&const DeepCollectionEquality().equals(other._bookmarks, _bookmarks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_bookmarks));

@override
String toString() {
  return 'BookmarkListing.loaded(bookmarks: $bookmarks)';
}


}

/// @nodoc
abstract mixin class $BookmarkListingLoadedCopyWith<$Res> implements $BookmarkListingCopyWith<$Res> {
  factory $BookmarkListingLoadedCopyWith(BookmarkListingLoaded value, $Res Function(BookmarkListingLoaded) _then) = _$BookmarkListingLoadedCopyWithImpl;
@useResult
$Res call({
 List<Bookmark> bookmarks
});




}
/// @nodoc
class _$BookmarkListingLoadedCopyWithImpl<$Res>
    implements $BookmarkListingLoadedCopyWith<$Res> {
  _$BookmarkListingLoadedCopyWithImpl(this._self, this._then);

  final BookmarkListingLoaded _self;
  final $Res Function(BookmarkListingLoaded) _then;

/// Create a copy of BookmarkListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bookmarks = null,}) {
  return _then(BookmarkListingLoaded(
bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,
  ));
}


}

/// @nodoc


class BookmarkListingFailed implements BookmarkListing {
  const BookmarkListingFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of BookmarkListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkListingFailedCopyWith<BookmarkListingFailed> get copyWith => _$BookmarkListingFailedCopyWithImpl<BookmarkListingFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkListingFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'BookmarkListing.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BookmarkListingFailedCopyWith<$Res> implements $BookmarkListingCopyWith<$Res> {
  factory $BookmarkListingFailedCopyWith(BookmarkListingFailed value, $Res Function(BookmarkListingFailed) _then) = _$BookmarkListingFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BookmarkListingFailedCopyWithImpl<$Res>
    implements $BookmarkListingFailedCopyWith<$Res> {
  _$BookmarkListingFailedCopyWithImpl(this._self, this._then);

  final BookmarkListingFailed _self;
  final $Res Function(BookmarkListingFailed) _then;

/// Create a copy of BookmarkListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BookmarkListingFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BookmarkListing
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
mixin _$BookmarkWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookmarkWrite()';
}


}

/// @nodoc
class $BookmarkWriteCopyWith<$Res>  {
$BookmarkWriteCopyWith(BookmarkWrite _, $Res Function(BookmarkWrite) __);
}


/// Adds pattern-matching-related methods to [BookmarkWrite].
extension BookmarkWritePatterns on BookmarkWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BookmarkSaved value)?  saved,TResult Function( BookmarkWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BookmarkSaved() when saved != null:
return saved(_that);case BookmarkWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BookmarkSaved value)  saved,required TResult Function( BookmarkWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case BookmarkSaved():
return saved(_that);case BookmarkWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BookmarkSaved value)?  saved,TResult? Function( BookmarkWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case BookmarkSaved() when saved != null:
return saved(_that);case BookmarkWriteFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Bookmark bookmark)?  saved,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BookmarkSaved() when saved != null:
return saved(_that.bookmark);case BookmarkWriteFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Bookmark bookmark)  saved,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case BookmarkSaved():
return saved(_that.bookmark);case BookmarkWriteFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Bookmark bookmark)?  saved,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case BookmarkSaved() when saved != null:
return saved(_that.bookmark);case BookmarkWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BookmarkSaved implements BookmarkWrite {
  const BookmarkSaved({required this.bookmark});
  

 final  Bookmark bookmark;

/// Create a copy of BookmarkWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkSavedCopyWith<BookmarkSaved> get copyWith => _$BookmarkSavedCopyWithImpl<BookmarkSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkSaved&&(identical(other.bookmark, bookmark) || other.bookmark == bookmark));
}


@override
int get hashCode => Object.hash(runtimeType,bookmark);

@override
String toString() {
  return 'BookmarkWrite.saved(bookmark: $bookmark)';
}


}

/// @nodoc
abstract mixin class $BookmarkSavedCopyWith<$Res> implements $BookmarkWriteCopyWith<$Res> {
  factory $BookmarkSavedCopyWith(BookmarkSaved value, $Res Function(BookmarkSaved) _then) = _$BookmarkSavedCopyWithImpl;
@useResult
$Res call({
 Bookmark bookmark
});


$BookmarkCopyWith<$Res> get bookmark;

}
/// @nodoc
class _$BookmarkSavedCopyWithImpl<$Res>
    implements $BookmarkSavedCopyWith<$Res> {
  _$BookmarkSavedCopyWithImpl(this._self, this._then);

  final BookmarkSaved _self;
  final $Res Function(BookmarkSaved) _then;

/// Create a copy of BookmarkWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bookmark = null,}) {
  return _then(BookmarkSaved(
bookmark: null == bookmark ? _self.bookmark : bookmark // ignore: cast_nullable_to_non_nullable
as Bookmark,
  ));
}

/// Create a copy of BookmarkWrite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookmarkCopyWith<$Res> get bookmark {
  
  return $BookmarkCopyWith<$Res>(_self.bookmark, (value) {
    return _then(_self.copyWith(bookmark: value));
  });
}
}

/// @nodoc


class BookmarkWriteFailed implements BookmarkWrite {
  const BookmarkWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of BookmarkWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkWriteFailedCopyWith<BookmarkWriteFailed> get copyWith => _$BookmarkWriteFailedCopyWithImpl<BookmarkWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'BookmarkWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BookmarkWriteFailedCopyWith<$Res> implements $BookmarkWriteCopyWith<$Res> {
  factory $BookmarkWriteFailedCopyWith(BookmarkWriteFailed value, $Res Function(BookmarkWriteFailed) _then) = _$BookmarkWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BookmarkWriteFailedCopyWithImpl<$Res>
    implements $BookmarkWriteFailedCopyWith<$Res> {
  _$BookmarkWriteFailedCopyWithImpl(this._self, this._then);

  final BookmarkWriteFailed _self;
  final $Res Function(BookmarkWriteFailed) _then;

/// Create a copy of BookmarkWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BookmarkWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BookmarkWrite
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
