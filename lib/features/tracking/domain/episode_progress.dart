/// Why an episode number cannot be sent (UC-30 AF-02).
enum EpisodeError {
  /// Not a whole number.
  notANumber,

  /// Zero or negative. Episodes are counted from one.
  notPositive,

  /// Past the total the owner stated.
  ///
  /// Checked against what they typed rather than against anything the core
  /// holds: the two fields are set together, and a current episode beyond its
  /// own total is a typo the owner can see.
  beyondTotal,
}

/// What the owner typed into the two episode fields (UC-30 step 4).
///
/// Raw strings, as everywhere a form holds a number: a half-typed episode is a
/// string and nothing else, and turning it into a number is the validation.
class EpisodeDraft {
  /// Creates a draft.
  const EpisodeDraft({this.current = '', this.total = ''});

  /// The episode the owner is on.
  final String current;

  /// How many there are, when they know.
  final String total;

  /// A copy with the given changes.
  EpisodeDraft copyWith({String? current, String? total}) => EpisodeDraft(
    current: current ?? this.current,
    total: total ?? this.total,
  );

  /// The episode number to send, or `null` when the field is empty.
  int? get currentEpisode => int.tryParse(current.trim());

  /// The total to send, or `null` when the field is empty.
  int? get totalEpisodes => int.tryParse(total.trim());
}

/// What is wrong with [draft]'s current episode, or `null` (AF-02).
///
/// An empty field is not an error: it is how the owner says they have not
/// started, and the core stores nothing for it.
EpisodeError? validateCurrentEpisode(EpisodeDraft draft) {
  final value = draft.current.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return EpisodeError.notANumber;
  if (number < 1) return EpisodeError.notPositive;

  final total = int.tryParse(draft.total.trim());
  if (total != null && number > total) return EpisodeError.beyondTotal;

  return null;
}

/// What is wrong with [draft]'s total, or `null` (AF-02).
EpisodeError? validateTotalEpisodes(EpisodeDraft draft) {
  final value = draft.total.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return EpisodeError.notANumber;
  if (number < 1) return EpisodeError.notPositive;

  return null;
}
