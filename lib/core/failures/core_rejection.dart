import 'package:freezed_annotation/freezed_annotation.dart';

part 'core_rejection.freezed.dart';

/// A reason the core gave for refusing something, in the form a client can
/// translate.
///
/// The core answers a failure with `{error, code, params}`: an English sentence
/// for a log, a stable code, and the values behind it. The code is the part
/// that matters here — this application must read in Brazilian Portuguese and
/// English (NFR-09), and it can translate neither an English sentence from the
/// core nor a bare status number.
///
/// [message] is carried for the log, never for the screen.
@freezed
abstract class CoreRejection with _$CoreRejection {
  /// Creates a rejection.
  const factory CoreRejection({
    /// The stable identifier, e.g. `password_too_short`.
    required String code,

    /// The values behind the code, e.g. `{'min': '12'}` — the bound that was
    /// violated, so the message can state it rather than hardcode a number
    /// this application does not own.
    @Default(<String, String>{}) Map<String, String> params,

    /// The core's own English sentence. For the log and for a report; the
    /// screen uses [code].
    String? message,
  }) = _CoreRejection;
}
