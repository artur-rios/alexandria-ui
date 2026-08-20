import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/file_hold.dart';

/// A viewer or an editor, while it has a file open (UC-33 AF-04).
///
/// It carries the way to close itself rather than a flag the screen watches:
/// a viewer is a route, and closing a route is something only the thing that
/// pushed it can do.
class OpenFileHold implements FileHold {
  /// Records that [uuid] is open, and that [close] closes it.
  const OpenFileHold({required this.uuid, required this.close});

  /// The file that is open.
  final String uuid;

  /// Closes whatever has it open.
  final Future<void> Function() close;

  @override
  bool holds(String uuid) => uuid == this.uuid;

  @override
  Future<void> release() => close();
}

/// Which viewers and editors currently have a file open (UC-33 AF-04).
///
/// A list rather than one entry: a viewer opened over another one is two, and
/// deleting the file both are showing has to close both.
class OpenFileHolds extends Notifier<List<OpenFileHold>> {
  @override
  List<OpenFileHold> build() => const [];

  /// Records that something opened [uuid], and answers how to forget it again.
  ///
  /// The returned callback is what the viewer calls from `dispose`; calling it
  /// twice is harmless, which is what a viewer closed by [FileHold.release]
  /// and then disposed does.
  void Function() register(OpenFileHold hold) {
    state = [...state, hold];
    return () => state = [
      for (final open in state)
        if (!identical(open, hold)) open,
    ];
  }
}
