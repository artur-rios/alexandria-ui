import 'package:alexandria_desktop/features/organization/domain/bookmark.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a bookmark can be sent to the core (UC-28 AF-01, FR-OG-12).
void main() {
  group('addresses the form accepts', () {
    for (final url in [
      'https://example.com',
      'http://example.com/path?query=1#fragment',
      'https://example.com:8443/deep/path',
      'https://sub.domain.example.com',
    ]) {
      test('Given"$url"_WhenItIsValidated_ThenItIsAccepted', () {
        expect(validateBookmarkUrl(url), isNull);
      });
    }

    test('GivenSurroundingWhitespace_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateBookmarkUrl('  https://example.com  '), isNull);
    });
  });

  group('addresses it refuses', () {
    test('GivenNothing_WhenItIsValidated_ThenItIsRefusedAsEmpty', () {
      expect(validateBookmarkUrl(''), BookmarkFieldError.empty);
      expect(validateBookmarkUrl('   '), BookmarkFieldError.empty);
    });

    // A bare word parses as a relative reference, which is not something a
    // browser can be handed.
    test('GivenABareWord_WhenItIsValidated_ThenItIsRefused', () {
      expect(validateBookmarkUrl('example'), BookmarkFieldError.unopenableUrl);
    });

    test('GivenNoHost_WhenItIsValidated_ThenItIsRefused', () {
      expect(validateBookmarkUrl('https://'), BookmarkFieldError.unopenableUrl);
    });

    // A bookmark is a page. Neither of these is one, and handing either to the
    // platform's opener is not what the owner saved a bookmark for.
    test('GivenAFileUrl_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateBookmarkUrl('file:///home/owner/notes.txt'),
        BookmarkFieldError.unopenableUrl,
      );
    });

    test('GivenAJavascriptUrl_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateBookmarkUrl('javascript:alert(1)'),
        BookmarkFieldError.unopenableUrl,
      );
    });

    test('GivenAMalformedUrl_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateBookmarkUrl('http://[not a host]'),
        BookmarkFieldError.malformedUrl,
      );
    });
  });

  group('the title', () {
    test('GivenATitle_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateBookmarkTitle('An article'), isNull);
    });

    test('GivenNothing_WhenItIsValidated_ThenItIsRefused', () {
      expect(validateBookmarkTitle(''), BookmarkFieldError.empty);
    });

    test('GivenOnlyWhitespace_WhenItIsValidated_ThenItIsRefused', () {
      expect(validateBookmarkTitle('   '), BookmarkFieldError.empty);
    });
  });
}
