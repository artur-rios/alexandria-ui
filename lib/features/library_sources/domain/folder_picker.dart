/// The platform's native folder picker (FR-LB-01).
///
/// An interface here rather than a call to `file_selector` from a controller,
/// for the reason every outward dependency gets one: a widget test cannot open
/// a native dialog, and the flow around the picker — including the owner
/// cancelling it (AF-01) — is what UC-05 is mostly made of.
abstract interface class FolderPicker {
  /// Opens the picker and answers the chosen folder's absolute path, or `null`
  /// when the owner cancelled (AF-01).
  Future<String?> pickFolder();
}

/// Whether a folder on disk exists and can be read (FR-LB-02).
///
/// Separate from [FolderPicker] because the two are different outward
/// dependencies that fail differently: the picker is a platform dialog, this
/// is the filesystem, and a test substitutes them independently.
abstract interface class FolderProbe {
  /// Whether there is a directory at [path].
  Future<bool> exists(String path);

  /// Whether the directory at [path] can be listed.
  ///
  /// Answers `false` rather than throwing when the directory is missing: the
  /// caller checks [exists] first and needs the two conditions told apart
  /// (FR-LB-02).
  Future<bool> isReadable(String path);
}
