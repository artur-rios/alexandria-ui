import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../domain/file_viewer.dart';
import '../domain/page_content.dart';
import 'page_styles.dart';

/// Reads a saved page from disk (UC-25 main flow step 2, FR-VW-07).
///
/// A Markdown file is converted to markup here rather than rendered by a
/// second renderer: one renderer means one set of theme styles and one answer
/// to what a link does, and the editor's preview is the only place the
/// Markdown widget is still the right tool (UC-18).
class DiskPageGateway implements PageGateway {
  /// Creates the gateway.
  const DiskPageGateway();

  /// The elements whose absence from disk the owner should be told about.
  ///
  /// Images, stylesheets, and frames — the things whose absence changes what
  /// the page looks like. A missing script is not listed, because none of them
  /// runs anyway (AF-03).
  static const Map<String, String> _assetAttributes = {
    'img': 'src',
    'link': 'href',
    'iframe': 'src',
  };

  @override
  Future<PageOutcome> read(String path, {required bool isMarkdown}) async {
    final file = File(path);
    if (!file.existsSync()) {
      return const PageFailed(failure: ViewerFailure.missingOnDisk);
    }

    final String source;
    try {
      source = await file.readAsString();
    } on Object {
      return const PageFailed(failure: ViewerFailure.unreadable);
    }

    final folder = p.dirname(path);

    // FR-VW-06: a Markdown file opened for reading is rendered rather than
    // edited. Converting it here is what puts both through the same renderer.
    //
    // An HTML page is also prepared for the renderer first: its own
    // stylesheets are folded onto the elements they style, because the
    // renderer reads a `style` attribute and nothing else, and its head's
    // text is dropped (`page_styles.dart`). Markdown skips that step — it was
    // just converted from text that carries neither.
    final html = isMarkdown
        ? md.markdownToHtml(source, extensionSet: md.ExtensionSet.gitHubWeb)
        : preparedForRendering(
            source,
            linkedStylesheet: (href) => _stylesheetAt(href, from: folder),
          );

    return PageRead(
      content: PageContent(
        html: html,
        // The folder the file came out of, so its own pictures resolve. A
        // directory rather than the file: `Uri.resolve` against a file would
        // take `assets/photo.jpg` as a sibling of the *page*, which is the
        // same thing here only by accident of the page being at the root of
        // its own folder.
        baseUrl: Uri.directory(folder),
        isMarkdown: isMarkdown,
        hasScript: !isMarkdown && _hasScript(source),
        // Read from the source rather than from the styled markup: the two
        // hold the same references, and the source is the file the owner is
        // being told about.
        missingAssets: _missingAssetsIn(source, from: folder),
        isMalformed: !isMarkdown && !_parses(source),
      ),
    );
  }

  /// The text of a stylesheet the page links, or `null` for one this
  /// application will not open.
  ///
  /// Local files only, and only ones that are there. A sheet on the network is
  /// not fetched — a saved page is read from the disk it was saved to, and
  /// reaching out to a site to draw a file the owner already has would be a
  /// request they never asked for. A missing one is already named to them
  /// (AF-02).
  static String? _stylesheetAt(String href, {required String from}) {
    if (href.isEmpty ||
        href.startsWith('http') ||
        href.startsWith('//') ||
        href.startsWith('data:')) {
      return null;
    }

    try {
      final file = File(p.normalize(p.join(from, Uri.decodeFull(href))));

      return file.existsSync() ? file.readAsStringSync() : null;
    } on Object {
      // A stylesheet that cannot be read styles nothing, which is the state
      // the page was already in. It is not a reason to refuse the page.
      return null;
    }
  }

  /// Whether the page carries script (AF-03).
  ///
  /// A text search rather than a parse, and deliberately: the answer is used
  /// only to *say* that scripts are not run, and a page too malformed to parse
  /// is exactly the kind that has a stray `<script>` in it.
  static bool _hasScript(String source) {
    final lowered = source.toLowerCase();

    return lowered.contains('<script') || lowered.contains('javascript:');
  }

  /// Whether the markup parses (AF-04).
  static bool _parses(String source) {
    try {
      XmlDocument.parse(source);
      return true;
    } on Object {
      // Most real HTML is not well-formed XML, so this is a conservative
      // reading: what it catches is a document nobody could parse, and the
      // renderer draws what it can either way.
      return false;
    }
  }

  /// The assets the page references and the disk does not have (AF-02).
  ///
  /// Only local ones. A page that references a stylesheet on the internet is
  /// not missing it in any sense this application can act on: nothing here
  /// fetches from the network, which is a property of the viewer and not a
  /// fault in the file.
  static List<String> _missingAssetsIn(String html, {required String from}) {
    final missing = <String>[];

    for (final entry in _assetAttributes.entries) {
      final pattern = RegExp(
        '<${entry.key}[^>]*${entry.value}="([^"]+)"',
        caseSensitive: false,
      );

      for (final match in pattern.allMatches(html)) {
        final reference = match.group(1);
        if (reference == null) continue;
        if (reference.startsWith('http') ||
            reference.startsWith('data:') ||
            reference.startsWith('//')) {
          continue;
        }

        final resolved = p.normalize(p.join(from, Uri.decodeFull(reference)));
        if (!File(resolved).existsSync()) missing.add(reference);
      }
    }

    return missing;
  }
}
