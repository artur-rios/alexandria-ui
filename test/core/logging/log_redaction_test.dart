import 'dart:io';

import 'package:alexandria_ui/core/logging/app_logger.dart';
import 'package:alexandria_ui/core/logging/log_redaction.dart';
import 'package:alexandria_ui/core/logging/rolling_file_log_sink.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

/// IR-13: the log contains no credential, no session material, and no file
/// content.
void main() {
  group('LogRedaction.redactMessage', () {
    const redacted = LogRedaction.placeholder;

    test('GivenAPasswordField_WhenTheMessageIsRedacted_ThenItIsRemoved', () {
      final line = LogRedaction.redactMessage(
        'login attempt email=owner@example.com password=hunter2',
      );

      expect(line, contains('owner@example.com'));
      expect(line, isNot(contains('hunter2')));
      expect(line, contains('password=$redacted'));
    });

    test(
      'GivenASessionCredential_WhenTheMessageIsRedacted_ThenItIsRemoved',
      () {
        final line = LogRedaction.redactMessage(
          'call made with sessionId: 3f9a-not-a-real-session',
        );

        expect(line, isNot(contains('3f9a-not-a-real-session')));
        expect(line, contains(redacted));
      },
    );

    test('GivenAJsonBody_WhenTheMessageIsRedacted_ThenTheTokenIsRemoved', () {
      final line = LogRedaction.redactMessage(
        '{"token": "abcdef123456", "status": 0}',
      );

      expect(line, isNot(contains('abcdef123456')));
      expect(line, contains('"status": 0'));
    });

    test('GivenFileContent_WhenTheMessageIsRedacted_ThenItIsRemoved', () {
      final line = LogRedaction.redactMessage(
        'edit saved content=the whole text of the note',
      );

      expect(line, isNot(contains('the whole text')));
    });

    test('GivenAFilePath_WhenTheMessageIsRedacted_ThenOnlyTheUuidSurvives', () {
      final line = LogRedaction.redactMessage(
        'opened uuid=8a1f-0000 path=/home/owner/library/private.pdf',
      );

      expect(
        line,
        contains('uuid=8a1f-0000'),
        reason:
            'a file is identified in a log by its UUID — that is the whole '
            'point of redacting the path',
      );
      expect(line, isNot(contains('private.pdf')));
    });

    test('GivenAHarmlessField_WhenTheMessageIsRedacted_ThenItIsUntouched', () {
      const message = 'index run settled files=1204 status=0';

      expect(LogRedaction.redactMessage(message), message);
    });
  });

  group('LogRedaction.redactContext', () {
    test('GivenSensitiveKeys_WhenTheContextIsRedacted_ThenOnlyThoseChange', () {
      final context = LogRedaction.redactContext({
        'feature': 'auth',
        'password': 'hunter2',
        'statusCode': 2,
      });

      expect(context['feature'], 'auth');
      expect(context['statusCode'], 2);
      expect(context['password'], LogRedaction.placeholder);
    });

    test('GivenMixedCasing_WhenTheContextIsRedacted_ThenItStillMatches', () {
      final context = LogRedaction.redactContext({'SessionId': 'abc'});

      expect(context['SessionId'], LogRedaction.placeholder);
    });
  });

  group('the release log file', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('alexandria_redact_test');
      AppLogger.reset();
    });

    tearDown(() {
      AppLogger.reset();
      directory.deleteSync(recursive: true);
    });

    test(
      'GivenARecordCarryingACredential_WhenItIsLoggedToFile_ThenTheFileNeverHoldsIt',
      () {
        final sink = RollingFileLogSink(directory: directory.path);
        AppLogger.initialize(fileSink: sink);

        Logger('auth').info('login password=hunter2 token=abcdef123456');

        final written = sink.currentFile.readAsStringSync();
        expect(written, isNot(contains('hunter2')));
        expect(written, isNot(contains('abcdef123456')));
        expect(written, contains('auth'));
      },
    );

    test('GivenARecord_WhenItIsFormatted_ThenItCarriesTheLevelAndFeature', () {
      final line = AppLogger.format(
        LogRecord(Level.SEVERE, 'core initialization failed', 'startup'),
      );

      expect(line, contains('SEVERE'));
      expect(line, contains('startup'));
      expect(line, contains('core initialization failed'));
    });

    test('GivenAnErrorOnTheRecord_WhenItIsFormatted_ThenItIsRedactedToo', () {
      final line = AppLogger.format(
        LogRecord(
          Level.SEVERE,
          'call rejected',
          'auth',
          'StateError: token=abcdef123456',
        ),
      );

      expect(line, isNot(contains('abcdef123456')));
    });
  });
}
