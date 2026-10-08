import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// How this application draws HTML (UC-25, Technology Stack Document §3.4).
///
/// The renderer's own factory, with the one part of it this application will
/// not have switched off: an `<iframe>` is **not** given a web view.
///
/// Two reasons, and either alone would be enough. It crashes: `webview_flutter`
/// has no Linux or Windows implementation, so building one raises
/// `LateInitializationError` and the embed's place in the page becomes an
/// error box. And it would be a browser engine — the thing the stack document
/// says this viewer deliberately is not. A web view runs script, reaches the
/// network, and does both for whatever URL a saved page happens to name; a
/// page that "executes no script" while embedding a frame that does is not
/// telling the owner the truth.
///
/// What an `<iframe>` becomes instead is the renderer's own fallback: a link
/// to where it pointed, which the owner can open in their browser if they want
/// what was there.
class PageWidgetFactory extends WidgetFactory {
  @override
  bool get webView => false;

  /// Hands a tapped link to the platform's opener only when it is a web
  /// address; an in-page anchor scrolls, and anything else does nothing.
  ///
  /// The renderer's own factory passes *every* link to `url_launcher`, and
  /// a saved page, an EPUB chapter, or a Markdown note is content from
  /// elsewhere. A relative `href="tool.bat"` resolves against the page's
  /// folder to a `file:` URL the platform runs on one click, and a scheme
  /// some installed program registered does whatever that program does.
  @override
  Future<bool> onTapUrl(String url) async {
    if (isLinkTheViewerMayOpen(url)) return super.onTapUrl(url);

    if (await onTapCallback(url)) return true;

    final hash = url.indexOf('#');
    if (hash >= 0) await onTapAnchorWrapper(url.substring(hash + 1));

    // Handled either way: returning false would let the caller treat the
    // link as unhandled, and the refusal is the handling.
    return true;
  }
}

/// Whether [url] may be handed to the platform's opener from a rendered
/// page: web and mail addresses only.
bool isLinkTheViewerMayOpen(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;

  return switch (uri.scheme.toLowerCase()) {
    'http' || 'https' => uri.host.isNotEmpty,
    'mailto' => true,
    _ => false,
  };
}
