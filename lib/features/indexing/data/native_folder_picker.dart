import 'package:file_selector/file_selector.dart';

import '../domain/folder_picker.dart';

/// [FolderPicker] over `file_selector` (Technology Stack Document §3.5).
///
/// The only file in the application that opens a platform dialog.
class NativeFolderPicker implements FolderPicker {
  /// Creates a picker over the platform's native dialog.
  const NativeFolderPicker();

  @override
  Future<String?> pickFolder() => getDirectoryPath();
}
