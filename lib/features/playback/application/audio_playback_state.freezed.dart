// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_playback_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioPlaybackState {

/// The tracks next and previous move through: the list the current one
/// was started from, active audio files only.
 List<CatalogFile> get queue;/// Where in [queue] the loaded track is, or -1 when nothing is loaded.
 int get index;/// Whether it is playing right now.
 bool get playing;/// How far into the track it is.
 Duration get position;/// How long the track is, once the engine knows.
 Duration? get duration;/// The loaded track's front cover, when it has one.
 Uint8List? get cover;/// The name of the last track that could not be opened and was skipped.
 String? get skippedName;/// Why nothing could be played, when nothing left in the queue opened.
 Failure? get failure;
/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioPlaybackStateCopyWith<AudioPlaybackState> get copyWith => _$AudioPlaybackStateCopyWithImpl<AudioPlaybackState>(this as AudioPlaybackState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioPlaybackState&&const DeepCollectionEquality().equals(other.queue, queue)&&(identical(other.index, index) || other.index == index)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.cover, cover)&&(identical(other.skippedName, skippedName) || other.skippedName == skippedName)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(queue),index,playing,position,duration,const DeepCollectionEquality().hash(cover),skippedName,failure);

@override
String toString() {
  return 'AudioPlaybackState(queue: $queue, index: $index, playing: $playing, position: $position, duration: $duration, cover: $cover, skippedName: $skippedName, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AudioPlaybackStateCopyWith<$Res>  {
  factory $AudioPlaybackStateCopyWith(AudioPlaybackState value, $Res Function(AudioPlaybackState) _then) = _$AudioPlaybackStateCopyWithImpl;
@useResult
$Res call({
 List<CatalogFile> queue, int index, bool playing, Duration position, Duration? duration, Uint8List? cover, String? skippedName, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$AudioPlaybackStateCopyWithImpl<$Res>
    implements $AudioPlaybackStateCopyWith<$Res> {
  _$AudioPlaybackStateCopyWithImpl(this._self, this._then);

  final AudioPlaybackState _self;
  final $Res Function(AudioPlaybackState) _then;

/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? index = null,Object? playing = null,Object? position = null,Object? duration = freezed,Object? cover = freezed,Object? skippedName = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<CatalogFile>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,skippedName: freezed == skippedName ? _self.skippedName : skippedName // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [AudioPlaybackState].
extension AudioPlaybackStatePatterns on AudioPlaybackState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioPlaybackState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioPlaybackState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioPlaybackState value)  $default,){
final _that = this;
switch (_that) {
case _AudioPlaybackState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioPlaybackState value)?  $default,){
final _that = this;
switch (_that) {
case _AudioPlaybackState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CatalogFile> queue,  int index,  bool playing,  Duration position,  Duration? duration,  Uint8List? cover,  String? skippedName,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioPlaybackState() when $default != null:
return $default(_that.queue,_that.index,_that.playing,_that.position,_that.duration,_that.cover,_that.skippedName,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CatalogFile> queue,  int index,  bool playing,  Duration position,  Duration? duration,  Uint8List? cover,  String? skippedName,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _AudioPlaybackState():
return $default(_that.queue,_that.index,_that.playing,_that.position,_that.duration,_that.cover,_that.skippedName,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CatalogFile> queue,  int index,  bool playing,  Duration position,  Duration? duration,  Uint8List? cover,  String? skippedName,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _AudioPlaybackState() when $default != null:
return $default(_that.queue,_that.index,_that.playing,_that.position,_that.duration,_that.cover,_that.skippedName,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AudioPlaybackState extends AudioPlaybackState {
  const _AudioPlaybackState({final  List<CatalogFile> queue = const <CatalogFile>[], this.index = -1, this.playing = false, this.position = Duration.zero, this.duration, this.cover, this.skippedName, this.failure}): _queue = queue,super._();
  

/// The tracks next and previous move through: the list the current one
/// was started from, active audio files only.
 final  List<CatalogFile> _queue;
/// The tracks next and previous move through: the list the current one
/// was started from, active audio files only.
@override@JsonKey() List<CatalogFile> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

/// Where in [queue] the loaded track is, or -1 when nothing is loaded.
@override@JsonKey() final  int index;
/// Whether it is playing right now.
@override@JsonKey() final  bool playing;
/// How far into the track it is.
@override@JsonKey() final  Duration position;
/// How long the track is, once the engine knows.
@override final  Duration? duration;
/// The loaded track's front cover, when it has one.
@override final  Uint8List? cover;
/// The name of the last track that could not be opened and was skipped.
@override final  String? skippedName;
/// Why nothing could be played, when nothing left in the queue opened.
@override final  Failure? failure;

/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioPlaybackStateCopyWith<_AudioPlaybackState> get copyWith => __$AudioPlaybackStateCopyWithImpl<_AudioPlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioPlaybackState&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.index, index) || other.index == index)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.cover, cover)&&(identical(other.skippedName, skippedName) || other.skippedName == skippedName)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue),index,playing,position,duration,const DeepCollectionEquality().hash(cover),skippedName,failure);

@override
String toString() {
  return 'AudioPlaybackState(queue: $queue, index: $index, playing: $playing, position: $position, duration: $duration, cover: $cover, skippedName: $skippedName, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AudioPlaybackStateCopyWith<$Res> implements $AudioPlaybackStateCopyWith<$Res> {
  factory _$AudioPlaybackStateCopyWith(_AudioPlaybackState value, $Res Function(_AudioPlaybackState) _then) = __$AudioPlaybackStateCopyWithImpl;
@override @useResult
$Res call({
 List<CatalogFile> queue, int index, bool playing, Duration position, Duration? duration, Uint8List? cover, String? skippedName, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$AudioPlaybackStateCopyWithImpl<$Res>
    implements _$AudioPlaybackStateCopyWith<$Res> {
  __$AudioPlaybackStateCopyWithImpl(this._self, this._then);

  final _AudioPlaybackState _self;
  final $Res Function(_AudioPlaybackState) _then;

/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? index = null,Object? playing = null,Object? position = null,Object? duration = freezed,Object? cover = freezed,Object? skippedName = freezed,Object? failure = freezed,}) {
  return _then(_AudioPlaybackState(
queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<CatalogFile>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,skippedName: freezed == skippedName ? _self.skippedName : skippedName // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of AudioPlaybackState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
