/// Something that runs for the length of a session and has to be wound down
/// when it ends (UC-03, FR-AU-09).
///
/// Signing out is the one action that reaches across every feature at once:
/// it stops playback, it discards the catalog projections, and it has to know
/// whether an editor is holding changes the owner has not saved. Asking each
/// feature directly would put a list of features inside the authentication
/// layer and would grow by one line for every use case that opens something.
///
/// So the shell owns the question and the features answer it. Each registers
/// one activity in the composition root; establishing a session and signing
/// out both read the list and know nothing about what is in it.
abstract interface class SessionActivity {
  /// Whether this activity holds changes the owner has not saved
  /// (UC-03 AF-01, FR-ME-09).
  ///
  /// A warning, not a refusal: the owner is told before the changes go, and
  /// may cancel and save first.
  bool get holdsUnsavedChanges;

  /// Whether the work continues inside the core after the session ends
  /// (UC-03 AF-02).
  ///
  /// An index run belongs to the core, not to the session, so signing out
  /// does not stop it. Saying so is the difference between a run that looks
  /// abandoned and one the owner knows to come back for.
  bool get continuesInTheCore;

  /// Winds the activity down.
  ///
  /// Called before the credential is discarded, so anything that needs the
  /// session to stop cleanly still has it.
  Future<void> end();

  /// Starts whatever this activity does for the length of a session.
  ///
  /// Called after the session is recorded, so anything that needs the
  /// credential has it — which is the difference between this and [end],
  /// whose whole purpose is to run while the *previous* session's state is
  /// still there to drop.
  ///
  /// Most activities have nothing to start. Indexing does: a library that
  /// changed while the application was closed is re-checked here (FR-LB-21).
  Future<void> begin();
}
