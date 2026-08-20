/// Why an issue number cannot be sent (UC-32 AF-02).
enum IssueError {
  /// Not a whole number.
  notANumber,

  /// Zero or negative. Issues are counted from one.
  notPositive,

  /// Past the total the owner stated.
  ///
  /// Checked against what they typed rather than against anything the core
  /// holds: the two fields are set together, and a current issue beyond its
  /// own total is a typo the owner can see.
  beyondTotal,
}

/// What the owner typed into the two issue fields (UC-32 step 4).
///
/// Raw strings, as everywhere a form holds a number: a half-typed issue is a
/// string and nothing else, and turning it into a number is the validation.
class IssueDraft {
  /// Creates a draft.
  const IssueDraft({this.current = '', this.total = ''});

  /// The issue the owner is on.
  final String current;

  /// How many there are, when they know.
  final String total;

  /// A copy with the given changes.
  IssueDraft copyWith({String? current, String? total}) =>
      IssueDraft(current: current ?? this.current, total: total ?? this.total);

  /// The issue number to send, or `null` when the field is empty.
  int? get currentIssue => int.tryParse(current.trim());

  /// The total to send, or `null` when the field is empty.
  int? get totalIssues => int.tryParse(total.trim());
}

/// What is wrong with [draft]'s current issue, or `null` (AF-02).
///
/// An empty field is not an error: it is how the owner says they have not
/// started, and the core stores nothing for it.
IssueError? validateCurrentIssue(IssueDraft draft) {
  final value = draft.current.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return IssueError.notANumber;
  if (number < 1) return IssueError.notPositive;

  final total = int.tryParse(draft.total.trim());
  if (total != null && number > total) return IssueError.beyondTotal;

  return null;
}

/// What is wrong with [draft]'s total, or `null` (AF-02).
IssueError? validateTotalIssues(IssueDraft draft) {
  final value = draft.total.trim();
  if (value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) return IssueError.notANumber;
  if (number < 1) return IssueError.notPositive;

  return null;
}
