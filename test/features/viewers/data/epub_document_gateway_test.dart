import 'dart:convert';
import 'dart:io';

import 'package:alexandria_desktop/features/viewers/data/epub_document_gateway.dart';
import 'package:alexandria_desktop/features/viewers/domain/document_gateway.dart';
import 'package:alexandria_desktop/features/viewers/domain/file_viewer.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading a document from disk (UC-22 main flow step 3, AF-01 … AF-03).
void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('alexandria_epub');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  /// Writes an EPUB holding [entries] and answers its path.
  String anEpub(Map<String, String> entries) {
    final archive = Archive();
    for (final entry in entries.entries) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    final path = '${directory.path}/book.epub';
    File(path).writeAsBytesSync(ZipEncoder().encode(archive));

    return path;
  }

  /// The two documents every EPUB carries, pointing at [spine].
  Map<String, String> shell({
    required String spine,
    required String manifest,
    String title = 'A Book',
  }) => {
    'META-INF/container.xml':
        '<?xml version="1.0"?><container><rootfiles>'
        '<rootfile full-path="OEBPS/content.opf"/>'
        '</rootfiles></container>',
    'OEBPS/content.opf':
        '<?xml version="1.0"?>'
        '<package xmlns:dc="http://purl.org/dc/elements/1.1/">'
        '<metadata><dc:title>$title</dc:title></metadata>'
        '<manifest>$manifest</manifest>'
        '<spine>$spine</spine>'
        '</package>',
  };

  const gateway = EpubDocumentGateway();

  group('a PDF', () {
    test('GivenAPdf_WhenItIsOpened_ThenItsPathIsHandedToTheRenderer', () async {
      final path = '${directory.path}/report.pdf';
      File(path).writeAsStringSync('%PDF-1.7');

      final outcome = await gateway.open(path);

      expect(outcome, isA<DocumentIsPdf>());
      expect((outcome as DocumentIsPdf).path, path);
    });
  });

  group('an e-book', () {
    test('GivenAnEpub_WhenItIsOpened_ThenItsChaptersAreInSpineOrder', () async {
      final path = anEpub({
        ...shell(
          manifest:
              '<item id="two" href="two.xhtml"/><item id="one" href="one.xhtml"/>',
          spine: '<itemref idref="one"/><itemref idref="two"/>',
        ),
        'OEBPS/one.xhtml': '<html><body><p>First</p></body></html>',
        'OEBPS/two.xhtml': '<html><body><p>Second</p></body></html>',
      });

      final outcome = await gateway.open(path);

      expect(outcome, isA<DocumentIsBook>());
      final book = outcome as DocumentIsBook;
      expect(book.chapters, hasLength(2));
      expect(book.chapters.first.html, contains('First'));
      expect(book.chapters.last.html, contains('Second'));
    });

    test('GivenAnEpub_WhenItIsOpened_ThenItsTitleIsRead', () async {
      final path = anEpub({
        ...shell(
          title: 'Solaris',
          manifest: '<item id="one" href="one.xhtml"/>',
          spine: '<itemref idref="one"/>',
        ),
        'OEBPS/one.xhtml': '<html><body>text</body></html>',
      });

      expect(((await gateway.open(path)) as DocumentIsBook).title, 'Solaris');
    });

    // A stylesheet is in the manifest too, and it is not a chapter.
    test(
      'GivenAManifestEntryNotInTheSpine_WhenItIsOpened_ThenItIsNotAChapter',
      () async {
        final path = anEpub({
          ...shell(
            manifest:
                '<item id="one" href="one.xhtml"/><item id="css" href="style.css"/>',
            spine: '<itemref idref="one"/>',
          ),
          'OEBPS/one.xhtml': '<html><body>text</body></html>',
          'OEBPS/style.css': 'p { margin: 0 }',
        });

        expect(
          ((await gateway.open(path)) as DocumentIsBook).chapters,
          hasLength(1),
        );
      },
    );

    test(
      'GivenATableOfContents_WhenItIsOpened_ThenChaptersCarryTheirNames',
      () async {
        final path = anEpub({
          ...shell(
            manifest:
                '<item id="nav" href="nav.xhtml" properties="nav"/>'
                '<item id="one" href="one.xhtml"/>',
            spine: '<itemref idref="one"/>',
          ),
          'OEBPS/nav.xhtml':
              '<html><body><nav><ol><li>'
              '<a href="one.xhtml">The Beginning</a>'
              '</li></ol></nav></body></html>',
          'OEBPS/one.xhtml': '<html><body>text</body></html>',
        });

        expect(
          ((await gateway.open(path)) as DocumentIsBook).chapters.first.title,
          'The Beginning',
        );
      },
    );

    // Refusing the whole book over one absent file would be worse than
    // reading the rest of it.
    test(
      'GivenASpineEntryThatIsMissing_WhenItIsOpened_ThenTheRestIsRead',
      () async {
        final path = anEpub({
          ...shell(
            manifest:
                '<item id="one" href="one.xhtml"/><item id="gone" href="gone.xhtml"/>',
            spine: '<itemref idref="one"/><itemref idref="gone"/>',
          ),
          'OEBPS/one.xhtml': '<html><body>text</body></html>',
        });

        expect(
          ((await gateway.open(path)) as DocumentIsBook).chapters,
          hasLength(1),
        );
      },
    );
  });

  // AF-01: the file is absent from disk.
  group('a file that is not there', () {
    test('GivenNoFile_WhenItIsOpened_ThenItIsReportedAsMissing', () async {
      final outcome = await gateway.open('${directory.path}/nothing.epub');

      expect((outcome as DocumentFailed).failure, ViewerFailure.missingOnDisk);
    });
  });

  // AF-02: the file is corrupt, or not the format its extension claims.
  group('a file that is not what it claims', () {
    test(
      'GivenBytesThatAreNotAZip_WhenOpened_ThenItIsReportedAsUnreadable',
      () async {
        final path = '${directory.path}/book.epub';
        File(path).writeAsStringSync('this is not an archive');

        expect(
          ((await gateway.open(path)) as DocumentFailed).failure,
          ViewerFailure.unreadable,
        );
      },
    );

    test(
      'GivenAZipWithNoContainer_WhenOpened_ThenItIsReportedAsUnreadable',
      () async {
        final path = anEpub({'readme.txt': 'nothing here'});

        expect(
          ((await gateway.open(path)) as DocumentFailed).failure,
          ViewerFailure.unreadable,
        );
      },
    );

    test(
      'GivenABookWithNoChapters_WhenOpened_ThenItIsReportedAsUnreadable',
      () async {
        final path = anEpub(shell(manifest: '', spine: ''));

        expect(
          ((await gateway.open(path)) as DocumentFailed).failure,
          ViewerFailure.unreadable,
        );
      },
    );
  });

  // AF-03: the document is encrypted.
  group('a document nobody has the key to', () {
    test(
      'GivenAnEncryptedEpub_WhenItIsOpened_ThenItIsReportedAsEncrypted',
      () async {
        final path = anEpub({
          ...shell(
            manifest: '<item id="one" href="one.xhtml"/>',
            spine: '<itemref idref="one"/>',
          ),
          'META-INF/encryption.xml': '<encryption/>',
          'OEBPS/one.xhtml': '<html><body>text</body></html>',
        });

        expect(
          ((await gateway.open(path)) as DocumentFailed).failure,
          ViewerFailure.encrypted,
        );
      },
    );
  });
}
