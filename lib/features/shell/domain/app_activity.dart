/// Something that runs for as long as the application does, and has to be
/// wound down when it closes for an update (library navigation design §2).
///
/// Closing for an update is the one action that reaches across every feature
/// at once: it stops playback, it discards the catalog projections, and it has
/// to know whether an editor is holding changes the owner has not saved.
/// Asking each feature directly would put a list of features inside the
/// updater and would grow by one line for every use case that opens something.
///
/// So the shell owns the question and the features answer it. Each registers
/// one activity in the composition root; startup begins them all once it is
/// ready, and closing for an update ends them, knowing nothing about what is
/// in the list.
abstract interface class AppActivity {
  /// Whether this activity holds changes the owner has not saved (FR-ME-09).
  ///
  /// A warning, not a refusal: the owner is told before the changes go, and
  /// may cancel and save first.
  bool get holdsUnsavedChanges;

  /// Winds the activity down.
  Future<void> end();

  /// Starts whatever this activity does while the application runs.
  ///
  /// Called once startup is ready, so the core is loaded and initialized.
  ///
  /// Most activities have nothing to start. Indexing does: a library that
  /// changed while the application was closed is re-checked here (FR-LB-21).
  Future<void> begin();
}

/// What a list of [AppActivity] answers as a whole.
extension AppActivities on List<AppActivity> {
  /// Whether any of them would lose unsaved changes (FR-ME-09).
  bool get holdUnsavedChanges =>
      any((activity) => activity.holdsUnsavedChanges);
}
