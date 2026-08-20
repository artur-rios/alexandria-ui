/// What the core knows about how a video's progress is counted (UC-16 AF-03,
/// FR-TR-07).
///
/// The whole of watchlists is UC-29's and UC-30's. This is the one question
/// UC-16 has to ask before it lets the owner turn a series into a movie, and
/// it is asked here rather than guessed at: per-episode progress becomes
/// single-item progress, and the owner is owed a warning that names what
/// actually exists rather than one shown on the off-chance.
abstract interface class WatchProgressGateway {
  /// Whether anything records per-episode progress for the video [uuid]
  /// identifies.
  ///
  /// `false` also when the question cannot be answered: a warning nobody can
  /// justify is worse than none, and the core is the authority on what it
  /// holds. The edit itself is not blocked by this — it is what decides
  /// whether a confirmation stands between the owner and the call.
  Future<bool> episodesRecordedFor({
    required String uuid,
    required String credential,
  });
}
