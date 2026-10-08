import 'package:alexandria_ui/features/organization/data/url_launcher_browser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opening a bookmark in the owner's browser (FR-OG-11).
void main() {
  late List<Uri> launched;
  late UrlLauncherBrowser browser;

  setUp(() {
    launched = [];
    browser = UrlLauncherBrowser(
      launch: (url, {mode = LaunchMode.platformDefault}) async {
        launched.add(url);
        return true;
      },
    );
  });

  test('GivenAWebAddress_WhenItIsOpened_ThenTheBrowserIsAskedForIt', () async {
    expect(await browser.open('https://example.com/article'), isTrue);
    expect(launched, [Uri.parse('https://example.com/article')]);
  });

  // The form refuses these, but a bookmark can reach the catalog without the
  // form — the core accepts any `scheme://` over HTTP — and the platform's
  // opener runs a program path or a registered scheme it is handed.
  for (final url in [
    'file:///C:/Users/owner/Downloads/tool.bat',
    'file://attacker/share/payload.exe',
    'ms-msdt://id/PCWDiagnostic',
    'javascript://example.com/%0Aalert(1)',
  ]) {
    test(
      'GivenABookmarkThatIsNotAWebPage_WhenItIsOpened_ThenNothingIsLaunched: $url',
      () async {
        expect(await browser.open(url), isFalse);
        expect(launched, isEmpty);
      },
    );
  }
}
