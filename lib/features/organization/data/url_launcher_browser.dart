import 'package:url_launcher/url_launcher.dart';

import '../domain/bookmark.dart';
import '../domain/browser_launcher.dart';

/// [BrowserLauncher] over `url_launcher` (FR-OG-11).
class UrlLauncherBrowser implements BrowserLauncher {
  /// Creates the launcher.
  ///
  /// [launch] is the platform's opener, injectable so a test can see what
  /// would have been handed to it without a platform channel.
  const UrlLauncherBrowser({
    Future<bool> Function(Uri url, {LaunchMode mode}) launch = launchUrl,
  })
    // An initializing formal is impossible here: the field is private and a
    // named parameter cannot be.
    // ignore: prefer_initializing_formals
    : _launch = launch;

  final Future<bool> Function(Uri url, {LaunchMode mode}) _launch;

  @override
  Future<bool> open(String url) async {
    // The form's own rule, applied again here: a bookmark can reach the
    // catalog without passing through this application's form — the core
    // takes any `scheme://` over its HTTP surface — and the platform's opener
    // runs whatever it is handed. A `file:` path to a program, or a scheme
    // some installed application registered, is not a page to open in a
    // browser, and declining it falls into AF-04, which offers the URL to
    // copy instead.
    if (validateBookmarkUrl(url) != null) return false;

    final parsed = Uri.tryParse(url.trim());
    if (parsed == null) return false;

    try {
      // An external application, explicitly: a bookmark is a page the owner
      // saved to read in their browser, not something this application shows.
      return await _launch(parsed, mode: LaunchMode.externalApplication);
    } on Object {
      // Broad by intent: the platform channel throws where no handler is
      // registered, and to the owner that is the same thing as a refusal —
      // AF-04, which offers the URL to copy instead.
      return false;
    }
  }
}
