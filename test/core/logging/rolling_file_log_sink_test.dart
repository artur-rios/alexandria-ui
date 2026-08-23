import 'dart:io';

import 'package:alexandria_ui/core/logging/rolling_file_log_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() {
    // A temporary directory, never the real application-support path: no test
    // reads or writes the developer's own logs (Testing Specification §7.3).
    directory = Directory.systemTemp.createTempSync('alexandria_log_test');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  RollingFileLogSink sinkWith({int maxBytes = 64, int maxFiles = 3}) =>
      RollingFileLogSink(
        directory: directory.path,
        maxBytes: maxBytes,
        maxFiles: maxFiles,
      );

  test('GivenNoLogFile_WhenARecordIsWritten_ThenTheFileIsCreated', () {
    final sink = sinkWith();

    sink.write('first record');

    expect(sink.currentFile.existsSync(), isTrue);
    expect(sink.currentFile.readAsStringSync(), 'first record\n');
  });

  test('GivenAMissingDirectory_WhenARecordIsWritten_ThenItIsCreated', () {
    final nested = RollingFileLogSink(
      directory: '${directory.path}/does/not/exist/yet',
    );

    nested.write('first record');

    expect(nested.currentFile.existsSync(), isTrue);
  });

  test('GivenTheFileIsUnderTheCap_WhenARecordIsWritten_ThenItDoesNotRoll', () {
    final sink = sinkWith(maxBytes: 1024);

    sink.write('one');
    sink.write('two');

    expect(sink.files, hasLength(1));
    expect(sink.currentFile.readAsStringSync(), 'one\ntwo\n');
  });

  test('GivenTheCapWouldBeExceeded_WhenARecordIsWritten_ThenTheFileRolls', () {
    final sink = sinkWith(maxBytes: 32);

    sink.write('a' * 20);
    sink.write('b' * 20);

    expect(sink.files, hasLength(2));
    expect(sink.currentFile.readAsStringSync().trim(), 'b' * 20);
  });

  test('GivenTheCap_WhenTheFileRolls_ThenItIsNeverExceeded', () {
    const maxBytes = 64;
    final sink = sinkWith(maxBytes: maxBytes);

    for (var i = 0; i < 40; i++) {
      sink.write('record $i padded out to force several rotations');
    }

    for (final file in sink.files) {
      expect(
        file.lengthSync(),
        lessThanOrEqualTo(maxBytes),
        reason:
            'rotation is checked before the write, so the cap is a ceiling the '
            'file never crosses rather than one it corrects afterwards',
      );
    }
  });

  test('GivenTheFileCount_WhenItRollsRepeatedly_ThenOlderFilesArePurged', () {
    const maxFiles = 3;
    final sink = sinkWith(maxBytes: 32, maxFiles: maxFiles);

    for (var i = 0; i < 50; i++) {
      sink.write('record $i padded out to force several rotations');
    }

    expect(sink.files, hasLength(maxFiles));
    expect(
      directory.listSync().whereType<File>(),
      hasLength(maxFiles),
      reason: 'a rolled file that is no longer tracked is still on disk',
    );
  });

  test(
    'GivenSeveralRotations_WhenTheFilesAreRead_ThenTheNewestIsTheLiveOne',
    () {
      final sink = sinkWith(maxBytes: 32, maxFiles: 3);

      sink.write('oldest record here');
      sink.write('middle record here');
      sink.write('newest record here');

      expect(sink.currentFile.readAsStringSync(), contains('newest'));
      expect(sink.files.first.path, sink.currentFile.path);
    },
  );
}
