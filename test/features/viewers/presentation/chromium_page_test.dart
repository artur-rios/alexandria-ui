import 'dart:async';

import 'package:alexandria_ui/features/viewers/presentation/chromium_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_cef/webview_cef.dart';

/// The page engine's side of UC-25 that has no Chromium in it: what the
/// viewer does with the answers the plugin gives (FR-VW-05, NFR-12).
///
/// The engine itself — that a page's script cannot read local files or leave
/// its folder — is proven against the real Chromium in
/// `integration_test/viewers/saved_page_engine_test.dart`. What is proven
/// here is the half that lives in this application: a link the engine hands
/// over is opened only when it is a web or mail address, and a refusal to
/// start is told apart from any other failure, so the owner can be told why
/// the page is drawn without its engine.
void main() {
  const channel = MethodChannel('webview_cef');
  const codec = StandardMethodCodec();

  late List<String> calls;
  late Object? Function(MethodCall call) answer;
  var nextBrowser = 100;

  setUp(() {
    calls = [];
    answer = (call) => switch (call.method) {
      'create' => [++nextBrowser, 1],
      'hasNativeKeySupport' => true,
      _ => null,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return answer(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Pumps a page and lets the plugin's start-up delays run out.
  Future<({List<PageEngineFailure> failures, List<Uri> opened})> pumpPage(
    WidgetTester tester,
  ) async {
    final failures = <PageEngineFailure>[];
    final opened = <Uri>[];
    if (WebviewManager().value) {
      // Started by an earlier test, whose fake clock is gone: the manager's
      // "ready" future belongs to that test's zone and would never resolve
      // in this one. Starting it again here gives it one that does — the
      // plugin side treats a second `init` as a no-op, as the real one does.
      unawaited(WebviewManager().initialize());
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpWidget(
      MaterialApp(
        home: ChromiumPage(
          fileUrl: 'file:///home/owner/pages/Article.html',
          onFailed: failures.add,
          openLink: (link) async => opened.add(link),
        ),
      ),
    );
    // WebviewManager.initialize waits 300 ms, the controller 50 ms more.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    return (failures: failures, opened: opened);
  }

  /// Delivers [method] from the plugin's native side, as Chromium would.
  Future<void> fromNative(
    WidgetTester tester,
    String method,
    Map<String, Object?> arguments,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
    await tester.pump();
  }

  /// Unmounts the page, so its load deadline is cancelled before the test
  /// ends.
  Future<void> closePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  // These run in order over one plugin: WebviewManager is a process-wide
  // singleton, and a Chromium that started stays started.
  testWidgets(
    'GivenNoUsableSandbox_WhenThePageOpens_ThenTheViewerIsToldItWasTheSandbox',
    (tester) async {
      answer = (call) => call.method == 'init'
          ? throw PlatformException(
              code: 'sandbox-unavailable',
              message: "Chromium's sandbox does not run as root",
            )
          : null;

      final page = await pumpPage(tester);

      expect(page.failures, [PageEngineFailure.sandboxUnavailable]);
      expect(calls, isNot(contains('create')));
      await closePage(tester);
    },
  );

  testWidgets(
    'GivenChromiumFailsForAnotherReason_WhenThePageOpens_ThenTheFailureIsNotBlamedOnTheSandbox',
    (tester) async {
      answer = (call) => call.method == 'init'
          ? throw PlatformException(code: 'engine-refused', message: 'no')
          : null;

      final page = await pumpPage(tester);

      expect(page.failures, [PageEngineFailure.other]);
      await closePage(tester);
    },
  );

  testWidgets(
    'GivenTheOwnerClicksLinks_WhenTheEngineHandsThemOver_ThenOnlyWebAndMailAddressesAreOpened',
    (tester) async {
      final page = await pumpPage(tester);
      expect(calls, contains('create'));
      final browser = nextBrowser;

      for (final url in [
        'https://example.com/article',
        'mailto:someone@example.com',
        // The plugin only ever hands over the two above; these prove the
        // application's own rule still stands behind it.
        'file:///home/owner/tool.sh',
        'ms-msdt:/id PCWDiagnostic',
        'javascript:alert(1)',
        'https://',
      ]) {
        await fromNative(tester, 'onOpenLinkRequested', {
          'browserId': browser,
          'url': url,
        });
      }

      expect(page.opened, [
        Uri.parse('https://example.com/article'),
        Uri.parse('mailto:someone@example.com'),
      ]);
      expect(page.failures, isEmpty);
      await closePage(tester);
    },
  );

  testWidgets(
    'GivenThePageCannotBeLoaded_WhenTheEngineReportsIt_ThenTheViewerFallsBackAtOnce',
    (tester) async {
      final page = await pumpPage(tester);
      final browser = nextBrowser;

      await fromNative(tester, 'onLoadError', {
        'browserId': browser,
        'url': 'file:///home/owner/pages/Article.html',
        'errorCode': -6,
        'errorText': 'net::ERR_FILE_NOT_FOUND',
      });

      expect(page.failures, [PageEngineFailure.other]);
      await closePage(tester);
    },
  );
}
