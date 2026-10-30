import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:webview_cef/webview_cef.dart';

/// The page viewer's browser engine, against the real Chromium (UC-25,
/// FR-VW-05, NFR-12).
///
/// A saved page is somebody else's markup and script, opened from the
/// owner's disk. What keeps that safe is the engine's own configuration —
/// web security on, the sandbox on, popups and navigations held to the
/// page's folder — and none of it is visible to the widget suite, which has
/// no Chromium. So this suite opens a hostile page in the real engine and
/// asserts on what its script managed to do.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Chromium's sandbox refuses to run as root, and this build has no
  // sandboxed launch on Windows (FORK.md), so on those the engine must
  // refuse to start; everywhere else it must start, sandboxed.
  final engineExpected = Platform.isLinux && !_runningAsRoot();

  late Directory root;
  late Directory folder;
  late File page;

  setUp(() {
    // Two levels: the page's own folder, and a parent holding a file the
    // page must not reach — the library around a saved page.
    root = Directory.systemTemp.createTempSync('alexandria_page_engine_');
    folder = Directory(p.join(root.path, 'saved'))..createSync();
    File(p.join(root.path, 'secret.txt')).writeAsStringSync('not yours');
    File(p.join(root.path, 'outside.png')).writeAsBytesSync(_onePixelPng);
    File(p.join(folder.path, 'inside.png')).writeAsBytesSync(_onePixelPng);
    page = File(p.join(folder.path, 'page.html'))
      ..writeAsStringSync(
        _hostilePage(
          outsideText: Uri.file(p.join(root.path, 'secret.txt')).toString(),
          outsideImage: Uri.file(p.join(root.path, 'outside.png')).toString(),
        ),
      );
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  testWidgets(
    'GivenAHostileSavedPage_WhenTheEngineRunsIt_ThenItReadsNoLocalFileAndStaysInItsFolder',
    skip: !engineExpected,
    (tester) async {
      final results = Completer<Map<String, Object?>>();
      final visited = <String>[];
      final linksRequested = <String>[];

      final controller = WebviewManager().createWebView();
      controller.setWebviewListener(
        WebviewEventsListener(
          onTitleChanged: (title) {
            if (title.startsWith('RESULT:') && !results.isCompleted) {
              results.complete(
                jsonDecode(title.substring('RESULT:'.length))
                    as Map<String, Object?>,
              );
            }
          },
          onUrlChanged: visited.add,
          onLoadStart: (_, url) => visited.add(url),
          onOpenLinkRequested: linksRequested.add,
        ),
      );

      PlatformException? refusal;
      await tester.runAsync(() async {
        try {
          if (!WebviewManager().value) await WebviewManager().initialize();
          await controller.initialize(page.uri.toString());
        } on PlatformException catch (e) {
          refusal = e;
        }
      });
      if (refusal != null) {
        // A Linux machine with no usable sandbox. CI's runner has one (the
        // workflow lifts Ubuntu's AppArmor restriction on user namespaces);
        // a developer machine may need the same, or the setuid helper.
        fail('the page engine refused to start: ${refusal!.message}');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ValueListenableBuilder<bool>(
                valueListenable: controller,
                builder: (context, ready, _) =>
                    ready ? controller.webviewWidget : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      final reported = await tester.runAsync(
        () => results.future.timeout(const Duration(seconds: 30)),
      );
      debugPrint('engine results: $reported');

      // The owner clicks the two links the page covers itself with: the left
      // half opens a new window, the right half navigates the page. Neither
      // may take the engine anywhere; both are handed to the application.
      //
      // A click is only seen once the engine has taken the widget's size and
      // laid the page out at it, which happens asynchronously after the first
      // frame — on a slow runner, well after the script has reported. So each
      // link is clicked until the application hears of it, for a bounded time.
      Future<int> clickUntilOffered(Offset at, String url) async {
        for (var attempt = 1; attempt <= 10; attempt++) {
          await tester.pump();
          await tester.tapAt(at);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 1)),
          );
          if (linksRequested.contains(url)) return attempt;
        }
        return -1;
      }

      final popupClicks = await clickUntilOffered(
        const Offset(200, 300),
        'https://example.com/clicked-popup',
      );
      final linkClicks = await clickUntilOffered(
        const Offset(600, 300),
        'https://example.com/clicked-link',
      );
      debugPrint('clicks until offered: popup $popupClicks, link $linkClicks');

      // The navigations the script and the clicks asked for are
      // asynchronous; give the engine time to have made them if it was going
      // to.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      debugPrint('visited: $visited; links requested: $linksRequested');

      expect(reported, isNotNull);
      expect(
        reported!['xhrSystemFile'],
        startsWith('blocked'),
        reason: 'XMLHttpRequest read /etc/hostname',
      );
      expect(
        reported['fetchSystemFile'],
        startsWith('blocked'),
        reason: 'fetch() read /etc/hostname',
      );
      expect(
        reported['xhrOutsideFolder'],
        startsWith('blocked'),
        reason: 'XMLHttpRequest read a file beside the page folder',
      );
      expect(
        reported['imageOutsideFolder'],
        'blocked',
        reason: 'an <img> outside the page folder was loaded',
      );
      expect(
        reported['imageInsideFolder'],
        'loaded',
        reason: "the page's own picture must still load",
      );

      final folderUrl = '${folder.uri}';
      final strayed = visited
          .where((url) => url.isNotEmpty && url != 'about:blank')
          .where((url) => !url.startsWith(folderUrl))
          .toList();
      expect(
        strayed,
        isEmpty,
        reason: 'the page navigated out of its folder: $strayed',
      );
      expect(
        reported['popup'],
        'blocked',
        reason: 'window.open() created a window',
      );
      // As a set: a click repeated while the engine was still getting ready
      // may be offered twice, which is harmless. What matters is that both
      // clicked links arrive and nothing the script opened does.
      expect(
        linksRequested.toSet(),
        {
          'https://example.com/clicked-popup',
          'https://example.com/clicked-link',
        },
        reason:
            'only the two links the owner clicked are offered to the '
            'application; the scripted window.open() calls are not',
      );

      await tester.runAsync(controller.dispose);
    },
  );

  testWidgets(
    'GivenNoUsableSandbox_WhenTheEngineIsStarted_ThenItRefusesAndSaysWhy',
    skip: engineExpected,
    (tester) async {
      Object? error;
      await tester.runAsync(() async {
        try {
          await WebviewManager().initialize();
        } on Object catch (e) {
          error = e;
        }
      });

      expect(error, isA<PlatformException>());
      final refusal = error! as PlatformException;
      debugPrint('engine refused: ${refusal.message}');
      expect(refusal.code, 'sandbox-unavailable');
      expect(refusal.message, contains('sandbox'));
      expect(WebviewManager().value, isFalse);
    },
  );
}

/// Whether this process runs as root, which Chromium's sandbox refuses.
bool _runningAsRoot() {
  if (!Platform.isLinux) return false;
  final result = Process.runSync('id', ['-u']);
  return result.exitCode == 0 && '${result.stdout}'.trim() == '0';
}

/// A page whose script tries everything a hostile saved page would, and puts
/// the outcome in its title.
String _hostilePage({
  required String outsideText,
  required String outsideImage,
}) =>
    '''
<!doctype html>
<html><head><meta charset="utf-8"><title>loading</title></head>
<body style="margin:0">
<a href="https://example.com/clicked-popup" target="_blank"
   style="position:fixed;left:0;top:0;width:50%;height:100%;display:block">new window</a>
<a href="https://example.com/clicked-link"
   style="position:fixed;right:0;top:0;width:50%;height:100%;display:block">same window</a>
<script>
const results = {};
function xhr(url) {
  return new Promise((resolve) => {
    try {
      const request = new XMLHttpRequest();
      request.open('GET', url);
      request.onload = () => resolve('read:' + request.responseText.length);
      request.onerror = () => resolve('blocked');
      request.send();
    } catch (e) {
      resolve('blocked:' + e.name);
    }
  });
}
async function viaFetch(url) {
  try {
    const response = await fetch(url);
    return 'read:' + (await response.text()).length;
  } catch (e) {
    return 'blocked:' + e.name;
  }
}
function image(url) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => resolve('loaded');
    img.onerror = () => resolve('blocked');
    img.src = url;
  });
}
(async () => {
  results.xhrSystemFile = await xhr('file:///etc/hostname');
  results.fetchSystemFile = await viaFetch('file:///etc/hostname');
  results.xhrOutsideFolder = await xhr('$outsideText');
  results.imageOutsideFolder = await image('$outsideImage');
  results.imageInsideFolder = await image('inside.png');
  // A popup the owner never asked for, at a local file: upstream loaded
  // every popup into the page itself.
  const popup = window.open('file:///etc/hostname');
  // And one to the web, which nobody clicked: not offered to the application.
  const scripted = window.open('https://example.com/scripted');
  results.popup = popup === null && scripted === null ? 'blocked' : 'opened';
  document.title = 'RESULT:' + JSON.stringify(results);
  // And a navigation away from the folder, driven by script.
  setTimeout(() => { location.href = 'file:///etc/'; }, 100);
})();
</script>
</body></html>
''';

/// A 1x1 transparent PNG.
final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);
