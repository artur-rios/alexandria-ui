import 'dart:io';

import 'package:alexandria_ui/features/viewers/data/disk_page_gateway.dart';
import 'package:alexandria_ui/features/viewers/domain/file_viewer.dart';
import 'package:alexandria_ui/features/viewers/domain/page_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Reading a saved page from disk (UC-25 main flow step 2, AF-01 … AF-04).
void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('alexandria_page');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  /// Writes [source] to [name] and answers its path.
  String aFileHolding(String source, {String name = 'page.html'}) {
    final path = '${directory.path}/$name';
    File(path).writeAsStringSync(source);

    return path;
  }

  const gateway = DiskPageGateway();

  Future<PageContent> read(String path, {bool isMarkdown = false}) async =>
      ((await gateway.read(path, isMarkdown: isMarkdown)) as PageRead).content;

  group('a saved HTML page', () {
    test('GivenAPage_WhenItIsRead_ThenItsMarkupComesBack', () async {
      final path = aFileHolding('<html><body><p>Saved.</p></body></html>');

      expect((await read(path)).html, contains('Saved.'));
    });

    test('GivenAPage_WhenItIsRead_ThenItIsNotMarkdown', () async {
      final path = aFileHolding('<html><body>x</body></html>');

      expect((await read(path)).isMarkdown, isFalse);
    });
  });

  group("a page's own styling (UC-25 main flow step 3)", () {
    test('GivenALinkedSheetBesideIt_WhenItIsRead_ThenItsRulesAreApplied', () {
      // The shape a page is actually saved in: the markup in one file and the
      // styling in another beside it. Read from disk here rather than handed
      // in, because finding that file is the gateway's half of the job.
      File('${directory.path}/site.css').writeAsStringSync('p { color: red; }');
      final path = aFileHolding(
        '<html><head><link rel="stylesheet" href="site.css"></head>'
        '<body><p>Words</p></body></html>',
      );

      expectLater(
        read(path).then((content) => content.html),
        completion(contains('style="color: red"')),
      );
    });

    test('GivenASheetOnTheNetwork_WhenItIsRead_ThenItIsNotFetched', () async {
      // A saved page is read from the disk it was saved to. Reaching out to a
      // site to draw a file the owner already has would be a request they
      // never made — and the missing-asset notice already tells them what the
      // page is without.
      final path = aFileHolding(
        '<html><head>'
        '<link rel="stylesheet" href="https://example.com/site.css">'
        '</head><body><p>Words</p></body></html>',
      );

      final content = await read(path);

      expect(content.html, contains('Words'));
      expect(content.html, isNot(contains('style=')));
    });

    test(
      'GivenAPage_WhenItIsRead_ThenItsFolderIsWhatReferencesResolveTo',
      () async {
        // Without this the renderer drops `src="assets/photo.jpg"` entirely: a
        // relative reference with nothing to resolve against is not a reference
        // at all, and the page draws its words with none of its pictures.
        final path = aFileHolding('<html><body><p>x</p></body></html>');

        expect((await read(path)).baseUrl, Uri.directory(directory.path));
      },
    );

    // A page is content from elsewhere, and what it links is opened by
    // this application with the owner's own permissions. A sheet outside the
    // page's folder is any file on the disk — a device that never ends, a
    // pipe that never answers, a key file parsed as CSS.
    test(
      'GivenASheetOutsideItsFolder_WhenItIsRead_ThenItIsNotOpened',
      () async {
        final outside = File('${directory.path}-outside.css')
          ..writeAsStringSync('p { color: red; }');
        addTearDown(outside.deleteSync);
        final path = aFileHolding(
          '<html><head><link rel="stylesheet" '
          'href="../${p.basename(outside.path)}"></head>'
          '<body><p>Words</p></body></html>',
        );

        expect((await read(path)).html, isNot(contains('style=')));
      },
    );

    test('GivenASheetByAbsolutePath_WhenItIsRead_ThenItIsNotOpened', () async {
      final sheet = File('${directory.path}/site.css')
        ..writeAsStringSync('p { color: red; }');
      final path = aFileHolding(
        '<html><head><link rel="stylesheet" href="${sheet.path}"></head>'
        '<body><p>Words</p></body></html>',
      );

      expect((await read(path)).html, isNot(contains('style=')));
    });

    test('GivenMarkdown_WhenItIsRead_ThenNothingIsInlined', () async {
      // It was converted from text a moment ago; there is no stylesheet to
      // read and no head to strip.
      final path = aFileHolding('# Title', name: 'notes.md');

      expect(
        (await read(path, isMarkdown: true)).html,
        isNot(contains('style=')),
      );
    });
  });

  // FR-VW-06: a Markdown file opened for reading is rendered.
  group('a Markdown file', () {
    test('GivenMarkdown_WhenItIsRead_ThenItIsConvertedToMarkup', () async {
      final path = aFileHolding('# Title\n\nA paragraph.', name: 'notes.md');

      final content = await read(path, isMarkdown: true);

      expect(content.html, contains('<h1'));
      expect(content.html, contains('A paragraph.'));
      expect(content.isMarkdown, isTrue);
    });

    // The whole of AF-03 and AF-04 is about markup somebody else wrote.
    test('GivenMarkdown_WhenItIsRead_ThenNoMarkupWarningIsRaised', () async {
      final path = aFileHolding('# Title', name: 'notes.md');

      final content = await read(path, isMarkdown: true);

      expect(content.hasScript, isFalse);
      expect(content.isMalformed, isFalse);
    });
  });

  // AF-01: the file is absent from disk.
  group('a file that is not there', () {
    test('GivenNoFile_WhenItIsRead_ThenItIsReportedAsMissing', () async {
      final outcome = await gateway.read(
        '${directory.path}/nothing.html',
        isMarkdown: false,
      );

      expect((outcome as PageFailed).failure, ViewerFailure.missingOnDisk);
    });
  });

  // AF-02: the page references assets that are absent.
  group('assets the page refers to', () {
    test('GivenAMissingImage_WhenThePageIsRead_ThenItIsNamed', () async {
      final path = aFileHolding('<img src="photo.png">');

      expect((await read(path)).missingAssets, ['photo.png']);
    });

    test(
      'GivenAnAssetThatIsThere_WhenThePageIsRead_ThenNothingIsMissing',
      () async {
        File('${directory.path}/photo.png').writeAsStringSync('bytes');
        final path = aFileHolding('<img src="photo.png">');

        expect((await read(path)).missingAssets, isEmpty);
      },
    );

    test('GivenAMissingStylesheet_WhenThePageIsRead_ThenItIsNamed', () async {
      final path = aFileHolding('<link rel="stylesheet" href="site.css">');

      expect((await read(path)).missingAssets, ['site.css']);
    });

    // Nothing here fetches from the network, so a remote reference is not
    // something this application can call missing.
    test(
      'GivenARemoteAsset_WhenThePageIsRead_ThenItIsNotCalledMissing',
      () async {
        final path = aFileHolding('<img src="https://example.com/photo.png">');

        expect((await read(path)).missingAssets, isEmpty);
      },
    );

    // Probing a reference is touching the disk it names. A UNC path or a
    // `file://host/` one is a connection to someone else's server on Windows
    // — and the owner's credentials offered to it — just for opening a page.
    test(
      'GivenAReferenceOutsideTheFolder_WhenThePageIsRead_ThenItIsNotProbed',
      () async {
        final path = aFileHolding(
          r'<img src="\\attacker\share\x.png">'
          '<img src="file://attacker/share/y.png">'
          '<img src="/etc/does-not-exist.png">'
          '<img src="../../elsewhere.png">',
        );

        expect((await read(path)).missingAssets, isEmpty);
      },
    );

    test(
      'GivenAReferenceWithAQuery_WhenThePageIsRead_ThenTheFileItNamesIsChecked',
      () async {
        File('${directory.path}/site.css').writeAsStringSync('');
        File('${directory.path}/icons.svg').writeAsStringSync('');
        final path = aFileHolding(
          '<link rel="stylesheet" href="site.css?ver=5">'
          '<img src="icons.svg#home">'
          '<img src="HTTPS://example.com/remote.png">',
        );

        expect((await read(path)).missingAssets, isEmpty);
      },
    );

    test(
      'GivenAnInlineAsset_WhenThePageIsRead_ThenItIsNotCalledMissing',
      () async {
        final path = aFileHolding('<img src="data:image/png;base64,AAAA">');

        expect((await read(path)).missingAssets, isEmpty);
      },
    );
  });

  // AF-03: the page contains script.
  group('script in the page', () {
    test('GivenAScriptTag_WhenThePageIsRead_ThenItIsNoted', () async {
      final path = aFileHolding('<script>alert(1)</script><p>text</p>');

      expect((await read(path)).hasScript, isTrue);
    });

    test('GivenAJavascriptLink_WhenThePageIsRead_ThenItIsNoted', () async {
      final path = aFileHolding('<a href="javascript:void(0)">click</a>');

      expect((await read(path)).hasScript, isTrue);
    });

    test('GivenNoScript_WhenThePageIsRead_ThenNothingIsNoted', () async {
      final path = aFileHolding('<p>Just text.</p>');

      expect((await read(path)).hasScript, isFalse);
    });
  });

  // AF-04: the markup is malformed.
  group('markup that does not parse', () {
    test(
      'GivenAnUnclosedTag_WhenThePageIsRead_ThenItIsReportedAsIncomplete',
      () async {
        final path = aFileHolding('<html><body><p>text</body></html>');

        expect((await read(path)).isMalformed, isTrue);
      },
    );

    test(
      'GivenWellFormedMarkup_WhenThePageIsRead_ThenNothingIsReported',
      () async {
        final path = aFileHolding('<html><body><p>text</p></body></html>');

        expect((await read(path)).isMalformed, isFalse);
      },
    );
  });
}
