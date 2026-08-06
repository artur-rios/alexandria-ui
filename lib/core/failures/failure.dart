import 'package:freezed_annotation/freezed_annotation.dart';

import 'core_status.dart';

part 'failure.freezed.dart';

/// Everything that can go wrong, as one closed set (IR-08).
///
/// Every status code the core can return maps to exactly one variant, and every
/// variant maps to exactly one localized message. A raw status code never
/// reaches the screen (FR-UX-09).
///
/// The variants divide in two. The first eight come from a core call and carry
/// the [CoreStatusFamily] and code that produced them, so a failure can be
/// logged with the core's own code and traced from a report without the owner
/// reading a code on screen (Operations & Infrastructure Document §4). The rest
/// arise before or around a core call — the library would not load, the
/// application-support directory would not open — and carry what the owner
/// needs to act on instead.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  /// The core rejected the input. Its verdict is always final and always
  /// surfaced, even when local validation passed.
  const factory Failure.invalidInput({
    required CoreStatusFamily family,
    required int code,
  }) = InvalidInputFailure;

  /// The session is absent, expired, or rejected. Clearing the session is the
  /// caller's obligation.
  const factory Failure.unauthorized({
    required CoreStatusFamily family,
    required int code,
  }) = UnauthorizedFailure;

  /// A call was made before `alexandria_index_init` succeeded. This is a
  /// programming error in the startup sequence rather than an owner-facing
  /// condition, and is reported as such.
  const factory Failure.notInitialized({
    required CoreStatusFamily family,
    required int code,
  }) = NotInitializedFailure;

  /// The record does not exist, or has passed the retention window that makes
  /// it reachable.
  const factory Failure.notFound({
    required CoreStatusFamily family,
    required int code,
  }) = NotFoundFailure;

  /// The record exists but is in the wrong state for the operation — purging
  /// one still inside its retention window, for instance.
  const factory Failure.invalidState({
    required CoreStatusFamily family,
    required int code,
  }) = InvalidStateFailure;

  /// A filesystem operation failed. The catalog is left untouched when this
  /// happens, per the core's contract.
  const factory Failure.disk({
    required CoreStatusFamily family,
    required int code,
  }) = DiskFailure;

  /// The file on disk no longer matches what the catalog recorded.
  const factory Failure.integrity({
    required CoreStatusFamily family,
    required int code,
  }) = IntegrityFailure;

  /// The core's own configuration is missing or unusable.
  const factory Failure.configuration({
    required CoreStatusFamily family,
    required int code,
  }) = ConfigurationFailure;

  /// A status code this application does not know.
  ///
  /// It exists so the mapping is total: a core that grows a code the front-end
  /// has not caught up with still produces a readable message rather than an
  /// unhandled branch.
  const factory Failure.unexpected({
    required CoreStatusFamily family,
    required int code,
  }) = UnexpectedFailure;

  /// The core's shared library could not be loaded (startup step 1).
  ///
  /// [path] is what was attempted, and is shown to the owner: it is the only
  /// thing that makes this actionable.
  const factory Failure.coreLibraryNotLoaded({required String path}) =
      CoreLibraryNotLoadedFailure;

  /// The application-support directory could not be resolved or created
  /// (startup step 2).
  const factory Failure.applicationDirectoryUnavailable({
    required String path,
  }) = ApplicationDirectoryUnavailableFailure;

  /// `alexandria_index_init` returned a non-success code (startup step 3).
  const factory Failure.coreInitializationFailed({required int code}) =
      CoreInitializationFailedFailure;

  /// The core loaded and initialized but reports itself unhealthy
  /// (startup step 4).
  const factory Failure.coreUnhealthy({required int code}) =
      CoreUnhealthyFailure;

  /// The core's version is outside the range this application supports
  /// (startup step 4).
  ///
  /// Both versions are carried because the message states the one found and
  /// the one required.
  const factory Failure.coreVersionUnsupported({
    required String found,
    required String required,
  }) = CoreVersionUnsupportedFailure;

  /// The local settings could not be read (startup step 5).
  ///
  /// Startup continues on the system theme and language; this is reported, not
  /// fatal.
  const factory Failure.preferencesUnreadable() = PreferencesUnreadableFailure;

  /// The core status code behind this failure, when there is one.
  ///
  /// Logged with every failure so a report can be traced back to the core
  /// (Operations & Infrastructure Document §4).
  int? get coreStatusCode => switch (this) {
    InvalidInputFailure(:final code) ||
    UnauthorizedFailure(:final code) ||
    NotInitializedFailure(:final code) ||
    NotFoundFailure(:final code) ||
    InvalidStateFailure(:final code) ||
    DiskFailure(:final code) ||
    IntegrityFailure(:final code) ||
    ConfigurationFailure(:final code) ||
    UnexpectedFailure(:final code) ||
    CoreInitializationFailedFailure(:final code) ||
    CoreUnhealthyFailure(:final code) => code,
    _ => null,
  };

  /// Whether this failure means the core is not usable at all.
  ///
  /// These are the conditions that put the application into the
  /// `CoreUnavailable` state — a first-class state, not an error dialog over a
  /// broken window (Operations & Infrastructure Document §5.2).
  bool get isCoreUnavailable => switch (this) {
    CoreLibraryNotLoadedFailure() ||
    ApplicationDirectoryUnavailableFailure() ||
    CoreInitializationFailedFailure() ||
    CoreUnhealthyFailure() ||
    CoreVersionUnsupportedFailure() => true,
    _ => false,
  };
}
