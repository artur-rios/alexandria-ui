/// When a track counts as played (play history design).
///
/// The core deliberately holds no rule of its own — it cannot see what the
/// owner is hearing — so the whole definition lives here, in one function,
/// rather than being half-applied in the player and half-checked in a
/// repository.
///
/// Half the track, or four minutes, whichever comes first. The convention
/// scrobblers have used for twenty years, and it is the right shape for two
/// reasons: a two-minute song abandoned after forty seconds was not
/// listened to, and an hour-long live set does not stop counting merely
/// because the owner left before the encore.
library;

/// The fraction of a track that has to have been heard.
const double playedFraction = 0.5;

/// The point past which the fraction stops mattering.
const Duration playedAfter = Duration(minutes: 4);

/// Whether [heard] of a track [duration] long counts as played.
///
/// [heard] is time the owner actually *heard*, not the position the engine
/// is reporting. The two are the same for a track played straight through
/// and nothing alike for one that was resumed or scrubbed, which is the
/// distinction this parameter exists to keep: a track reopened at the point
/// it was left has a position past the threshold before a second of it has
/// been played, and dragging the slider past the middle reaches the same
/// place with nothing heard at all. Counting either would report listening
/// that did not happen — the failure this whole rule is here to prevent,
/// arrived at from the other side.
///
/// A [duration] the engine has not worked out yet — null, or zero — counts
/// nothing: with no length to take half of, every rule reduces to guessing,
/// and the status that follows a moment later carries the real value.
bool countsAsPlayed({required Duration heard, required Duration? duration}) {
  if (duration == null || duration <= Duration.zero) return false;
  if (heard >= playedAfter) return true;

  return heard.inMilliseconds >= duration.inMilliseconds * playedFraction;
}
