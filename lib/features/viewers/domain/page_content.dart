import 'file_viewer.dart';

/// How a saved page's markup reads once it has been looked at (UC-25).
class PageContent {
  /// Creates page content.
  const PageContent({
    required this.html,
    this.isMarkdown = false,
    this.hasScript = false,
    this.missingAssets = const [],
    this.isMalformed = false,
  });

  /// The markup, as it will be rendered.
  final String html;

  /// Whether it came from a Markdown file rather than an HTML one
  /// (FR-VW-06).
  final bool isMarkdown;

  /// Whether the page carries script (AF-03).
  ///
  /// None of it runs either way — the renderer draws widgets and has no
  /// engine to run it in. This is here so the application can *say* so, which
  /// is what the flow asks for: a page whose interactive parts do nothing
  /// should explain itself rather than look broken.
  final bool hasScript;

  /// The assets the page references and the disk does not have (AF-02).
  final List<String> missingAssets;

  /// Whether the markup did not parse cleanly (AF-04).
  final bool isMalformed;
}

/// What reading a saved page produced (UC-25 main flow step 2).
sealed class PageOutcome {
  const PageOutcome();
}

/// The page was read.
class PageRead extends PageOutcome {
  /// Creates the outcome.
  const PageRead({required this.content});

  /// What it holds.
  final PageContent content;
}

/// It could not be (AF-01).
class PageFailed extends PageOutcome {
  /// Creates the outcome.
  const PageFailed({required this.failure});

  /// Why.
  final ViewerFailure failure;
}

/// Reads a saved page at the moment it is opened (FR-VW-05, FR-VW-06,
/// FR-VW-07).
abstract interface class PageGateway {
  /// Reads the page at [path].
  ///
  /// [isMarkdown] selects which of the two the file is, which the caller
  /// knows from the record's type and the reader would otherwise have to
  /// guess from an extension.
  Future<PageOutcome> read(String path, {required bool isMarkdown});
}
