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
}
