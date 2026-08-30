// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_enrichment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistImage {

 String get artistName;/// Where the bytes are on disk, absolute.
///
/// The core stores this relative to its own image cache and resolves it
/// on read, because that directory is the core's configuration and this
/// application has no way to learn it. Read straight off disk, which is
/// how every other media byte reaches this application (Operations §3).
 String get path;/// The page the image came from, for attribution. Wikimedia Commons
/// licences require it, and an image whose provenance was lost cannot
/// lawfully be shown.
 String? get sourceUrl;
/// Create a copy of ArtistImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistImageCopyWith<ArtistImage> get copyWith => _$ArtistImageCopyWithImpl<ArtistImage>(this as ArtistImage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistImage&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.path, path) || other.path == path)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl));
}


@override
int get hashCode => Object.hash(runtimeType,artistName,path,sourceUrl);

@override
String toString() {
  return 'ArtistImage(artistName: $artistName, path: $path, sourceUrl: $sourceUrl)';
}


}

/// @nodoc
abstract mixin class $ArtistImageCopyWith<$Res>  {
  factory $ArtistImageCopyWith(ArtistImage value, $Res Function(ArtistImage) _then) = _$ArtistImageCopyWithImpl;
@useResult
$Res call({
 String artistName, String path, String? sourceUrl
});




}
/// @nodoc
class _$ArtistImageCopyWithImpl<$Res>
    implements $ArtistImageCopyWith<$Res> {
  _$ArtistImageCopyWithImpl(this._self, this._then);

  final ArtistImage _self;
  final $Res Function(ArtistImage) _then;

/// Create a copy of ArtistImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistName = null,Object? path = null,Object? sourceUrl = freezed,}) {
  return _then(_self.copyWith(
artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistImage].
extension ArtistImagePatterns on ArtistImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistImage value)  $default,){
final _that = this;
switch (_that) {
case _ArtistImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistImage value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String artistName,  String path,  String? sourceUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistImage() when $default != null:
return $default(_that.artistName,_that.path,_that.sourceUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String artistName,  String path,  String? sourceUrl)  $default,) {final _that = this;
switch (_that) {
case _ArtistImage():
return $default(_that.artistName,_that.path,_that.sourceUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String artistName,  String path,  String? sourceUrl)?  $default,) {final _that = this;
switch (_that) {
case _ArtistImage() when $default != null:
return $default(_that.artistName,_that.path,_that.sourceUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistImage implements ArtistImage {
  const _ArtistImage({required this.artistName, required this.path, this.sourceUrl});
  

@override final  String artistName;
/// Where the bytes are on disk, absolute.
///
/// The core stores this relative to its own image cache and resolves it
/// on read, because that directory is the core's configuration and this
/// application has no way to learn it. Read straight off disk, which is
/// how every other media byte reaches this application (Operations §3).
@override final  String path;
/// The page the image came from, for attribution. Wikimedia Commons
/// licences require it, and an image whose provenance was lost cannot
/// lawfully be shown.
@override final  String? sourceUrl;

/// Create a copy of ArtistImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistImageCopyWith<_ArtistImage> get copyWith => __$ArtistImageCopyWithImpl<_ArtistImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistImage&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.path, path) || other.path == path)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl));
}


@override
int get hashCode => Object.hash(runtimeType,artistName,path,sourceUrl);

@override
String toString() {
  return 'ArtistImage(artistName: $artistName, path: $path, sourceUrl: $sourceUrl)';
}


}

/// @nodoc
abstract mixin class _$ArtistImageCopyWith<$Res> implements $ArtistImageCopyWith<$Res> {
  factory _$ArtistImageCopyWith(_ArtistImage value, $Res Function(_ArtistImage) _then) = __$ArtistImageCopyWithImpl;
@override @useResult
$Res call({
 String artistName, String path, String? sourceUrl
});




}
/// @nodoc
class __$ArtistImageCopyWithImpl<$Res>
    implements _$ArtistImageCopyWith<$Res> {
  __$ArtistImageCopyWithImpl(this._self, this._then);

  final _ArtistImage _self;
  final $Res Function(_ArtistImage) _then;

/// Create a copy of ArtistImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artistName = null,Object? path = null,Object? sourceUrl = freezed,}) {
  return _then(_ArtistImage(
artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TrackLyrics {

/// The unsynchronized text, as lines.
///
/// Split here rather than in the presentation layer so nothing rendering
/// them has to agree about what a line is.
 List<String> get lines;/// The timed lines, when the provider had them.
///
/// Parsed at the boundary like [lines], so nothing rendering them has to
/// know what LRC is — and so a malformed document costs one track its
/// timing rather than throwing inside a widget mid-frame.
 SyncedLyrics? get synced;/// Which service answered, for attribution.
 String? get source;
/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackLyricsCopyWith<TrackLyrics> get copyWith => _$TrackLyricsCopyWithImpl<TrackLyrics>(this as TrackLyrics, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackLyrics&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(lines),synced,source);

@override
String toString() {
  return 'TrackLyrics(lines: $lines, synced: $synced, source: $source)';
}


}

/// @nodoc
abstract mixin class $TrackLyricsCopyWith<$Res>  {
  factory $TrackLyricsCopyWith(TrackLyrics value, $Res Function(TrackLyrics) _then) = _$TrackLyricsCopyWithImpl;
@useResult
$Res call({
 List<String> lines, SyncedLyrics? synced, String? source
});




}
/// @nodoc
class _$TrackLyricsCopyWithImpl<$Res>
    implements $TrackLyricsCopyWith<$Res> {
  _$TrackLyricsCopyWithImpl(this._self, this._then);

  final TrackLyrics _self;
  final $Res Function(TrackLyrics) _then;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,Object? synced = freezed,Object? source = freezed,}) {
  return _then(_self.copyWith(
lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,synced: freezed == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as SyncedLyrics?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackLyrics].
extension TrackLyricsPatterns on TrackLyrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackLyrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackLyrics value)  $default,){
final _that = this;
switch (_that) {
case _TrackLyrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackLyrics value)?  $default,){
final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> lines,  SyncedLyrics? synced,  String? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
return $default(_that.lines,_that.synced,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> lines,  SyncedLyrics? synced,  String? source)  $default,) {final _that = this;
switch (_that) {
case _TrackLyrics():
return $default(_that.lines,_that.synced,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> lines,  SyncedLyrics? synced,  String? source)?  $default,) {final _that = this;
switch (_that) {
case _TrackLyrics() when $default != null:
return $default(_that.lines,_that.synced,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _TrackLyrics implements TrackLyrics {
  const _TrackLyrics({required final  List<String> lines, this.synced, this.source}): _lines = lines;
  

/// The unsynchronized text, as lines.
///
/// Split here rather than in the presentation layer so nothing rendering
/// them has to agree about what a line is.
 final  List<String> _lines;
/// The unsynchronized text, as lines.
///
/// Split here rather than in the presentation layer so nothing rendering
/// them has to agree about what a line is.
@override List<String> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// The timed lines, when the provider had them.
///
/// Parsed at the boundary like [lines], so nothing rendering them has to
/// know what LRC is — and so a malformed document costs one track its
/// timing rather than throwing inside a widget mid-frame.
@override final  SyncedLyrics? synced;
/// Which service answered, for attribution.
@override final  String? source;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackLyricsCopyWith<_TrackLyrics> get copyWith => __$TrackLyricsCopyWithImpl<_TrackLyrics>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackLyrics&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_lines),synced,source);

@override
String toString() {
  return 'TrackLyrics(lines: $lines, synced: $synced, source: $source)';
}


}

/// @nodoc
abstract mixin class _$TrackLyricsCopyWith<$Res> implements $TrackLyricsCopyWith<$Res> {
  factory _$TrackLyricsCopyWith(_TrackLyrics value, $Res Function(_TrackLyrics) _then) = __$TrackLyricsCopyWithImpl;
@override @useResult
$Res call({
 List<String> lines, SyncedLyrics? synced, String? source
});




}
/// @nodoc
class __$TrackLyricsCopyWithImpl<$Res>
    implements _$TrackLyricsCopyWith<$Res> {
  __$TrackLyricsCopyWithImpl(this._self, this._then);

  final _TrackLyrics _self;
  final $Res Function(_TrackLyrics) _then;

/// Create a copy of TrackLyrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lines = null,Object? synced = freezed,Object? source = freezed,}) {
  return _then(_TrackLyrics(
lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,synced: freezed == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as SyncedLyrics?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TrackEnrichment {

 ArtistImage? get artistImage; TrackLyrics? get lyrics;
/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackEnrichmentCopyWith<TrackEnrichment> get copyWith => _$TrackEnrichmentCopyWithImpl<TrackEnrichment>(this as TrackEnrichment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackEnrichment&&(identical(other.artistImage, artistImage) || other.artistImage == artistImage)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics));
}


@override
int get hashCode => Object.hash(runtimeType,artistImage,lyrics);

@override
String toString() {
  return 'TrackEnrichment(artistImage: $artistImage, lyrics: $lyrics)';
}


}

/// @nodoc
abstract mixin class $TrackEnrichmentCopyWith<$Res>  {
  factory $TrackEnrichmentCopyWith(TrackEnrichment value, $Res Function(TrackEnrichment) _then) = _$TrackEnrichmentCopyWithImpl;
@useResult
$Res call({
 ArtistImage? artistImage, TrackLyrics? lyrics
});


$ArtistImageCopyWith<$Res>? get artistImage;$TrackLyricsCopyWith<$Res>? get lyrics;

}
/// @nodoc
class _$TrackEnrichmentCopyWithImpl<$Res>
    implements $TrackEnrichmentCopyWith<$Res> {
  _$TrackEnrichmentCopyWithImpl(this._self, this._then);

  final TrackEnrichment _self;
  final $Res Function(TrackEnrichment) _then;

/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistImage = freezed,Object? lyrics = freezed,}) {
  return _then(_self.copyWith(
artistImage: freezed == artistImage ? _self.artistImage : artistImage // ignore: cast_nullable_to_non_nullable
as ArtistImage?,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as TrackLyrics?,
  ));
}
/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistImageCopyWith<$Res>? get artistImage {
    if (_self.artistImage == null) {
    return null;
  }

  return $ArtistImageCopyWith<$Res>(_self.artistImage!, (value) {
    return _then(_self.copyWith(artistImage: value));
  });
}/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackLyricsCopyWith<$Res>? get lyrics {
    if (_self.lyrics == null) {
    return null;
  }

  return $TrackLyricsCopyWith<$Res>(_self.lyrics!, (value) {
    return _then(_self.copyWith(lyrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackEnrichment].
extension TrackEnrichmentPatterns on TrackEnrichment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackEnrichment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackEnrichment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackEnrichment value)  $default,){
final _that = this;
switch (_that) {
case _TrackEnrichment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackEnrichment value)?  $default,){
final _that = this;
switch (_that) {
case _TrackEnrichment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArtistImage? artistImage,  TrackLyrics? lyrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackEnrichment() when $default != null:
return $default(_that.artistImage,_that.lyrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArtistImage? artistImage,  TrackLyrics? lyrics)  $default,) {final _that = this;
switch (_that) {
case _TrackEnrichment():
return $default(_that.artistImage,_that.lyrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArtistImage? artistImage,  TrackLyrics? lyrics)?  $default,) {final _that = this;
switch (_that) {
case _TrackEnrichment() when $default != null:
return $default(_that.artistImage,_that.lyrics);case _:
  return null;

}
}

}

/// @nodoc


class _TrackEnrichment extends TrackEnrichment {
  const _TrackEnrichment({this.artistImage, this.lyrics}): super._();
  

@override final  ArtistImage? artistImage;
@override final  TrackLyrics? lyrics;

/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackEnrichmentCopyWith<_TrackEnrichment> get copyWith => __$TrackEnrichmentCopyWithImpl<_TrackEnrichment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackEnrichment&&(identical(other.artistImage, artistImage) || other.artistImage == artistImage)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics));
}


@override
int get hashCode => Object.hash(runtimeType,artistImage,lyrics);

@override
String toString() {
  return 'TrackEnrichment(artistImage: $artistImage, lyrics: $lyrics)';
}


}

/// @nodoc
abstract mixin class _$TrackEnrichmentCopyWith<$Res> implements $TrackEnrichmentCopyWith<$Res> {
  factory _$TrackEnrichmentCopyWith(_TrackEnrichment value, $Res Function(_TrackEnrichment) _then) = __$TrackEnrichmentCopyWithImpl;
@override @useResult
$Res call({
 ArtistImage? artistImage, TrackLyrics? lyrics
});


@override $ArtistImageCopyWith<$Res>? get artistImage;@override $TrackLyricsCopyWith<$Res>? get lyrics;

}
/// @nodoc
class __$TrackEnrichmentCopyWithImpl<$Res>
    implements _$TrackEnrichmentCopyWith<$Res> {
  __$TrackEnrichmentCopyWithImpl(this._self, this._then);

  final _TrackEnrichment _self;
  final $Res Function(_TrackEnrichment) _then;

/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artistImage = freezed,Object? lyrics = freezed,}) {
  return _then(_TrackEnrichment(
artistImage: freezed == artistImage ? _self.artistImage : artistImage // ignore: cast_nullable_to_non_nullable
as ArtistImage?,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as TrackLyrics?,
  ));
}

/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistImageCopyWith<$Res>? get artistImage {
    if (_self.artistImage == null) {
    return null;
  }

  return $ArtistImageCopyWith<$Res>(_self.artistImage!, (value) {
    return _then(_self.copyWith(artistImage: value));
  });
}/// Create a copy of TrackEnrichment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackLyricsCopyWith<$Res>? get lyrics {
    if (_self.lyrics == null) {
    return null;
  }

  return $TrackLyricsCopyWith<$Res>(_self.lyrics!, (value) {
    return _then(_self.copyWith(lyrics: value));
  });
}
}

/// @nodoc
mixin _$EnrichmentReport {

 int get considered; int get found; int get notFound; int get rejected; int get failed; int get skipped;/// How many files still have something outstanding once this run
/// finished.
///
/// What makes a batched sweep showable: a caller asking for a few at a
/// time has no other way to know whether it is near the end or nowhere
/// near it. Zero is how it knows to stop asking.
 int get remaining;
/// Create a copy of EnrichmentReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrichmentReportCopyWith<EnrichmentReport> get copyWith => _$EnrichmentReportCopyWithImpl<EnrichmentReport>(this as EnrichmentReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrichmentReport&&(identical(other.considered, considered) || other.considered == considered)&&(identical(other.found, found) || other.found == found)&&(identical(other.notFound, notFound) || other.notFound == notFound)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}


@override
int get hashCode => Object.hash(runtimeType,considered,found,notFound,rejected,failed,skipped,remaining);

@override
String toString() {
  return 'EnrichmentReport(considered: $considered, found: $found, notFound: $notFound, rejected: $rejected, failed: $failed, skipped: $skipped, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class $EnrichmentReportCopyWith<$Res>  {
  factory $EnrichmentReportCopyWith(EnrichmentReport value, $Res Function(EnrichmentReport) _then) = _$EnrichmentReportCopyWithImpl;
@useResult
$Res call({
 int considered, int found, int notFound, int rejected, int failed, int skipped, int remaining
});




}
/// @nodoc
class _$EnrichmentReportCopyWithImpl<$Res>
    implements $EnrichmentReportCopyWith<$Res> {
  _$EnrichmentReportCopyWithImpl(this._self, this._then);

  final EnrichmentReport _self;
  final $Res Function(EnrichmentReport) _then;

/// Create a copy of EnrichmentReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? considered = null,Object? found = null,Object? notFound = null,Object? rejected = null,Object? failed = null,Object? skipped = null,Object? remaining = null,}) {
  return _then(_self.copyWith(
considered: null == considered ? _self.considered : considered // ignore: cast_nullable_to_non_nullable
as int,found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as int,notFound: null == notFound ? _self.notFound : notFound // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrichmentReport].
extension EnrichmentReportPatterns on EnrichmentReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrichmentReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrichmentReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrichmentReport value)  $default,){
final _that = this;
switch (_that) {
case _EnrichmentReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrichmentReport value)?  $default,){
final _that = this;
switch (_that) {
case _EnrichmentReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int considered,  int found,  int notFound,  int rejected,  int failed,  int skipped,  int remaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrichmentReport() when $default != null:
return $default(_that.considered,_that.found,_that.notFound,_that.rejected,_that.failed,_that.skipped,_that.remaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int considered,  int found,  int notFound,  int rejected,  int failed,  int skipped,  int remaining)  $default,) {final _that = this;
switch (_that) {
case _EnrichmentReport():
return $default(_that.considered,_that.found,_that.notFound,_that.rejected,_that.failed,_that.skipped,_that.remaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int considered,  int found,  int notFound,  int rejected,  int failed,  int skipped,  int remaining)?  $default,) {final _that = this;
switch (_that) {
case _EnrichmentReport() when $default != null:
return $default(_that.considered,_that.found,_that.notFound,_that.rejected,_that.failed,_that.skipped,_that.remaining);case _:
  return null;

}
}

}

/// @nodoc


class _EnrichmentReport implements EnrichmentReport {
  const _EnrichmentReport({this.considered = 0, this.found = 0, this.notFound = 0, this.rejected = 0, this.failed = 0, this.skipped = 0, this.remaining = 0});
  

@override@JsonKey() final  int considered;
@override@JsonKey() final  int found;
@override@JsonKey() final  int notFound;
@override@JsonKey() final  int rejected;
@override@JsonKey() final  int failed;
@override@JsonKey() final  int skipped;
/// How many files still have something outstanding once this run
/// finished.
///
/// What makes a batched sweep showable: a caller asking for a few at a
/// time has no other way to know whether it is near the end or nowhere
/// near it. Zero is how it knows to stop asking.
@override@JsonKey() final  int remaining;

/// Create a copy of EnrichmentReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrichmentReportCopyWith<_EnrichmentReport> get copyWith => __$EnrichmentReportCopyWithImpl<_EnrichmentReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrichmentReport&&(identical(other.considered, considered) || other.considered == considered)&&(identical(other.found, found) || other.found == found)&&(identical(other.notFound, notFound) || other.notFound == notFound)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}


@override
int get hashCode => Object.hash(runtimeType,considered,found,notFound,rejected,failed,skipped,remaining);

@override
String toString() {
  return 'EnrichmentReport(considered: $considered, found: $found, notFound: $notFound, rejected: $rejected, failed: $failed, skipped: $skipped, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class _$EnrichmentReportCopyWith<$Res> implements $EnrichmentReportCopyWith<$Res> {
  factory _$EnrichmentReportCopyWith(_EnrichmentReport value, $Res Function(_EnrichmentReport) _then) = __$EnrichmentReportCopyWithImpl;
@override @useResult
$Res call({
 int considered, int found, int notFound, int rejected, int failed, int skipped, int remaining
});




}
/// @nodoc
class __$EnrichmentReportCopyWithImpl<$Res>
    implements _$EnrichmentReportCopyWith<$Res> {
  __$EnrichmentReportCopyWithImpl(this._self, this._then);

  final _EnrichmentReport _self;
  final $Res Function(_EnrichmentReport) _then;

/// Create a copy of EnrichmentReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? considered = null,Object? found = null,Object? notFound = null,Object? rejected = null,Object? failed = null,Object? skipped = null,Object? remaining = null,}) {
  return _then(_EnrichmentReport(
considered: null == considered ? _self.considered : considered // ignore: cast_nullable_to_non_nullable
as int,found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as int,notFound: null == notFound ? _self.notFound : notFound // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
