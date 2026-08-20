import 'package:url_launcher/url_launcher.dart';

import '../domain/browser_launcher.dart';

/// [BrowserLauncher] over `url_launcher` (FR-OG-11).
class UrlLauncherBrowser implements BrowserLauncher {
  /// Creates the launcher.
  const UrlLauncherBrowser();

  @override
  Future<bool> open(String url) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return false;

    try {
      // An external application, explicitly: a bookmark is a page the owner
      // saved to read in their browser, not something this application shows.
      return await launchUrl(parsed, mode: LaunchMode.externalApplication);
    } on Object {
      // Broad by intent: the platform channel throws where no handler is
      // registered, and to the owner that is the same thing as a refusal —
      // AF-04, which offers the URL to copy instead.
      return false;
    }
  }
}
