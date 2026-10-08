import 'package:alexandria_ui/features/viewers/presentation/page_widget_factory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which links a rendered page may hand to the platform's opener (UC-25).
void main() {
  for (final url in [
    'https://example.com/page',
    'HTTP://example.com/',
    'mailto:owner@example.com',
  ]) {
    test('GivenAWebOrMailAddress_WhenTapped_ThenItMayBeOpened: $url', () {
      expect(isLinkTheViewerMayOpen(url), isTrue);
    });
  }

  // A relative `href="tool.bat"` in a saved page resolves against its folder
  // to the first of these, which the platform's opener would run.
  for (final url in [
    'file:///C:/Users/owner/pages/tool.bat',
    'file://attacker/share/x.exe',
    'ms-msdt:/id PCWDiagnostic',
    'search-ms:query=x',
    'javascript:alert(1)',
    'file:///home/owner/pages/#section',
  ]) {
    test('GivenAnythingElse_WhenTapped_ThenItIsNotOpened: $url', () {
      expect(isLinkTheViewerMayOpen(url), isFalse);
    });
  }
}
