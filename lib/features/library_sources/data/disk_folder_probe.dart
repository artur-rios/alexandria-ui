import 'dart:io';

import 'package:logging/logging.dart';

import '../domain/folder_picker.dart';

/// [FolderProbe] over `dart:io` (FR-LB-02).
///
/// The two questions are asked separately because FR-LB-02 requires the
/// refusals be told apart: "there is no folder there" and "there is one and it
/// will not open" send the owner to different places.
class DiskFolderProbe implements FolderProbe {
  /// Creates a probe over the real filesystem.
  const DiskFolderProbe();

  static final Logger _log = Logger('library_sources');

  @override
  Future<bool> exists(String path) => Directory(path).exists();

  @override
  Future<bool> isReadable(String path) async {
    try {
      // Listing one entry is the cheapest honest answer: a directory whose
      // permissions forbid it throws here and nowhere earlier, and taking only
      // the first entry means a folder with a hundred thousand files costs the
      // same as an empty one.
      await Directory(path).list(followLinks: false).first;
      return true;
    } on StateError {
      // An empty directory: `first` found nothing to return. Readable, and the
      // owner may well be about to fill it.
      return true;
    } on FileSystemException catch (error) {
      _log.info('source folder is not readable: $path', error);
      return false;
    }
  }
}
