import 'library_source.dart';

/// Why a folder cannot be registered, or what the owner must confirm first
/// (FR-LB-02, UC-05 AF-02 … AF-04).
///
/// Named conditions rather than messages: the domain decides what is wrong and
/// the presentation layer localizes it, so the same verdict reads correctly in
/// both supported languages.
enum FolderRegistrationVerdict {
  /// The folder can be registered as it is.
  acceptable,

  /// There is no folder at that path (AF-02).
  missing,

  /// The folder is there but cannot be read (AF-02).
  unreadable,

  /// The folder is already registered (AF-03).
  ///
  /// FR-LB-02 requires the three refusals be told apart, which is why this is
  /// not folded into [missing] and [unreadable] as one "no".
  alreadyRegistered,

  /// The folder overlaps one already registered — it contains one, or sits
  /// inside one (AF-04).
  ///
  /// Not a refusal. The owner is warned that files will be indexed once per
  /// overlapping source and decides; a duplicate is a real thing to want when
  /// two folders are indexed with different labels.
  overlaps,
}

/// Whether [verdict] stops the registration outright.
///
/// [FolderRegistrationVerdict.overlaps] deliberately does not: it is a warning
/// the owner can accept.
bool refuses(FolderRegistrationVerdict verdict) =>
    verdict != FolderRegistrationVerdict.acceptable &&
    verdict != FolderRegistrationVerdict.overlaps;

/// The registered source [path] duplicates or overlaps, if any.
///
/// Returned rather than a boolean so AF-03 can highlight the existing entry and
/// AF-04 can name the folder the owner is being warned about.
LibrarySource? conflictingSource(
  String path,
  Iterable<LibrarySource> registered,
) {
  final candidate = normalizeFolderPath(path);

  for (final source in registered) {
    final existing = normalizeFolderPath(source.path);
    if (existing == candidate ||
        _contains(existing, candidate) ||
        _contains(candidate, existing)) {
      return source;
    }
  }

  return null;
}

/// The verdict for [path] against what is already [registered].
///
/// [exists] and [readable] are answered by the filesystem, which the domain
/// does not touch — the caller probes and passes the answers in.
FolderRegistrationVerdict verdictFor({
  required String path,
  required bool exists,
  required bool readable,
  required Iterable<LibrarySource> registered,
}) {
  // Existence first: a path with nothing at it is neither unreadable nor a
  // duplicate, and saying "already registered" about a folder that is gone
  // would send the owner looking for the wrong problem.
  if (!exists) return FolderRegistrationVerdict.missing;
  if (!readable) return FolderRegistrationVerdict.unreadable;

  final conflict = conflictingSource(path, registered);
  if (conflict == null) return FolderRegistrationVerdict.acceptable;

  return normalizeFolderPath(conflict.path) == normalizeFolderPath(path)
      ? FolderRegistrationVerdict.alreadyRegistered
      : FolderRegistrationVerdict.overlaps;
}

/// The default label for a folder: its own name (main flow step 4).
///
/// Falls back to the whole path for a drive or filesystem root, which has no
/// name to take — an empty label would list as a blank row.
String defaultLabelFor(String path) {
  final normalized = normalizeFolderPath(path);
  final separator = normalized.lastIndexOf('/');
  if (separator < 0) return normalized;

  final name = normalized.substring(separator + 1);
  return name.isEmpty ? normalized : name;
}

/// A path in one shape, so two spellings of the same folder compare equal.
///
/// Backslashes become forward slashes and a trailing separator is dropped, so
/// `C:\Music\` and `C:/Music` are one folder. Case is left alone: Windows
/// paths are case-insensitive and Linux paths are not, and lowercasing here
/// would merge two genuinely different folders on Linux to spare Windows a
/// duplicate the owner would notice immediately.
String normalizeFolderPath(String path) {
  final slashed = path.replaceAll(r'\', '/');
  if (slashed.length > 1 && slashed.endsWith('/')) {
    return slashed.substring(0, slashed.length - 1);
  }
  return slashed;
}

/// Whether [ancestor] contains [descendant].
///
/// The trailing separator is what stops `/music` from containing
/// `/music-videos`: without it the prefix check is true and two unrelated
/// folders read as overlapping.
bool _contains(String ancestor, String descendant) =>
    descendant.startsWith('$ancestor/');
