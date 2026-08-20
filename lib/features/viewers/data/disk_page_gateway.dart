import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../domain/file_viewer.dart';
import '../domain/page_content.dart';

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

    // FR-VW-06: a Markdown file opened for reading is rendered rather than
    // edited. Converting it here is what puts both through the same renderer.
    final html = isMarkdown
        ? md.markdownToHtml(source, extensionSet: md.ExtensionSet.gitHubWeb)
        : source;

    return PageRead(
      content: PageContent(
        html: html,
        isMarkdown: isMarkdown,
        hasScript: !isMarkdown && _hasScript(source),
        missingAssets: _missingAssetsIn(html, from: p.dirname(path)),
        isMalformed: !isMarkdown && !_parses(source),
      ),
    );
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
