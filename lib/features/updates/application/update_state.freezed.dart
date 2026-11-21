// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState()';
}


}

/// @nodoc
class $UpdateStateCopyWith<$Res>  {
$UpdateStateCopyWith(UpdateState _, $Res Function(UpdateState) __);
}


/// Adds pattern-matching-related methods to [UpdateState].
extension UpdateStatePatterns on UpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateIdle value)?  idle,TResult Function( UpdateChecking value)?  checking,TResult Function( UpdateUpToDate value)?  upToDate,TResult Function( UpdateCheckFailed value)?  checkFailed,TResult Function( UpdateAvailable value)?  available,TResult Function( UpdateDownloading value)?  downloading,TResult Function( UpdateDownloadFailed value)?  downloadFailed,TResult Function( UpdateVerifyFailed value)?  verifyFailed,TResult Function( UpdateReadyToInstall value)?  readyToInstall,TResult Function( UpdateInstallFailed value)?  installFailed,TResult Function( UpdatePreviousFailed value)?  previousUpdateFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle(_that);case UpdateChecking() when checking != null:
return checking(_that);case UpdateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateCheckFailed() when checkFailed != null:
return checkFailed(_that);case UpdateAvailable() when available != null:
return available(_that);case UpdateDownloading() when downloading != null:
return downloading(_that);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that);case UpdateVerifyFailed() when verifyFailed != null:
return verifyFailed(_that);case UpdateReadyToInstall() when readyToInstall != null:
return readyToInstall(_that);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that);case UpdatePreviousFailed() when previousUpdateFailed != null:
return previousUpdateFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateIdle value)  idle,required TResult Function( UpdateChecking value)  checking,required TResult Function( UpdateUpToDate value)  upToDate,required TResult Function( UpdateCheckFailed value)  checkFailed,required TResult Function( UpdateAvailable value)  available,required TResult Function( UpdateDownloading value)  downloading,required TResult Function( UpdateDownloadFailed value)  downloadFailed,required TResult Function( UpdateVerifyFailed value)  verifyFailed,required TResult Function( UpdateReadyToInstall value)  readyToInstall,required TResult Function( UpdateInstallFailed value)  installFailed,required TResult Function( UpdatePreviousFailed value)  previousUpdateFailed,}){
final _that = this;
switch (_that) {
case UpdateIdle():
return idle(_that);case UpdateChecking():
return checking(_that);case UpdateUpToDate():
return upToDate(_that);case UpdateCheckFailed():
return checkFailed(_that);case UpdateAvailable():
return available(_that);case UpdateDownloading():
return downloading(_that);case UpdateDownloadFailed():
return downloadFailed(_that);case UpdateVerifyFailed():
return verifyFailed(_that);case UpdateReadyToInstall():
return readyToInstall(_that);case UpdateInstallFailed():
return installFailed(_that);case UpdatePreviousFailed():
return previousUpdateFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateIdle value)?  idle,TResult? Function( UpdateChecking value)?  checking,TResult? Function( UpdateUpToDate value)?  upToDate,TResult? Function( UpdateCheckFailed value)?  checkFailed,TResult? Function( UpdateAvailable value)?  available,TResult? Function( UpdateDownloading value)?  downloading,TResult? Function( UpdateDownloadFailed value)?  downloadFailed,TResult? Function( UpdateVerifyFailed value)?  verifyFailed,TResult? Function( UpdateReadyToInstall value)?  readyToInstall,TResult? Function( UpdateInstallFailed value)?  installFailed,TResult? Function( UpdatePreviousFailed value)?  previousUpdateFailed,}){
final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle(_that);case UpdateChecking() when checking != null:
return checking(_that);case UpdateUpToDate() when upToDate != null:
return upToDate(_that);case UpdateCheckFailed() when checkFailed != null:
return checkFailed(_that);case UpdateAvailable() when available != null:
return available(_that);case UpdateDownloading() when downloading != null:
return downloading(_that);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that);case UpdateVerifyFailed() when verifyFailed != null:
return verifyFailed(_that);case UpdateReadyToInstall() when readyToInstall != null:
return readyToInstall(_that);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that);case UpdatePreviousFailed() when previousUpdateFailed != null:
return previousUpdateFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  checking,TResult Function()?  upToDate,TResult Function()?  checkFailed,TResult Function( ReleaseInfo release,  InstallKind kind,  bool canInstall)?  available,TResult Function( ReleaseInfo release,  int received,  int total)?  downloading,TResult Function( ReleaseInfo release)?  downloadFailed,TResult Function( ReleaseInfo release)?  verifyFailed,TResult Function( ReleaseInfo release,  File package)?  readyToInstall,TResult Function( ReleaseInfo release)?  installFailed,TResult Function( String to)?  previousUpdateFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle();case UpdateChecking() when checking != null:
return checking();case UpdateUpToDate() when upToDate != null:
return upToDate();case UpdateCheckFailed() when checkFailed != null:
return checkFailed();case UpdateAvailable() when available != null:
return available(_that.release,_that.kind,_that.canInstall);case UpdateDownloading() when downloading != null:
return downloading(_that.release,_that.received,_that.total);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that.release);case UpdateVerifyFailed() when verifyFailed != null:
return verifyFailed(_that.release);case UpdateReadyToInstall() when readyToInstall != null:
return readyToInstall(_that.release,_that.package);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that.release);case UpdatePreviousFailed() when previousUpdateFailed != null:
return previousUpdateFailed(_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  checking,required TResult Function()  upToDate,required TResult Function()  checkFailed,required TResult Function( ReleaseInfo release,  InstallKind kind,  bool canInstall)  available,required TResult Function( ReleaseInfo release,  int received,  int total)  downloading,required TResult Function( ReleaseInfo release)  downloadFailed,required TResult Function( ReleaseInfo release)  verifyFailed,required TResult Function( ReleaseInfo release,  File package)  readyToInstall,required TResult Function( ReleaseInfo release)  installFailed,required TResult Function( String to)  previousUpdateFailed,}) {final _that = this;
switch (_that) {
case UpdateIdle():
return idle();case UpdateChecking():
return checking();case UpdateUpToDate():
return upToDate();case UpdateCheckFailed():
return checkFailed();case UpdateAvailable():
return available(_that.release,_that.kind,_that.canInstall);case UpdateDownloading():
return downloading(_that.release,_that.received,_that.total);case UpdateDownloadFailed():
return downloadFailed(_that.release);case UpdateVerifyFailed():
return verifyFailed(_that.release);case UpdateReadyToInstall():
return readyToInstall(_that.release,_that.package);case UpdateInstallFailed():
return installFailed(_that.release);case UpdatePreviousFailed():
return previousUpdateFailed(_that.to);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  checking,TResult? Function()?  upToDate,TResult? Function()?  checkFailed,TResult? Function( ReleaseInfo release,  InstallKind kind,  bool canInstall)?  available,TResult? Function( ReleaseInfo release,  int received,  int total)?  downloading,TResult? Function( ReleaseInfo release)?  downloadFailed,TResult? Function( ReleaseInfo release)?  verifyFailed,TResult? Function( ReleaseInfo release,  File package)?  readyToInstall,TResult? Function( ReleaseInfo release)?  installFailed,TResult? Function( String to)?  previousUpdateFailed,}) {final _that = this;
switch (_that) {
case UpdateIdle() when idle != null:
return idle();case UpdateChecking() when checking != null:
return checking();case UpdateUpToDate() when upToDate != null:
return upToDate();case UpdateCheckFailed() when checkFailed != null:
return checkFailed();case UpdateAvailable() when available != null:
return available(_that.release,_that.kind,_that.canInstall);case UpdateDownloading() when downloading != null:
return downloading(_that.release,_that.received,_that.total);case UpdateDownloadFailed() when downloadFailed != null:
return downloadFailed(_that.release);case UpdateVerifyFailed() when verifyFailed != null:
return verifyFailed(_that.release);case UpdateReadyToInstall() when readyToInstall != null:
return readyToInstall(_that.release,_that.package);case UpdateInstallFailed() when installFailed != null:
return installFailed(_that.release);case UpdatePreviousFailed() when previousUpdateFailed != null:
return previousUpdateFailed(_that.to);case _:
  return null;

}
}

}

/// @nodoc


class UpdateIdle implements UpdateState {
  const UpdateIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.idle()';
}


}




/// @nodoc


class UpdateChecking implements UpdateState {
  const UpdateChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.checking()';
}


}




/// @nodoc


class UpdateUpToDate implements UpdateState {
  const UpdateUpToDate();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUpToDate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.upToDate()';
}


}




/// @nodoc


class UpdateCheckFailed implements UpdateState {
  const UpdateCheckFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCheckFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateState.checkFailed()';
}


}




/// @nodoc


class UpdateAvailable implements UpdateState {
  const UpdateAvailable({required this.release, required this.kind, required this.canInstall});
  

 final  ReleaseInfo release;
 final  InstallKind kind;
 final  bool canInstall;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateAvailableCopyWith<UpdateAvailable> get copyWith => _$UpdateAvailableCopyWithImpl<UpdateAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateAvailable&&(identical(other.release, release) || other.release == release)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.canInstall, canInstall) || other.canInstall == canInstall));
}


@override
int get hashCode => Object.hash(runtimeType,release,kind,canInstall);

@override
String toString() {
  return 'UpdateState.available(release: $release, kind: $kind, canInstall: $canInstall)';
}


}

/// @nodoc
abstract mixin class $UpdateAvailableCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateAvailableCopyWith(UpdateAvailable value, $Res Function(UpdateAvailable) _then) = _$UpdateAvailableCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release, InstallKind kind, bool canInstall
});




}
/// @nodoc
class _$UpdateAvailableCopyWithImpl<$Res>
    implements $UpdateAvailableCopyWith<$Res> {
  _$UpdateAvailableCopyWithImpl(this._self, this._then);

  final UpdateAvailable _self;
  final $Res Function(UpdateAvailable) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,Object? kind = null,Object? canInstall = null,}) {
  return _then(UpdateAvailable(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InstallKind,canInstall: null == canInstall ? _self.canInstall : canInstall // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class UpdateDownloading implements UpdateState {
  const UpdateDownloading({required this.release, required this.received, required this.total});
  

 final  ReleaseInfo release;
 final  int received;
 final  int total;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateDownloadingCopyWith<UpdateDownloading> get copyWith => _$UpdateDownloadingCopyWithImpl<UpdateDownloading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateDownloading&&(identical(other.release, release) || other.release == release)&&(identical(other.received, received) || other.received == received)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,release,received,total);

@override
String toString() {
  return 'UpdateState.downloading(release: $release, received: $received, total: $total)';
}


}

/// @nodoc
abstract mixin class $UpdateDownloadingCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateDownloadingCopyWith(UpdateDownloading value, $Res Function(UpdateDownloading) _then) = _$UpdateDownloadingCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release, int received, int total
});




}
/// @nodoc
class _$UpdateDownloadingCopyWithImpl<$Res>
    implements $UpdateDownloadingCopyWith<$Res> {
  _$UpdateDownloadingCopyWithImpl(this._self, this._then);

  final UpdateDownloading _self;
  final $Res Function(UpdateDownloading) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,Object? received = null,Object? total = null,}) {
  return _then(UpdateDownloading(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,received: null == received ? _self.received : received // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UpdateDownloadFailed implements UpdateState {
  const UpdateDownloadFailed({required this.release});
  

 final  ReleaseInfo release;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateDownloadFailedCopyWith<UpdateDownloadFailed> get copyWith => _$UpdateDownloadFailedCopyWithImpl<UpdateDownloadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateDownloadFailed&&(identical(other.release, release) || other.release == release));
}


@override
int get hashCode => Object.hash(runtimeType,release);

@override
String toString() {
  return 'UpdateState.downloadFailed(release: $release)';
}


}

/// @nodoc
abstract mixin class $UpdateDownloadFailedCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateDownloadFailedCopyWith(UpdateDownloadFailed value, $Res Function(UpdateDownloadFailed) _then) = _$UpdateDownloadFailedCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release
});




}
/// @nodoc
class _$UpdateDownloadFailedCopyWithImpl<$Res>
    implements $UpdateDownloadFailedCopyWith<$Res> {
  _$UpdateDownloadFailedCopyWithImpl(this._self, this._then);

  final UpdateDownloadFailed _self;
  final $Res Function(UpdateDownloadFailed) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,}) {
  return _then(UpdateDownloadFailed(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,
  ));
}


}

/// @nodoc


class UpdateVerifyFailed implements UpdateState {
  const UpdateVerifyFailed({required this.release});
  

 final  ReleaseInfo release;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateVerifyFailedCopyWith<UpdateVerifyFailed> get copyWith => _$UpdateVerifyFailedCopyWithImpl<UpdateVerifyFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateVerifyFailed&&(identical(other.release, release) || other.release == release));
}


@override
int get hashCode => Object.hash(runtimeType,release);

@override
String toString() {
  return 'UpdateState.verifyFailed(release: $release)';
}


}

/// @nodoc
abstract mixin class $UpdateVerifyFailedCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateVerifyFailedCopyWith(UpdateVerifyFailed value, $Res Function(UpdateVerifyFailed) _then) = _$UpdateVerifyFailedCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release
});




}
/// @nodoc
class _$UpdateVerifyFailedCopyWithImpl<$Res>
    implements $UpdateVerifyFailedCopyWith<$Res> {
  _$UpdateVerifyFailedCopyWithImpl(this._self, this._then);

  final UpdateVerifyFailed _self;
  final $Res Function(UpdateVerifyFailed) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,}) {
  return _then(UpdateVerifyFailed(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,
  ));
}


}

/// @nodoc


class UpdateReadyToInstall implements UpdateState {
  const UpdateReadyToInstall({required this.release, required this.package});
  

 final  ReleaseInfo release;
 final  File package;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateReadyToInstallCopyWith<UpdateReadyToInstall> get copyWith => _$UpdateReadyToInstallCopyWithImpl<UpdateReadyToInstall>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateReadyToInstall&&(identical(other.release, release) || other.release == release)&&(identical(other.package, package) || other.package == package));
}


@override
int get hashCode => Object.hash(runtimeType,release,package);

@override
String toString() {
  return 'UpdateState.readyToInstall(release: $release, package: $package)';
}


}

/// @nodoc
abstract mixin class $UpdateReadyToInstallCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateReadyToInstallCopyWith(UpdateReadyToInstall value, $Res Function(UpdateReadyToInstall) _then) = _$UpdateReadyToInstallCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release, File package
});




}
/// @nodoc
class _$UpdateReadyToInstallCopyWithImpl<$Res>
    implements $UpdateReadyToInstallCopyWith<$Res> {
  _$UpdateReadyToInstallCopyWithImpl(this._self, this._then);

  final UpdateReadyToInstall _self;
  final $Res Function(UpdateReadyToInstall) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,Object? package = null,}) {
  return _then(UpdateReadyToInstall(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,package: null == package ? _self.package : package // ignore: cast_nullable_to_non_nullable
as File,
  ));
}


}

/// @nodoc


class UpdateInstallFailed implements UpdateState {
  const UpdateInstallFailed({required this.release});
  

 final  ReleaseInfo release;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateInstallFailedCopyWith<UpdateInstallFailed> get copyWith => _$UpdateInstallFailedCopyWithImpl<UpdateInstallFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateInstallFailed&&(identical(other.release, release) || other.release == release));
}


@override
int get hashCode => Object.hash(runtimeType,release);

@override
String toString() {
  return 'UpdateState.installFailed(release: $release)';
}


}

/// @nodoc
abstract mixin class $UpdateInstallFailedCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdateInstallFailedCopyWith(UpdateInstallFailed value, $Res Function(UpdateInstallFailed) _then) = _$UpdateInstallFailedCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo release
});




}
/// @nodoc
class _$UpdateInstallFailedCopyWithImpl<$Res>
    implements $UpdateInstallFailedCopyWith<$Res> {
  _$UpdateInstallFailedCopyWithImpl(this._self, this._then);

  final UpdateInstallFailed _self;
  final $Res Function(UpdateInstallFailed) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? release = null,}) {
  return _then(UpdateInstallFailed(
release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as ReleaseInfo,
  ));
}


}

/// @nodoc


class UpdatePreviousFailed implements UpdateState {
  const UpdatePreviousFailed({required this.to});
  

 final  String to;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePreviousFailedCopyWith<UpdatePreviousFailed> get copyWith => _$UpdatePreviousFailedCopyWithImpl<UpdatePreviousFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePreviousFailed&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,to);

@override
String toString() {
  return 'UpdateState.previousUpdateFailed(to: $to)';
}


}

/// @nodoc
abstract mixin class $UpdatePreviousFailedCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory $UpdatePreviousFailedCopyWith(UpdatePreviousFailed value, $Res Function(UpdatePreviousFailed) _then) = _$UpdatePreviousFailedCopyWithImpl;
@useResult
$Res call({
 String to
});




}
/// @nodoc
class _$UpdatePreviousFailedCopyWithImpl<$Res>
    implements $UpdatePreviousFailedCopyWith<$Res> {
  _$UpdatePreviousFailedCopyWithImpl(this._self, this._then);

  final UpdatePreviousFailed _self;
  final $Res Function(UpdatePreviousFailed) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? to = null,}) {
  return _then(UpdatePreviousFailed(
to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
