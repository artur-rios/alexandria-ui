// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PreferencesState {

 ThemeMode get themeMode; Locale? get locale; bool get opensPlayerOnPlay; bool get rechecksAtStartup; bool get musicLookupEnabled; String get musicLookupContact; bool get lastChangeUnsaved;
/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreferencesStateCopyWith<PreferencesState> get copyWith => _$PreferencesStateCopyWithImpl<PreferencesState>(this as PreferencesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreferencesState&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.opensPlayerOnPlay, opensPlayerOnPlay) || other.opensPlayerOnPlay == opensPlayerOnPlay)&&(identical(other.rechecksAtStartup, rechecksAtStartup) || other.rechecksAtStartup == rechecksAtStartup)&&(identical(other.musicLookupEnabled, musicLookupEnabled) || other.musicLookupEnabled == musicLookupEnabled)&&(identical(other.musicLookupContact, musicLookupContact) || other.musicLookupContact == musicLookupContact)&&(identical(other.lastChangeUnsaved, lastChangeUnsaved) || other.lastChangeUnsaved == lastChangeUnsaved));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,locale,opensPlayerOnPlay,rechecksAtStartup,musicLookupEnabled,musicLookupContact,lastChangeUnsaved);

@override
String toString() {
  return 'PreferencesState(themeMode: $themeMode, locale: $locale, opensPlayerOnPlay: $opensPlayerOnPlay, rechecksAtStartup: $rechecksAtStartup, musicLookupEnabled: $musicLookupEnabled, musicLookupContact: $musicLookupContact, lastChangeUnsaved: $lastChangeUnsaved)';
}


}

/// @nodoc
abstract mixin class $PreferencesStateCopyWith<$Res>  {
  factory $PreferencesStateCopyWith(PreferencesState value, $Res Function(PreferencesState) _then) = _$PreferencesStateCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode, Locale? locale, bool opensPlayerOnPlay, bool rechecksAtStartup, bool musicLookupEnabled, String musicLookupContact, bool lastChangeUnsaved
});




}
/// @nodoc
class _$PreferencesStateCopyWithImpl<$Res>
    implements $PreferencesStateCopyWith<$Res> {
  _$PreferencesStateCopyWithImpl(this._self, this._then);

  final PreferencesState _self;
  final $Res Function(PreferencesState) _then;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? locale = freezed,Object? opensPlayerOnPlay = null,Object? rechecksAtStartup = null,Object? musicLookupEnabled = null,Object? musicLookupContact = null,Object? lastChangeUnsaved = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as Locale?,opensPlayerOnPlay: null == opensPlayerOnPlay ? _self.opensPlayerOnPlay : opensPlayerOnPlay // ignore: cast_nullable_to_non_nullable
as bool,rechecksAtStartup: null == rechecksAtStartup ? _self.rechecksAtStartup : rechecksAtStartup // ignore: cast_nullable_to_non_nullable
as bool,musicLookupEnabled: null == musicLookupEnabled ? _self.musicLookupEnabled : musicLookupEnabled // ignore: cast_nullable_to_non_nullable
as bool,musicLookupContact: null == musicLookupContact ? _self.musicLookupContact : musicLookupContact // ignore: cast_nullable_to_non_nullable
as String,lastChangeUnsaved: null == lastChangeUnsaved ? _self.lastChangeUnsaved : lastChangeUnsaved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PreferencesState].
extension PreferencesStatePatterns on PreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreferencesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreferencesState value)  $default,){
final _that = this;
switch (_that) {
case _PreferencesState():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreferencesState value)?  $default,){
final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode themeMode,  Locale? locale,  bool opensPlayerOnPlay,  bool rechecksAtStartup,  bool musicLookupEnabled,  String musicLookupContact,  bool lastChangeUnsaved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
return $default(_that.themeMode,_that.locale,_that.opensPlayerOnPlay,_that.rechecksAtStartup,_that.musicLookupEnabled,_that.musicLookupContact,_that.lastChangeUnsaved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode themeMode,  Locale? locale,  bool opensPlayerOnPlay,  bool rechecksAtStartup,  bool musicLookupEnabled,  String musicLookupContact,  bool lastChangeUnsaved)  $default,) {final _that = this;
switch (_that) {
case _PreferencesState():
return $default(_that.themeMode,_that.locale,_that.opensPlayerOnPlay,_that.rechecksAtStartup,_that.musicLookupEnabled,_that.musicLookupContact,_that.lastChangeUnsaved);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode themeMode,  Locale? locale,  bool opensPlayerOnPlay,  bool rechecksAtStartup,  bool musicLookupEnabled,  String musicLookupContact,  bool lastChangeUnsaved)?  $default,) {final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
return $default(_that.themeMode,_that.locale,_that.opensPlayerOnPlay,_that.rechecksAtStartup,_that.musicLookupEnabled,_that.musicLookupContact,_that.lastChangeUnsaved);case _:
  return null;

}
}

}

/// @nodoc


class _PreferencesState implements PreferencesState {
  const _PreferencesState({this.themeMode = ThemeMode.system, this.locale, this.opensPlayerOnPlay = true, this.rechecksAtStartup = true, this.musicLookupEnabled = true, this.musicLookupContact = defaultMusicLookupContact, this.lastChangeUnsaved = false});
  

@override@JsonKey() final  ThemeMode themeMode;
@override final  Locale? locale;
@override@JsonKey() final  bool opensPlayerOnPlay;
@override@JsonKey() final  bool rechecksAtStartup;
@override@JsonKey() final  bool musicLookupEnabled;
@override@JsonKey() final  String musicLookupContact;
@override@JsonKey() final  bool lastChangeUnsaved;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreferencesStateCopyWith<_PreferencesState> get copyWith => __$PreferencesStateCopyWithImpl<_PreferencesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreferencesState&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.opensPlayerOnPlay, opensPlayerOnPlay) || other.opensPlayerOnPlay == opensPlayerOnPlay)&&(identical(other.rechecksAtStartup, rechecksAtStartup) || other.rechecksAtStartup == rechecksAtStartup)&&(identical(other.musicLookupEnabled, musicLookupEnabled) || other.musicLookupEnabled == musicLookupEnabled)&&(identical(other.musicLookupContact, musicLookupContact) || other.musicLookupContact == musicLookupContact)&&(identical(other.lastChangeUnsaved, lastChangeUnsaved) || other.lastChangeUnsaved == lastChangeUnsaved));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,locale,opensPlayerOnPlay,rechecksAtStartup,musicLookupEnabled,musicLookupContact,lastChangeUnsaved);

@override
String toString() {
  return 'PreferencesState(themeMode: $themeMode, locale: $locale, opensPlayerOnPlay: $opensPlayerOnPlay, rechecksAtStartup: $rechecksAtStartup, musicLookupEnabled: $musicLookupEnabled, musicLookupContact: $musicLookupContact, lastChangeUnsaved: $lastChangeUnsaved)';
}


}

/// @nodoc
abstract mixin class _$PreferencesStateCopyWith<$Res> implements $PreferencesStateCopyWith<$Res> {
  factory _$PreferencesStateCopyWith(_PreferencesState value, $Res Function(_PreferencesState) _then) = __$PreferencesStateCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode themeMode, Locale? locale, bool opensPlayerOnPlay, bool rechecksAtStartup, bool musicLookupEnabled, String musicLookupContact, bool lastChangeUnsaved
});




}
/// @nodoc
class __$PreferencesStateCopyWithImpl<$Res>
    implements _$PreferencesStateCopyWith<$Res> {
  __$PreferencesStateCopyWithImpl(this._self, this._then);

  final _PreferencesState _self;
  final $Res Function(_PreferencesState) _then;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? locale = freezed,Object? opensPlayerOnPlay = null,Object? rechecksAtStartup = null,Object? musicLookupEnabled = null,Object? musicLookupContact = null,Object? lastChangeUnsaved = null,}) {
  return _then(_PreferencesState(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as Locale?,opensPlayerOnPlay: null == opensPlayerOnPlay ? _self.opensPlayerOnPlay : opensPlayerOnPlay // ignore: cast_nullable_to_non_nullable
as bool,rechecksAtStartup: null == rechecksAtStartup ? _self.rechecksAtStartup : rechecksAtStartup // ignore: cast_nullable_to_non_nullable
as bool,musicLookupEnabled: null == musicLookupEnabled ? _self.musicLookupEnabled : musicLookupEnabled // ignore: cast_nullable_to_non_nullable
as bool,musicLookupContact: null == musicLookupContact ? _self.musicLookupContact : musicLookupContact // ignore: cast_nullable_to_non_nullable
as String,lastChangeUnsaved: null == lastChangeUnsaved ? _self.lastChangeUnsaved : lastChangeUnsaved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
