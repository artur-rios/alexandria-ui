import 'file_viewer.dart';

/// One chapter of an e-book, as the viewer presents it (FR-VW-02).
class DocumentChapter {
  /// Creates a chapter.
  const DocumentChapter({required this.title, required this.html});

  /// What the book calls it, or a generated name when it names none.
  final String title;

  /// Its content, as markup the page renderer draws.
  ///
  /// Markup rather than widgets, because rendering it is the presentation's
  /// and the same renderer draws a saved page in UC-25.
  final String html;
}

/// What opening a document produced (UC-22 main flow steps 3 and 4).
sealed class DocumentOutcome {
  const DocumentOutcome();
}

/// A PDF, which its own renderer draws from the path.
///
/// The bytes are not carried here: pdfrx opens the file itself, and reading a
/// hundred megabytes into memory to hand it back would be worse at every size
/// that matters.
class DocumentIsPdf extends DocumentOutcome {
  /// Creates the outcome.
  const DocumentIsPdf({required this.path});

  /// Where the file is.
  final String path;
}

/// An e-book, read into its chapters.
class DocumentIsBook extends DocumentOutcome {
  /// Creates the outcome.
  const DocumentIsBook({required this.title, required this.chapters});

  /// What the book calls itself, when it says.
  final String? title;

  /// Its chapters, in reading order.
  final List<DocumentChapter> chapters;
}

/// The document could not be presented (AF-01, AF-02, AF-03).
class DocumentFailed extends DocumentOutcome {
  /// Creates the outcome.
  const DocumentFailed({required this.failure});

  /// Why.
  final ViewerFailure failure;
}

/// Reads a document at the moment it is opened (FR-VW-07).
///
/// Behind an interface for the usual reason and one more: a document is bytes
/// on disk, and a widget test has no disk to put them on.
abstract interface class DocumentGateway {
  /// Opens the document at [path] (main flow step 3).
  Future<DocumentOutcome> open(String path);
}
