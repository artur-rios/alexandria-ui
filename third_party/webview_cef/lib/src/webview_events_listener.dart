// Alexandria fork of webview_cef 0.6.2: modified file (see FORK.md).

import 'package:webview_cef/src/webview.dart';

typedef TitleChangeCb = void Function(String title);
typedef UrlChangeCb = void Function(String url);
/* Log severity levels. from CEF include/internal/cef_types.h
  0:default logging (currently info logging)
  1:verbose logging or debug logging
  2:info logging
  3:warning logging
  4:error logging
  5:fatal logging
  99:disable logging to file for all messages, and to stderr for messages with severity less than fatal
 */
typedef LoadStartCb = void Function(WebViewController controller, String url);
typedef LoadStopCb = void Function(WebViewController controller, String url);

typedef OnConsoleMessage = void Function(
    int level, String message, String source, int line);

// Alexandria fork: the page's own document could not be loaded. [errorCode]
// is Chromium's net error (e.g. -6 for a file that is not there).
typedef LoadErrorCb = void Function(
    WebViewController controller, String url, int errorCode, String errorText);

// Alexandria fork: the owner clicked a link to a web or mail address. The
// engine never follows one itself; whether and how it is opened is the host's
// decision.
typedef OpenLinkRequestedCb = void Function(String url);

class WebviewEventsListener {
  TitleChangeCb? onTitleChanged;
  UrlChangeCb? onUrlChanged;
  OnConsoleMessage? onConsoleMessage;
  LoadStartCb? onLoadStart;
  LoadStopCb? onLoadEnd;
  LoadErrorCb? onLoadError;
  OpenLinkRequestedCb? onOpenLinkRequested;

  WebviewEventsListener({
    this.onTitleChanged,
    this.onUrlChanged,
    this.onConsoleMessage,
    this.onLoadStart,
    this.onLoadEnd,
    this.onLoadError,
    this.onOpenLinkRequested,
  });
}
