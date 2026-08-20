// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_content_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextContentRead {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentRead);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TextContentRead()';
}


}

/// @nodoc
class $TextContentReadCopyWith<$Res>  {
$TextContentReadCopyWith(TextContentRead _, $Res Function(TextContentRead) __);
}


/// Adds pattern-matching-related methods to [TextContentRead].
extension TextContentReadPatterns on TextContentRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextContentLoaded value)?  loaded,TResult Function( TextContentReadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextContentLoaded() when loaded != null:
return loaded(_that);case TextContentReadFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextContentLoaded value)  loaded,required TResult Function( TextContentReadFailed value)  failed,}){
final _that = this;
switch (_that) {
case TextContentLoaded():
return loaded(_that);case TextContentReadFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextContentLoaded value)?  loaded,TResult? Function( TextContentReadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case TextContentLoaded() when loaded != null:
return loaded(_that);case TextContentReadFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String content)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextContentLoaded() when loaded != null:
return loaded(_that.content);case TextContentReadFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String content)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case TextContentLoaded():
return loaded(_that.content);case TextContentReadFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String content)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case TextContentLoaded() when loaded != null:
return loaded(_that.content);case TextContentReadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TextContentLoaded implements TextContentRead {
  const TextContentLoaded({required this.content});
  

 final  String content;

/// Create a copy of TextContentRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextContentLoadedCopyWith<TextContentLoaded> get copyWith => _$TextContentLoadedCopyWithImpl<TextContentLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentLoaded&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'TextContentRead.loaded(content: $content)';
}


}

/// @nodoc
abstract mixin class $TextContentLoadedCopyWith<$Res> implements $TextContentReadCopyWith<$Res> {
  factory $TextContentLoadedCopyWith(TextContentLoaded value, $Res Function(TextContentLoaded) _then) = _$TextContentLoadedCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$TextContentLoadedCopyWithImpl<$Res>
    implements $TextContentLoadedCopyWith<$Res> {
  _$TextContentLoadedCopyWithImpl(this._self, this._then);

  final TextContentLoaded _self;
  final $Res Function(TextContentLoaded) _then;

/// Create a copy of TextContentRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(TextContentLoaded(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TextContentReadFailed implements TextContentRead {
  const TextContentReadFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of TextContentRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextContentReadFailedCopyWith<TextContentReadFailed> get copyWith => _$TextContentReadFailedCopyWithImpl<TextContentReadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentReadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TextContentRead.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TextContentReadFailedCopyWith<$Res> implements $TextContentReadCopyWith<$Res> {
  factory $TextContentReadFailedCopyWith(TextContentReadFailed value, $Res Function(TextContentReadFailed) _then) = _$TextContentReadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TextContentReadFailedCopyWithImpl<$Res>
    implements $TextContentReadFailedCopyWith<$Res> {
  _$TextContentReadFailedCopyWithImpl(this._self, this._then);

  final TextContentReadFailed _self;
  final $Res Function(TextContentReadFailed) _then;

/// Create a copy of TextContentRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TextContentReadFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TextContentRead
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
mixin _$TextContentWrite {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentWrite);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TextContentWrite()';
}


}

/// @nodoc
class $TextContentWriteCopyWith<$Res>  {
$TextContentWriteCopyWith(TextContentWrite _, $Res Function(TextContentWrite) __);
}


/// Adds pattern-matching-related methods to [TextContentWrite].
extension TextContentWritePatterns on TextContentWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextContentWritten value)?  written,TResult Function( TextContentWriteFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextContentWritten() when written != null:
return written(_that);case TextContentWriteFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextContentWritten value)  written,required TResult Function( TextContentWriteFailed value)  failed,}){
final _that = this;
switch (_that) {
case TextContentWritten():
return written(_that);case TextContentWriteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextContentWritten value)?  written,TResult? Function( TextContentWriteFailed value)?  failed,}){
final _that = this;
switch (_that) {
case TextContentWritten() when written != null:
return written(_that);case TextContentWriteFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CatalogFile file)?  written,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextContentWritten() when written != null:
return written(_that.file);case TextContentWriteFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CatalogFile file)  written,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case TextContentWritten():
return written(_that.file);case TextContentWriteFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CatalogFile file)?  written,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case TextContentWritten() when written != null:
return written(_that.file);case TextContentWriteFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TextContentWritten implements TextContentWrite {
  const TextContentWritten({required this.file});
  

 final  CatalogFile file;

/// Create a copy of TextContentWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextContentWrittenCopyWith<TextContentWritten> get copyWith => _$TextContentWrittenCopyWithImpl<TextContentWritten>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentWritten&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode => Object.hash(runtimeType,file);

@override
String toString() {
  return 'TextContentWrite.written(file: $file)';
}


}

/// @nodoc
abstract mixin class $TextContentWrittenCopyWith<$Res> implements $TextContentWriteCopyWith<$Res> {
  factory $TextContentWrittenCopyWith(TextContentWritten value, $Res Function(TextContentWritten) _then) = _$TextContentWrittenCopyWithImpl;
@useResult
$Res call({
 CatalogFile file
});


$CatalogFileCopyWith<$Res> get file;

}
/// @nodoc
class _$TextContentWrittenCopyWithImpl<$Res>
    implements $TextContentWrittenCopyWith<$Res> {
  _$TextContentWrittenCopyWithImpl(this._self, this._then);

  final TextContentWritten _self;
  final $Res Function(TextContentWritten) _then;

/// Create a copy of TextContentWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,}) {
  return _then(TextContentWritten(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,
  ));
}

/// Create a copy of TextContentWrite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}

/// @nodoc


class TextContentWriteFailed implements TextContentWrite {
  const TextContentWriteFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of TextContentWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextContentWriteFailedCopyWith<TextContentWriteFailed> get copyWith => _$TextContentWriteFailedCopyWithImpl<TextContentWriteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextContentWriteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TextContentWrite.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TextContentWriteFailedCopyWith<$Res> implements $TextContentWriteCopyWith<$Res> {
  factory $TextContentWriteFailedCopyWith(TextContentWriteFailed value, $Res Function(TextContentWriteFailed) _then) = _$TextContentWriteFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TextContentWriteFailedCopyWithImpl<$Res>
    implements $TextContentWriteFailedCopyWith<$Res> {
  _$TextContentWriteFailedCopyWithImpl(this._self, this._then);

  final TextContentWriteFailed _self;
  final $Res Function(TextContentWriteFailed) _then;

/// Create a copy of TextContentWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TextContentWriteFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TextContentWrite
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
