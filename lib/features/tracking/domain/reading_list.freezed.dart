// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingProgress {

 String get readingListUuid; String get itemUuid; ReadingTargetKind get targetKind; ReadingState get state; int? get currentIssue; int? get totalIssues;
/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressCopyWith<ReadingProgress> get copyWith => _$ReadingProgressCopyWithImpl<ReadingProgress>(this as ReadingProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgress&&(identical(other.readingListUuid, readingListUuid) || other.readingListUuid == readingListUuid)&&(identical(other.itemUuid, itemUuid) || other.itemUuid == itemUuid)&&(identical(other.targetKind, targetKind) || other.targetKind == targetKind)&&(identical(other.state, state) || other.state == state)&&(identical(other.currentIssue, currentIssue) || other.currentIssue == currentIssue)&&(identical(other.totalIssues, totalIssues) || other.totalIssues == totalIssues));
}


@override
int get hashCode => Object.hash(runtimeType,readingListUuid,itemUuid,targetKind,state,currentIssue,totalIssues);

@override
String toString() {
  return 'ReadingProgress(readingListUuid: $readingListUuid, itemUuid: $itemUuid, targetKind: $targetKind, state: $state, currentIssue: $currentIssue, totalIssues: $totalIssues)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressCopyWith<$Res>  {
  factory $ReadingProgressCopyWith(ReadingProgress value, $Res Function(ReadingProgress) _then) = _$ReadingProgressCopyWithImpl;
@useResult
$Res call({
 String readingListUuid, String itemUuid, ReadingTargetKind targetKind, ReadingState state, int? currentIssue, int? totalIssues
});




}
/// @nodoc
class _$ReadingProgressCopyWithImpl<$Res>
    implements $ReadingProgressCopyWith<$Res> {
  _$ReadingProgressCopyWithImpl(this._self, this._then);

  final ReadingProgress _self;
  final $Res Function(ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readingListUuid = null,Object? itemUuid = null,Object? targetKind = null,Object? state = null,Object? currentIssue = freezed,Object? totalIssues = freezed,}) {
  return _then(_self.copyWith(
readingListUuid: null == readingListUuid ? _self.readingListUuid : readingListUuid // ignore: cast_nullable_to_non_nullable
as String,itemUuid: null == itemUuid ? _self.itemUuid : itemUuid // ignore: cast_nullable_to_non_nullable
as String,targetKind: null == targetKind ? _self.targetKind : targetKind // ignore: cast_nullable_to_non_nullable
as ReadingTargetKind,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ReadingState,currentIssue: freezed == currentIssue ? _self.currentIssue : currentIssue // ignore: cast_nullable_to_non_nullable
as int?,totalIssues: freezed == totalIssues ? _self.totalIssues : totalIssues // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingProgress].
extension ReadingProgressPatterns on ReadingProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingProgress value)  $default,){
final _that = this;
switch (_that) {
case _ReadingProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingProgress value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String readingListUuid,  String itemUuid,  ReadingTargetKind targetKind,  ReadingState state,  int? currentIssue,  int? totalIssues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
return $default(_that.readingListUuid,_that.itemUuid,_that.targetKind,_that.state,_that.currentIssue,_that.totalIssues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String readingListUuid,  String itemUuid,  ReadingTargetKind targetKind,  ReadingState state,  int? currentIssue,  int? totalIssues)  $default,) {final _that = this;
switch (_that) {
case _ReadingProgress():
return $default(_that.readingListUuid,_that.itemUuid,_that.targetKind,_that.state,_that.currentIssue,_that.totalIssues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String readingListUuid,  String itemUuid,  ReadingTargetKind targetKind,  ReadingState state,  int? currentIssue,  int? totalIssues)?  $default,) {final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
return $default(_that.readingListUuid,_that.itemUuid,_that.targetKind,_that.state,_that.currentIssue,_that.totalIssues);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingProgress extends ReadingProgress {
  const _ReadingProgress({required this.readingListUuid, required this.itemUuid, required this.targetKind, required this.state, this.currentIssue, this.totalIssues}): super._();
  

@override final  String readingListUuid;
@override final  String itemUuid;
@override final  ReadingTargetKind targetKind;
@override final  ReadingState state;
@override final  int? currentIssue;
@override final  int? totalIssues;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressCopyWith<_ReadingProgress> get copyWith => __$ReadingProgressCopyWithImpl<_ReadingProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgress&&(identical(other.readingListUuid, readingListUuid) || other.readingListUuid == readingListUuid)&&(identical(other.itemUuid, itemUuid) || other.itemUuid == itemUuid)&&(identical(other.targetKind, targetKind) || other.targetKind == targetKind)&&(identical(other.state, state) || other.state == state)&&(identical(other.currentIssue, currentIssue) || other.currentIssue == currentIssue)&&(identical(other.totalIssues, totalIssues) || other.totalIssues == totalIssues));
}


@override
int get hashCode => Object.hash(runtimeType,readingListUuid,itemUuid,targetKind,state,currentIssue,totalIssues);

@override
String toString() {
  return 'ReadingProgress(readingListUuid: $readingListUuid, itemUuid: $itemUuid, targetKind: $targetKind, state: $state, currentIssue: $currentIssue, totalIssues: $totalIssues)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressCopyWith<$Res> implements $ReadingProgressCopyWith<$Res> {
  factory _$ReadingProgressCopyWith(_ReadingProgress value, $Res Function(_ReadingProgress) _then) = __$ReadingProgressCopyWithImpl;
@override @useResult
$Res call({
 String readingListUuid, String itemUuid, ReadingTargetKind targetKind, ReadingState state, int? currentIssue, int? totalIssues
});




}
/// @nodoc
class __$ReadingProgressCopyWithImpl<$Res>
    implements _$ReadingProgressCopyWith<$Res> {
  __$ReadingProgressCopyWithImpl(this._self, this._then);

  final _ReadingProgress _self;
  final $Res Function(_ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readingListUuid = null,Object? itemUuid = null,Object? targetKind = null,Object? state = null,Object? currentIssue = freezed,Object? totalIssues = freezed,}) {
  return _then(_ReadingProgress(
readingListUuid: null == readingListUuid ? _self.readingListUuid : readingListUuid // ignore: cast_nullable_to_non_nullable
as String,itemUuid: null == itemUuid ? _self.itemUuid : itemUuid // ignore: cast_nullable_to_non_nullable
as String,targetKind: null == targetKind ? _self.targetKind : targetKind // ignore: cast_nullable_to_non_nullable
as ReadingTargetKind,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ReadingState,currentIssue: freezed == currentIssue ? _self.currentIssue : currentIssue // ignore: cast_nullable_to_non_nullable
as int?,totalIssues: freezed == totalIssues ? _self.totalIssues : totalIssues // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$ReadingList {

 String get uuid; String get name; List<ReadingProgress> get items;
/// Create a copy of ReadingList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingListCopyWith<ReadingList> get copyWith => _$ReadingListCopyWithImpl<ReadingList>(this as ReadingList, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingList&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ReadingList(uuid: $uuid, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class $ReadingListCopyWith<$Res>  {
  factory $ReadingListCopyWith(ReadingList value, $Res Function(ReadingList) _then) = _$ReadingListCopyWithImpl;
@useResult
$Res call({
 String uuid, String name, List<ReadingProgress> items
});




}
/// @nodoc
class _$ReadingListCopyWithImpl<$Res>
    implements $ReadingListCopyWith<$Res> {
  _$ReadingListCopyWithImpl(this._self, this._then);

  final ReadingList _self;
  final $Res Function(ReadingList) _then;

/// Create a copy of ReadingList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? items = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReadingProgress>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingList].
extension ReadingListPatterns on ReadingList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingList value)  $default,){
final _that = this;
switch (_that) {
case _ReadingList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingList value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name,  List<ReadingProgress> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingList() when $default != null:
return $default(_that.uuid,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name,  List<ReadingProgress> items)  $default,) {final _that = this;
switch (_that) {
case _ReadingList():
return $default(_that.uuid,_that.name,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name,  List<ReadingProgress> items)?  $default,) {final _that = this;
switch (_that) {
case _ReadingList() when $default != null:
return $default(_that.uuid,_that.name,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingList extends ReadingList {
  const _ReadingList({required this.uuid, required this.name, final  List<ReadingProgress> items = const <ReadingProgress>[]}): _items = items,super._();
  

@override final  String uuid;
@override final  String name;
 final  List<ReadingProgress> _items;
@override@JsonKey() List<ReadingProgress> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ReadingList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingListCopyWith<_ReadingList> get copyWith => __$ReadingListCopyWithImpl<_ReadingList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingList&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,name,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ReadingList(uuid: $uuid, name: $name, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ReadingListCopyWith<$Res> implements $ReadingListCopyWith<$Res> {
  factory _$ReadingListCopyWith(_ReadingList value, $Res Function(_ReadingList) _then) = __$ReadingListCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name, List<ReadingProgress> items
});




}
/// @nodoc
class __$ReadingListCopyWithImpl<$Res>
    implements _$ReadingListCopyWith<$Res> {
  __$ReadingListCopyWithImpl(this._self, this._then);

  final _ReadingList _self;
  final $Res Function(_ReadingList) _then;

/// Create a copy of ReadingList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? items = null,}) {
  return _then(_ReadingList(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReadingProgress>,
  ));
}


}

// dart format on
