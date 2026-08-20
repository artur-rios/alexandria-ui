import 'package:alexandria_desktop/features/viewers/domain/file_viewer.dart';
import 'package:alexandria_desktop/features/viewers/domain/page_content.dart';

/// A [PageGateway] that never touches a disk (Testing Specification §2.3).
class FakePageGateway implements PageGateway {
  /// Creates a gateway answering a plain saved article.
  FakePageGateway({PageOutcome? outcome})
    : outcome =
          outcome ??
          const PageRead(content: PageContent(html: '<p>A saved article.</p>'));

  /// What [read] answers.
  PageOutcome outcome;

  /// Every path read, in order.
  ///
  /// Empty is the assertion FR-VW-07 needs: nothing is read until the owner
  /// opens the page. Named apart from the interface's own `read`, which a
  /// field of that name would collide with.
  final List<String> paths = [];

  /// Whether each read was asked for as Markdown.
  final List<bool> asMarkdown = [];

  @override
  Future<PageOutcome> read(String path, {required bool isMarkdown}) async {
    paths.add(path);
    asMarkdown.add(isMarkdown);

    return outcome;
  }

  /// A Markdown file, rendered.
  static const PageOutcome markdown = PageRead(
    content: PageContent(
      html: '<h1>Rendered heading</h1><p>Body.</p>',
      isMarkdown: true,
    ),
  );

  /// What a file that is not there answers (AF-01).
  static const PageOutcome missing = PageFailed(
    failure: ViewerFailure.missingOnDisk,
  );
}
