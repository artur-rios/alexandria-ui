/// Hands a URL to the platform's default browser (FR-OG-11).
///
/// Behind an interface because AF-04 — no browser could be launched — is a
/// flow that has to be reachable in a test, and a widget test has no desktop
/// to fail to open one on.
abstract interface class BrowserLauncher {
  /// Opens [url], answering whether the platform took it.
  Future<bool> open(String url);
}
