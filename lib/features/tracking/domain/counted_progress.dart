/// Why a position in a numbered sequence cannot be sent (UC-30 and UC-32,
/// both AF-02).
///
/// Shared by episodes and issues. The two were the same enum, the same draft
/// and the same two validators written out twice, with `Episode` swapped for
/// `Issue` and nothing else changed — so a rule fixed in one was a rule still
/// wrong in the other. What genuinely differs between them is the *wording*,
/// and that lives in each screen's own message mapping rather than here.
enum CountedProgressError {
  /// Not a whole number.
  notANumber,

  /// Zero or negative. Episodes and issues are counted from one.
  notPositive,

  /// Past the total the owner stated.
  ///
  /// Checked against what they typed rather than against anything the core
  /// holds: the two fields are set together, and a current position beyond
  /// its own total is a typo the owner can see.
  beyondTotal,
}

/// What the owner typed into a pair of "where I am / how many there are"
/// fields (UC-30 and UC-32, step 4).
///
/// Raw strings, as everywhere a form holds a number: a half-typed episode is
/// a string and nothing else, and turning it into a number is the validation.
class CountedProgressDraft {
  /// Creates a draft.
  const CountedProgressDraft({this.current = '', this.total = ''});

  /// The position the owner is on.
  final String current;

  /// How many there are, when they know.
  final String total;

  /// A copy with the given changes.
  CountedProgressDraft copyWith({String? current, String? total}) =>
      CountedProgressDraft(
        current: current ?? this.current,
        total: total ?? this.total,
      );

  /// The position to send, or `null` when the field is empty.
  int? get currentValue => int.tryParse(current.trim());

  /// The total to send, or `null` when the field is empty.
  int? get totalValue => int.tryParse(total.trim());
}

/// What is wrong with [draft]'s current position, or `null` (AF-02).
///
/// An empty field is not an error: it is how the owner says they have not
/// started, and the core stores nothing for it.
CountedProgressError? validateCurrentCount(CountedProgressDraft draft) {
  final value = draft.current.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return CountedProgressError.notANumber;
  if (number < 1) return CountedProgressError.notPositive;

  final total = int.tryParse(draft.total.trim());
  if (total != null && number > total) return CountedProgressError.beyondTotal;

  return null;
}

/// What is wrong with [draft]'s total, or `null` (AF-02).
CountedProgressError? validateTotalCount(CountedProgressDraft draft) {
  final value = draft.total.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return CountedProgressError.notANumber;
  if (number < 1) return CountedProgressError.notPositive;

  return null;
}
