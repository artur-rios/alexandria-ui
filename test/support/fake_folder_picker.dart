import 'dart:async';

import 'package:alexandria_ui/features/indexing/domain/folder_picker.dart';

/// A [FolderPicker] that answers whatever a test told it to
/// (Testing Specification §6.2).
///
/// A widget test cannot open a native dialog, and cancelling one is an
/// alternative flow in its own right (UC-05 AF-01) — so the dialog is the
/// thing that gets substituted.
class FakeFolderPicker implements FolderPicker {
  /// Creates a picker answering [path], or `null` to model a cancellation.
  FakeFolderPicker({this.path, this.gate});

  /// What [pickFolder] answers. `null` is the owner cancelling (AF-01).
  String? path;

  /// When set, the picker answers only once this completes — the native
  /// dialog is open for seconds, long enough for the screen behind it to
  /// change.
  Completer<void>? gate;

  /// How many times the picker was opened.
  int openCount = 0;

  @override
  Future<String?> pickFolder() async {
    openCount++;
    await gate?.future;
    return path;
  }
}
