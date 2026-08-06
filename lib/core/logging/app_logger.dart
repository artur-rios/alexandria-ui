import 'dart:developer' as developer;

import 'package:logging/logging.dart';

import 'log_redaction.dart';
import 'rolling_file_log_sink.dart';

/// Wires the `logging` package to its destinations (IR-13).
///
/// The console in development, a rolling file in release
/// (Operations & Infrastructure Document §4). Every record passes through
/// [LogRedaction] on the way out, whichever destination it is bound for — a
/// developer's console is still a place a password should not appear.
abstract final class AppLogger {
  /// The log level, set at build time by
  /// `--dart-define=ALEXANDRIA_LOG_LEVEL=fine`.
  ///
  /// Verbose in development, informational in release, per §3.
  static const String _configuredLevel = String.fromEnvironment(
    'ALEXANDRIA_LOG_LEVEL',
    defaultValue: 'INFO',
  );

  static RollingFileLogSink? _sink;
  static bool _initialized = false;

  /// Starts logging.
  ///
  /// [fileSink] is supplied in release builds and omitted in development, where
  /// the console is the destination. Calling this twice is a no-op rather than a
  /// second subscription, which would double every record.
  static void initialize({RollingFileLogSink? fileSink}) {
    if (_initialized) return;
    _initialized = true;
    _sink = fileSink;

    Logger.root.level = _levelFrom(_configuredLevel);
    Logger.root.onRecord.listen(_emit);
  }

  /// Stops logging and forgets the sink. For tests.
  static void reset() {
    _initialized = false;
    _sink = null;
    Logger.root.clearListeners();
  }

  static Level _levelFrom(String name) => Level.LEVELS.firstWhere(
    (level) => level.name.toLowerCase() == name.toLowerCase(),
    orElse: () => Level.INFO,
  );

  static void _emit(LogRecord record) {
    final line = format(record);

    final sink = _sink;
    if (sink != null) {
      sink.write(line);
      return;
    }

    developer.log(
      line,
      name: record.loggerName,
      level: record.level.value,
      time: record.time,
    );
  }

  /// Formats one record as a structured line: timestamp, level, feature,
  /// message.
  ///
  /// Redaction happens here rather than at the sink so it applies to the console
  /// too, and so a future second destination cannot be added without it.
  static String format(LogRecord record) {
    final message = LogRedaction.redactMessage(record.message);
    final buffer = StringBuffer(
      '${record.time.toIso8601String()} '
      '${record.level.name.padRight(7)} '
      '${record.loggerName} '
      '$message',
    );

    final error = record.error;
    if (error != null) {
      buffer.write(' error=${LogRedaction.redactMessage(error.toString())}');
    }

    return buffer.toString();
  }
}
