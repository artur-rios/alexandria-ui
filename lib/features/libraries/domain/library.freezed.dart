// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Library {

 String get uuid;/// The owner's name for it, not the folder's.
///
/// A directory called `2024-final-v2` is a path, not a title, and
/// renaming the library must not mean renaming the directory.
 String get name;/// The folder every entry's position is relative to.
 String get rootPath;
/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryCopyWith<Library> get copyWith => _$LibraryCopyWithImpl<Library>(this as Library, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Library&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,rootPath);

@override
String toString() {
  return 'Library(uuid: $uuid, name: $name, rootPath: $rootPath)';
}


}

/// @nodoc
abstract mixin class $LibraryCopyWith<$Res>  {
  factory $LibraryCopyWith(Library value, $Res Function(Library) _then) = _$LibraryCopyWithImpl;
@useResult
$Res call({
 String uuid, String name, String rootPath
});




}
/// @nodoc
class _$LibraryCopyWithImpl<$Res>
    implements $LibraryCopyWith<$Res> {
  _$LibraryCopyWithImpl(this._self, this._then);

  final Library _self;
  final $Res Function(Library) _then;

/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? rootPath = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Library].
extension LibraryPatterns on Library {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Library value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Library() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Library value)  $default,){
final _that = this;
switch (_that) {
case _Library():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Library value)?  $default,){
final _that = this;
switch (_that) {
case _Library() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name,  String rootPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Library() when $default != null:
return $default(_that.uuid,_that.name,_that.rootPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name,  String rootPath)  $default,) {final _that = this;
switch (_that) {
case _Library():
return $default(_that.uuid,_that.name,_that.rootPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name,  String rootPath)?  $default,) {final _that = this;
switch (_that) {
case _Library() when $default != null:
return $default(_that.uuid,_that.name,_that.rootPath);case _:
  return null;

}
}

}

/// @nodoc


class _Library implements Library {
  const _Library({required this.uuid, required this.name, required this.rootPath});
  

@override final  String uuid;
/// The owner's name for it, not the folder's.
///
/// A directory called `2024-final-v2` is a path, not a title, and
/// renaming the library must not mean renaming the directory.
@override final  String name;
/// The folder every entry's position is relative to.
@override final  String rootPath;

/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryCopyWith<_Library> get copyWith => __$LibraryCopyWithImpl<_Library>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Library&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,rootPath);

@override
String toString() {
  return 'Library(uuid: $uuid, name: $name, rootPath: $rootPath)';
}


}

/// @nodoc
abstract mixin class _$LibraryCopyWith<$Res> implements $LibraryCopyWith<$Res> {
  factory _$LibraryCopyWith(_Library value, $Res Function(_Library) _then) = __$LibraryCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name, String rootPath
});




}
/// @nodoc
class __$LibraryCopyWithImpl<$Res>
    implements _$LibraryCopyWith<$Res> {
  __$LibraryCopyWithImpl(this._self, this._then);

  final _Library _self;
  final $Res Function(_Library) _then;

/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? rootPath = null,}) {
  return _then(_Library(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LibraryFolder {

/// Its own name, as it is on disk.
 String get name;/// Its path relative to the library root — what opening it sends back.
 String get path;
/// Create a copy of LibraryFolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryFolderCopyWith<LibraryFolder> get copyWith => _$LibraryFolderCopyWithImpl<LibraryFolder>(this as LibraryFolder, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryFolder&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,name,path);

@override
String toString() {
  return 'LibraryFolder(name: $name, path: $path)';
}


}

/// @nodoc
abstract mixin class $LibraryFolderCopyWith<$Res>  {
  factory $LibraryFolderCopyWith(LibraryFolder value, $Res Function(LibraryFolder) _then) = _$LibraryFolderCopyWithImpl;
@useResult
$Res call({
 String name, String path
});




}
/// @nodoc
class _$LibraryFolderCopyWithImpl<$Res>
    implements $LibraryFolderCopyWith<$Res> {
  _$LibraryFolderCopyWithImpl(this._self, this._then);

  final LibraryFolder _self;
  final $Res Function(LibraryFolder) _then;

/// Create a copy of LibraryFolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryFolder].
extension LibraryFolderPatterns on LibraryFolder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryFolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryFolder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryFolder value)  $default,){
final _that = this;
switch (_that) {
case _LibraryFolder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryFolder value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryFolder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryFolder() when $default != null:
return $default(_that.name,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path)  $default,) {final _that = this;
switch (_that) {
case _LibraryFolder():
return $default(_that.name,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path)?  $default,) {final _that = this;
switch (_that) {
case _LibraryFolder() when $default != null:
return $default(_that.name,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryFolder implements LibraryFolder {
  const _LibraryFolder({required this.name, required this.path});
  

/// Its own name, as it is on disk.
@override final  String name;
/// Its path relative to the library root — what opening it sends back.
@override final  String path;

/// Create a copy of LibraryFolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryFolderCopyWith<_LibraryFolder> get copyWith => __$LibraryFolderCopyWithImpl<_LibraryFolder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryFolder&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,name,path);

@override
String toString() {
  return 'LibraryFolder(name: $name, path: $path)';
}


}

/// @nodoc
abstract mixin class _$LibraryFolderCopyWith<$Res> implements $LibraryFolderCopyWith<$Res> {
  factory _$LibraryFolderCopyWith(_LibraryFolder value, $Res Function(_LibraryFolder) _then) = __$LibraryFolderCopyWithImpl;
@override @useResult
$Res call({
 String name, String path
});




}
/// @nodoc
class __$LibraryFolderCopyWithImpl<$Res>
    implements _$LibraryFolderCopyWith<$Res> {
  __$LibraryFolderCopyWithImpl(this._self, this._then);

  final _LibraryFolder _self;
  final $Res Function(_LibraryFolder) _then;

/// Create a copy of LibraryFolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,}) {
  return _then(_LibraryFolder(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LibraryFile {

 CatalogFile get file;/// The track's tags, when it is audio the core has read.
 MusicMetadata? get metadata;
/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryFileCopyWith<LibraryFile> get copyWith => _$LibraryFileCopyWithImpl<LibraryFile>(this as LibraryFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryFile&&(identical(other.file, file) || other.file == file)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,file,metadata);

@override
String toString() {
  return 'LibraryFile(file: $file, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $LibraryFileCopyWith<$Res>  {
  factory $LibraryFileCopyWith(LibraryFile value, $Res Function(LibraryFile) _then) = _$LibraryFileCopyWithImpl;
@useResult
$Res call({
 CatalogFile file, MusicMetadata? metadata
});


$CatalogFileCopyWith<$Res> get file;$MusicMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$LibraryFileCopyWithImpl<$Res>
    implements $LibraryFileCopyWith<$Res> {
  _$LibraryFileCopyWithImpl(this._self, this._then);

  final LibraryFile _self;
  final $Res Function(LibraryFile) _then;

/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MusicMetadata?,
  ));
}
/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MusicMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryFile].
extension LibraryFilePatterns on LibraryFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryFile value)  $default,){
final _that = this;
switch (_that) {
case _LibraryFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryFile value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogFile file,  MusicMetadata? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryFile() when $default != null:
return $default(_that.file,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogFile file,  MusicMetadata? metadata)  $default,) {final _that = this;
switch (_that) {
case _LibraryFile():
return $default(_that.file,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogFile file,  MusicMetadata? metadata)?  $default,) {final _that = this;
switch (_that) {
case _LibraryFile() when $default != null:
return $default(_that.file,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryFile implements LibraryFile {
  const _LibraryFile({required this.file, this.metadata});
  

@override final  CatalogFile file;
/// The track's tags, when it is audio the core has read.
@override final  MusicMetadata? metadata;

/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryFileCopyWith<_LibraryFile> get copyWith => __$LibraryFileCopyWithImpl<_LibraryFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryFile&&(identical(other.file, file) || other.file == file)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}


@override
int get hashCode => Object.hash(runtimeType,file,metadata);

@override
String toString() {
  return 'LibraryFile(file: $file, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$LibraryFileCopyWith<$Res> implements $LibraryFileCopyWith<$Res> {
  factory _$LibraryFileCopyWith(_LibraryFile value, $Res Function(_LibraryFile) _then) = __$LibraryFileCopyWithImpl;
@override @useResult
$Res call({
 CatalogFile file, MusicMetadata? metadata
});


@override $CatalogFileCopyWith<$Res> get file;@override $MusicMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$LibraryFileCopyWithImpl<$Res>
    implements _$LibraryFileCopyWith<$Res> {
  __$LibraryFileCopyWithImpl(this._self, this._then);

  final _LibraryFile _self;
  final $Res Function(_LibraryFile) _then;

/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? metadata = freezed,}) {
  return _then(_LibraryFile(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MusicMetadata?,
  ));
}

/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}/// Create a copy of LibraryFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $MusicMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$LibraryListing {

 Library get library;/// The folder being shown, relative to the root. Empty at the top.
 String get path; List<LibraryFolder> get folders; List<LibraryFile> get files;
/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryListingCopyWith<LibraryListing> get copyWith => _$LibraryListingCopyWithImpl<LibraryListing>(this as LibraryListing, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryListing&&(identical(other.library, library) || other.library == library)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other.folders, folders)&&const DeepCollectionEquality().equals(other.files, files));
}


@override
int get hashCode => Object.hash(runtimeType,library,path,const DeepCollectionEquality().hash(folders),const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'LibraryListing(library: $library, path: $path, folders: $folders, files: $files)';
}


}

/// @nodoc
abstract mixin class $LibraryListingCopyWith<$Res>  {
  factory $LibraryListingCopyWith(LibraryListing value, $Res Function(LibraryListing) _then) = _$LibraryListingCopyWithImpl;
@useResult
$Res call({
 Library library, String path, List<LibraryFolder> folders, List<LibraryFile> files
});


$LibraryCopyWith<$Res> get library;

}
/// @nodoc
class _$LibraryListingCopyWithImpl<$Res>
    implements $LibraryListingCopyWith<$Res> {
  _$LibraryListingCopyWithImpl(this._self, this._then);

  final LibraryListing _self;
  final $Res Function(LibraryListing) _then;

/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? library = null,Object? path = null,Object? folders = null,Object? files = null,}) {
  return _then(_self.copyWith(
library: null == library ? _self.library : library // ignore: cast_nullable_to_non_nullable
as Library,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as List<LibraryFolder>,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<LibraryFile>,
  ));
}
/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibraryCopyWith<$Res> get library {
  
  return $LibraryCopyWith<$Res>(_self.library, (value) {
    return _then(_self.copyWith(library: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryListing].
extension LibraryListingPatterns on LibraryListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryListing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryListing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryListing value)  $default,){
final _that = this;
switch (_that) {
case _LibraryListing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryListing value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryListing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Library library,  String path,  List<LibraryFolder> folders,  List<LibraryFile> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryListing() when $default != null:
return $default(_that.library,_that.path,_that.folders,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Library library,  String path,  List<LibraryFolder> folders,  List<LibraryFile> files)  $default,) {final _that = this;
switch (_that) {
case _LibraryListing():
return $default(_that.library,_that.path,_that.folders,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Library library,  String path,  List<LibraryFolder> folders,  List<LibraryFile> files)?  $default,) {final _that = this;
switch (_that) {
case _LibraryListing() when $default != null:
return $default(_that.library,_that.path,_that.folders,_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryListing extends LibraryListing {
  const _LibraryListing({required this.library, required this.path, required final  List<LibraryFolder> folders, required final  List<LibraryFile> files}): _folders = folders,_files = files,super._();
  

@override final  Library library;
/// The folder being shown, relative to the root. Empty at the top.
@override final  String path;
 final  List<LibraryFolder> _folders;
@override List<LibraryFolder> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

 final  List<LibraryFile> _files;
@override List<LibraryFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryListingCopyWith<_LibraryListing> get copyWith => __$LibraryListingCopyWithImpl<_LibraryListing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryListing&&(identical(other.library, library) || other.library == library)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other._folders, _folders)&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,library,path,const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'LibraryListing(library: $library, path: $path, folders: $folders, files: $files)';
}


}

/// @nodoc
abstract mixin class _$LibraryListingCopyWith<$Res> implements $LibraryListingCopyWith<$Res> {
  factory _$LibraryListingCopyWith(_LibraryListing value, $Res Function(_LibraryListing) _then) = __$LibraryListingCopyWithImpl;
@override @useResult
$Res call({
 Library library, String path, List<LibraryFolder> folders, List<LibraryFile> files
});


@override $LibraryCopyWith<$Res> get library;

}
/// @nodoc
class __$LibraryListingCopyWithImpl<$Res>
    implements _$LibraryListingCopyWith<$Res> {
  __$LibraryListingCopyWithImpl(this._self, this._then);

  final _LibraryListing _self;
  final $Res Function(_LibraryListing) _then;

/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? library = null,Object? path = null,Object? folders = null,Object? files = null,}) {
  return _then(_LibraryListing(
library: null == library ? _self.library : library // ignore: cast_nullable_to_non_nullable
as Library,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<LibraryFolder>,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<LibraryFile>,
  ));
}

/// Create a copy of LibraryListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibraryCopyWith<$Res> get library {
  
  return $LibraryCopyWith<$Res>(_self.library, (value) {
    return _then(_self.copyWith(library: value));
  });
}
}

// dart format on
