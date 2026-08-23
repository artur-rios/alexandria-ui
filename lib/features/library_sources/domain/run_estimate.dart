/// One observation of a run's progress.
///
/// `activeMillis` is time the run spent *working*, which the core reports
/// with paused stretches already subtracted. Using wall time here would
/// overstate the work done by however long the owner left the run paused.
class RunSample {
  /// Creates a sample of progress at a point in time.
  const RunSample({required this.processed, required this.activeMillis});

  /// The number of items processed so far.
  final int processed;

  /// The active time spent on this run, in milliseconds (excluding pauses).
  final int activeMillis;
}

/// How many samples a window needs before it is worth trusting.
const int _minimumSamples = 3;

/// How far the fastest and slowest observed rates may differ before the
/// window is called unsteady.
///
/// A run's rate genuinely varies — a folder of small text files and a folder
/// of tagged FLACs are different work — so some spread is expected. Beyond
/// this, the estimate would swing far enough between polls to read as broken,
/// and showing nothing is the more honest answer.
const double _maximumRateSpread = 4.0;

/// How long the run has left, or null when no honest estimate can be made.
///
/// Returns null rather than a guess when: there are too few samples, the run
/// made no progress across the window, no active time elapsed (it is paused),
/// or the observed rate is too unsteady to extrapolate from. Each of those
/// would otherwise produce a figure — infinity, or one swinging by orders of
/// magnitude between polls — that is worse than an absent one.
Duration? estimateRemaining(List<RunSample> samples, {required int total}) {
  if (samples.length < _minimumSamples) return null;

  final rates = <double>[];
  for (var i = 1; i < samples.length; i++) {
    final deltaProcessed = samples[i].processed - samples[i - 1].processed;
    final deltaMillis = samples[i].activeMillis - samples[i - 1].activeMillis;
    if (deltaMillis <= 0) return null;
    rates.add(deltaProcessed / deltaMillis);
  }

  final fastest = rates.reduce((a, b) => a > b ? a : b);
  final slowest = rates.reduce((a, b) => a < b ? a : b);
  if (fastest <= 0) return null;
  if (slowest <= 0 || fastest / slowest > _maximumRateSpread) return null;

  final remaining = total - samples.last.processed;
  if (remaining <= 0) return Duration.zero;

  final overall =
      (samples.last.processed - samples.first.processed) /
      (samples.last.activeMillis - samples.first.activeMillis);

  return Duration(milliseconds: (remaining / overall).round());
}
