// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'window_geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WindowGeometry {

 double get left; double get top; double get width; double get height;
/// Create a copy of WindowGeometry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WindowGeometryCopyWith<WindowGeometry> get copyWith => _$WindowGeometryCopyWithImpl<WindowGeometry>(this as WindowGeometry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WindowGeometry&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,left,top,width,height);

@override
String toString() {
  return 'WindowGeometry(left: $left, top: $top, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $WindowGeometryCopyWith<$Res>  {
  factory $WindowGeometryCopyWith(WindowGeometry value, $Res Function(WindowGeometry) _then) = _$WindowGeometryCopyWithImpl;
@useResult
$Res call({
 double left, double top, double width, double height
});




}
/// @nodoc
class _$WindowGeometryCopyWithImpl<$Res>
    implements $WindowGeometryCopyWith<$Res> {
  _$WindowGeometryCopyWithImpl(this._self, this._then);

  final WindowGeometry _self;
  final $Res Function(WindowGeometry) _then;

/// Create a copy of WindowGeometry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WindowGeometry].
extension WindowGeometryPatterns on WindowGeometry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WindowGeometry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WindowGeometry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WindowGeometry value)  $default,){
final _that = this;
switch (_that) {
case _WindowGeometry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WindowGeometry value)?  $default,){
final _that = this;
switch (_that) {
case _WindowGeometry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double left,  double top,  double width,  double height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WindowGeometry() when $default != null:
return $default(_that.left,_that.top,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double left,  double top,  double width,  double height)  $default,) {final _that = this;
switch (_that) {
case _WindowGeometry():
return $default(_that.left,_that.top,_that.width,_that.height);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double left,  double top,  double width,  double height)?  $default,) {final _that = this;
switch (_that) {
case _WindowGeometry() when $default != null:
return $default(_that.left,_that.top,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _WindowGeometry extends WindowGeometry {
  const _WindowGeometry({required this.left, required this.top, required this.width, required this.height}): super._();
  

@override final  double left;
@override final  double top;
@override final  double width;
@override final  double height;

/// Create a copy of WindowGeometry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WindowGeometryCopyWith<_WindowGeometry> get copyWith => __$WindowGeometryCopyWithImpl<_WindowGeometry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WindowGeometry&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,left,top,width,height);

@override
String toString() {
  return 'WindowGeometry(left: $left, top: $top, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$WindowGeometryCopyWith<$Res> implements $WindowGeometryCopyWith<$Res> {
  factory _$WindowGeometryCopyWith(_WindowGeometry value, $Res Function(_WindowGeometry) _then) = __$WindowGeometryCopyWithImpl;
@override @useResult
$Res call({
 double left, double top, double width, double height
});




}
/// @nodoc
class __$WindowGeometryCopyWithImpl<$Res>
    implements _$WindowGeometryCopyWith<$Res> {
  __$WindowGeometryCopyWithImpl(this._self, this._then);

  final _WindowGeometry _self;
  final $Res Function(_WindowGeometry) _then;

/// Create a copy of WindowGeometry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? top = null,Object? width = null,Object? height = null,}) {
  return _then(_WindowGeometry(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
