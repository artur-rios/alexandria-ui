import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:webview_cef/webview_cef.dart';

/// A saved page drawn by Chromium (UC-25, FR-VW-05).
///
/// The widget renderer this replaced honoured an element's `style` attribute
/// and a subset of CSS properties, which is a reader for a page rather than
/// the page: no layout engine, no `@media`, no hover, no script. This is the
/// engine itself — CEF, rendered off-screen and composed into the window as a
/// texture — so a saved page looks the way it looked in the browser it was
/// saved from.
///
/// **It runs the page's script.** That is what an engine is, and it is the
/// trade this application made deliberately when it chose one; the stack
/// document records the reasoning. A page is loaded over `file:` from the
/// owner's own disk, which is the one thing that keeps the blast radius
/// sensible: Chromium refuses a `file:` document access to other local files,
/// so a saved page can act on itself and reach the network, and cannot read
/// the library around it.
class ChromiumPage extends StatefulWidget {
  /// Draws the page at [fileUrl], which must be a `file:` URL.
  const ChromiumPage({
    required this.fileUrl,
    required this.onFailed,
    super.key,
  });

  /// What to load.
  final String fileUrl;

  /// Called when the engine could not be started, or started and then never
  /// read the file.
  ///
  /// A machine without a working CEF — an unpacked build, a missing library,
  /// a sandbox that refuses it — still has a library full of saved pages, so
  /// the viewer falls back to drawing the markup itself rather than showing
  /// the owner an empty frame (`PageViewerScreen`).
  ///
  /// What it cannot answer for is an engine that reads the file and then draws
  /// nothing: `webview_cef` reports a load, and reports no frame. A page whose
  /// texture stays empty is a page this callback never hears about.
  final VoidCallback onFailed;

  @override
  State<ChromiumPage> createState() => _ChromiumPageState();
}

class _ChromiumPageState extends State<ChromiumPage> {
  static final Logger _log = Logger('viewers');

  /// How long the engine has to produce a page before the viewer gives up on
  /// it.
  ///
  /// Chromium takes a moment to start — this is generous for that. What it is
  /// really for is the case where nothing is coming at all: a plugin whose
  /// native half never registered answers politely and then never calls back,
  /// and without a deadline the owner watches a spinner forever over a file
  /// this application could have drawn itself. Failing after ten seconds is a
  /// page; waiting is not.
  static const Duration _startupBudget = Duration(seconds: 10);

  /// How long the engine has to finish loading the file after it has started.
  ///
  /// Separate from [_startupBudget] because they are different failures: that
  /// one is Chromium never coming up, this one is Chromium coming up and then
  /// never reading the file. The document is on the owner's own disk, so this
  /// is many times longer than it can honestly take.
  static const Duration _loadBudget = Duration(seconds: 15);

  late final WebViewController _controller;

  /// Whether the engine got far enough to own anything worth closing.
  bool _started = false;

  /// Runs while the engine has a file open and has not said it read it.
  Timer? _loadDeadline;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView(
      loading: const Center(child: CircularProgressIndicator()),
    );
    // Set before the load starts, not after: `initialize` is what begins it,
    // and a listener attached afterwards can miss the event it is waiting for
    // on a file that was quick to read.
    _controller.setWebviewListener(
      WebviewEventsListener(
        onLoadEnd: (_, _) {
          _loadDeadline?.cancel();
          _loadDeadline = null;
        },
      ),
    );
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      // Once for the process, not once per page: the manager is a singleton
      // over one Chromium, and initializing it twice is what would leave two
      // sets of sub-processes behind.
      if (!WebviewManager().value) {
        await WebviewManager().initialize().timeout(_startupBudget);
      }

      await _controller.initialize(widget.fileUrl).timeout(_startupBudget);
      _started = true;
      // Armed only now: before this there is no browser to be waiting on, and
      // a slow start is already [_startupBudget]'s to complain about.
      _loadDeadline = Timer(_loadBudget, _giveUp);
    } on Object catch (error) {
      // Not raised: a page that cannot be drawn by the engine is a page this
      // application can still draw itself, and that is a better answer than a
      // failure view over a file that is sitting right there.
      _log.warning('the page engine would not start', error);
      if (mounted) widget.onFailed();
    }
  }

  @override
  void dispose() {
    // The controller only, never `WebviewManager().quit()`: that tears down
    // Chromium for the whole process, and the owner is closing one page.
    //
    // And only one that started: closing a controller that never opened a
    // browser reaches for state the plugin only creates on the way up, and
    // raises `LateInitializationError` out of a widget being unmounted —
    // which is a crash while leaving a page, over an engine that had already
    // failed.
    _loadDeadline?.cancel();
    if (_started) unawaited(_close());
    super.dispose();
  }

  /// Hands the page back to the markup renderer, once.
  void _giveUp() {
    _loadDeadline = null;
    _log.warning('the page engine did not read the file in $_loadBudget');
    if (mounted) widget.onFailed();
  }

  Future<void> _close() async {
    try {
      await _controller.dispose();
    } on Object catch (error) {
      // Nothing to do about it and nobody to tell: the page is gone from the
      // screen either way, and this is the last thing that happens to it.
      _log.warning('a page engine would not close', error);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _controller,
    builder: (context, ready, _) =>
        ready ? _controller.webviewWidget : _controller.loadingWidget,
  );
}
