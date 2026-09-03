import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as cssv;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

/// A saved page's markup as the renderer should see it (UC-25, FR-VW-05).
///
/// Two things, and they belong to one pass because both are about the part of
/// a document that is not its body: the page's own stylesheets are folded onto
/// the elements they style, and the head's text is dropped.
///
/// The renderer honours the `style` attribute of an element and nothing else:
/// a `<style>` block is drawn as `display: none`, and a `<link>` to a
/// stylesheet is a file it never opens. A saved article therefore arrived as
/// unstyled text — the words in the reader's default face, with none of the
/// page's own type, colour or spacing — which is what "it does not render the
/// page" meant. This puts the rules back where the renderer will read them.
///
/// What this is not: a browser. It resolves declarations onto elements; it
/// does not lay out a document. Rules that depend on something other than the
/// document itself are left out on purpose, and each exclusion is named where
/// it happens below.
///
/// [linkedStylesheet] answers a `<link>`'s `href` with the stylesheet's text,
/// or `null` for one this application will not open — anything on the network,
/// or a file that is not there. Reading from disk belongs to the gateway; this
/// function does no I/O, which is what makes the whole cascade testable
/// without one.
String preparedForRendering(
  String source, {
  required String? Function(String href) linkedStylesheet,
}) {
  final document = html.parse(source);
  final rules = _rulesOf(document, linkedStylesheet);

  // The renderer draws the head's text along with the body's, so a saved page
  // opened with a stray line of its own `<title>` above the headline — the
  // one piece of a document that is a label for it rather than part of it.
  // The viewer's own title bar is already showing the file's name.
  for (final title in document.querySelectorAll('title')) {
    title.remove();
  }

  // Sorted the way a browser resolves a conflict: the more specific selector
  // wins, and between two of equal specificity the later one does. Without
  // this, `a { color: blue }` further down a stylesheet would repaint every
  // link that `.byline a { color: grey }` had already claimed.
  rules.sort((a, b) {
    final bySpecificity = a.specificity.compareTo(b.specificity);

    return bySpecificity != 0 ? bySpecificity : a.order.compareTo(b.order);
  });

  final resolved = <dom.Element, Map<String, String>>{};
  for (final rule in rules) {
    final Iterable<dom.Element> matched;
    try {
      matched = document.querySelectorAll(rule.selector);
    } on Object {
      // The selector engine here is not a browser's either: `:hover` and the
      // rest of the state pseudo-classes raise rather than match. A rule this
      // application cannot resolve is skipped, which leaves the element with
      // whatever the rest of the sheet said about it — the same thing a
      // browser shows before the mouse arrives.
      continue;
    }

    for (final element in matched) {
      (resolved[element] ??= {}).addAll(rule.declarations);
    }
  }

  // The sheets themselves go once they have been read: every rule they hold
  // is now on the elements it applies to, and what is left is a block of text
  // the renderer would parse again to draw nothing with. A page's stylesheets
  // are still named to the owner when they are missing — that notice is read
  // from the file as saved (`DiskPageGateway`), not from this.
  for (final sheet in [
    ...document.querySelectorAll('style'),
    ...document
        .querySelectorAll('link')
        .where(
          (link) => (link.attributes['rel'] ?? '').toLowerCase().contains(
            'stylesheet',
          ),
        ),
  ]) {
    sheet.remove();
  }

  for (final entry in resolved.entries) {
    final element = entry.key;
    final declarations = entry.value;

    // The element's own attribute goes last, so it wins: an inline style beats
    // every rule in a sheet, and a page that set one meant it.
    final own = element.attributes['style'];
    element.attributes['style'] = [
      for (final declaration in declarations.entries)
        '${declaration.key}: ${declaration.value}',
      if (own != null && own.trim().isNotEmpty) own.trim(),
    ].join('; ');
  }

  return document.outerHtml;
}

/// One selector and what it says, with what it takes to outrank another.
class _Rule {
  const _Rule({
    required this.selector,
    required this.declarations,
    required this.specificity,
    required this.order,
  });

  final String selector;
  final Map<String, String> declarations;
  final int specificity;
  final int order;
}

/// Every rule the page carries, in the order the page carries them.
List<_Rule> _rulesOf(
  dom.Document document,
  String? Function(String href) linkedStylesheet,
) {
  final rules = <_Rule>[];

  // Walked in document order rather than `<style>` blocks first and links
  // after: a page that links a sheet and then overrides three rules of it in
  // a block is the common shape, and reversing the two would undo exactly the
  // overrides it wrote.
  for (final element in document.querySelectorAll('*')) {
    final text = switch (element.localName) {
      'style' => element.text,
      'link' =>
        (element.attributes['rel'] ?? '').toLowerCase().contains('stylesheet')
            ? linkedStylesheet(element.attributes['href'] ?? '')
            : null,
      _ => null,
    };
    if (text == null || text.trim().isEmpty) continue;

    _collectInto(rules, text);
  }

  return rules;
}

/// The most rules one page's styling is read from.
///
/// A saved page often links a whole framework's stylesheet — tens of thousands
/// of rules written for every page of a site, of which this one uses a
/// handful. Each rule costs a walk of the document, so the sheet is read until
/// this many have been kept and then left: the rules a page's own styling
/// starts with are the ones at the top of its own sheet, and an article that
/// needs its ten-thousandth rule to be readable is not a case worth making
/// every other page wait for.
const int _ruleCeiling = 2000;

void _collectInto(List<_Rule> rules, String text) {
  final cssv.StyleSheet sheet;
  try {
    sheet = css.parse(text);
  } on Object {
    // A stylesheet nobody can parse styles nothing, which is the state the
    // page was already in.
    return;
  }

  for (final top in sheet.topLevels) {
    if (rules.length >= _ruleCeiling) return;

    // Only unconditional rules. `@media` is the interesting exclusion: this
    // is not a viewport a page's breakpoints were written for, and a print
    // sheet applied to a screen is worse than no sheet at all. `@font-face`
    // and `@keyframes` describe things this renderer has no way to do.
    if (top is! cssv.RuleSet) continue;

    final selectors = top.selectorGroup?.span?.text;
    if (selectors == null) continue;

    final declarations = _declarationsOf(top.declarationGroup);
    // A rule saying nothing the renderer reads is not worth matching against
    // the document — and on a framework stylesheet that is most of them.
    if (declarations.isEmpty) continue;

    for (final selector in selectors.split(',')) {
      final trimmed = selector.trim();
      if (trimmed.isEmpty) continue;

      rules.add(
        _Rule(
          selector: trimmed,
          declarations: declarations,
          specificity: _specificityOf(trimmed),
          order: rules.length,
        ),
      );
    }
  }
}

/// The declarations of [group] the renderer will actually read.
Map<String, String> _declarationsOf(cssv.DeclarationGroup group) {
  final declarations = <String, String>{};

  for (final declaration in group.declarations) {
    final text = declaration.span?.text;
    if (text == null) continue;

    final colon = text.indexOf(':');
    if (colon <= 0) continue;

    final property = text.substring(0, colon).trim().toLowerCase();
    if (!_isHonoured(property)) continue;

    // `!important` is dropped rather than passed on: it is a cascade
    // instruction, and the value it decorates is what the renderer parses.
    final value = text
        .substring(colon + 1)
        .replaceAll(RegExp(r'!\s*important', caseSensitive: false), '')
        .trim();
    if (value.isEmpty) continue;

    declarations[property] = value;
  }

  return declarations;
}

/// The properties the renderer reads (`flutter_widget_from_html_core`).
///
/// Kept as a set rather than passing everything through, for the reason the
/// ceiling exists: a framework stylesheet is mostly `position`, `transform`,
/// `transition` and `z-index`, none of which this renderer has an answer for.
/// Dropping them here is what keeps the matching work proportional to the
/// styling a page actually gets.
const Set<String> _honouredProperties = {
  'align-items',
  'color',
  'direction',
  'display',
  'flex-direction',
  'gap',
  'height',
  'justify-content',
  'line-height',
  'list-style-type',
  'max-height',
  'max-width',
  'min-height',
  'min-width',
  'text-align',
  'text-overflow',
  'text-shadow',
  'vertical-align',
  'white-space',
  'width',
};

/// The families whose longhands the renderer reads as well as their shorthand.
const List<String> _honouredFamilies = [
  'background',
  'border',
  'font',
  'margin',
  'padding',
  'text-decoration',
  'text-emphasis',
];

bool _isHonoured(String property) =>
    _honouredProperties.contains(property) ||
    _honouredFamilies.any(
      (family) => property == family || property.startsWith('$family-'),
    );

/// How strongly [selector] claims what it styles.
///
/// The CSS rule, counted the CSS way: identifiers are worth a hundred,
/// classes and attributes and pseudo-classes ten, element names one. Counted
/// from the text rather than from a parsed selector because that is all this
/// needs — the number only ever orders one rule against another.
int _specificityOf(String selector) {
  final ids = RegExp(r'#[\w-]+').allMatches(selector).length;
  final classes =
      RegExp(r'\.[\w-]+').allMatches(selector).length +
      RegExp(r'\[[^\]]*\]').allMatches(selector).length +
      RegExp(r'(?<!:):[\w-]+').allMatches(selector).length;
  final elements = RegExp(
    r'(^|[\s>+~])[a-zA-Z][\w-]*',
  ).allMatches(selector).length;

  return ids * 100 + classes * 10 + elements;
}
