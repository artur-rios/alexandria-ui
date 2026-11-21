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
