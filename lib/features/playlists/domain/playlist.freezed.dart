// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Playlist {

 String get uuid; String get name;
/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCopyWith<Playlist> get copyWith => _$PlaylistCopyWithImpl<Playlist>(this as Playlist, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Playlist&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name);

@override
String toString() {
  return 'Playlist(uuid: $uuid, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlaylistCopyWith<$Res>  {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) _then) = _$PlaylistCopyWithImpl;
@useResult
$Res call({
 String uuid, String name
});




}
/// @nodoc
class _$PlaylistCopyWithImpl<$Res>
    implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._self, this._then);

  final Playlist _self;
  final $Res Function(Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Playlist].
extension PlaylistPatterns on Playlist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Playlist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Playlist value)  $default,){
final _that = this;
switch (_that) {
case _Playlist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Playlist value)?  $default,){
final _that = this;
switch (_that) {
case _Playlist() when $default != null:
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
case _Playlist() when $default != null:
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
case _Playlist():
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
case _Playlist() when $default != null:
return $default(_that.uuid,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _Playlist implements Playlist {
  const _Playlist({required this.uuid, required this.name});
  

@override final  String uuid;
@override final  String name;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistCopyWith<_Playlist> get copyWith => __$PlaylistCopyWithImpl<_Playlist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Playlist&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name);

@override
String toString() {
  return 'Playlist(uuid: $uuid, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlaylistCopyWith<$Res> implements $PlaylistCopyWith<$Res> {
  factory _$PlaylistCopyWith(_Playlist value, $Res Function(_Playlist) _then) = __$PlaylistCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name
});




}
/// @nodoc
class __$PlaylistCopyWithImpl<$Res>
    implements _$PlaylistCopyWith<$Res> {
  __$PlaylistCopyWithImpl(this._self, this._then);

  final _Playlist _self;
  final $Res Function(_Playlist) _then;

/// Create a copy of Playlist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,}) {
  return _then(_Playlist(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlaylistEntry {

 String get uuid; CatalogFile get file;/// The track's metadata, as the music area already reads it. `null` when
/// the core answered no metadata for this file — a row a listener has
/// not tagged yet, not a parse failure.
 MusicMetadata? get metadata; int get position;/// Whether the file this entry points at is missing on disk.
///
/// The entry stays in the list either way (playlists design section 5):
/// dropping it here would delete curation work this application was
/// never asked to discard.
 bool get missing;
/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistEntryCopyWith<PlaylistEntry> get copyWith => _$PlaylistEntryCopyWithImpl<PlaylistEntry>(this as PlaylistEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistEntry&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.file, file) || other.file == file)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.position, position) || other.position == position)&&(identical(other.missing, missing) || other.missing == missing));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,file,metadata,position,missing);

@override
String toString() {
  return 'PlaylistEntry(uuid: $uuid, file: $file, metadata: $metadata, position: $position, missing: $missing)';
}


}

/// @nodoc
abstract mixin class $PlaylistEntryCopyWith<$Res>  {
  factory $PlaylistEntryCopyWith(PlaylistEntry value, $Res Function(PlaylistEntry) _then) = _$PlaylistEntryCopyWithImpl;
@useResult
$Res call({
 String uuid, CatalogFile file, MusicMetadata? metadata, int position, bool missing
});


$CatalogFileCopyWith<$Res> get file;$MusicMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$PlaylistEntryCopyWithImpl<$Res>
    implements $PlaylistEntryCopyWith<$Res> {
  _$PlaylistEntryCopyWithImpl(this._self, this._then);

  final PlaylistEntry _self;
  final $Res Function(PlaylistEntry) _then;

/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? file = null,Object? metadata = freezed,Object? position = null,Object? missing = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MusicMetadata?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}/// Create a copy of PlaylistEntry
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


/// Adds pattern-matching-related methods to [PlaylistEntry].
extension PlaylistEntryPatterns on PlaylistEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistEntry value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistEntry value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  CatalogFile file,  MusicMetadata? metadata,  int position,  bool missing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistEntry() when $default != null:
return $default(_that.uuid,_that.file,_that.metadata,_that.position,_that.missing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  CatalogFile file,  MusicMetadata? metadata,  int position,  bool missing)  $default,) {final _that = this;
switch (_that) {
case _PlaylistEntry():
return $default(_that.uuid,_that.file,_that.metadata,_that.position,_that.missing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  CatalogFile file,  MusicMetadata? metadata,  int position,  bool missing)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistEntry() when $default != null:
return $default(_that.uuid,_that.file,_that.metadata,_that.position,_that.missing);case _:
  return null;

}
}

}

/// @nodoc


class _PlaylistEntry implements PlaylistEntry {
  const _PlaylistEntry({required this.uuid, required this.file, this.metadata, required this.position, required this.missing});
  

@override final  String uuid;
@override final  CatalogFile file;
/// The track's metadata, as the music area already reads it. `null` when
/// the core answered no metadata for this file — a row a listener has
/// not tagged yet, not a parse failure.
@override final  MusicMetadata? metadata;
@override final  int position;
/// Whether the file this entry points at is missing on disk.
///
/// The entry stays in the list either way (playlists design section 5):
/// dropping it here would delete curation work this application was
/// never asked to discard.
@override final  bool missing;

/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistEntryCopyWith<_PlaylistEntry> get copyWith => __$PlaylistEntryCopyWithImpl<_PlaylistEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistEntry&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.file, file) || other.file == file)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.position, position) || other.position == position)&&(identical(other.missing, missing) || other.missing == missing));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,file,metadata,position,missing);

@override
String toString() {
  return 'PlaylistEntry(uuid: $uuid, file: $file, metadata: $metadata, position: $position, missing: $missing)';
}


}

/// @nodoc
abstract mixin class _$PlaylistEntryCopyWith<$Res> implements $PlaylistEntryCopyWith<$Res> {
  factory _$PlaylistEntryCopyWith(_PlaylistEntry value, $Res Function(_PlaylistEntry) _then) = __$PlaylistEntryCopyWithImpl;
@override @useResult
$Res call({
 String uuid, CatalogFile file, MusicMetadata? metadata, int position, bool missing
});


@override $CatalogFileCopyWith<$Res> get file;@override $MusicMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$PlaylistEntryCopyWithImpl<$Res>
    implements _$PlaylistEntryCopyWith<$Res> {
  __$PlaylistEntryCopyWithImpl(this._self, this._then);

  final _PlaylistEntry _self;
  final $Res Function(_PlaylistEntry) _then;

/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? file = null,Object? metadata = freezed,Object? position = null,Object? missing = null,}) {
  return _then(_PlaylistEntry(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as CatalogFile,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MusicMetadata?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PlaylistEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogFileCopyWith<$Res> get file {
  
  return $CatalogFileCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}/// Create a copy of PlaylistEntry
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
mixin _$PlaylistView {

 Playlist get playlist; List<PlaylistEntry> get entries;
/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistViewCopyWith<PlaylistView> get copyWith => _$PlaylistViewCopyWithImpl<PlaylistView>(this as PlaylistView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistView&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other.entries, entries));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'PlaylistView(playlist: $playlist, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $PlaylistViewCopyWith<$Res>  {
  factory $PlaylistViewCopyWith(PlaylistView value, $Res Function(PlaylistView) _then) = _$PlaylistViewCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<PlaylistEntry> entries
});


$PlaylistCopyWith<$Res> get playlist;

}
/// @nodoc
class _$PlaylistViewCopyWithImpl<$Res>
    implements $PlaylistViewCopyWith<$Res> {
  _$PlaylistViewCopyWithImpl(this._self, this._then);

  final PlaylistView _self;
  final $Res Function(PlaylistView) _then;

/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playlist = null,Object? entries = null,}) {
  return _then(_self.copyWith(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<PlaylistEntry>,
  ));
}
/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res> get playlist {
  
  return $PlaylistCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistView].
extension PlaylistViewPatterns on PlaylistView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistView value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistView value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Playlist playlist,  List<PlaylistEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistView() when $default != null:
return $default(_that.playlist,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Playlist playlist,  List<PlaylistEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _PlaylistView():
return $default(_that.playlist,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Playlist playlist,  List<PlaylistEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistView() when $default != null:
return $default(_that.playlist,_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _PlaylistView implements PlaylistView {
  const _PlaylistView({required this.playlist, required final  List<PlaylistEntry> entries}): _entries = entries;
  

@override final  Playlist playlist;
 final  List<PlaylistEntry> _entries;
@override List<PlaylistEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistViewCopyWith<_PlaylistView> get copyWith => __$PlaylistViewCopyWithImpl<_PlaylistView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistView&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'PlaylistView(playlist: $playlist, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$PlaylistViewCopyWith<$Res> implements $PlaylistViewCopyWith<$Res> {
  factory _$PlaylistViewCopyWith(_PlaylistView value, $Res Function(_PlaylistView) _then) = __$PlaylistViewCopyWithImpl;
@override @useResult
$Res call({
 Playlist playlist, List<PlaylistEntry> entries
});


@override $PlaylistCopyWith<$Res> get playlist;

}
/// @nodoc
class __$PlaylistViewCopyWithImpl<$Res>
    implements _$PlaylistViewCopyWith<$Res> {
  __$PlaylistViewCopyWithImpl(this._self, this._then);

  final _PlaylistView _self;
  final $Res Function(_PlaylistView) _then;

/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? entries = null,}) {
  return _then(_PlaylistView(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<PlaylistEntry>,
  ));
}

/// Create a copy of PlaylistView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCopyWith<$Res> get playlist {
  
  return $PlaylistCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}

// dart format on
