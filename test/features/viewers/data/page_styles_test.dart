import 'package:alexandria_ui/features/viewers/data/page_styles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Folding a saved page's own stylesheets onto the elements they style
/// (UC-25, FR-VW-05).
///
/// The renderer honours an element's `style` attribute and nothing else: a
/// `<style>` block is drawn as `display: none` and a linked sheet is a file it
/// never opens. A page arrived as unstyled text because of it, which is what
/// these cases are about — every one of them asserts the attribute the
/// renderer will read, because that is the only thing about this pass the
/// renderer can see.
void main() {
  /// Prepares [source] with no linked stylesheet available.
  String prepared(String source, {Map<String, String> sheets = const {}}) =>
      preparedForRendering(source, linkedStylesheet: (href) => sheets[href]);

  group('a style block', () {
    test('GivenARuleForATag_WhenThePageIsPrepared_ThenItSitsOnTheElement', () {
      final html = prepared(
        '<html><head><style>p { color: #112233; }</style></head>'
        '<body><p>Words</p></body></html>',
      );

      expect(html, contains('<p style="color: #112233">Words</p>'));
    });

    test('GivenARuleForAClass_WhenThePageIsPrepared_ThenOnlyThatOneGetsIt', () {
      final html = prepared(
        '<html><head><style>.lede { font-style: italic; }</style></head>'
        '<body><p class="lede">One</p><p>Two</p></body></html>',
      );

      expect(html, contains('<p class="lede" style="font-style: italic">One'));
      expect(
        html,
        contains('<p>Two</p>'),
        reason: 'a rule that matched nothing here must not style everything',
      );
    });

    test('GivenNoStylesheetAtAll_WhenThePageIsPrepared_ThenNothingIsAdded', () {
      final html = prepared('<html><body><p>Words</p></body></html>');

      expect(html, isNot(contains('style=')));
    });
  });

  group('a linked stylesheet', () {
    test('GivenALocalSheet_WhenThePageIsPrepared_ThenItsRulesApply', () {
      // The common shape of a saved page: the styling is in a file beside it,
      // and the markup only points at it.
      final html = prepared(
        '<html><head><link rel="stylesheet" href="assets/site.css"></head>'
        '<body><h1>Headline</h1></body></html>',
        sheets: {'assets/site.css': 'h1 { color: #ff0000; }'},
      );

      expect(html, contains('<h1 style="color: #ff0000">Headline</h1>'));
    });

    test(
      'GivenASheetThatIsNotThere_WhenThePageIsPrepared_ThenItStillDraws',
      () {
        // AF-02: a page whose stylesheet was not saved with it is a page that
        // reads plainly, not a page that fails to open.
        final html = prepared(
          '<html><head><link rel="stylesheet" href="gone.css"></head>'
          '<body><h1>Headline</h1></body></html>',
        );

        expect(html, contains('<h1>Headline</h1>'));
      },
    );

    test('GivenANonStylesheetLink_WhenThePageIsPrepared_ThenItIsNotRead', () {
      // A `<link>` is also how a page names its icon and its feeds; only the
      // stylesheets are styling.
      final asked = <String>[];
      preparedForRendering(
        '<html><head><link rel="icon" href="favicon.ico"></head>'
        '<body><p>Words</p></body></html>',
        linkedStylesheet: (href) {
          asked.add(href);
          return null;
        },
      );

      expect(asked, isEmpty);
    });
  });

  group('the cascade', () {
    test('GivenTwoRulesForOneElement_WhenTheyTie_ThenTheLaterWins', () {
      final html = prepared(
        '<html><head><style>p { color: #111111; } p { color: #222222; }'
        '</style></head><body><p>Words</p></body></html>',
      );

      expect(html, contains('color: #222222'));
      expect(html, isNot(contains('#111111')));
    });

    test('GivenAClassAndATag_WhenTheyDisagree_ThenTheClassWins', () {
      // Specificity, and it is not decoration: a stylesheet almost always
      // states the general rule after the specific one, so ordering alone
      // would repaint every element its own classes had claimed.
      final html = prepared(
        '<html><head><style>.lede { color: #aaaaaa; } p { color: #bbbbbb; }'
        '</style></head><body><p class="lede">Words</p></body></html>',
      );

      expect(html, contains('color: #aaaaaa'));
    });

    test('GivenALinkedSheetAndABlock_WhenBothMatch_ThenTheBlockWins', () {
      // Document order across sources: a page that links a sheet and then
      // overrides three of its rules in a block is the ordinary shape, and
      // reading the block first would undo exactly those overrides.
      final html = prepared(
        '<html><head><link rel="stylesheet" href="s.css">'
        '<style>h1 { color: #0000ff; }</style></head>'
        '<body><h1>Headline</h1></body></html>',
        sheets: {'s.css': 'h1 { color: #ff0000; }'},
      );

      expect(html, contains('color: #0000ff'));
    });

    test('GivenAnInlineStyle_WhenARuleAlsoMatches_ThenTheInlineOneWins', () {
      final html = prepared(
        '<html><head><style>p { color: #111111; }</style></head>'
        '<body><p style="color: #999999">Words</p></body></html>',
      );

      // Last in the attribute is what the renderer resolves to, which is the
      // page's own inline declaration.
      expect(html, contains('style="color: #111111; color: #999999"'));
    });
  });

  group('what is deliberately left out', () {
    test('GivenAMediaQuery_WhenThePageIsPrepared_ThenItIsNotApplied', () {
      // This is not the viewport those breakpoints were written for, and a
      // print sheet applied to a screen is worse than no sheet at all.
      final html = prepared(
        '<html><head><style>@media print { p { color: #ff0000; } }</style>'
        '</head><body><p>Words</p></body></html>',
      );

      expect(html, isNot(contains('#ff0000')));
    });

    test('GivenAStatePseudoClass_WhenThePageIsPrepared_ThenItIsSkipped', () {
      // `a:hover` cannot be resolved against a document — and a page whose
      // links were all painted with their hover colour would be wrong in a
      // way the owner can see.
      final html = prepared(
        '<html><head><style>a:hover { color: #ff0000; } a { color: #00ff00; }'
        '</style></head><body><a href="/x">Link</a></body></html>',
      );

      expect(html, contains('color: #00ff00'));
      expect(html, isNot(contains('#ff0000')));
    });

    test(
      'GivenAPropertyTheRendererIgnores_WhenPrepared_ThenItIsNotCarried',
      () {
        // A framework stylesheet is mostly properties this renderer has no
        // answer for. Dropping them is what keeps the matching work
        // proportional to the styling a page actually gets.
        final html = prepared(
          '<html><head><style>p { position: absolute; z-index: 4; '
          'color: #123456; }</style></head><body><p>Words</p></body></html>',
        );

        expect(html, contains('color: #123456'));
        expect(html, isNot(contains('position')));
        expect(html, isNot(contains('z-index')));
      },
    );

    test('GivenAnImportantRule_WhenThePageIsPrepared_ThenTheValueIsClean', () {
      // The renderer parses the value, not the cascade instruction attached
      // to it.
      final html = prepared(
        '<html><head><style>p { color: #123456 !important; }</style></head>'
        '<body><p>Words</p></body></html>',
      );

      expect(html, contains('color: #123456'));
      expect(html, isNot(contains('important')));
    });

    test('GivenUnparseableCss_WhenThePageIsPrepared_ThenThePageStillDraws', () {
      final html = prepared(
        '<html><head><style>p { color: </style></head>'
        '<body><p>Words</p></body></html>',
      );

      expect(html, contains('Words'));
    });
  });

  group("the head's text", () {
    test('GivenATitle_WhenThePageIsPrepared_ThenItIsNotDrawnAsContent', () {
      // The renderer draws the head's text with the body's, so a saved page
      // opened with a stray line of its own title above the headline.
      final html = prepared(
        '<html><head><title>A page</title></head>'
        '<body><h1>Headline</h1></body></html>',
      );

      expect(html, isNot(contains('A page')));
      expect(html, contains('Headline'));
    });
  });
}
