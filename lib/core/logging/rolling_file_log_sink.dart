import 'dart:io';

import 'package:path/path.dart' as p;

/// A local log file that rolls, so it cannot grow without bound (IR-13).
///
/// The `logging` package routes records but does not persist them, and no
/// rotating-file sink in the ecosystem is small enough to be worth a dependency
/// for a file with two rules — cap the size, cap the count — so it is written
/// here.
///
/// Rotation is by rename: `alexandria.log` becomes `alexandria.1.log`, which
/// becomes `alexandria.2.log`, and the oldest beyond [maxFiles] is deleted. A
/// timestamped-filename scheme would leave the owner to work out which file is
/// current; this one always has the live records in `alexandria.log`.
class RollingFileLogSink {
  /// Opens (or creates) the log file in [directory].
  RollingFileLogSink({
    required this.directory,
    this.baseName = 'alexandria',
    this.maxBytes = 5 * 1024 * 1024,
    this.maxFiles = 5,
  }) : assert(maxBytes > 0, 'a zero-byte cap would rotate on every record'),
       assert(maxFiles > 0, 'keeping zero files is the same as not logging');

  /// The directory the log files live in — the application-support directory.
  final String directory;

  /// The file name stem. The live file is `<baseName>.log`.
  final String baseName;

  /// The size at which the live file rolls.
  final int maxBytes;

  /// How many files are kept, including the live one.
  final int maxFiles;

  /// The file records are currently appended to.
  File get currentFile => File(p.join(directory, '$baseName.log'));

  File _rotatedFile(int index) =>
      File(p.join(directory, '$baseName.$index.log'));

  /// Appends one already-formatted, already-redacted record.
  ///
  /// Rotation is checked before the write rather than after, so the cap is a
  /// ceiling the file never exceeds rather than one it crosses and then corrects.
  void write(String line) {
    Directory(directory).createSync(recursive: true);

    final file = currentFile;
    final existing = file.existsSync() ? file.lengthSync() : 0;
    if (existing > 0 && existing + line.length + 1 > maxBytes) {
      _rotate();
    }

    currentFile.writeAsStringSync(
      '$line\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  void _rotate() {
    // Drop the oldest first, then shift each survivor up one, so no rename ever
    // lands on a file that is still wanted.
    final oldest = _rotatedFile(maxFiles - 1);
    if (oldest.existsSync()) oldest.deleteSync();

    for (var index = maxFiles - 2; index >= 1; index--) {
      final file = _rotatedFile(index);
      if (file.existsSync()) file.renameSync(_rotatedFile(index + 1).path);
    }

    final live = currentFile;
    if (live.existsSync()) live.renameSync(_rotatedFile(1).path);
  }

  /// Every log file that currently exists, newest first.
  List<File> get files => [
    currentFile,
    for (var index = 1; index < maxFiles; index++) _rotatedFile(index),
  ].where((file) => file.existsSync()).toList();
}
