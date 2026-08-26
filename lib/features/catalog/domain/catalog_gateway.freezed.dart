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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<FileDetails> files)?  loaded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<FileDetails> files)  loaded,required TResult Function( Failure failure)  failed,}) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<FileDetails> files)?  loaded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
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
  const CatalogListingLoaded({required final  List<FileDetails> files}): _files = files;
  

 final  List<FileDetails> _files;
 List<FileDetails> get files {
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
 List<FileDetails> files
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
as List<FileDetails>,
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

/// @nodoc
mixin _$FileDetailsOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileDetailsOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FileDetailsOutcome()';
}


}

/// @nodoc
class $FileDetailsOutcomeCopyWith<$Res>  {
$FileDetailsOutcomeCopyWith(FileDetailsOutcome _, $Res Function(FileDetailsOutcome) __);
}


/// Adds pattern-matching-related methods to [FileDetailsOutcome].
extension FileDetailsOutcomePatterns on FileDetailsOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FileDetailsRead value)?  read,TResult Function( FileDetailsFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FileDetailsRead() when read != null:
return read(_that);case FileDetailsFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FileDetailsRead value)  read,required TResult Function( FileDetailsFailed value)  failed,}){
final _that = this;
switch (_that) {
case FileDetailsRead():
return read(_that);case FileDetailsFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FileDetailsRead value)?  read,TResult? Function( FileDetailsFailed value)?  failed,}){
final _that = this;
switch (_that) {
case FileDetailsRead() when read != null:
return read(_that);case FileDetailsFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( FileDetails details)?  read,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FileDetailsRead() when read != null:
return read(_that.details);case FileDetailsFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( FileDetails details)  read,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case FileDetailsRead():
return read(_that.details);case FileDetailsFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( FileDetails details)?  read,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case FileDetailsRead() when read != null:
return read(_that.details);case FileDetailsFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class FileDetailsRead implements FileDetailsOutcome {
  const FileDetailsRead({required this.details});
  

 final  FileDetails details;

/// Create a copy of FileDetailsOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileDetailsReadCopyWith<FileDetailsRead> get copyWith => _$FileDetailsReadCopyWithImpl<FileDetailsRead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileDetailsRead&&(identical(other.details, details) || other.details == details));
}


@override
int get hashCode => Object.hash(runtimeType,details);

@override
String toString() {
  return 'FileDetailsOutcome.read(details: $details)';
}


}

/// @nodoc
abstract mixin class $FileDetailsReadCopyWith<$Res> implements $FileDetailsOutcomeCopyWith<$Res> {
  factory $FileDetailsReadCopyWith(FileDetailsRead value, $Res Function(FileDetailsRead) _then) = _$FileDetailsReadCopyWithImpl;
@useResult
$Res call({
 FileDetails details
});


$FileDetailsCopyWith<$Res> get details;

}
/// @nodoc
class _$FileDetailsReadCopyWithImpl<$Res>
    implements $FileDetailsReadCopyWith<$Res> {
  _$FileDetailsReadCopyWithImpl(this._self, this._then);

  final FileDetailsRead _self;
  final $Res Function(FileDetailsRead) _then;

/// Create a copy of FileDetailsOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? details = null,}) {
  return _then(FileDetailsRead(
details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as FileDetails,
  ));
}

/// Create a copy of FileDetailsOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileDetailsCopyWith<$Res> get details {
  
  return $FileDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}

/// @nodoc


class FileDetailsFailed implements FileDetailsOutcome {
  const FileDetailsFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of FileDetailsOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileDetailsFailedCopyWith<FileDetailsFailed> get copyWith => _$FileDetailsFailedCopyWithImpl<FileDetailsFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileDetailsFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'FileDetailsOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FileDetailsFailedCopyWith<$Res> implements $FileDetailsOutcomeCopyWith<$Res> {
  factory $FileDetailsFailedCopyWith(FileDetailsFailed value, $Res Function(FileDetailsFailed) _then) = _$FileDetailsFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FileDetailsFailedCopyWithImpl<$Res>
    implements $FileDetailsFailedCopyWith<$Res> {
  _$FileDetailsFailedCopyWithImpl(this._self, this._then);

  final FileDetailsFailed _self;
  final $Res Function(FileDetailsFailed) _then;

/// Create a copy of FileDetailsOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FileDetailsFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of FileDetailsOutcome
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
mixin _$MetadataEditOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MetadataEditOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MetadataEditOutcome()';
}


}

/// @nodoc
class $MetadataEditOutcomeCopyWith<$Res>  {
$MetadataEditOutcomeCopyWith(MetadataEditOutcome _, $Res Function(MetadataEditOutcome) __);
}


/// Adds pattern-matching-related methods to [MetadataEditOutcome].
extension MetadataEditOutcomePatterns on MetadataEditOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MetadataEditSaved value)?  saved,TResult Function( MetadataEditFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MetadataEditSaved() when saved != null:
return saved(_that);case MetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MetadataEditSaved value)  saved,required TResult Function( MetadataEditFailed value)  failed,}){
final _that = this;
switch (_that) {
case MetadataEditSaved():
return saved(_that);case MetadataEditFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MetadataEditSaved value)?  saved,TResult? Function( MetadataEditFailed value)?  failed,}){
final _that = this;
switch (_that) {
case MetadataEditSaved() when saved != null:
return saved(_that);case MetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( MusicMetadata metadata)?  saved,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MetadataEditSaved() when saved != null:
return saved(_that.metadata);case MetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( MusicMetadata metadata)  saved,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case MetadataEditSaved():
return saved(_that.metadata);case MetadataEditFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( MusicMetadata metadata)?  saved,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case MetadataEditSaved() when saved != null:
return saved(_that.metadata);case MetadataEditFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class MetadataEditSaved implements MetadataEditOutcome {
  const MetadataEditSaved({required this.metadata});
  

 final  MusicMetadata metadata;

/// Create a copy of MetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MetadataEditSavedCopyWith<MetadataEditSaved> get copyWith => _$MetadataEditSavedCopyWithImpl<MetadataEditSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MetadataEditSaved&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,metadata);

@override
String toString() {
  return 'MetadataEditOutcome.saved(metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $MetadataEditSavedCopyWith<$Res> implements $MetadataEditOutcomeCopyWith<$Res> {
  factory $MetadataEditSavedCopyWith(MetadataEditSaved value, $Res Function(MetadataEditSaved) _then) = _$MetadataEditSavedCopyWithImpl;
@useResult
$Res call({
 MusicMetadata metadata
});


$MusicMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$MetadataEditSavedCopyWithImpl<$Res>
    implements $MetadataEditSavedCopyWith<$Res> {
  _$MetadataEditSavedCopyWithImpl(this._self, this._then);

  final MetadataEditSaved _self;
  final $Res Function(MetadataEditSaved) _then;

/// Create a copy of MetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? metadata = null,}) {
  return _then(MetadataEditSaved(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MusicMetadata,
  ));
}

/// Create a copy of MetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicMetadataCopyWith<$Res> get metadata {
  
  return $MusicMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc


class MetadataEditFailed implements MetadataEditOutcome {
  const MetadataEditFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of MetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MetadataEditFailedCopyWith<MetadataEditFailed> get copyWith => _$MetadataEditFailedCopyWithImpl<MetadataEditFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MetadataEditFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'MetadataEditOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $MetadataEditFailedCopyWith<$Res> implements $MetadataEditOutcomeCopyWith<$Res> {
  factory $MetadataEditFailedCopyWith(MetadataEditFailed value, $Res Function(MetadataEditFailed) _then) = _$MetadataEditFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$MetadataEditFailedCopyWithImpl<$Res>
    implements $MetadataEditFailedCopyWith<$Res> {
  _$MetadataEditFailedCopyWithImpl(this._self, this._then);

  final MetadataEditFailed _self;
  final $Res Function(MetadataEditFailed) _then;

/// Create a copy of MetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(MetadataEditFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of MetadataEditOutcome
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
mixin _$VideoMetadataEditOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMetadataEditOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VideoMetadataEditOutcome()';
}


}

/// @nodoc
class $VideoMetadataEditOutcomeCopyWith<$Res>  {
$VideoMetadataEditOutcomeCopyWith(VideoMetadataEditOutcome _, $Res Function(VideoMetadataEditOutcome) __);
}


/// Adds pattern-matching-related methods to [VideoMetadataEditOutcome].
extension VideoMetadataEditOutcomePatterns on VideoMetadataEditOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VideoMetadataEditSaved value)?  saved,TResult Function( VideoMetadataEditFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VideoMetadataEditSaved() when saved != null:
return saved(_that);case VideoMetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VideoMetadataEditSaved value)  saved,required TResult Function( VideoMetadataEditFailed value)  failed,}){
final _that = this;
switch (_that) {
case VideoMetadataEditSaved():
return saved(_that);case VideoMetadataEditFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VideoMetadataEditSaved value)?  saved,TResult? Function( VideoMetadataEditFailed value)?  failed,}){
final _that = this;
switch (_that) {
case VideoMetadataEditSaved() when saved != null:
return saved(_that);case VideoMetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( VideoMetadata metadata)?  saved,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VideoMetadataEditSaved() when saved != null:
return saved(_that.metadata);case VideoMetadataEditFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( VideoMetadata metadata)  saved,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case VideoMetadataEditSaved():
return saved(_that.metadata);case VideoMetadataEditFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( VideoMetadata metadata)?  saved,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case VideoMetadataEditSaved() when saved != null:
return saved(_that.metadata);case VideoMetadataEditFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class VideoMetadataEditSaved implements VideoMetadataEditOutcome {
  const VideoMetadataEditSaved({required this.metadata});
  

 final  VideoMetadata metadata;

/// Create a copy of VideoMetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoMetadataEditSavedCopyWith<VideoMetadataEditSaved> get copyWith => _$VideoMetadataEditSavedCopyWithImpl<VideoMetadataEditSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMetadataEditSaved&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,metadata);

@override
String toString() {
  return 'VideoMetadataEditOutcome.saved(metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $VideoMetadataEditSavedCopyWith<$Res> implements $VideoMetadataEditOutcomeCopyWith<$Res> {
  factory $VideoMetadataEditSavedCopyWith(VideoMetadataEditSaved value, $Res Function(VideoMetadataEditSaved) _then) = _$VideoMetadataEditSavedCopyWithImpl;
@useResult
$Res call({
 VideoMetadata metadata
});


$VideoMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$VideoMetadataEditSavedCopyWithImpl<$Res>
    implements $VideoMetadataEditSavedCopyWith<$Res> {
  _$VideoMetadataEditSavedCopyWithImpl(this._self, this._then);

  final VideoMetadataEditSaved _self;
  final $Res Function(VideoMetadataEditSaved) _then;

/// Create a copy of VideoMetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? metadata = null,}) {
  return _then(VideoMetadataEditSaved(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as VideoMetadata,
  ));
}

/// Create a copy of VideoMetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoMetadataCopyWith<$Res> get metadata {
  
  return $VideoMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc


class VideoMetadataEditFailed implements VideoMetadataEditOutcome {
  const VideoMetadataEditFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of VideoMetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoMetadataEditFailedCopyWith<VideoMetadataEditFailed> get copyWith => _$VideoMetadataEditFailedCopyWithImpl<VideoMetadataEditFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMetadataEditFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'VideoMetadataEditOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $VideoMetadataEditFailedCopyWith<$Res> implements $VideoMetadataEditOutcomeCopyWith<$Res> {
  factory $VideoMetadataEditFailedCopyWith(VideoMetadataEditFailed value, $Res Function(VideoMetadataEditFailed) _then) = _$VideoMetadataEditFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$VideoMetadataEditFailedCopyWithImpl<$Res>
    implements $VideoMetadataEditFailedCopyWith<$Res> {
  _$VideoMetadataEditFailedCopyWithImpl(this._self, this._then);

  final VideoMetadataEditFailed _self;
  final $Res Function(VideoMetadataEditFailed) _then;

/// Create a copy of VideoMetadataEditOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(VideoMetadataEditFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of VideoMetadataEditOutcome
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
mixin _$FileRenameOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileRenameOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FileRenameOutcome()';
}


}

/// @nodoc
class $FileRenameOutcomeCopyWith<$Res>  {
$FileRenameOutcomeCopyWith(FileRenameOutcome _, $Res Function(FileRenameOutcome) __);
}


/// Adds pattern-matching-related methods to [FileRenameOutcome].
extension FileRenameOutcomePatterns on FileRenameOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FileRenamed value)?  renamed,TResult Function( FileRenameFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FileRenamed() when renamed != null:
return renamed(_that);case FileRenameFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FileRenamed value)  renamed,required TResult Function( FileRenameFailed value)  failed,}){
final _that = this;
switch (_that) {
case FileRenamed():
return renamed(_that);case FileRenameFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FileRenamed value)?  renamed,TResult? Function( FileRenameFailed value)?  failed,}){
final _that = this;
switch (_that) {
case FileRenamed() when renamed != null:
return renamed(_that);case FileRenameFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CatalogFile file)?  renamed,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FileRenamed() when renamed != null:
return renamed(_that.file);case FileRenameFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CatalogFile file)  renamed,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case FileRenamed():
return renamed(_that.file);case FileRenameFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CatalogFile file)?  renamed,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case FileRenamed() when renamed != null:
return renamed(_that.file);case FileRenameFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class FileRenamed implements FileRenameOutcome {
  const FileRenamed({required this.file});
  

 final  CatalogFile file;

/// Create a copy of FileRenameOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileRenamedCopyWith<FileRenamed> get copyWith => _$FileRenamedCopyWithImpl<FileRenamed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileRenamed&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode => Object.hash(runtimeType,file);

@override
String toString() {
  return 'FileRenameOutcome.renamed(file: $file)';
}


}

/// @nodoc
abstract mixin class $FileRenamedCopyWith<$Res> implements $FileRenameOutcomeCopyWith<$Res> {
  factory $FileRenamedCopyWith(FileRenamed value, $Res Function(FileRenamed) _then) = _$FileRenamedCopyWithImpl;
@useResult
$Res call({
 CatalogFile file
});


$CatalogFileCopyWith<$Res> get file;

}
/// @nodoc
class _$FileRenamedCopyWithImpl<$Res>
    implements $FileRenamedCopyWith<$Res> {
  _$FileRenamedCopyWithImpl(this._self, this._then);

  final FileRenamed _self;
  final $Res Function(FileRenamed) _then;

/// Create a copy of FileRenameOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,}) {
  return _then(FileRenamed(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,
  ));
}

/// Create a copy of FileRenameOutcome
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


class FileRenameFailed implements FileRenameOutcome {
  const FileRenameFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of FileRenameOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileRenameFailedCopyWith<FileRenameFailed> get copyWith => _$FileRenameFailedCopyWithImpl<FileRenameFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileRenameFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'FileRenameOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FileRenameFailedCopyWith<$Res> implements $FileRenameOutcomeCopyWith<$Res> {
  factory $FileRenameFailedCopyWith(FileRenameFailed value, $Res Function(FileRenameFailed) _then) = _$FileRenameFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FileRenameFailedCopyWithImpl<$Res>
    implements $FileRenameFailedCopyWith<$Res> {
  _$FileRenameFailedCopyWithImpl(this._self, this._then);

  final FileRenameFailed _self;
  final $Res Function(FileRenameFailed) _then;

/// Create a copy of FileRenameOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FileRenameFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of FileRenameOutcome
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
mixin _$FileThumbnailOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileThumbnailOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FileThumbnailOutcome()';
}


}

/// @nodoc
class $FileThumbnailOutcomeCopyWith<$Res>  {
$FileThumbnailOutcomeCopyWith(FileThumbnailOutcome _, $Res Function(FileThumbnailOutcome) __);
}


/// Adds pattern-matching-related methods to [FileThumbnailOutcome].
extension FileThumbnailOutcomePatterns on FileThumbnailOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FileThumbnailRead value)?  read,TResult Function( FileThumbnailFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FileThumbnailRead() when read != null:
return read(_that);case FileThumbnailFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FileThumbnailRead value)  read,required TResult Function( FileThumbnailFailed value)  failed,}){
final _that = this;
switch (_that) {
case FileThumbnailRead():
return read(_that);case FileThumbnailFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FileThumbnailRead value)?  read,TResult? Function( FileThumbnailFailed value)?  failed,}){
final _that = this;
switch (_that) {
case FileThumbnailRead() when read != null:
return read(_that);case FileThumbnailFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Uint8List bytes)?  read,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FileThumbnailRead() when read != null:
return read(_that.bytes);case FileThumbnailFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Uint8List bytes)  read,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case FileThumbnailRead():
return read(_that.bytes);case FileThumbnailFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Uint8List bytes)?  read,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case FileThumbnailRead() when read != null:
return read(_that.bytes);case FileThumbnailFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class FileThumbnailRead implements FileThumbnailOutcome {
  const FileThumbnailRead({required this.bytes});
  

 final  Uint8List bytes;

/// Create a copy of FileThumbnailOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileThumbnailReadCopyWith<FileThumbnailRead> get copyWith => _$FileThumbnailReadCopyWithImpl<FileThumbnailRead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileThumbnailRead&&const DeepCollectionEquality().equals(other.bytes, bytes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes));

@override
String toString() {
  return 'FileThumbnailOutcome.read(bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $FileThumbnailReadCopyWith<$Res> implements $FileThumbnailOutcomeCopyWith<$Res> {
  factory $FileThumbnailReadCopyWith(FileThumbnailRead value, $Res Function(FileThumbnailRead) _then) = _$FileThumbnailReadCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes
});




}
/// @nodoc
class _$FileThumbnailReadCopyWithImpl<$Res>
    implements $FileThumbnailReadCopyWith<$Res> {
  _$FileThumbnailReadCopyWithImpl(this._self, this._then);

  final FileThumbnailRead _self;
  final $Res Function(FileThumbnailRead) _then;

/// Create a copy of FileThumbnailOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,}) {
  return _then(FileThumbnailRead(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc


class FileThumbnailFailed implements FileThumbnailOutcome {
  const FileThumbnailFailed({required this.failure});
  

 final  Failure failure;

/// Create a copy of FileThumbnailOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileThumbnailFailedCopyWith<FileThumbnailFailed> get copyWith => _$FileThumbnailFailedCopyWithImpl<FileThumbnailFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileThumbnailFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'FileThumbnailOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FileThumbnailFailedCopyWith<$Res> implements $FileThumbnailOutcomeCopyWith<$Res> {
  factory $FileThumbnailFailedCopyWith(FileThumbnailFailed value, $Res Function(FileThumbnailFailed) _then) = _$FileThumbnailFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FileThumbnailFailedCopyWithImpl<$Res>
    implements $FileThumbnailFailedCopyWith<$Res> {
  _$FileThumbnailFailedCopyWithImpl(this._self, this._then);

  final FileThumbnailFailed _self;
  final $Res Function(FileThumbnailFailed) _then;

/// Create a copy of FileThumbnailOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FileThumbnailFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of FileThumbnailOutcome
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
