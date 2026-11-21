import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/install_kind.dart';
import '../domain/release_info.dart';

part 'update_state.freezed.dart';

/// Where the update check and the update are (update-check design §2, §3).
@freezed
sealed class UpdateState with _$UpdateState {
  /// Nothing to show: not checked, nothing newer, or the owner said later.
  const factory UpdateState.idle() = UpdateIdle;

  /// "Check now" is asking.
  const factory UpdateState.checking() = UpdateChecking;

  /// "Check now" found nothing newer.
  const factory UpdateState.upToDate() = UpdateUpToDate;

  /// "Check now" could not ask.
  const factory UpdateState.checkFailed() = UpdateCheckFailed;

  /// A newer release is out. [canInstall] is whether this copy can install it
  /// itself: its kind updates itself, and the release has its package and a
  /// checksums file. Otherwise the owner is sent to the release page.
  const factory UpdateState.available({
    required ReleaseInfo release,
    required InstallKind kind,
    required bool canInstall,
  }) = UpdateAvailable;

  /// The package is downloading.
  const factory UpdateState.downloading({
    required ReleaseInfo release,
    required int received,
    required int total,
  }) = UpdateDownloading;

  /// The package could not be downloaded.
  const factory UpdateState.downloadFailed({required ReleaseInfo release}) =
      UpdateDownloadFailed;

  /// The package did not match its checksum, and was deleted.
  const factory UpdateState.verifyFailed({required ReleaseInfo release}) =
      UpdateVerifyFailed;

  /// The verified package, ready to install.
  const factory UpdateState.readyToInstall({
    required ReleaseInfo release,
    required File package,
  }) = UpdateReadyToInstall;

  /// The last start's update to [to] did not complete.
  /// The installer could not be started; the running version stays.
  const factory UpdateState.installFailed({required ReleaseInfo release}) =
      UpdateInstallFailed;

  const factory UpdateState.previousUpdateFailed({required String to}) =
      UpdatePreviousFailed;
}
