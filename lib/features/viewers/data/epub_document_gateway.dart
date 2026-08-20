import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../domain/document_gateway.dart';
import '../domain/file_viewer.dart';

/// Reads PDFs and EPUBs from disk (UC-22 main flow step 3, FR-VW-07).
///
/// A PDF is handed to its own renderer as a path. An EPUB is a zip carrying
/// XHTML, so it is read here into chapters the page renderer draws — the same
/// renderer UC-25 uses for a saved page, which is why the chapters come out as
/// markup rather than as widgets.
///
/// Written against `archive` and `xml` rather than an EPUB package: the one
/// the Technology Stack Document names, `epub_view`, pins a pre-null-safety
/// SDK, and every maintained alternative pins `image` 3 against media_kit's 4.
/// The format itself is a container document, a package document, and a spine,
/// which is what this reads.
class EpubDocumentGateway implements DocumentGateway {
  /// Creates the gateway.
  const EpubDocumentGateway();

  /// Where an EPUB always keeps the pointer to its package document.
  static const String _containerPath = 'META-INF/container.xml';

  @override
  Future<DocumentOutcome> open(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return const DocumentFailed(failure: ViewerFailure.missingOnDisk);
    }

    if (p.extension(path).toLowerCase() == '.pdf') {
      return DocumentIsPdf(path: path);
    }

    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());

      // AF-03: an encrypted EPUB carries an encryption declaration, and this
      // application neither prompts for a password nor stores one.
      if (archive.findFile('META-INF/encryption.xml') != null) {
        return const DocumentFailed(failure: ViewerFailure.encrypted);
      }

      final packagePath = _packagePathIn(archive);
      if (packagePath == null) {
        return const DocumentFailed(failure: ViewerFailure.unreadable);
      }

      return _bookFrom(archive, packagePath);
    } on Object {
      // Broad by intent: a file that is not a zip surfaces as one exception
      // and malformed markup as another, and both mean the same thing to the
      // owner — this is not the document its name claims (AF-02).
      return const DocumentFailed(failure: ViewerFailure.unreadable);
    }
  }

  /// The package document's path, read from the container.
  String? _packagePathIn(Archive archive) {
    final container = archive.findFile(_containerPath);
    if (container == null) return null;

    final document = XmlDocument.parse(utf8.decode(container.content));
    final rootfile = document.findAllElements('rootfile').firstOrNull;

    return rootfile?.getAttribute('full-path');
  }

  /// The book the package document describes.
  DocumentOutcome _bookFrom(Archive archive, String packagePath) {
    final package = archive.findFile(packagePath);
    if (package == null) {
      return const DocumentFailed(failure: ViewerFailure.unreadable);
    }

    final document = XmlDocument.parse(utf8.decode(package.content));
    final base = p.url.dirname(packagePath);

    // The manifest says what the book holds; the spine says in what order it
    // is read. A file in the manifest and not in the spine is not a chapter —
    // a stylesheet is in there too.
    final manifest = {
      for (final item in document.findAllElements('item'))
        ?item.getAttribute('id'): item.getAttribute('href') ?? '',
    };

    final titles = _titlesByHref(archive, document, base);
    final chapters = <DocumentChapter>[];

    for (final reference in document.findAllElements('itemref')) {
      final href = manifest[reference.getAttribute('idref')];
      if (href == null || href.isEmpty) continue;

      final entryPath = base.isEmpty ? href : p.url.join(base, href);
      final entry = archive.findFile(entryPath);
      // A spine entry the archive does not hold is a chapter that is not
      // there. The rest of the book still reads, which is better than
      // refusing all of it over one missing file.
      if (entry == null) continue;

      chapters.add(
        DocumentChapter(
          title: titles[href] ?? _fallbackTitle(chapters.length),
          html: utf8.decode(entry.content, allowMalformed: true),
        ),
      );
    }

    if (chapters.isEmpty) {
      return const DocumentFailed(failure: ViewerFailure.unreadable);
    }

    return DocumentIsBook(
      title: document.findAllElements('dc:title').firstOrNull?.innerText,
      chapters: chapters,
    );
  }

  /// The chapter titles the book's own table of contents gives, by href.
  ///
  /// Read from the EPUB 3 navigation document where there is one and the
  /// EPUB 2 `toc.ncx` otherwise, because a book in the wild is as likely to
  /// be either.
  Map<String, String> _titlesByHref(
    Archive archive,
    XmlDocument package,
    String base,
  ) {
    final titles = <String, String>{};

    for (final item in package.findAllElements('item')) {
      final href = item.getAttribute('href');
      if (href == null) continue;

      final isNavigation =
          item.getAttribute('properties')?.contains('nav') ?? false;
      final isNcx = href.toLowerCase().endsWith('.ncx');
      if (!isNavigation && !isNcx) continue;

      final entry = archive.findFile(
        base.isEmpty ? href : p.url.join(base, href),
      );
      if (entry == null) continue;

      try {
        final document = XmlDocument.parse(
          utf8.decode(entry.content, allowMalformed: true),
        );

        // EPUB 3: an ordered list of anchors. EPUB 2: navPoint elements.
        for (final anchor in document.findAllElements('a')) {
          final target = anchor.getAttribute('href')?.split('#').first;
          if (target != null) titles[target] = anchor.innerText.trim();
        }
        for (final point in document.findAllElements('navPoint')) {
          final target = point
              .findAllElements('content')
              .firstOrNull
              ?.getAttribute('src')
              ?.split('#')
              .first;
          final label = point.findAllElements('text').firstOrNull?.innerText;
          if (target != null && label != null) titles[target] = label.trim();
        }
      } on Object {
        // A table of contents that will not parse costs the chapters their
        // names and nothing else.
        continue;
      }
    }

    return titles;
  }

  static String _fallbackTitle(int index) => '${index + 1}';
}
